class_name LevelResource
extends Resource

## Ресурс описывает уровень игры, содержащий формацию врагов
## Resource describing a game level containing an enemy formation

## Основная формация врагов для уровня
## Main enemy formation for this level
@export var formation: FormationResource

## Версия формата ресурса (для совместимости)
## Resource format version (for compatibility)
var format_version: String = "2v4"


#region File operations

## Загружает уровень из файла .tres
## Loads a level resource from a .tres file
static func load_from_file(path: String) -> LevelResource:
	if not ResourceLoader.exists(path):
		push_warning("Level file not found: %s" % path)
		return null
	var res = load(path)
	if res is LevelResource:
		return res
	push_warning("Invalid resource type: expected LevelResource")
	return null


## Сохраняет уровень в указанный файл .tres
## Saves the level resource to a .tres file
func save_to_file(path: String) -> bool:
	var result = ResourceSaver.save(self, path)
	if result != OK:
		push_error("Failed to save LevelResource: %s (code %d)" % [path, result])
		return false
	return true

#endregion
