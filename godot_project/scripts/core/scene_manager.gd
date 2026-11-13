extends Node

signal scene_load_started(target_path: String)
signal scene_load_progress(progress: float)
signal scene_load_finished(target_path: String)

const LOADING_SCREEN_SCENE := "res://scenes/menus/loading_screen.tscn"

var _target_scene_path: String = ""
var _is_loading: bool = false
var _loading_overlay: CanvasLayer = null

func _process(_delta: float) -> void:
	if not _is_loading or _target_scene_path.is_empty():
		return

	var progress_arr: Array = []
	var status: int = ResourceLoader.load_threaded_get_status(_target_scene_path, progress_arr)
	match status:
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			var pct: float = float(progress_arr[0]) if progress_arr.size() > 0 else 0.25
			scene_load_progress.emit(pct)
			if _loading_overlay and _loading_overlay.has_method("set_progress"):
				_loading_overlay.set_progress(pct)
		ResourceLoader.THREAD_LOAD_LOADED:
			var packed: PackedScene = ResourceLoader.load_threaded_get(_target_scene_path)
			_is_loading = false
			scene_load_progress.emit(1.0)
			if _loading_overlay and _loading_overlay.has_method("set_progress"):
				_loading_overlay.set_progress(1.0)
			var err: int = get_tree().change_scene_to_packed(packed)
			if err != OK:
				push_error("SceneManager: Failed to switch to scene %s (err=%d)" % [_target_scene_path, err])
			var finished_path := _target_scene_path
			_target_scene_path = ""
			await get_tree().process_frame
			_hide_loading_screen()
			scene_load_finished.emit(finished_path)
		ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			push_error("SceneManager: Threaded load failed for %s" % _target_scene_path)
			_is_loading = false
			_target_scene_path = ""
			_hide_loading_screen()

func load_scene(scene_path: String) -> void:
	if _is_loading:
		return
	if not ResourceLoader.exists(scene_path):
		push_error("SceneManager: Missing scene resource %s" % scene_path)
		return

	_show_loading_screen(scene_path)
	_target_scene_path = scene_path
	_is_loading = true
	scene_load_started.emit(scene_path)

	var err: int = ResourceLoader.load_threaded_request(scene_path)
	if err != OK:
		push_warning("SceneManager: Falling back to synchronous load for %s" % scene_path)
		_is_loading = false
		_target_scene_path = ""
		get_tree().change_scene_to_file(scene_path)
		_hide_loading_screen()
		scene_load_finished.emit(scene_path)

func _show_loading_screen(target_path: String) -> void:
	if _loading_overlay == null and ResourceLoader.exists(LOADING_SCREEN_SCENE):
		var packed := load(LOADING_SCREEN_SCENE) as PackedScene
		if packed:
			_loading_overlay = packed.instantiate()
			get_tree().root.add_child(_loading_overlay)
	if _loading_overlay:
		_loading_overlay.visible = true
		if _loading_overlay.has_method("set_target_label"):
			_loading_overlay.set_target_label(target_path)

func _hide_loading_screen() -> void:
	if _loading_overlay and is_instance_valid(_loading_overlay):
		if _loading_overlay.has_method("fade_out_and_hide"):
			_loading_overlay.fade_out_and_hide()
		else:
			_loading_overlay.visible = false
