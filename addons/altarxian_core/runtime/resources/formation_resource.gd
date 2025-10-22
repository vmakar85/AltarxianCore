## FormationResource 2 v3 
#LevelResource (Resource)
#	└── FormationResource (Resource)
#			├─ level_name (String)
#			├─ ascii_layout (Array[String])
#			├─ movement_speed
#			├─ shift_down_speed
#			├─ start_y 
#			└─ enemy_overrides (Array[EnemyOverrideResource])
#					├─ enemy_id (String) 
#					├─ enemy_overrided_id (String) 
#					├─ health (int)
#					├─ points (int)
#					├─ self_name (String)            
#					└─ powerup (PowerupResource)
#						  ├─ type  (PowerupType)
#						  ├─ icon  (Texture2D)
#						  └─ scene (PackedScene)

class_name FormationResource
extends Resource

## FormationResource — ресурс, описывающий формацию врагов для уровня.
## FormationResource — defines enemy formation layout and parameters for a game level.
##
## 💡 Используется LevelManager для генерации сетки якорей и спавна врагов.
## 💡 Used by LevelManager to generate anchor grid and spawn enemies accordingly.

# =====================================================
# === Level Info / Информация об уровне
# =====================================================
## Название уровня
## Level name
@export var level_name: String = "Level test"

# =====================================================
# === Layout / Расположение врагов
# =====================================================
## ASCII-представление формации врагов.
## ASCII layout representing the enemy grid.
##
## '*' — пустая ячейка / empty cell  
## '0'..'8' — базовый враг / base enemy  
## 'A'..'Z' — переопределённый враг / overridden enemy  
##
## Пример / Example:
## ["****1****", "123*123", "*1*"]
@export var ascii_layout: Array[String] = ["*"]

# =====================================================
# === Movement / Движение
# =====================================================
## Скорость горизонтального движения формации (px/s)
## Horizontal movement speed (px/s)
@export var movement_speed: float = 50.0

## Смещение вниз при смене направления (px)
## Vertical shift after direction change (px)
@export var shift_down_speed: float = 20.0

## Начальная позиция формации по оси Y
## Starting Y position of the formation
@export var start_y: float = 100.0

# =====================================================
# === Enemy Overrides / Переопределения врагов
# =====================================================
## Список переопределённых врагов (hp, очки, powerup и т.п.)
## List of overridden enemies (hp, points, powerup, etc.)
@export var enemy_overrides: Array[EnemyOverrideResource] = []

# =====================================================
# === Inner Structure / Внутренняя структура
# =====================================================
## Вспомогательный класс ячейки формации.
## Helper structure representing a single formation cell.
class Cell:
	var type: int = -1            # enemy id (0–8), -1 если пустая / -1 if empty
	var override_key: String = "" # символ переопределения / override symbol

# =====================================================
# === Core Methods / Основные методы
# =====================================================
## Преобразует ascii_layout в двумерный массив ячеек.
## Converts ascii_layout into a 2D grid of Cell objects.
func parse_ascii() -> Array:
	var grid: Array = []
	for row in ascii_layout:
		var row_data: Array = []
		for chr in row:
			var cell = Cell.new()
			if chr == "*":
				cell.type = -1
			elif chr.is_valid_int():
				# Базовый враг / Base enemy
				cell.type = int(chr)
				cell.override_key = ""
			elif chr.is_valid_identifier() and chr.length() == 1:
				# Символ переопределения (буква) / Override symbol (letter)
				cell.type = -2
				cell.override_key = chr
			else:
				cell.type = -1
			row_data.append(cell)
		grid.append(row_data)
	return grid

## Находит переопределение врага по его ID.
## Finds an enemy override by its enemy_id.
func get_override(enemy_id: String) -> EnemyOverrideResource:
	for ov in enemy_overrides:
		if ov.enemy_id == enemy_id:
			return ov
	return null

# =====================================================
# === Editor Tools / Методы редактора
# =====================================================
## Добавляет пустую строку в формацию.
## Adds an empty row to the formation.
func add_row() -> void:
	ascii_layout.append("")
	emit_changed()

## Добавляет строку, заполненную указанным символом.
## Adds a row filled with the given symbol.
func add_row_filled(length: int, fill_char: String = "*") -> void:
	if length <= 0:
		length = 1
	ascii_layout.append(fill_char.repeat(length))
	emit_changed()

## Удаляет строку по индексу.
## Removes a row by index.
func remove_row(row_index: int) -> void:
	if row_index >= 0 and row_index < ascii_layout.size():
		ascii_layout.remove_at(row_index)
		emit_changed()

## Добавляет символ в конец строки.
## Adds a cell (symbol) to the end of a row.
func add_cell_to_row(row_index: int, symbol: String = "*") -> void:
	if row_index < 0 or row_index >= ascii_layout.size():
		return
	ascii_layout[row_index] += symbol
	emit_changed()

## Удаляет последний символ из строки.
## Removes the last cell (symbol) from a row.
func remove_cell_from_row(row_index: int) -> void:
	if row_index < 0 or row_index >= ascii_layout.size():
		return
	if ascii_layout[row_index].length() > 0:
		var chars = ascii_layout[row_index].to_utf8_buffer()
		chars.resize(chars.size() - 1)
		ascii_layout[row_index] = ""
		for c in chars:
			ascii_layout[row_index] += String.chr(c)
		emit_changed()

## Устанавливает символ в заданную позицию.
## Sets a cell symbol at a given position.
func set_cell(row_index: int, col_index: int, symbol: String) -> void:
	if row_index < 0 or row_index >= ascii_layout.size():
		return
	if col_index < 0 or col_index >= ascii_layout[row_index].length():
		return

	var row_chars = ascii_layout[row_index].to_utf8_buffer()
	row_chars[col_index] = symbol.unicode_at(0)
	ascii_layout[row_index] = ""
	for chr in row_chars:
		ascii_layout[row_index] += String.chr(chr)
	emit_changed()

## Возвращает символ по координатам.
## Returns the symbol at given coordinates.
func get_cell(row_index: int, col_index: int) -> String:
	if row_index < 0 or row_index >= ascii_layout.size():
		return ""
	if col_index < 0 or col_index >= ascii_layout[row_index].length():
		return ""
	return ascii_layout[row_index][col_index]

## Возвращает максимальную длину строки.
## Returns the maximum row length.
func get_max_row_length() -> int:
	var max_len = 0
	for row in ascii_layout:
		if row.length() > max_len:
			max_len = row.length()
	return max_len

# =====================================================
# === Override Management / Управление оверрайдами
# =====================================================
## Находит переопределение по символу (A, B, ...).
## Finds override by its key (A, B, ...).
func get_override_by_key(key: String) -> EnemyOverrideResource:
	for ov in enemy_overrides:
		if ov.enemy_overrided_id == key:
			return ov
	return null

## Возвращает все оверрайды по заданному enemy_id.
## Returns all overrides for a given enemy_id.
func get_overrides_by_key(key: String) -> Array[EnemyOverrideResource]:
	var overrides: Array[EnemyOverrideResource] = []
	for ov in enemy_overrides:
		if ov.enemy_id == key:
			overrides.append(ov)
	return overrides

## Удаляет все оверрайды с указанным ключом.
## Deletes all overrides with the given key.
func delete_overrides_by_key(key: String) -> Array[EnemyOverrideResource]:
	var overrides: Array[EnemyOverrideResource] = []
	for ov in enemy_overrides:
		if ov.enemy_overrided_id != key:
			overrides.append(ov)
	enemy_overrides = overrides
	return enemy_overrides
