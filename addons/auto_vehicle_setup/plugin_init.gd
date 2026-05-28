@tool
extends EditorPlugin

func _enter_tree() -> void:
	var janitor_icon = preload("res://addons/auto_vehicle_setup/janitor_icon.png")
	
	add_custom_type(
		"Auto-Vehicle-Setup3D", 
		"Node3D", 
		preload("VehicleAutoSetup.gd"), 
		janitor_icon
	)

func _exit_tree() -> void:
	remove_custom_type("Auto-Vehicle-Setup3D")
	print("[AutoVehicleSetup] Nodes unregistered cleanly.")
