extends XRAnchor3D

@export var ui : MeshInstance3D
@export var ui_scale_factor := 10
@onready var viewport_2Din3D : XRToolsViewport2DIn3D = $Viewport2Din3D

var marker_tracker: OpenXRMarkerTracker
const QR_CODE_UI_SCALER := 1.4

var content := ""
var content_is_valid_url := false

func _ready() -> void:
	marker_tracker = XRServer.get_tracker(tracker)
	
	viewport_2Din3D.screen_size = marker_tracker.bounds_size * QR_CODE_UI_SCALER
	# connect ui signals
	viewport_2Din3D.get_scene_instance().open_link.connect(on_open_link_pressed)
	# TODO
	
	if marker_tracker:
		match marker_tracker.marker_type:
			OpenXRSpatialComponentMarkerList.MARKER_TYPE_QRCODE:
				@warning_ignore("untyped_declaration")
				var data = marker_tracker.get_marker_data()
				if data is String:
					# Data is a QR code as a string, usually a URL.
					content = data
					pass
				elif data is PackedByteArray:
					# Data is binary, can be anything.
					pass
			OpenXRSpatialComponentMarkerList.MARKER_TYPE_MICRO_QRCODE:
				@warning_ignore("untyped_declaration")
				var data = marker_tracker.get_marker_data()
				if data is String:
					# Data is a QR code as a string, usually a URL.
					content = data
					pass
				elif data is PackedByteArray:
					# Data is binary, can be anything.
					pass
			OpenXRSpatialComponentMarkerList.MARKER_TYPE_ARUCO:
				# Use marker_tracker.marker_id to identify the marker.
				pass
			OpenXRSpatialComponentMarkerList.MARKER_TYPE_APRIL_TAG:
				# Use marker_tracker.marker_id to identify the marker.
				pass

func is_valid_url(url : String) -> bool:
	var regex := RegEx.new()
	
	# Using a raw string (r"...") prevents having to double-escape backslashes
	# URL RegEx from https://regex101.com/r/3fYy3x/1
	var pattern := r"(?:http[s]?:\/\/.)?(?:www\.)?[-a-zA-Z0-9@%._\+~#=]{2,256}\.[a-z]{2,6}\b(?:[-a-zA-Z0-9@:%_\+.~#?&\/\/=]*)"
	
	# Compile the pattern and check for errors
	var err := regex.compile(pattern)
	if err != OK:
		push_error("Failed to compile regex!")
		return false
	  
	# search() returns a RegExMatch object if it finds a match, or null if it fails
	var result := regex.search(url)
		
	return result != null

func on_open_link_pressed() -> void:
	OS.shell_open(content)
	get_tree().quit()

func on_copy_content_pressed() -> void:
	pass
