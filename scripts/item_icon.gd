class_name ItemIcon
extends RefCounted

## Renders a kit model once into a small transparent texture for the HUD.

const SIZE_PX: int = 64
const CAMERA_SIZE: float = 1.9
const CAMERA_POS: Vector3 = Vector3(2.0, 1.6, 2.0)
const LIGHT_POS: Vector3 = Vector3(1.0, 3.0, 2.0)


## Adds a SubViewport under parent that draws the item once and returns its texture.
static func create(parent: Node, item_id: int) -> Texture2D:
	var vp: SubViewport = SubViewport.new()
	vp.size = Vector2i(SIZE_PX, SIZE_PX)
	vp.own_world_3d = true
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	parent.add_child(vp)

	var mesh: Mesh = BlockDefs.get_mesh(item_id)
	if mesh != null:
		var aabb: AABB = mesh.get_aabb()
		var s: float = 1.0 / maxf(aabb.size.x, maxf(aabb.size.y, aabb.size.z))
		var mi: MeshInstance3D = MeshInstance3D.new()
		mi.mesh = mesh
		mi.scale = Vector3.ONE * s
		mi.position = -aabb.get_center() * s
		vp.add_child(mi)

	var cam: Camera3D = Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = CAMERA_SIZE
	vp.add_child(cam)
	cam.look_at_from_position(CAMERA_POS, Vector3.ZERO)

	var light: DirectionalLight3D = DirectionalLight3D.new()
	vp.add_child(light)
	light.look_at_from_position(LIGHT_POS, Vector3.ZERO)

	var env: Environment = Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1, 1, 1)
	env.ambient_light_energy = 0.5
	var world_env: WorldEnvironment = WorldEnvironment.new()
	world_env.environment = env
	vp.add_child(world_env)
	return vp.get_texture()
