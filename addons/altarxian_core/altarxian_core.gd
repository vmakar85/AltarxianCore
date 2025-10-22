@tool
extends EditorPlugin

var icon_res : Texture2D

func _enable_plugin() -> void:
	# Add autoloads here.
	pass


func _disable_plugin() -> void:
	# Remove autoloads here.
	pass


func _enter_tree() -> void:
	icon_res = load("res://addons/altarxian_core/editor/icons/altarxian_icon.svg")
	add_autoload_singleton("AcSignalBus", "res://addons/altarxian_core/runtime/autoload/ac_signal_bus.gd")
	add_custom_type("FormationResource", "Resource", load("res://addons/altarxian_core/runtime/resources/formation_resource.gd"), icon_res)
	add_custom_type("LevelResource", "Resource", load("res://addons/altarxian_core/runtime/resources/level_resource.gd"), icon_res)
	add_custom_type("PowerupResource", "Resource", load("res://addons/altarxian_core/runtime/resources/powerup_resource.gd"), icon_res)
	add_custom_type("EnemyOverrideResource", "Resource", load("res://addons/altarxian_core/runtime/resources/enemy_override_resource.gd"), icon_res)
	pass


func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	pass
