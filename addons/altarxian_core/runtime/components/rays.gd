extends Node2D
class_name FormationRays

## Отслеживает столкновения формации с границами экрана.
## Использует два RayCast2D и отправляет сигнал в ACSignalBus при касании.
## Tracks formation collisions with screen borders.
## Uses two RayCast2D and emits a signal to ACSignalBus when hitting a border.

@export var ray_left: RayCast2D
@export var ray_right: RayCast2D

var bus: ACSignalBus

func _ready() -> void:
	## Проверяем корректность назначения лучей
	## Validate assigned RayCast2D nodes
	if ray_left == null:
		push_error("FormationRays: 'ray_left' is not assigned!")
	if ray_right == null:
		push_error("FormationRays: 'ray_right' is not assigned!")

	## Настраиваем лучи, если они существуют
	## Configure rays if present
	if ray_left:
		ray_left.collide_with_areas = true
		ray_left.collide_with_bodies = false
		ray_left.set_collision_mask_value(10, true)

	if ray_right:
		ray_right.collide_with_areas = true
		ray_right.collide_with_bodies = false
		ray_right.set_collision_mask_value(10, true)

	bus = ACSignalBus.instance()

	if bus == null:
		push_error("FormationRays: ACSignalBus instance not found!")

func _physics_process(_delta: float) -> void:
	## Проверяем столкновения и отправляем сигнал в шину
	## Check collisions and emit signal to the bus
	if bus == null:
		return

	if ray_left == null or ray_right == null:
		return

	var left_hit := ray_left.is_colliding()
	var right_hit := ray_right.is_colliding()

	if left_hit or right_hit:
		var collider_left = left_hit and ray_left.get_collider()
		var collider_right = right_hit and ray_right.get_collider()

		if collider_left or collider_right:
			## Отправляем сигнал смены направления в шину
			## Emit direction switch signal to the bus
			bus.emit_switch_direction_request()
