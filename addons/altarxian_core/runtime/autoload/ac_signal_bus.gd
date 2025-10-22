extends Node
class_name ACSignalBus

## Глобальная шина сигналов Altarxian Core
## Global signal bus for Altarxian Core runtime

@export var debug: bool = true

signal switch_direction_request

static var _instance: ACSignalBus = null

func _ready() -> void:
	# Регистрируем инстанс как синглтон
	if _instance != null and _instance != self:
		push_error("[ACSignalBus] Another instance already exists! This one will override it.")
	_instance = self
	if debug:
		print("[ACSignalBus] Ready and registered as autoload singleton")

# Убираем static, делаем обычной функцией
static func instance() -> ACSignalBus:
	# Проверяем, что синглтон реально инициализирован
	if _instance == null:
		push_error("[ACSignalBus] Tried to access instance() before initialization!")
	return _instance

func emit_switch_direction_request() -> void:
	if debug:
		print("[ACSignalBus] Emitting signal: switch_direction_request")
	# Проверка на подключение сигнала (опционально)
	emit_signal("switch_direction_request")
