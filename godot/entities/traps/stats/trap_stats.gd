class_name TrapStats
extends Resource

signal rank_changed(property, value)

enum CATEGORIES  {
	TOWER
}

@export var category : CATEGORIES = CATEGORIES.TOWER
@export var special_1 : String = ""
@export var special_2 : String = ""

var ranks : Dictionary[String, int] = {
	"interval"  : 1,
	"duration"  : 1,
	"special_1" : 1,
	"special_2" : 1
}

func set_rank(property : String, value) -> void:
	ranks[property] = value
	var variable_name = property
	if variable_name.has("special"):
		variable_name = get(property)
	rank_changed.emit(variable_name, value)
