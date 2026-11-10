extends Node3D
class_name XRPopUp

@onready var xr_camera_3d: XRCamera3D = %XRCamera3D
@export var distance_to_camera : float = 1
@export var roation_angle_threshold : int = 30
@export var tween_time : float = 0.5

var is_ready : bool = false
var rotation_tween : Tween

func show_pop_up() -> void:
	if(not is_ready):
		setup_pop_up()
	
	visible = true

func hide_pop_up() -> void:
	visible= false

func setup_pop_up() -> void:
	place_pop_up_in_view()
	
	var xr_main : XRMain = get_tree().root.get_node("XRMain") as XRMain
	assert(xr_main != null and xr_main is XRMain)
	
	xr_main.pose_recentered.connect(place_pop_up_in_view)
	
	is_ready = true
	
	

func _process(_delta: float) -> void:
	if (visible):
		move_pop_up_to_view()

func place_pop_up_in_view() -> void:
	
	position = xr_camera_3d.position
	rotation.y = xr_camera_3d.rotation.y
	get_child(0).position.z = -distance_to_camera


# move the pop up back to view when the rotation threshold is met
func move_pop_up_to_view() -> void:
	var rotation_delta_deg : float = rad_to_deg(abs(rotation.y - xr_camera_3d.rotation.y))
	
	if (rotation_delta_deg > roation_angle_threshold):
		rotation_tween = get_tree().create_tween()
		var target_rotation : Vector3 = Vector3(0, xr_camera_3d.rotation.y, 0)
		rotation_tween.tween_property(self, "rotation", target_rotation, tween_time).set_ease(Tween.EASE_IN_OUT)
	
