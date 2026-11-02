class_name ChunkManager
extends Node3D

const Chunk: GDScript = preload("res://scripts/chunk.gd")
const ChunkGenerator: GDScript = preload("res://scripts/chunk_generator.gd")
const ChunkMesher: GDScript = preload("res://scripts/chunk_mesher.gd")
const ChunkRenderer: GDScript = preload("res://scripts/chunk_renderer.gd")
const WorldSave: GDScript = preload("res://scripts/world_save.gd")

const DEFAULT_VIEW_RADIUS: int = 4
const STREAM_INTERVAL: float = 0.1
const LOADS_PER_TICK: int = 2
const REBUILD_INTERVAL: float = 1.0 / 30.0
const SPAWN_CHUNK: Vector2i = Vector2i(0, 0)
const REFRESH_PER_TICK: int = 2
## Chunks built on worker threads that are added to the world each frame
const ADDS_PER_FRAME: int = 1
const NEIGHBOUR_DIRS: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)
]

signal chunk_loaded(chunk)
signal chunk_unloaded(chunk)
signal chunk_rebuilt(chunk)

@export var view_radius: int = DEFAULT_VIEW_RADIUS
@export var block_materials: Dictionary = {}
@export var auto_save_on_unload: bool = true

var active_chunks: Dictionary = {}
var dirty_rebuilds: Array = []
var _player: Node3D = null
var _chunk_scene: PackedScene = preload("res://scenes/chunk.tscn")
var _streaming_timer: Timer
var _rebuild_timer: Timer
var _streaming_dirty: bool = true
var _render_refresh: Array = []
## Chunk key -> {task, out, neighbours, edits} for the worker thread jobs that
## build new chunks and redraw loaded ones
var _builds: Dictionary = {}
var _refreshes: Dictionary = {}
## Counts block and facing changes, so a job can tell its copy is out of date
var _edits: int = 0


func _ready() -> void:
	_streaming_timer = Timer.new()
	_streaming_timer.wait_time = STREAM_INTERVAL
	_streaming_timer.autostart = true
	_streaming_timer.one_shot = false
	_streaming_timer.timeout.connect(_on_streaming_tick)
	add_child(_streaming_timer)

	_rebuild_timer = Timer.new()
	_rebuild_timer.wait_time = REBUILD_INTERVAL
	_rebuild_timer.autostart = true
	_rebuild_timer.one_shot = false
	_rebuild_timer.timeout.connect(_on_rebuild_tick)
	add_child(_rebuild_timer)

	_load_chunk_at(SPAWN_CHUNK)


func _process(_delta: float) -> void:
	_add_built_chunks(ADDS_PER_FRAME)
	_finish_refreshes()


func _exit_tree() -> void:
	for job: Dictionary in _builds.values() + _refreshes.values():
		WorkerThreadPool.wait_for_task_completion(job["task"])
	_builds.clear()
	_refreshes.clear()


func set_player(p: Node3D) -> void:
	_player = p
	_streaming_dirty = true
	# The ground under the player is there from the first frame
	ensure_chunk_at_world(p.global_position)


func set_view_radius(r: int) -> void:
	view_radius = maxi(1, r)
	_streaming_dirty = true


func get_chunk(cx: int, cz: int) -> Node3D:
	return active_chunks.get(Vector2i(cx, cz), null)


func ensure_chunk_at_world(world_pos: Vector3) -> Node3D:
	var cx: int = floori(world_pos.x / float(Chunk.CHUNK_X))
	var cz: int = floori(world_pos.z / float(Chunk.CHUNK_Z))
	var key: Vector2i = Vector2i(cx, cz)
	if active_chunks.has(key):
		return active_chunks[key]
	return _load_chunk_at(key)


func world_cell_to_chunk_key(cell: Vector3i) -> Vector2i:
	return Vector2i(floori(cell.x / float(Chunk.CHUNK_X)), floori(cell.z / float(Chunk.CHUNK_Z)))


func world_cell_to_local(cell: Vector3i) -> Vector3i:
	return Vector3i(posmod(cell.x, Chunk.CHUNK_X), cell.y, posmod(cell.z, Chunk.CHUNK_Z))


func get_block_at(cell: Vector3i) -> int:
	var key: Vector2i = world_cell_to_chunk_key(cell)
	if not active_chunks.has(key):
		return Chunk.AIR
	return active_chunks[key].get_block(world_cell_to_local(cell))


func set_block_at(cell: Vector3i, id: int) -> bool:
	if cell.y < 0 or cell.y >= Chunk.CHUNK_Y:
		return false
	var key: Vector2i = world_cell_to_chunk_key(cell)
	var chunk: Node3D = _load_chunk_at(key)
	if chunk == null:
		return false
	var local: Vector3i = world_cell_to_local(cell)
	chunk.set_block(local, id)
	_edits += 1
	request_rebuild(chunk)
	if local.x == 0:
		request_rebuild(get_chunk(key.x - 1, key.y))
	elif local.x == Chunk.CHUNK_X - 1:
		request_rebuild(get_chunk(key.x + 1, key.y))
	if local.z == 0:
		request_rebuild(get_chunk(key.x, key.y - 1))
	elif local.z == Chunk.CHUNK_Z - 1:
		request_rebuild(get_chunk(key.x, key.y + 1))
	return true


