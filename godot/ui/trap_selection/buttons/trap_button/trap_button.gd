@tool
class_name TrapButton
extends SelectionButton

@export var data : TrapData = null : set = set_data

@onready var cost_label = %CostLabel

var affordable : bool = false : set = set_affordable


func _ready() -> void:
	super()
	GameManager.currency_modified.connect(_on_game_manager_currency_modified)

func match_data(d = data) -> void:
	icon_texture = data.icon
	cost_label.text = str(data.base_cost)
	update_affordable()

func update_affordable():
	affordable = GameManager.can_afford(data.base_cost)


# SIGNALS ----------------------------------------------------------------------
func _on_game_manager_currency_modified(_value : int) -> void:
	update_affordable()


# SETTERS ----------------------------------------------------------------------
func set_affordable(state : bool) -> void:
	affordable = state
	disabled = not affordable

func set_data(d) -> void:
	data = d
	match_data()
