@tool
extends Node3D

@export_group("Track Customisation")
@export_range(10, 100, 5) var segment_length: int = 20:
	set(value):
		segment_length = value
		
		generate_track()

@export_range(2, 25, 1) var track_points: int = 2:
	set(value):
		track_points = value
		
		generate_track()

@export_range(0, 100, 5) var variation_factor: int = 5:
	set(value):
		variation_factor = value
		generate_track()

@export_range(0, 5, 1) var height_variation_factor: int = 0:
	set(value):
		height_variation_factor = value
		generate_track()

@export_range(0, 20, 1) var corner_tangent_scale: int = 5:
	set(value):
		corner_tangent_scale = value
		generate_track()

@export var smooth_corners: bool = false:
	set(value):
		smooth_corners = value
		generate_track()

@export_group("Save Settings")
@export var track_name: String

@export var save_track: bool = false:
	set(value):
		save_track = value
		
		if track_name and save_track:
			save_current_track()

func generate_track() -> void:
	var generated_curve = Curve3D.new()
	
	# Ensure that the track is closed
	generated_curve.closed = true
	
	var angle := 0.0
	# Use TAU to track the change in angle to create a circle
	var angle_step = TAU / track_points
	
	var points := []
	
	for i in range(track_points):
		angle += angle_step
		
		var radius := segment_length + randi_range(-variation_factor, variation_factor)
		
		# Convert Polar coordinates to Cartesian coordinates
		var x := radius * cos(angle)
		var z := radius * sin(angle)
		
		var y := randf_range(-height_variation_factor, height_variation_factor)
		
		# Add the generated point to the curve
		points.append(Vector3(x, y, z))
	
	if not smooth_corners:
		for i in range(track_points):
			var point = points[i]
			
			generated_curve.add_point(point)
			
	else:
		for i in range(track_points):
			var point = points[i]
				
			var previousPoint = points[(i - 1 + track_points) % track_points]
			var nextPoint = points[(i + 1) % track_points]
			
			var tangent = (nextPoint - previousPoint).normalized()
			
			var in_handle = -tangent * corner_tangent_scale
			var out_handle = tangent * corner_tangent_scale

			generated_curve.add_point(point, in_handle, out_handle)

	$TrackPath.curve = generated_curve

func save_current_track() -> void:
	var root = Node3D.new()
	var path = Path3D.new()
	var new_curve = Curve3D.new()
	var poly = CSGPolygon3D.new()
	
	poly.mode = CSGPolygon3D.MODE_PATH
	
	poly.set_polygon($TrackPath/Track.get_polygon())
	
	var current_track_points = $TrackPath.curve.get_baked_points()
	
	path.add_child(poly)
	root.add_child(path)
	
	poly.owner = root
	path.owner = root
	
	root.name = "TrackRoot"
	path.name = "TrackPath"
	poly.name = "Track"

	for i in range(current_track_points.size()):
		var point = current_track_points[i]
		new_curve.add_point(point)
	
	new_curve.closed = true
	
	path.curve = new_curve

	poly.use_collision = true
	poly.path_node = ^".."
	
	var new_scene = PackedScene.new()
	# Returns an integer error, 0 for OK
	var result = new_scene.pack(root)
	
	# Dynamically generates the file name from the given track name
	var save_path = "res://Entities/Tracks/%s.tscn" % track_name.to_snake_case()
	
	if result == OK:
		# Saves the scene
		var err = ResourceSaver.save(new_scene, save_path)
		
		if err != OK:
			print("Failed to save scene: ", err)
	else:
		print("Failed to pack scene")