func get_facing_at(cell: Vector3i) -> int:
	var key: Vector2i = world_cell_to_chunk_key(cell)
	if not active_chunks.has(key):
		return 0
	return active_chunks[key].get_facing(world_cell_to_local(cell))


## Turns the item in cell by quarter turns (0-3). Only props use it.
func set_facing_at(cell: Vector3i, turns: int) -> void:
	var chunk: Node3D = get_chunk(world_cell_to_chunk_key(cell).x, world_cell_to_chunk_key(cell).y)
	if chunk == null:
		return
	chunk.set_facing(world_cell_to_local(cell), turns)
	_edits += 1
	request_rebuild(chunk)


func request_rebuild(chunk) -> void:
	if chunk == null:
		return
	if chunk not in dirty_rebuilds:
		dirty_rebuilds.append(chunk)


func save_dirty_chunks() -> int:
	var saved: int = 0
	for key in active_chunks:
		var chunk: Node3D = active_chunks[key]
		if chunk.is_dirty():
			var err: int = WorldSave.save_chunk(chunk)
			if err == OK:
				chunk.mark_clean()
				saved += 1
			else:
				push_warning("ChunkManager: save failed for %s err=%d" % [key, err])
	return saved


func _load_chunk_at(key: Vector2i) -> Node3D:
	if active_chunks.has(key):
		return active_chunks[key]
	var chunk: Node3D = _add_chunk(key)
	if chunk == null:
		return null

	var data: Dictionary = WorldSave.load_chunk_data(key.x, key.y)
	if not data.is_empty():
		chunk.from_dict(data)
	else:
		ChunkGenerator.generate(chunk)

	chunk.rebuild(_neighbour_blocks(key))
	chunk.mark_clean()
	_queue_render_refresh(key)
	chunk_loaded.emit(chunk)
	return chunk


## Adds an empty chunk at key to the world.
func _add_chunk(key: Vector2i) -> Node3D:
	var chunk: Node3D = _chunk_scene.instantiate()
	if chunk == null:
		push_error("ChunkManager: failed to instantiate chunk scene")
		return null
	chunk.cx = key.x
	chunk.cz = key.y
	chunk.position = Vector3(key.x * Chunk.CHUNK_X, 0, key.y * Chunk.CHUNK_Z)
	chunk.block_materials = block_materials
	add_child(chunk)
	active_chunks[key] = chunk
	return chunk


## Starts a worker thread generating and meshing the chunk at key.
func _start_build(key: Vector2i) -> void:
	var neighbours: Array = _neighbour_blocks(key, true)
	var out: Dictionary = {}
	var task: int = WorkerThreadPool.add_task(_build_job.bind(key, neighbours, block_materials, out))
	_builds[key] = {"task": task, "out": out, "neighbours": neighbours, "edits": _edits}


## Runs on a worker thread, so it touches no nodes.
func _build_job(key: Vector2i, neighbours: Array, materials: Dictionary, out: Dictionary) -> void:
	var blocks: Array[int] = ChunkGenerator.generate_blocks(key.x, key.y)
	out["blocks"] = blocks
	var built: Dictionary = ChunkMesher.build(blocks, materials)
	out["mesh"] = built["mesh"]
	out["faces"] = built["faces"]
	out["transforms"] = ChunkRenderer.transforms_for(blocks, neighbours)


## Adds up to max_adds chunks whose worker builds are done.
func _add_built_chunks(max_adds: int) -> void:
	var added: int = 0
	for key: Vector2i in _builds.keys():
		if added >= max_adds:
			return
		var job: Dictionary = _builds[key]
		if not WorkerThreadPool.is_task_completed(job["task"]):
			continue
		WorkerThreadPool.wait_for_task_completion(job["task"])
		_builds.erase(key)
		# set_block_at may have loaded it meanwhile
		if active_chunks.has(key):
			continue
		var chunk: Node3D = _add_chunk(key)
		if chunk == null:
			continue
		var out: Dictionary = job["out"]
		chunk.blocks = out["blocks"]
		chunk.apply_built(out["mesh"], out["faces"], out["transforms"])
		chunk.mark_clean()
		if _is_stale(key, job) and chunk not in _render_refresh:
			_render_refresh.append(chunk)
		_queue_render_refresh(key)
		chunk_loaded.emit(chunk)
		added += 1


## Starts a worker thread working out how to draw chunk with its side chunks.
func _start_refresh(chunk: Node3D) -> void:
	var key: Vector2i = Vector2i(chunk.cx, chunk.cz)
	var neighbours: Array = _neighbour_blocks(key, true)
	var out: Dictionary = {}
	var blocks: Array = chunk.blocks.duplicate()
	var job: Callable = _refresh_job.bind(blocks, neighbours, chunk.facing.duplicate(), out)
	var task: int = WorkerThreadPool.add_task(job)
	_refreshes[key] = {"task": task, "out": out, "neighbours": neighbours, "edits": _edits}


