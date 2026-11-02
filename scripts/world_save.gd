class_name WorldSave

const SAVE_DIR: String = "user://saves/default/chunks"
const CHUNK_FILE_FORMAT: String = "%d_%d.json"

static var save_dir: String = SAVE_DIR


static func set_save_dir(path: String) -> void:
	save_dir = path


static func chunk_path(cx: int, cz: int) -> String:
	return "%s/%s" % [save_dir, CHUNK_FILE_FORMAT % [cx, cz]]


static func ensure_save_dir() -> int:
	var abs_path: String = ProjectSettings.globalize_path(save_dir)
	if DirAccess.dir_exists_absolute(abs_path):
		return OK
	return DirAccess.make_dir_recursive_absolute(abs_path)


static func save_chunk(chunk: Node3D) -> int:
	if chunk == null:
		return ERR_INVALID_PARAMETER
	var err: int = ensure_save_dir()
	if err != OK:
		return err
	var path: String = chunk_path(chunk.cx, chunk.cz)
	var f: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return FileAccess.get_open_error()
	var dict: Dictionary = chunk.to_dict()
	f.store_string(JSON.stringify(dict))
	f.close()
	return OK


static func load_chunk_data(cx: int, cz: int) -> Dictionary:
	var path: String = chunk_path(cx, cz)
	if not FileAccess.file_exists(path):
		return {}
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var text: String = f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Dictionary:
		return parsed
	return {}


static func has_chunk(cx: int, cz: int) -> bool:
	return FileAccess.file_exists(chunk_path(cx, cz))


## The player's file (what they carry), next to the chunk folder.
static func player_path() -> String:
	return save_dir.get_base_dir() + "/player.json"


static func save_player(data: Dictionary) -> int:
	return _save_json(player_path(), data)


## The player's saved data, or an empty dictionary when there is none.
static func load_player() -> Dictionary:
	if not FileAccess.file_exists(player_path()):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(player_path()))
	if parsed is Dictionary:
		return parsed
	return {}


## The world's own file (its seed), next to the player's.
static func world_path() -> String:
	return save_dir.get_base_dir() + "/world.json"


static func save_seed(world_seed: int) -> int:
	return _save_json(world_path(), {"seed": world_seed})


## The saved world's seed, or 0 (the first world, made before seeds were
## saved) when there is none.
static func load_seed() -> int:
	if not FileAccess.file_exists(world_path()):
		return 0
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(world_path()))
	if parsed is Dictionary and parsed.get("seed") is float:
		return int(parsed["seed"])
	return 0


## Whether there is a saved world to continue.
static func has_world() -> bool:
	return FileAccess.file_exists(player_path()) or FileAccess.file_exists(world_path())


## Deletes the saved world: its chunks, the player's file and the seed.
static func delete_world() -> int:
	var paths: Array[String] = [player_path(), world_path()]
	var chunks: String = ProjectSettings.globalize_path(save_dir)
	if DirAccess.dir_exists_absolute(chunks):
		for file: String in DirAccess.get_files_at(chunks):
			paths.append(save_dir + "/" + file)
	for path: String in paths:
		if FileAccess.file_exists(path):
			var err: int = DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
			if err != OK:
				return err
	return OK


## Writes data to path as JSON, making its folder first.
static func _save_json(path: String, data: Dictionary) -> int:
	var dir: String = ProjectSettings.globalize_path(path.get_base_dir())
	var err: int = DirAccess.make_dir_recursive_absolute(dir)
	if err != OK:
		return err
	var f: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return FileAccess.get_open_error()
	f.store_string(JSON.stringify(data))
	f.close()
	return OK
