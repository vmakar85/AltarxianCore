class_name PowerupResource
extends Resource

## Ресурс описывает бонус (паверап)
## Resource describing a power-up item

## Перечисление типов бонусов
## Enumeration of available power-up types
enum PowerupType {
	EMPTY,          # Нет бонуса / No bonus
	HEALUP,         # Восстановление здоровья / Health recovery
	MOVESPEEDUP,    # Ускорение движения / Movement speed boost
	SHOOTSPEEDUP,   # Ускорение стрельбы / Fire rate boost
	SHIELDUP,       # Защитный щит / Shield bonus
	CONTINUEUP,     # Дополнительная жизнь / Extra continue
	SHOOTPOWERUP    # Усиленная атака / Attack power boost
}

## Тип бонуса (из enum PowerupType)
## Power-up type (from PowerupType enum)
@export var type: PowerupType

## Иконка бонуса (для интерфейса или HUD)
## Power-up icon (for UI or HUD)
@export var icon: Texture2D

## Сцена, которая создаётся при получении бонуса
## Scene to instantiate when the power-up is collected
@export var scene: PackedScene
