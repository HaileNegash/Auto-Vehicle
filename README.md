# Godot 4 Auto-Vehicle-Setup Addon

A powerful editor utility for Godot 4 that automates the tedious process of rigging 3D vehicles. With a single click, this tool identifies wheel geometry, sets up the node hierarchy, assigns `RayCast3D` components, and configures a `RigidBody3D` physics setup.

## Features
* **One-Click Rigging:** Automatically detects tire geometry and mesh bounds.
* **Physics Ready:** Converts your static mesh root into a fully functional `RigidBody3D`.
* **Standardized Hierarchy:** Creates a clean, predictable node structure (`Wheel_FL`, `Wheel_FR`, etc.) for arcade physics systems.
* **Non-Destructive:** Reparents existing meshes safely into the new vehicle structure.

## Installation
1. Download this repository.
2. Navigate to your Godot project folder.
3. Copy the `addons/auto_vehicle_setup` folder into your project's `addons/` directory.
   - *Note: If you don't have an `addons/` folder, create one in the root of your project.*
4. Open your project in the Godot Editor.
5. Go to **Project > Project Settings > Plugins**.
6. Find **Auto-Vehicle-Setup** and set the status to **Enabled**.

## How to Use
1. Select the `Node3D` (or root object) containing your vehicle meshes.
2. In the **Inspector** panel, locate the `Auto-Vehicle-Setup3D` section.
3. Assign your target mesh node and vehicle physics script.
4. Click the **Run Organization** button.
5. Your car is now rigged and ready for physics!

## Contributing
Feedback and Pull Requests are welcome. If you find a bug or want to support more suspension types, please open an issue!

## License
MIT License
