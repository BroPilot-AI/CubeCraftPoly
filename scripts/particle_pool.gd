class_name ParticlePool
extends Node3D

const POOL_SIZE: int = 8

var _particles: Array[CPUParticles3D] = []
var _next: int = 0


func _ready() -> void:
	for i in POOL_SIZE:
		var p: CPUParticles3D = CPUParticles3D.new()
		p.amount = 12
		p.lifetime = 0.4
		p.explosiveness = 0.9
		p.one_shot = true
		p.emitting = false
		p.gravity = Vector3(0, -8, 0)
		p.initial_velocity_min = 1.5
		p.initial_velocity_max = 3.0
		# Up and out, not all one way
		p.direction = Vector3.UP
		p.spread = 50.0
		p.scale_amount_min = 0.08
		p.scale_amount_max = 0.15
		p.damping_min = 1.0
		p.damping_max = 2.0
		p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(p)
		_particles.append(p)


## Throws amount little copies of mesh out from position.
func burst(position: Vector3, mesh: Mesh, amount: int = 12) -> void:
	if _particles.is_empty():
		return
	var p: CPUParticles3D = _particles[_next]
	_next = (_next + 1) % POOL_SIZE
	if p == null:
		return
	p.global_position = position
	p.mesh = mesh
	p.amount = amount
	p.restart()
	p.emitting = true
	_return_after(p, 0.5)


func _return_after(p: CPUParticles3D, delay: float) -> void:
	var t: Timer = p.get_node_or_null("_return") as Timer
	if t == null:
		t = Timer.new()
		t.one_shot = true
		t.name = "_return"
		p.add_child(t)
		t.timeout.connect(func() -> void:
			if is_instance_valid(p):
				p.emitting = false
		)
	t.start(delay)
