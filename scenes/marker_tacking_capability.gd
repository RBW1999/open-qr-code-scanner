extends Node

## implementation from https://docs.godotengine.org/en/stable/tutorials/xr/openxr_spatial_entities.html#marker-tracking-capability

var qrcode_config : OpenXRSpatialCapabilityConfigurationQrCode
var spatial_context: RID

func _set_up_spatial_context() ->  void:
	# Already set up?
	if spatial_context:
		return

	var configurations : Array

	OpenXRSpatialMarkerTrackingCapability.is_april_tag_supported()

	# Add our QR code configuration.
	if not OpenXRSpatialMarkerTrackingCapability.is_qrcode_supported(): #qrcode_is_supported():
		qrcode_config = OpenXRSpatialCapabilityConfigurationQrCode.new()
		configurations.push_back(qrcode_config)


	# Nothing supported?
	if configurations.is_empty():
		return

	var future_result : OpenXRFutureResult = OpenXRSpatialEntityExtension.create_spatial_context(configurations)

	# Wait for async completion.
	await future_result.completed

	# Obtain our result.
	spatial_context = future_result.get_spatial_context()
	if spatial_context:
		# Connect to our discovery signal.
		OpenXRSpatialEntityExtension.spatial_discovery_recommended.connect(_on_perform_discovery)

		# Perform our initial discovery.
		_on_perform_discovery(spatial_context)


func _enter_tree() -> void:
	var openxr_interface : OpenXRInterface = XRServer.find_interface("OpenXR")
	if openxr_interface and openxr_interface.is_initialized():
		# Just in case our session hasn't started yet,
		# call our spatial context creation on start.
		openxr_interface.session_begun.connect(_set_up_spatial_context)

		# And in case it is already up and running, call it already,
		# it will exit if we've called it too early.
		_set_up_spatial_context()

func _exit_tree() -> void:
	if spatial_context:
		# Disconnect from our discovery signal.
		OpenXRSpatialEntityExtension.spatial_discovery_recommended.disconnect(_on_perform_discovery)

		# Free our spatial context, this will clean it up.
		OpenXRSpatialEntityExtension.free_spatial_context(spatial_context)
		spatial_context = RID()

	var openxr_interface : OpenXRInterface = XRServer.find_interface("OpenXR")
	if openxr_interface and openxr_interface.is_initialized():
		openxr_interface.session_begun.disconnect(_set_up_spatial_context)

var discovery_result : OpenXRFutureResult

func _on_perform_discovery(p_spatial_context):
	# We get this signal for all spatial contexts, so exit if this is not for us.
	if p_spatial_context != spatial_context:
		return

	# If we currently have an ongoing discovery result, cancel it.
	if discovery_result:
		discovery_result.cancel_discovery()

	# Perform our discovery.
	discovery_result = OpenXRSpatialEntityExtension.discover_spatial_entities(spatial_context, [ \
			OpenXRSpatialEntityExtension.COMPONENT_TYPE_BOUNDED_2D, \
			OpenXRSpatialEntityExtension.COMPONENT_TYPE_PLANE_ALIGNMENT \
		])

	# Wait for async completion.
	await discovery_result.completed

	var snapshot : RID = discovery_result.get_spatial_snapshot()
	if snapshot:
		# Process our snapshot result.
		_process_snapshot(snapshot)

		# And clean up our snapshot.
		OpenXRSpatialEntityExtension.free_spatial_snapshot(snapshot)

var entities : Dictionary[int, OpenXRSpatialEntityTracker]

func _process(_delta : float) -> void:
	if not spatial_context:
		return

	if entities.is_empty():
		return

	var entity_rids: Array[RID]
	for entity_id in entities:
		entity_rids.push_back(entities[entity_id].entity)

	var snapshot : RID = OpenXRSpatialEntityExtension.update_spatial_entities(spatial_context, entity_rids, [ \
			OpenXRSpatialEntityExtension.COMPONENT_TYPE_BOUNDED_2D, \
			OpenXRSpatialEntityExtension.COMPONENT_TYPE_PLANE_ALIGNMENT \
		])
	if snapshot:
		# Process our snapshot.
		_process_snapshot(snapshot)

		# And clean up our snapshot.
		OpenXRSpatialEntityExtension.free_spatial_snapshot(snapshot)

func _process_snapshot(p_snapshot):
	# Always include our query result data.
	var query_result_data : OpenXRSpatialQueryResultData = OpenXRSpatialQueryResultData.new()

	# Add our bounded 2D component data.
	var bounded2d_list : OpenXRSpatialComponentBounded2DList = OpenXRSpatialComponentBounded2DList.new()

	# And our plane alignment component data.
	var alignment_list : OpenXRSpatialComponentPlaneAlignmentList = OpenXRSpatialComponentPlaneAlignmentList.new()

	if OpenXRSpatialEntityExtension.query_snapshot(p_snapshot, [ query_result_data, bounded2d_list, alignment_list]):
		for i in query_result_data.get_entity_id_size():
			var entity_id = query_result_data.get_entity_id(i)
			var entity_state = query_result_data.get_entity_state(i)

			if entity_state == OpenXRSpatialEntityTracker.ENTITY_TRACKING_STATE_STOPPED:
				# This state should only appear when doing an update snapshot
				# and tells us this entity is no longer tracked.
				# We thus remove it from our dictionary which should result
				# in the entity being cleaned up.
				if entities.has(entity_id):
					var entity_tracker : OpenXRSpatialEntityTracker = entities[entity_id]
					entity_tracker.spatial_tracking_state = entity_state
					XRServer.remove_tracker(entity_tracker)
					entities.erase(entity_id)
			else:
				var entity_tracker : OpenXRSpatialEntityTracker
				var register_with_xr_server : bool = false
				if entities.has(entity_id):
					entity_tracker = entities[entity_id]
				else:
					entity_tracker = OpenXRSpatialEntityTracker.new()
					entity_tracker.entity = OpenXRSpatialEntityExtension.make_spatial_entity(spatial_context, entity_id)
					entities[entity_id] = entity_tracker
					register_with_xr_server = true

				# Copy the state.
				entity_tracker.spatial_tracking_state = entity_state

				# If we're tracking, we should query the rest of our components.
				if entity_state == OpenXRSpatialEntityTracker.ENTITY_TRACKING_STATE_TRACKING:
					var center_pose : Transform3D = bounded2d_list.get_center_pose(i)
					entity_tracker.set_pose("default", center_pose, Vector3(), Vector3(), XRPose.XR_TRACKING_CONFIDENCE_HIGH)

					# For this example I'm using OpenXRSpatialEntityTracker which does not
					# hold further data. You should extend this class to store the additional
					# state retrieved. For plane tracking this would be OpenXRPlaneTracker
					# and we can store the following data in the tracker:
					var size : Vector2 = bounded2d_list.get_size(i)
					var alignment = alignment_list.get_plane_alignment(i)
				else:
					entity_tracker.invalidate_pose("default")

				# We don't register our tracker until after we've set our initial data.
				if register_with_xr_server:
					XRServer.add_tracker(entity_tracker)
