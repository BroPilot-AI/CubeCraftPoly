class_name Chunk
extends Node3D

const ChunkMesher: GDScript = preload("res://scripts/chunk_mesher.gd")
const ChunkRenderer: GDScript = preload("res://scripts/chunk_renderer.gd")
const ChunkProps: GDScript = preload("res://scripts/chunk_props.gd")

const CHUNK_X: int = 16
const CHUNK_Y: int = 32
const CHUNK_Z: int = 16

const AIR: int = 0
const DIRT: int = 1
const GRASS: int = 2
const STONE: int = 3
const WOOD_PLANKS: int = 4
const BRICK: int = 5
const GREY_BRICK: int = 6
const COAL: int = 7
const DIAMOND: int = 8
const CRYSTAL: int = 9
const METAL: int = 10
const ICE: int = 11
const SNOW: int = 12
const CHEESE: int = 13
const WOOL: int = 14
const SAND: int = 15
const CRATE: int = 16

@export var cx: int = 0
@export var cz: int = 0

var blocks: Array[int] = []
## Cell index -> quarter turns (1-3) for items placed facing the player
var facing: Dictionary = {}
var block_materials: Dictionary = {}
var dirty: bool = true

@onready var chunk_mesh: MeshInstance3D = $ChunkMesh
@onready var chunk_collision: CollisionShape3D = $ChunkBody/ChunkCollision
@onready var blocks_root: Node3D = $Blocks
@onready var props_root: Node3D = $Props


func _init() -> void:
	_init_blocks()


func _ready() -> void:
	if chunk_mesh == null:
		push_error("Chunk requires a MeshInstance3D child named 'ChunkMesh'")


func _init_blocks() -> void:
	if blocks.size() == CHUNK_X * CHUNK_Y * CHUNK_Z:
		return
	blocks.resize(CHUNK_X * CHUNK_Y * CHUNK_Z)
	blocks.fill(AIR)


func is_dirty() -> bool:
	return dirty


func mark_dirty() -> void:
	dirty = true


func mark_clean() -> void:
	dirty = false


func in_bounds(local_pos: Vector3i) -> bool:
	return local_pos.x >= 0 and local_pos.x < CHUNK_X \
		and local_pos.y >= 0 and local_pos.y < CHUNK_Y \
		and local_pos.z >= 0 and local_pos.z < CHUNK_Z


func get_block(local_pos: Vector3i) -> int:
	if not in_bounds(local_pos):
		return AIR
	return blocks[_idx(local_pos)]


func set_block(local_pos: Vector3i, id: int) -> void:
	if not in_bounds(local_pos):
		return
	var prev: int = blocks[_idx(local_pos)]
	if prev == id:
		return
	blocks[_idx(local_pos)] = id
	if id == AIR:
		facing.erase(_idx(local_pos))
	dirty = true


func get_facing(local_pos: Vector3i) -> int:
	if not in_bounds(local_pos):
		return 0
	return facing.get(_idx(local_pos), 0)


func set_facing(local_pos: Vector3i, turns: int) -> void:
	if not in_bounds(local_pos):
		return
	var t: int = posmod(turns, 4)
	if t == 0:
		facing.erase(_idx(local_pos))
	else:
		facing[_idx(local_pos)] = t
	dirty = true


func world_to_local_cell(world_pos: Vector3) -> Vector3i:
	var local: Vector3 = to_local(world_pos)
	return Vector3i(local)


func get_block_world(world_pos: Vector3) -> int:
	return get_block(world_to_local_cell(world_pos))


func set_block_world(world_pos: Vector3, id: int) -> void:
	set_block(world_to_local_cell(world_pos), id)


func rebuild(neighbours: Array = []) -> void:
	if chunk_mesh == null:
		return
	var built: Dictionary = ChunkMesher.build(blocks, block_materials)
	_set_mesh(built["mesh"], built["faces"])
	refresh_render(neighbours)


## Shows what a worker thread built from blocks: the mesh and its collision faces
## from ChunkMesher.build, and instance transforms from ChunkRenderer.
func apply_built(mesh: ArrayMesh, faces: PackedVector3Array, transforms: Dictionary) -> void:
	if chunk_mesh == null:
		return
	_set_mesh(mesh, faces)
	apply_render(transforms)


func refresh_render(neighbours: Array = []) -> void:
	if blocks_root != null:
		ChunkRenderer.build(blocks_root, blocks, neighbours, facing)


## Shows instance transforms from ChunkRenderer.transforms_for.
func apply_render(transforms: Dictionary) -> void:
	if blocks_root != null:
		ChunkRenderer.apply(blocks_root, transforms)


## Sets the mesh, a collision shape of its faces and the props.
func _set_mesh(mesh: ArrayMesh, faces: PackedVector3Array) -> void:
	chunk_mesh.mesh = mesh
	if chunk_collision != null:
		if faces.is_empty():
			chunk_collision.shape = null
		else:
			var shape: ConcavePolygonShape3D = ConcavePolygonShape3D.new()
			shape.set_faces(faces)
			chunk_collision.shape = shape
	if props_root != null:
		ChunkProps.build(props_root, blocks, facing)


func to_dict() -> Dictionary:
	var used: Array = []
	for i in blocks.size():
		if blocks[i] != AIR:
			used.append([i, blocks[i]])
	var turned: Array = []
	for i: int in facing:
		turned.append([i, facing[i]])
	return {"version": 1, "cx": cx, "cz": cz, "cells": used, "facing": turned}


func from_dict(d: Dictionary) -> void:
	blocks.resize(CHUNK_X * CHUNK_Y * CHUNK_Z)
	blocks.fill(AIR)
	var cells_v: Variant = d.get("cells", [])
	if cells_v is Array:
		for entry: Variant in cells_v:
			if entry is Array and entry.size() >= 2:
				var idx: int = entry[0]
				var id: int = entry[1]
				if idx >= 0 and idx < blocks.size():
					blocks[idx] = id
	facing.clear()
	var facing_v: Variant = d.get("facing", [])
	if facing_v is Array:
		for entry: Variant in facing_v:
			if entry is Array and entry.size() >= 2:
				var idx: int = entry[0]
				var turns: int = entry[1]
				if idx >= 0 and idx < blocks.size() and blocks[idx] != AIR:
					facing[idx] = posmod(turns, 4)
	dirty = true


func _idx(p: Vector3i) -> int:
	return p.x + p.y * CHUNK_X + p.z * CHUNK_X * CHUNK_Y
