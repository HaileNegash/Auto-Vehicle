@tool
extends Node3D

@export_category("Bulletproof Addon Setup")
@export var target_car: Node3D 

@export var vehicle_physics_script: Script = preload("res://addons/auto_vehicle_setup/Auto_Vehicle.gd")

@export_group("Permanent Scene Export")
@export var save_as_permanent_scene: bool = false
@export_dir var export_directory: String = "res://"

@export_tool_button("Run Organization", "Script")
var run_setup_action = _run_full_setup

func _run_full_setup():
	if not target_car:
		push_error("AutoSetup Error: No target car node assigned!")
		return
		
	if not vehicle_physics_script:
		push_error("AutoSetup Error: No script assigned!")
		return
		
	var scene_root = get_tree().edited_scene_root
	if not scene_root:
		push_error("AutoSetup Error: This utility must be run inside an active editor scene window.")
		return

	var all_meshes: Array = []
	_get_all_meshes(target_car, all_meshes)
	if all_meshes.is_empty():
		push_error("AutoSetup Error: Zero MeshInstance3D nodes detected.")
		return

	var root = target_car
	var is_already_arcade = (root is RigidBody3D and root.get_script() == vehicle_physics_script)
	
	if not is_already_arcade:
		var original_name = root.name
		root.name = original_name + "_deleting"
		
		var new_vehicle = RigidBody3D.new()
		new_vehicle.name = original_name
		new_vehicle.transform = root.transform
		new_vehicle.set_script(vehicle_physics_script)
		
		root.add_sibling(new_vehicle)
		new_vehicle.owner = scene_root
		
		var children_to_move = root.get_children()
		for child in children_to_move:
			root.remove_child(child)
			new_vehicle.add_child(child)
			child.owner = scene_root 
			
		var old_root = root
		root = new_vehicle
		target_car = new_vehicle 
		old_root.free()
		
		root.name = original_name
		print("Transformation Successful: Root safely swapped to RigidBody3D.")
	else:
		print("Target already has the assigned vehicle script attached, skipping conversion.")

	var Body = root.get_node_or_null("Body")
	if not Body:
		Body = Node3D.new()
		Body.name = "Body"
		root.add_child(Body)
		Body.owner = scene_root

	var min_y = INF; var max_y = -INF
	for m in all_meshes:
		var pos = m.to_global(m.get_aabb().get_center()).y
		min_y = min(min_y, pos); max_y = max(max_y, pos)
	var bottom_threshold = min_y + ((max_y - min_y) * 0.5) 

	var potential_seeds = []
	for m in all_meshes:
		var aabb = m.get_aabb()
		var size = aabb.size * m.global_transform.basis.get_scale()
		var center = m.to_global(aabb.get_center())
		
		var is_tire_x = abs(size.y - size.z) < (max(size.y, size.z) * 0.35) and size.x < (max(size.y, size.z) * 0.6)
		var is_tire_z = abs(size.x - size.y) < (max(size.x, size.y) * 0.35) and size.z < (max(size.x, size.y) * 0.6)
		
		if center.y < bottom_threshold and (is_tire_x or is_tire_z):
			var radius = max(size.y, size.z) / 2.0 if is_tire_x else max(size.x, size.y) / 2.0
			if radius > 0.15 and radius < 1.0:
				potential_seeds.append({"mesh": m, "pos": center, "radius": radius})

	var primary_seeds = []
	for s in potential_seeds:
		var too_close = false
		for p in primary_seeds:
			if s.pos.distance_to(p.pos) < s.radius:
				too_close = true; break
		if not too_close: primary_seeds.append(s)

	var car_center_x = 0.0; var car_center_z = 0.0
	for s in primary_seeds:
		car_center_x += s.pos.x; car_center_z += s.pos.z
	if primary_seeds.size() > 0:
		car_center_x /= primary_seeds.size(); car_center_z /= primary_seeds.size()

	var used_meshes = []
	for w_seed in primary_seeds:
		var is_front = w_seed.pos.z > car_center_z
		var is_left = w_seed.pos.x < car_center_x
		var wheel_name = "Wheel_%s%s" % [("F" if is_front else "B"), ("L" if is_left else "R")]
		
		var w_cont = root.get_node_or_null(wheel_name)
		if not w_cont:
			w_cont = Node3D.new()
			w_cont.name = wheel_name
			root.add_child(w_cont)
			w_cont.owner = scene_root
		w_cont.global_position = w_seed.pos
		
		var ray = w_cont.get_node_or_null("RayCast3D")
		if not ray:
			ray = RayCast3D.new()
			ray.name = "RayCast3D"
			w_cont.add_child(ray)
			ray.owner = scene_root
		ray.target_position = Vector3(0, -1.0, 0)
		ray.enabled = true
		
		for m in all_meshes:
			if m in used_meshes: continue
			if m.to_global(m.get_aabb().get_center()).distance_to(w_seed.pos) <= w_seed.radius * 1.5:
				m.reparent(w_cont, true)
				m.owner = scene_root
				used_meshes.append(m)

	for m in all_meshes:
		if not m in used_meshes:
			m.reparent(Body, true)
			m.owner = scene_root

	_link_to_arcade_fields(root)
	
	var col = root.get_node_or_null("CollisionShape3D")
	if not col:
		col = CollisionShape3D.new()
		col.name = "CollisionShape3D"
		var shape = BoxShape3D.new()
		shape.size = Vector3(1.8, 1.2, 4.0)
		col.shape = shape
		col.position = Vector3(0, 0.6, 0)
		root.add_child(col)
		col.owner = scene_root
		print("Injected standard baseline CollisionShape3D bounds.")

	if save_as_permanent_scene:
		root.owner = null
		_set_owners_recursive(root, root)
		
		var clean_name = root.name.validate_filename()
		var final_file_path = export_directory.path_join(clean_name + "_rigged.tscn")
		
		var packed_scene = PackedScene.new()
		var pack_status = packed_scene.pack(root)
		
		if pack_status == OK:
			var save_status = ResourceSaver.save(packed_scene, final_file_path)
			if save_status == OK:
				print("SUCCESS: Permanent asset generated at: ", final_file_path)
			else:
				push_error("AutoSetup Error: Failed to write the .tscn file to disk.")
		else:
			push_error("AutoSetup Error: Failed to pack the vehicle node tree hierarchy.")
		
		root.owner = scene_root
		_set_owners_recursive(root, scene_root)

	EditorInterface.mark_scene_as_unsaved()
	print("SUCCESS: Vehicle pipeline finished processing!")

