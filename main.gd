extends Node2D

export(Texture) var texture

export(bool) var expire = true
export(float, 0.1, 60, 0.1) var duration = 1.0
export(Vector2) var half_extends = Vector2(0.0, 0.0)

export(int, 0, 360) var direction = 0
export(int, 0, 360) var spread = 20
export(int) var velocity = 10

export(float, 0.0, 1.0, 0.01) var initial_opacity = 1.0
export(Vector2) var initial_scale = Vector2(1.0, 1.0)

export(float, 0.0, 1.0, 0.01) var final_opacity = 1.0
export(Vector2) var final_scale = Vector2(1.0, 1.0)

export(NodePath) var particle_attractor = null
export(float, 0.0, 99999.0, 0.1) var particle_attraction_radius = 50.0
export(float, 0.0, 99999.0, 0.1) var particle_attraction_disable_radius = 10.0
export(float, -9999.0, 9999.0, 0.1) var particle_attraction_force = 10.0

onready var texture_size = texture.get_size()
onready var texture_size_half = texture_size / 2.0
onready var particle_rect = Rect2(Vector2(), texture_size)
onready var canvas_item = get_canvas_item()
onready var texture_rid = texture.get_rid()
onready var particle_attraction = false

var default_speed = Vector2(0.0, -1.0)
var particles_list = []

signal particle_expired()
signal particle_attracted()

func _ready():
  set_particle_attractor(particle_attractor)

func set_particle_attractor(node_path):
  if node_path != null:
    particle_attractor = get_node(node_path)
    particle_attraction = true
  else:
    particle_attractor = null
    particle_attraction = false

func _process(delta):
  var particle_attractor_pos = null

  if particle_attraction:
    particle_attractor_pos = particle_attractor.get_pos()

  for particle in particles_list:
    particle.custom_duration += delta

    # If expiration is set to 1
    if expire and particle.custom_duration > duration:
      _remove_particle(particle)
      emit_signal('particle_expired')
      continue

    # Compute variables
    var current_progress = min(1.0, particle.custom_duration / duration)
    var current_opacity = lerp(initial_opacity, final_opacity, current_progress)
    var current_scale = initial_scale.linear_interpolate(final_scale, current_progress)
    var current_position = particle.custom_matrix.o

    # Compute particle attraction
    if particle_attraction:
      var angle = current_position.angle_to_point(particle_attractor_pos)
      var distance = current_position.distance_to(particle_attractor_pos)

      if distance < particle_attraction_radius:
        var computed_velocity = (default_speed * particle_attraction_force).rotated(angle)

        particle.custom_velocity += computed_velocity
        current_position += computed_velocity
        
      if distance < particle_attraction_disable_radius:
        _remove_particle(particle)
        emit_signal('particle_attracted')
        continue

    particle.custom_matrix.o = current_position + particle.custom_velocity * delta

    # Update canvas
    VisualServer.canvas_item_set_self_opacity(particle.custom_rid, current_opacity)
    VisualServer.canvas_item_set_transform(particle.custom_rid, matrix_scale_from_center(particle.custom_matrix, current_scale))

func matrix_scale_from_center(matrix, current_scale):
  var scaled_matrix = matrix.scaled(current_scale)

  scaled_matrix.o = matrix.o - texture_size_half * current_scale

  return scaled_matrix

func _remove_particle(particle):
  if particles_list.size() == 0: return
  
  VisualServer.canvas_item_clear(particle.custom_rid)

  particles_list.erase(particle)

  # If no more to process, stop processing
  if particles_list.size() <= 0:
    set_process(false)

func _build_parameters(position):
  var computed_position = position + Vector2(randf() * half_extends.x, randf() * half_extends.y) - half_extends / 2.0 - texture_size_half
  var computed_rotation = deg2rad(direction + spread * randf() - spread / 2.0)
  var particle = {
    custom_rid = VisualServer.canvas_item_create(),
    custom_position = computed_position,
    custom_duration = 0,
    custom_velocity = (default_speed * velocity).rotated(computed_rotation),
    custom_direction = direction,
    custom_rotation = computed_rotation,
    custom_matrix = Matrix32(computed_rotation, computed_position),
  }

  VisualServer.canvas_item_set_transform(particle.custom_rid, matrix_scale_from_center(particle.custom_matrix, initial_scale))
  VisualServer.canvas_item_add_texture_rect(particle.custom_rid, particle_rect, texture_rid, false)
  VisualServer.canvas_item_set_parent(particle.custom_rid, canvas_item)

  particles_list.append(particle)

func emit(amount = 1):
  randomize()
  var current_position = get_pos()

  for index in range(amount): _build_parameters(current_position)

  set_process(true)
