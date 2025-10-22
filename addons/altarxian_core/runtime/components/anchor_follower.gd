@tool
extends Node
class_name AnchorFollower

## Узел, который синхронизирует позицию родителя с якорем.
## Node that synchronizes its parent’s position with an assigned anchor.

@export var anchor_path: NodePath
## Путь к якорю (Anchor)
## Path to the anchor node

var anchor: Node2D

@export var debug: bool = true
## Включает отладочный вывод
## Enables debug output

func _ready() -> void:
	# Откладываем проверку на один кадр
	call_deferred("_initialize_anchor")

func _process(_delta: float) -> void:
	## Обновляет позицию родителя, если якорь существует
	## Updates parent position if anchor exists
	if anchor:
		var parent = get_parent()
		if parent:
			parent.global_position = anchor.global_position
		else:
			push_error("[AnchorFollower] No parent node found!")

func _initialize_anchor() -> void:
	## Если указан путь — пытаемся найти якорь
	## If path is assigned — try to get the anchor node
	if anchor_path != NodePath():
		anchor = get_node_or_null(anchor_path)
		if anchor == null:
			push_error("[AnchorFollower] Anchor not found at path: %s" % str(anchor_path))
	else:
		if debug:
			print("[AnchorFollower] anchor_path is empty, will try to get anchor later")
	if debug:
		print("[AnchorFollower] ready, anchor: %s" % (anchor if anchor else "null"))
