extends XRAnchor3D

@export var ui : MeshInstance3D
@export var ui_scale_factor := 10
@onready var qr_code_border: XRToolsViewport2DIn3D = %QRCodeBorder
@onready var qr_code_buttons: XRToolsViewport2DIn3D = %QRCodeButtons

var marker_tracker: OpenXRMarkerTracker

var content := ""
var content_is_valid_url := false
var data_is_binary := false
var marker_type_not_supported := false

var qr_code_ui : QR_Code_UI_Controller

func _ready() -> void:
	marker_tracker = XRServer.get_tracker(tracker)
	
	if marker_tracker:
		match marker_tracker.marker_type:
			OpenXRSpatialComponentMarkerList.MARKER_TYPE_QRCODE:
				@warning_ignore("untyped_declaration")
				var data = marker_tracker.get_marker_data()
				if data is String:
					# Data is a QR code as a string, usually a URL.
					content = data
				elif data is PackedByteArray:
					# Data is binary, can be anything.
					data_is_binary = true
			OpenXRSpatialComponentMarkerList.MARKER_TYPE_MICRO_QRCODE:
				@warning_ignore("untyped_declaration")
				var data = marker_tracker.get_marker_data()
				if data is String:
					# Data is a QR code as a string, usually a URL.
					content = data
					pass
				elif data is PackedByteArray:
					# Data is binary, can be anything.
					data_is_binary = true
			OpenXRSpatialComponentMarkerList.MARKER_TYPE_ARUCO:
				# Use marker_tracker.marker_id to identify the marker.
				pass
			OpenXRSpatialComponentMarkerList.MARKER_TYPE_APRIL_TAG:
				# Use marker_tracker.marker_id to identify the marker.
				pass
	
	if (marker_type_not_supported):
		push_warning("Marker Type is not supported.")
		return
	
	if (data_is_binary):
		push_warning("Binary data is not supported.")
		return
	
	# setup UI
	var qr_code_size := marker_tracker.bounds_size * 10
	
	qr_code_border.screen_size *= qr_code_size
	
	print(qr_code_size)
	
	# transform buttons under qr code border
	# qr_code_buttons.screen_size *= bounds
	qr_code_buttons.position = Vector3(0, qr_code_buttons.position.y * qr_code_size.x, 0)
	
	qr_code_ui = qr_code_buttons.get_scene_instance()
	
	content_is_valid_url = is_valid_url(content)
	qr_code_ui.set_qr_code_ui_content(content_is_valid_url, content)
	
	print("Content: " + content)
	
	qr_code_ui.open_link.connect(on_open_link_pressed)
	qr_code_ui.copy_content.connect(on_copy_content_pressed)


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
	DisplayServer.clipboard_set(content)
