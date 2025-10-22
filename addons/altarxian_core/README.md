# Altarxian Core - Документация

## Обзор

Altarxian Core - это модульная система для создания аркадных игр в Godot 4, предоставляющая готовые компоненты для управления уровнями, врагами, сигналами и границами экрана.

## Архитектура системы

### 1. Система сигналов (ACSignalBus)

**Файл:** `ac_signal_bus.gd`

Глобальная шина сигналов для межсистемного взаимодействия.

```gdscript
# Использование
var bus = ACSignalBus.instance()
bus.emit_switch_direction_request()
```

**Основные функции:**
- Глобальный доступ к сигналам через синглтон
- Отладочный режим с выводом в консоль
- Централизованное управление событиями игры

### 2. Система следования за якорем (AnchorFollower)

**Файл:** `anchor_follower.gd`

Компонент для привязки объектов к якорям в реальном времени.

```gdscript
# Настройка через инспектор
@export var anchor_path: NodePath = "Path/To/Anchor"
```

**Свойства:**
- `anchor_path` - путь к узлу-якорю
- `debug` - включение отладочного вывода

### 3. Система границ экрана (ScreenBorders)

**Файл:** `screen_borders.gd`

Создает невидимые границы для ограничения движения объектов.

```gdscript
# Настройки границ
@export_range(-500, 500) var left_offset: float = -200.0
@export_range(-500, 500) var right_offset: float = 200.0
@export_range(10, 500) var border_thickness: float = 64.0
```

**Особенности:**
- Автоматическая адаптация к размеру экрана
- Визуализация в редакторе
- Настраиваемые слои коллизий

### 4. Система обнаружения столкновений (FormationRays)

**Файл:** `formation_rays.gd`

Отслеживает касание формацией границ экрана с помощью RayCast2D.

```gdscript
# Назначение лучей
@export var ray_left: RayCast2D
@export var ray_right: RayCast2D
```

**Функциональность:**
- Автоматическая отправка сигналов в ACSignalBus
- Настройка масок коллизий
- Отладочный режим

### 5. Менеджер уровней (LevelManager)

**Файл:** `level_manager.gd`

Центральный компонент для управления формациями врагов и уровнями.

```gdscript
# Основные настройки
@export var enemy_size: float = 64.0
@export var enemy_offset: float = 10.0
@export var cooldown_time: float = 1.0
```

**Ключевые методы:**
- `load_level(index)` - загрузка уровня по индексу
- `set_enemy_scenes(dict)` - регистрация сцен врагов
- `move_formation(delta)` - обновление движения формации

## Ресурсная система

### FormationResource

Описание формации врагов через ASCII-разметку:

```gdscript
# Пример формации
ascii_layout = [
	"****1****",
	"*123*123*", 
    "****0****"
]
```

**Символы:**
- `*` - пустая ячейка
- `0-8` - базовые враги
- `A-Z` - переопределенные враги

**Свойства:**
- `movement_speed` - скорость движения
- `shift_down_speed` - смещение вниз
- `start_y` - начальная позиция Y
- `enemy_overrides` - кастомизация врагов

### LevelResource

Контейнер для уровня игры:

```gdscript
@export var formation: FormationResource
var format_version: String = "2v4"
```

### PowerupResource

Система бонусов:

```gdscript
enum PowerupType {
	EMPTY, HEALUP, MOVESPEEDUP, SHOOTSPEEDUP, 
	SHIELDUP, CONTINUEUP, SHOOTPOWERUP
}
```

## Интеграция с Godot Editor

### Плагин редактора

Автоматически регистрирует типы ресурсов и добавляет автолоад-синглтоны:

```gdscript
func _enter_tree():
	add_autoload_singleton("AcSignalBus", "...")
	add_custom_type("FormationResource", "Resource", ...)
	add_custom_type("LevelResource", "Resource", ...)
	# ... и т.д.
```

## Типичный workflow

### 1. Настройка сцены

```gdscript
# Главная сцена игры
- Main (Node2D)
  - LevelManager (LevelManager)
  - EnemiesContainer (Node2D)
  - ScreenBorders (ScreenBorders) 
  - FormationRays (FormationRays)
```

### 2. Создание уровня

1. Создать `FormationResource` в инспекторе
2. Настроить ASCII-разметку
3. Создать `LevelResource` и назначить формацию
4. Добавить путь к уровню в `LevelManager.levels`

### 3. Настройка врагов

```gdscript
# В LevelManager
enemy_scenes = {
	"0": preload("res://enemies/basic_enemy.tscn"),
	"1": preload("res://enemies/fast_enemy.tscn")
}
```

## Отладка

Все компоненты поддерживают режим отладки:

```gdscript
@export var debug: bool = true
```

При включении выводятся подробные сообщения в консоль о:
- Создании и удалении объектов
- Отправке сигналов
- Обнаружении столкновений
- Ошибках конфигурации

## Советы по использованию

1. **Производительность:** Используйте пулы объектов для врагов
2. **Расширяемость:** Добавляйте новые типы врагов через `enemy_scenes`
3. **Балансировка:** Настраивайте скорости и тайминги через ресурсы
4. **Тестирование:** Используйте визуализацию границ для отладки

Эта система предоставляет полный цикл разработки аркадной игры - от проектирования уровней до реализации игровой логики.
