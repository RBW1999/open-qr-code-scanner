extends Control

@export var hover_scale : float = 1.1

func _ready() -> void:
	offset_transform_enabled = true
	
	mouse_entered.connect(on_mouse_entered)
	mouse_exited.connect(on_mouse_exited)

func on_mouse_entered() -> void:
	offset_transform_scale = Vector2(hover_scale,hover_scale)

func on_mouse_exited() -> void:
	offset_transform_scale = Vector2(1,1)
