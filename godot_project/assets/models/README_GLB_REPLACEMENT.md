# Custom 3D GLB / glTF Asset Replacement Guide

`TACTICAL STRIKE: ZERO HOUR` ships with ready-to-play procedural 3D meshes and animations for all 7 weapons and 3 enemy archetypes so the APK runs out-of-the-box without external paid packs.

To drop in custom `.glb` or `.gltf` models:

1. **Weapons (`res://assets/models/weapons/`)**
   - Place your `.glb` file inside `assets/models/weapons/`.
   - Open the target `.tres` file in `resources/weapons/` (e.g., `vx47_assault_rifle.tres`).
   - Set `custom_glb_path = "res://assets/models/weapons/your_rifle.glb"`.
   - `WeaponRig` automatically hides the procedural placeholder and mounts your GLB under `ModelRoot/CustomModelAnchor` while preserving `AnimationPlayer` recoil, reload, equip, and inspect animations.

2. **Characters & Enemies (`res://assets/models/characters/`)**
   - Place your rigged `.glb` file inside `assets/models/characters/`.
   - Open the target `.tres` file in `resources/enemies/` (e.g., `rifleman.tres`).
   - Set `custom_glb_path = "res://assets/models/characters/your_soldier.glb"`.
   - `EnemyAI` preserves `NavigationAgent3D`, `AnimationTree` state machine, and head/torso hitboxes automatically.
