@tool
class_name CostButton
extends SelectionButton

@onready var cost_label = %CostLabel

var data : TrapData = null : set = set_data
var affordable : bool = false : set = set_affordable


func match_data(d = data) -> void:
	icon_texture = data.icon
	cost_label.text = str(data.base_cost)
	update_affordable()

func update_affordable():
	affordable = GameManager.can_afford(data.base_cost)


# SETTERS ----------------------------------------------------------------------
func set_affordable(state : bool) -> void:
	affordable = state
	disabled = not affordable

func set_data(d) -> void:
	data = d
	GameManager.currency_modified.connect(update_affordable.unbind(1))
	match_data()
