@tool
extends Node2D
class_name ScreenBorders

## ScreenBorders — создаёт невидимые границы по краям экрана для столкновений врагов или игрока.
## ScreenBorders — creates invisible screen edge borders for enemy or player collision handling.
##
## 💡 Используется для ограничения движения объектов по горизонтали.
## 💡 Used to restrict object movement horizontally across the screen.

# =====================================================
# === Настройки / Settings  
# =====================================================
@export_group("Settings")
## Отступ левой границы (в пикселях)
## Left border offset (in pixels)
@export_range(-500, 500, 10, "suffix:px") var left_offset: float = -200.0:
	set(value):
		if left_offset == value:
			return
		left_offset = value
		call_deferred("_update_borders")
## Отступ правой границы (в пикселях)
## Right border offset (in pixels)
@export_range(-500, 500, 10, "suffix:px") var right_offset: float = 200.0:
	set(value):
		if right_offset == value:
			return
		right_offset = value
		call_deferred("_update_borders")
## Толщина границы (в пикселях)
## Border thickness (in pixels)
@export_range(10, 500, 1, "suffix:px") var border_thickness: float = 64.0:
	set(value):
		border_thickness = value
		call_deferred("_update_borders")

# =====================================================
# === Столкновения / Collision
# =====================================================
@export_group("Collision")
## Слой коллизии, на котором находятся границы
## Collision layer assigned to borders
@export_range(0, 31, 1, "suffix:layer") var collision_layer: int = 10:
	set(value):
		collision_layer = value
		call_deferred("_update_borders")
## Маска коллизии, с какими слоями взаимодействовать
## Collision mask determining which layers interact
@export_range(0, 31, 1, "suffix:layer")  var collision_mask: int = 0:
	set(value):
		collision_mask = value
		call_deferred("_update_borders")

# =====================================================
# === Визуализация / Visualization
# =====================================================
@export_group("Visualization")
## Включить визуализацию границ в редакторе
## Enable border visualization in editor
@export var visualize: bool = true:
	set(value):
		visualize = value
		queue_redraw()
## Цвет визуализации
## Visualization color
@export var visualize_color: Color = Color(0, 1, 0, 0.25):
	set(value):
		visualize_color = value
		queue_redraw()
## Закрашивать границы или рисовать контур
## Fill or outline visualization rectangles
@export var fill_visual: bool = true:
	set(value):
		fill_visual = value
		queue_redraw()
# =====================================================
# === Переменные рантайма / Runtime state
# =====================================================
var left_border: Area2D
var right_border: Area2D
var debug = true

# =====================================================
# === Жизненный цикл / Lifecycle
# =====================================================
func _ready() -> void:
	if Engine.is_editor_hint():
		# Автоматически обновляем границы в редакторе
		# Automatically update borders in editor
		call_deferred("_update_borders")
		pass
	else:
		# В рантайме инициализация выполняется отдельно
		# In runtime, initialization is handled separately
		call_deferred("_update_borders")
		if debug:
			call_deferred("initialize_viewport_size")

## Выводит текущий размер вьюпорта (для отладки)
## Prints current viewport size (for debugging)
func initialize_viewport_size() -> void:
	var viewport_size = _get_base_viewport_size()
	print("Размер вьюпорта: ", viewport_size)

# =====================================================
# === Создание границ / Borders creation
# =====================================================
## Пересоздаёт границы, очищая старые
## Recreates borders, clearing previous ones
func _update_borders() -> void:
	# Очищаем старые границы
	for child in get_tree().get_nodes_in_group("screen_borders"):
		child.queue_free()

	var viewport_size = _get_base_viewport_size()
	var height = viewport_size.y

	left_border = _create_border(left_offset, height)
	add_child(left_border)

	right_border = _create_border(viewport_size.x + right_offset, height)
	add_child(right_border)

	queue_redraw()

## Создаёт и настраивает область столкновений (границу)
## Creates and configures a collision area (border)
func _create_border(x_pos: float, height: float) -> Area2D:
	var area := Area2D.new()
	area.add_to_group("screen_borders")
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(border_thickness, height)
	shape.shape = rect
	area.add_child(shape)
	area.position = Vector2(x_pos, height / 2)
	area.collision_layer = 0
	area.set_collision_layer_value(collision_layer, true)
	area.collision_mask = collision_mask
	return area

# =====================================================
# === Визуализация / Visualization
# =====================================================
## Отрисовывает визуализацию границ, если включено visualize
## Draws border visualization if visualize is enabled
func _draw() -> void:
	if not visualize:
		return

	var viewport_size = _get_base_viewport_size()
	var height = viewport_size.y

	var left_rect = Rect2(Vector2(left_offset - border_thickness / 2, 0), Vector2(border_thickness, height))
	var right_rect = Rect2(Vector2(viewport_size.x + right_offset - border_thickness / 2, 0), Vector2(border_thickness, height))

	if fill_visual:
		draw_rect(left_rect, visualize_color, true)
		draw_rect(right_rect, visualize_color, true)
	else:
		draw_rect(left_rect, visualize_color, false)
		draw_rect(right_rect, visualize_color, false)

# =====================================================
# === Вспомогательные функции / Helpers
# =====================================================
## Возвращает базовый размер вьюпорта (в редакторе или в игре)
## Returns base viewport size (in editor or in-game)
func _get_base_viewport_size() -> Vector2:
	if Engine.is_editor_hint():
		return Vector2(
			ProjectSettings.get_setting("display/window/size/viewport_width"),
			ProjectSettings.get_setting("display/window/size/viewport_height")
		)
	else:
		return get_viewport().get_visible_rect().size
