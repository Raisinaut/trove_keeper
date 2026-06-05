class_name TrapData
extends Resource

enum TYPES  {
	TOWER
}

@export var type : TYPES = TYPES.TOWER
## The name used to represent the trap within the UI.
@export var display_name : String
## The texture used to represent the trap within the UI.
@export var icon : Texture
## The game object used within the game world.
@export var scene : PackedScene
## How much it costs to place the trap
@export var base_cost : int

@export_category("UPGRADEABLE PROPERTIES")
@export var interval : String = "active_interval"
@export var duration : String = "active_duration"
@export var special_1 : String = ""
@export var special_2 : String = ""

var upgradeable_properties = [
	"interval",
	"duration",
	"special_1",
	"special_2"
]

func get_type_as_string(lowercase := true) -> String:
	var string : String = TYPES.keys()[type]
	if lowercase:
		string = string.to_lower()
	return string
