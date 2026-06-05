extends CanvasLayer

@onready var button_container = %ButtonContainer
@onready var selection_indicator = $SelectionIndicator
@onready var remove_button: SelectionButton = %RemoveButton
@onready var upgrade_button: SelectionButton = %UpgradeButton

@export var button_scene : PackedScene
@export var map : InteractableMap


func _ready() -> void:
	selection_indicator.hide()
	for d in TrapManager.all_data:
		add_button(d)
	connect_button_signals(remove_button)
	connect_button_signals(upgrade_button)

func add_button(data : TrapData):
	var inst : TrapButton = button_scene.instantiate()
	button_container.call_deferred("add_child", inst)
	await inst.ready
	inst.data = data
	connect_button_signals(inst)
	map.add_trap_tile(data.scene)

func connect_button_signals(btn) -> void:
	btn.selected.connect(_on_button_selected.bind(btn))
	btn.focus_changed.connect(_on_button_focus_changed.bind(btn))


# MAP MANAGEMENT ---------------------------------------------------------------
func place_trap_on_map(data : TrapData) -> void:
	map.selected_scene = TrapManager.find_data_idx(data)
	if map.can_place():
		map.place_trap(data.base_cost)

func remove_highlighted_trap_from_map() -> void:
	if map.can_remove():
		var ps : PackedScene = map.get_highlighted_scene_as_packed()
		var data : TrapData = TrapManager.get_trap_data_for_scene(ps)
		var refund_value = data.base_cost
		map.remove_trap(refund_value)
		
func attempt_to_upgrade_highlighted_trap_on_map() -> void:
	var s = map.get_highlighted_scene()
	if not s:
		return
	var upgrade_property : String = "special_2"
	var current_tier = TrapManager.get_trap_tier(s, upgrade_property)
	TrapManager.set_trap_tier(s, upgrade_property, current_tier + 1)
	print("Upgraded " + s.name + "'s " + upgrade_property)


# SIGNALS ----------------------------------------------------------------------
func _on_button_selected(btn) -> void:
	match(btn.function):
		SelectionButton.FUNCTIONS.PLACE:
			place_trap_on_map(btn.data)
		SelectionButton.FUNCTIONS.REMOVE:
			remove_highlighted_trap_from_map()
		SelectionButton.FUNCTIONS.UPGRADE:
			attempt_to_upgrade_highlighted_trap_on_map()

func _on_button_focus_changed(is_focused : bool, btn : SelectionButton) -> void:
	map.selected_scene = -1
	map.mode = map.MODES.DEFAULT
	if is_focused:
		selection_indicator.show()
		selection_indicator.update_corners(btn)
		match(btn.function):
			SelectionButton.FUNCTIONS.PLACE:
				map.mode = map.MODES.PLACE
				if not btn.disabled:
					map.selected_scene = TrapManager.find_data_idx(btn.data)
			SelectionButton.FUNCTIONS.REMOVE:
				map.mode = map.MODES.REMOVE
	else:
		selection_indicator.hide()
