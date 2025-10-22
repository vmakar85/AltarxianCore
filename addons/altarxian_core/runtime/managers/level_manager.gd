# addons/altarxian_core/runtime/managers/level_manager.gd
## LevelManager — менеджер формаций/уровней (рефактор исходного LevelManager2)
## LevelManager — main level and formation manager, responsible for spawning and controlling enemies
class_name LevelManager
extends Node2D

@export var debug: bool = true

# ========== Настройки (доступны в инспекторе) ==========
## Размер врага в пикселях (для расчёта позиций в сетке)
## Enemy size in pixels (used for grid positioning)
@export var enemy_size: float = 64.0
## Отступ между врагами в сетке
## Spacing between enemies in the grid
@export var enemy_offset: float = 10.0
## Задержка между сменой направлений движения формации (секунды)
## Delay between direction switches of the formation (in seconds)
@export var cooldown_time: float = 1.0
## Дополнительный горизонтальный сдвиг центра формации
## Additional horizontal offset for centering the formation
@export var extra_center_offset: int = 38
## Имя узла-контейнера, куда будут помещаться инстансы врагов
## Name of the node that contains spawned enemy instances
@export var enemies_container_name: String = "EnemiesContainer"

## Словарь с шаблонами врагов: { "id": PackedScene }
## Dictionary of enemy templates: { "id": PackedScene }
@export var enemy_scenes: Dictionary[String,PackedScene] = {}

# ========== Runtime state ==========
## Текущая формация (ресурс типа FormationResource)
## Current formation (FormationResource or compatible)
var current_formation: FormationResource  = null
## Список всех якорей (Anchor) текущей формации
## List of all anchors (Anchor nodes) of the current formation
var anchors: Array = []
## Направление движения (1 = вправо, -1 = влево)
## Movement direction (1 = right, -1 = left)
var movement_direction: int = 1 
## Хранит ширину рядов формации (используется при расчётах)
## Stores the width of formation rows (used for layout calculations)
var space_left: Array = []
## Список уровней (путей к .tres файлам)
## List of level resource paths (.tres files)
var levels: Array[String] = []
## Индекс текущего уровня
## Index of the currently loaded level
var current_level_index: int = -1

enum EnemyType {
	NORMAL_ENEMY = 0,
	OVERRIDE_ENEMY = -2
}

@onready var _cooldown_timer: Timer = Timer.new()

func _ready() -> void:
	## Инициализация таймера и подключение к AcSignalBus
	## Initializes cooldown timer and connects to AcSignalBus
	_cooldown_timer.wait_time = cooldown_time
	_cooldown_timer.one_shot = true
	add_child(_cooldown_timer)

	## Попытка подключиться к AcSignalBus (если он в autoload)
	## Try to connect to AcSignalBus (if it exists as autoload)
	var bus = AcSignalBus.instance()
	if bus != null:
		# безопасная подписка
		# safe connection
		if not bus.is_connected("switch_direction_request", Callable(self, "_on_switch_direction_request")):
			bus.connect("switch_direction_request", Callable(self, "_on_switch_direction_request"))
		if debug:
			print("[LevelManager] connected to AcSignalBus")
	else:
		# не фатально — возможно, пользователь добавит шину по-другому
		# not fatal — user may add the signal bus differently
		# print("AcSignalBus instance not found; continuing without it.")
		pass

# ================== Публичный API ==================
## Назначает словарь сцен врагов (id -> PackedScene)
## Assigns dictionary of enemy scenes (id -> PackedScene)
func set_enemy_scenes(dict: Dictionary[String,PackedScene] ) -> void:
	enemy_scenes = dict

## Загружает и активирует уровень по индексу в списке levels
## Возвращает true при успехе
## Loads and activates a level by its index in the levels list  
## Returns true if successful
func load_level(index: int) -> bool:
	if index < 0 or index >= levels.size():
		push_error("LevelManager.load_level: индекс вне диапазона: %d" % index)
		return false
	var path := levels[index]
	var level_res := ResourceLoader.load(path)
	if level_res == null:
		push_error("LevelManager.load_level: Не удалось загрузить ресурс уровня: %s" % path)
		return false
	if not level_res.has_method("formation") and not level_res.has_meta("formation"):
		# пытаемся безопасно получить поле formation (если скрипт-ресурс обычный — свойство напрямую)
		if not ("formation" in level_res):
			# fallback: если объект типа LevelResource с export formation, это сработает
			# если нет — ошибка
			if level_res.get("formation") == null:
				push_error("LevelManager.load_level: В ресурсе уровня нет formation: %s" % path)
				return false
	current_formation = level_res.get("formation")
	current_level_index = index
	_spawn_formation()
	return true

# ================== Внутренние методы ==================
## Полностью пересоздаёт текущую формацию (очищает старую, создаёт новую)
## Fully rebuilds the current formation (clears and recreates)
func _spawn_formation() -> void:
	_clear_formation()
	_spawn_anchors_and_enemies()

