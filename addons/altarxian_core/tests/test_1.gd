extends Node2D

@onready var lm = $LevelManager

func _ready():
	var dict:Dictionary[String,PackedScene]  = {"0": preload("res://addons/altarxian_core/tests/enemy0.tscn")}
	lm.set_enemy_scenes(dict)
	lm.levels.append("res://addons/altarxian_core/tests/level_test.tres")
	lm.load_level(0)
	print("done")
	
func _process(delta: float) -> void:
	lm.move_formation(delta)