func _link_to_arcade_fields(root: Node3D):
	root.set("front_left_ray", root.get_node_or_null("Wheel_FL/RayCast3D"))
	root.set("front_right_ray", root.get_node_or_null("Wheel_FR/RayCast3D"))
	root.set("rear_left_ray", root.get_node_or_null("Wheel_BL/RayCast3D"))
	root.set("rear_right_ray", root.get_node_or_null("Wheel_BR/RayCast3D"))
	
	var fl_w = root.get_node_or_null("Wheel_FL")
	var fr_w = root.get_node_or_null("Wheel_FR")
	var bl_w = root.get_node_or_null("Wheel_BL")
	var br_w = root.get_node_or_null("Wheel_BR")
	
	if fl_w: root.set("front_left_mesh", _find_mesh_child(fl_w))
	if fr_w: root.set("front_right_mesh", _find_mesh_child(fr_w))
	if bl_w: root.set("rear_left_mesh", _find_mesh_child(bl_w))
	if br_w: root.set("rear_right_mesh", _find_mesh_child(br_w))

func _find_mesh_child(node: Node) -> MeshInstance3D:
	for c in node.get_children():
		if c is MeshInstance3D: return c
	return null

func _get_all_meshes(node: Node, list: Array) -> void:
	if node is MeshInstance3D: list.append(node)
	for child in node.get_children():
		_get_all_meshes(child, list)

func _set_owners_recursive(node: Node, new_owner: Node):
	for child in node.get_children():
		if child != new_owner:
			child.owner = new_owner
		_set_owners_recursive(child, new_owner)
