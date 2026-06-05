extends Node

var weapon_tiers_file = "res://data/Trove Keeper Weapon Tiers .json"
var weapon_tiers : Dictionary = {}

var data_folder := "res://resources/traps/"
var all_data : Array = []


func _ready() -> void:
	populate_data_list(all_data)
	weapon_tiers = parse_json(load_from_file(weapon_tiers_file))


# TRAP-SPECFIC -----------------------------------------------------------------
func find_data_idx(data : TrapData) -> int:
	return all_data.find(data)

func get_trap_data_for_scene(trap_scene : PackedScene) -> TrapData:
	var data = null
	for d : TrapData in all_data:
		if d.scene == trap_scene:
			data = d
			break
	return data

func get_data_for_instance(inst : BaseTrap) -> TrapData:
	var scene = load(inst.scene_file_path)
	return get_trap_data_for_scene(scene)


# GENERAL ----------------------------------------------------------------------
func populate_data_list(data_list : Array):
	# clear previous list contents
	data_list.clear()
	
	# open the directory
	var dir = DirAccess.open(data_folder)
	var list : Array = dir.get_files()
	
	for file_name : String in list:
		# exclude .import files
		if file_name.ends_with(".import"):
			list.erase(file_name)
			continue
		
		# trim .remap from file names (might only be relevent for web builds)
		file_name = file_name.trim_suffix(".remap")
		
		# load and add all other files
		var file_path = data_folder + file_name
		var item_data = ResourceLoader.load(file_path)
		if item_data:
			data_list.append(item_data)
		else:
			push_error("Could not load item from ", file_path)


# TIERS ------------------------------------------------------------------------
func reset_tiers(trap : BaseTrap) -> void:
	var data = get_data_for_instance(trap)
	for p in data.upgradeable_properties:
		set_trap_tier(trap, p, 0)

func set_trap_tier(trap : BaseTrap, property : String, tier : int) -> void:
	var data = get_data_for_instance(trap)
	var all_tiers = get_tiers(data.get_type_as_string(), data.display_name, property)
	if all_tiers:
		var full_property_name = data.get(property)
		var max_tier = all_tiers.size() - 1
		var value = all_tiers[min(tier, max_tier)]
		trap.set(full_property_name, value)
	else:
		push_warning("Property \"" + property + "\" \
		does not exist in " + str(trap))
		pass

## Returns an array of tier values for the given property.[br]
##  [code]type[/code] can be tower or consumable [br]
##  [code]trap_name[/code] should match the trap's display name, case does not matter. [br]
##  [code]property[/code] must be an upgradable property: interval_1, special_2, etc.
func get_tiers(type : String, trap_name : String, property : String) -> Array:
	return weapon_tiers[type][trap_name][property]

## Returns the given property's tier [br]
## Tiers use zero-based indices
func get_trap_tier(trap : BaseTrap, property : String) -> int:
	# get current property value
	var data = get_data_for_instance(trap)
	var actual_property_name = data.get(property) # find linked property
	var property_value : float = trap.get(actual_property_name) # cast value to float to work with json
	# find and return that value's tier index
	var tiers = get_tiers(data.get_type_as_string(), data.display_name, property)
	return tiers.find(property_value)


# JSON -------------------------------------------------------------------------
func parse_json(json_string):
	var json = JSON.new()
	var error = json.parse(json_string)
	if error == OK:
		var data_received = json.data
		var data_type = typeof(data_received)
		var accepted_types = [TYPE_DICTIONARY, TYPE_ARRAY]
		if accepted_types.has(data_type):
			#print(data_received) # Prints array
			return data_received
		else:
			print("Unexpected data")
	else:
		print("JSON Parse Error: ", json.get_error_message(), \
		" in ", json_string, " at line ", json.get_error_line())

func load_from_file(path : String):
	var file = FileAccess.open(path, FileAccess.READ)
	var content = file.get_as_text()
	return content
