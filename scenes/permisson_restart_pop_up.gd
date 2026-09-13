extends Node3D
@onready var xr_camera_3d: XRCamera3D = %XRCamera3D


func _ready() -> void:
	rotate_y(xr_camera_3d.rotation.y)
