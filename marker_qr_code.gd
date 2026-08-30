extends XRAnchor3D

var marker_tracker: OpenXRMarkerTracker
@export var ui : MeshInstance3D
@export var ui_scale_factor := 10

func _ready() -> void:
	marker_tracker = XRServer.get_tracker(tracker)
	
	var bounds := marker_tracker.bounds_size
	print(marker_tracker.bounds_size)
	
	
	if marker_tracker:
		match marker_tracker.marker_type:
			OpenXRSpatialComponentMarkerList.MARKER_TYPE_QRCODE:
				@warning_ignore("untyped_declaration")
				var data = marker_tracker.get_marker_data()
				if data is String:
					# Data is a QR code as a string, usually a URL.
					pass
				elif data is PackedByteArray:
					# Data is binary, can be anything.
					pass
			OpenXRSpatialComponentMarkerList.MARKER_TYPE_MICRO_QRCODE:
				@warning_ignore("untyped_declaration")
				var data = marker_tracker.get_marker_data()
				if data is String:
					# Data is a QR code as a string, usually a URL.
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
		