## Runs on a worker thread, so it touches no nodes.
func _refresh_job(blocks: Array, neighbours: Array, facing: Dictionary, out: Dictionary) -> void:
	out["transforms"] = ChunkRenderer.transforms_for(blocks, neighbours, facing)


## Draws the chunks whose refresh jobs are done, or queues them again when a
## job's copy went out of date.
func _finish_refreshes() -> void:
	for key: Vector2i in _refreshes.keys():
		var job: Dictionary = _refreshes[key]
		if not WorkerThreadPool.is_task_completed(job["task"]):
			continue
		WorkerThreadPool.wait_for_task_completion(job["task"])
		_refreshes.erase(key)
		var chunk: Node3D = active_chunks.get(key, null)
		if chunk == null:
			continue
		if _is_stale(key, job):
			if chunk not in _render_refresh:
				_render_refresh.append(chunk)
		else:
			chunk.apply_render(job["out"]["transforms"])


## True when a block changed or a side chunk came or went since job started.
func _is_stale(key: Vector2i, job: Dictionary) -> bool:
	if job["edits"] != _edits:
		return true
	for k in NEIGHBOUR_DIRS.size():
		if job["neighbours"][k].is_empty() == active_chunks.has(key + NEIGHBOUR_DIRS[k]):
			return true
	return false


func _unload_chunk_at(key: Vector2i) -> void:
	if not active_chunks.has(key):
		return
	var chunk: Node3D = active_chunks[key]
	if auto_save_on_unload and chunk.is_dirty():
		var err: int = WorldSave.save_chunk(chunk)
		if err != OK:
			push_warning("ChunkManager: save-on-unload failed for %s err=%d" % [key, err])
	chunk_unloaded.emit(chunk)
	active_chunks.erase(key)
	dirty_rebuilds.erase(chunk)
	_render_refresh.erase(chunk)
	chunk.queue_free()
	_queue_render_refresh(key)


## copy: duplicate the arrays, for a worker thread to read.
func _neighbour_blocks(key: Vector2i, copy: bool = false) -> Array:
	var out: Array = []
	for d in NEIGHBOUR_DIRS:
		var n: Node3D = active_chunks.get(key + d, null)
		if n == null:
			out.append([])
		else:
			out.append(n.blocks.duplicate() if copy else n.blocks)
	return out


func _queue_render_refresh(key: Vector2i) -> void:
	for d in NEIGHBOUR_DIRS:
		var n: Node3D = active_chunks.get(key + d, null)
		if n != null and n not in _render_refresh:
			_render_refresh.append(n)


func _on_streaming_tick() -> void:
	if _streaming_dirty or _player != null:
		_streaming_dirty = false
		_run_streaming_pass(LOADS_PER_TICK, true)


## Loads missing chunks nearest the player first, at most max_loads of them
## (-1 = all), and unloads the chunks outside the view radius. threaded: build
## new chunks on worker threads; saved chunks still load at once.
func _run_streaming_pass(max_loads: int = -1, threaded: bool = false) -> void:
	var pcx: int = 0
	var pcz: int = 0
	if _player != null:
		pcx = floori(_player.global_position.x / float(Chunk.CHUNK_X))
		pcz = floori(_player.global_position.z / float(Chunk.CHUNK_Z))

	var target: Dictionary = {}
	var missing: Array[Vector2i] = []
	for dx in range(-view_radius, view_radius + 1):
		for dz in range(-view_radius, view_radius + 1):
			if dx * dx + dz * dz > view_radius * view_radius:
				continue
			var key: Vector2i = Vector2i(pcx + dx, pcz + dz)
			target[key] = true
			if not active_chunks.has(key) and not (threaded and _builds.has(key)):
				missing.append(key)

	var centre: Vector2i = Vector2i(pcx, pcz)
	missing.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return (a - centre).length_squared() < (b - centre).length_squared()
	)
	if max_loads >= 0 and missing.size() > max_loads:
		missing.resize(max_loads)
	for key in missing:
		if threaded and not WorldSave.has_chunk(key.x, key.y):
			_start_build(key)
		else:
			_load_chunk_at(key)

	var to_unload: Array = []
	for key in active_chunks:
		if not target.has(key):
			to_unload.append(key)
	for key in to_unload:
		_unload_chunk_at(key)


func _on_rebuild_tick() -> void:
	for chunk in dirty_rebuilds:
		if is_instance_valid(chunk):
			chunk.rebuild(_neighbour_blocks(Vector2i(chunk.cx, chunk.cz)))
			chunk_rebuilt.emit(chunk)
	dirty_rebuilds.clear()
	# Chunks with a refresh job still running wait for the next tick
	var waiting: Array = []
	var started: int = 0
	while started < REFRESH_PER_TICK and not _render_refresh.is_empty():
		var chunk: Node3D = _render_refresh.pop_front()
		if not is_instance_valid(chunk):
			continue
		if _refreshes.has(Vector2i(chunk.cx, chunk.cz)):
			waiting.append(chunk)
			continue
		_start_refresh(chunk)
		started += 1
	_render_refresh.append_array(waiting)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_dirty_chunks()
		get_tree().quit()
