extends Resource
class_name EnemyOverrideResource

## Ресурс, описывающий индивидуальные параметры врага
## Resource describing individual enemy parameters

@export var enemy_id: String = "0" # ID базового врага / Base enemy ID
@export var enemy_overrided_id: String = "A" # Символ переопределения / Override symbol
@export var health: int = -1 # Переопределённое здоровье / Overridden health
@export var points: int = -1 # Очки за уничтожение / Points for destruction
@export var self_name: String = "" # Имя врага (для отладки) / Enemy name (for debug)
@export var powerup: PowerupResource # Ссылка на бонус / Linked powerup resource


## Возвращает переопределённое здоровье
## Returns overridden health
func get_health() -> int:
	return health


## Возвращает количество очков за врага
## Returns points for enemy
func get_points() -> int:
	return points


## Возвращает базовый ID врага
## Returns base enemy ID
func get_enemy_id() -> String:
	return enemy_id


## Возвращает имя врага (если задано)
## Returns enemy name (if defined)
func get_self_name() -> String:
	return self_name 


## Возвращает символ переопределения (например 'A')
## Returns override symbol (e.g. 'A')
func get_enemy_overrided_id() -> String:
	return enemy_overrided_id


## Возвращает имя типа бонуса (из enum PowerupType)
## Returns powerup type name (from PowerupType enum)
## Если powerup отсутствует — возвращает "EMPTY"
## Returns "EMPTY" if no powerup is assigned
func get_powerup_name() -> String:
	if powerup == null:
		return "EMPTY"
	return str(PowerupResource.PowerupType.keys()[powerup.type])