## Создаёт якоря и врагов на основе данных из current_formation
## Creates anchors and enemies based on current_formation data
func _spawn_anchors_and_enemies() -> void:
	if current_formation == null:
		push_error("LevelManager._spawn_anchors_and_enemies: current_formation == null")
		return

	# Получаем видимую ширину
	var viewport_width = get_viewport().get_visible_rect().size.x

	# ожидаем метод parse_ascii у formation
	if not current_formation.has_method("parse_ascii"):
		push_error("Formation resource не имеет parse_ascii()")
		return
	var grid: Array = current_formation.parse_ascii()
	if grid.is_empty():
		push_error("LevelManager: формация пуста (grid.empty())")
		return

	# Поиск контейнера врагов
	var enemies_container: Node = null
	if get_parent() != null:
		enemies_container = get_parent().get_node_or_null(enemies_container_name)
	if enemies_container == null:
		enemies_container = get_node_or_null(enemies_container_name)
	if enemies_container == null:
		push_error("LevelManager: Не найден EnemiesContainer (ищем ../%s или %s)" % [enemies_container_name, enemies_container_name])
		return

	for row in range(grid.size()):
		var columns = grid[row].size()
		var row_width = columns * (enemy_size + enemy_offset)
		space_left.append(row_width)
		var start_x = (viewport_width - row_width) / 2 + extra_center_offset
		for col in range(columns):
			var cell = grid[row][col]
			# Anchor как Node2D (легковесный)
			var anchor := Node2D.new()
			anchor.position = Vector2(
				start_x + col * (enemy_size + enemy_offset),
				current_formation.start_y + row * (enemy_size + enemy_offset)
			)
			anchor.name = "Anchor_R%sC%s" % [row, col]
			add_child(anchor)
			anchors.append(anchor)
			# spawn enemy если нужно
			if cell.type >= 0:
				var key := str(cell.type)
				if enemy_scenes.has(key):
					var enemy_scene: PackedScene = enemy_scenes[key]
					if enemy_scene != null:
						var enemy = enemy_scene.instantiate()
						enemy.position = anchor.position
						# пытаемся назначить anchor, но делаем проверку
						_set_enemy_anchor(enemy, anchor)
						enemies_container.add_child(enemy)
					else:
						push_error("LevelManager: enemy_scenes[%s] == null" % key)
				else:
					push_error("LevelManager: Не найден enemy_scenes[%s]" % key)
			elif cell.type == EnemyType.OVERRIDE_ENEMY and cell.override_key != "":
				var override = null
				if current_formation.has_method("get_override_by_key"):
					override = current_formation.get_override_by_key(cell.override_key)
				elif current_formation.has_method("get_override"):
					override = current_formation.get_override(cell.override_key)
				if override != null and enemy_scenes.has(override.enemy_id):
					var enemy_scene2: PackedScene = enemy_scenes[override.enemy_id]
					if enemy_scene2 != null:
						var enemy2 = enemy_scene2.instantiate()
						enemy2.position = anchor.position
						if override.health > 0 and enemy2.has_meta("health") or enemy2.has_variable("health"):
							# устанавливаем поля опционально (без падений)
							if enemy2.has_property("health"):
								enemy2.health = override.health
						if override.points > 0 and enemy2.has_property("points"):
							enemy2.points = override.points
						if override.powerup != null and enemy2.has_property("power_up"):
							enemy2.power_up = override.get_powerup_name()
						# Пробуем назначить anchor универсально
						_set_enemy_anchor(enemy2, anchor)
						enemies_container.add_child(enemy2)
					else:
						push_error("LevelManager: enemy scene null for override %s" % override.enemy_id)
				else:
					push_error("LevelManager: Override not found or scene missing for key %s" % cell.override_key)

## Удаляет текущие якоря и врагов
## Removes all anchors and enemies
func _clear_formation() -> void:
	# free anchors
	for a in anchors:
		if is_instance_valid(a):
			a.queue_free()
	anchors.clear()

	# clear enemies in container
	var enemies_container: Node = null
	if get_parent() != null:
		enemies_container = get_parent().get_node_or_null(enemies_container_name)
	if enemies_container == null:
		enemies_container = get_node_or_null(enemies_container_name)
	if enemies_container != null:
		for child in enemies_container.get_children():
			if is_instance_valid(child):
				child.queue_free()

	space_left.clear()
	position = Vector2.ZERO

## Двигает формацию по горизонтали (в зависимости от направления)
## Moves the formation horizontally (according to direction)
func move_formation(delta: float) -> void:
	if current_formation == null or anchors.is_empty():
		return
	var movement = movement_direction * current_formation.movement_speed * delta
	position.x += movement

## Меняет направление движения и смещает формацию вниз
## Reverses movement direction and shifts formation downward
func _switch_direction_and_step_down() -> void:
	movement_direction = -movement_direction
	position.y += current_formation.shift_down_speed

## Реакция на сигнал от FormationRays / SignalBus — смена направления
## Responds to a direction switch signal from FormationRays / SignalBus
func _on_switch_direction_request() -> void:
	if _cooldown_timer.time_left > 0.0:
		return
	_switch_direction_and_step_down()
	_cooldown_timer.start()

## Назначает якорь врагу (универсально для разных реализаций)
## Assigns anchor to enemy (universal for different implementations)
func _set_enemy_anchor(enemy, anchor) -> void:
	if enemy.has_method("set_anchor"):
		enemy.set_anchor(anchor)
	# Правильный способ проверки наличия переменной
	elif "anchor" in enemy:
		enemy.anchor = anchor
	else:
		# если у врага нет прямой поддержки якоря — проверим, есть ли компонент AnchorFollower
		var follower = enemy.get_node_or_null("AnchorFollower")
		if follower:
			follower.anchor = anchor
			
# ========== Editor helpers ==========
## Добавляет путь к уровню в список levels
## Adds a level path to the levels list
func add_level_path(res_path: String) -> void:
	levels.append(res_path)

## Полностью очищает список уровней
## Completely clears the levels list
func clear_levels() -> void:
	levels.clear()

## Создаёт уровень напрямую из ресурса (минуя список levels)
## Creates a level directly from a resource (bypassing levels list)
func create_level_from_resource(level_resource: Resource) -> bool:
	if level_resource == null:
		return false
	current_formation = level_resource.get("formation")
	_spawn_formation()
	return true
