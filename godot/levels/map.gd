class_name InteractableMap
extends Node2D

@onready var ground = $Ground
@onready var traps = $Traps
@onready var traps_hover = $TrapsHover
@onready var highlight_box = $Ground/HighlightBox

var highlight_coords = Vector2i.ZERO
var hover_opacity = 0.6 # visibility percent
var selected_scene = -1 # -1 is null
var refund_percent = 0.5

enum MODES {
	DEFAULT,
	PLACE,
	REMOVE
}
var mode = MODES.DEFAULT


func _ready() -> void:
	# Change ground z-index to allow for more layered spritework
	ground.z_index = -10
	highlight_box.z_index = 1
	ground.update_track_tiles()
	traps.child_registered.connect(_on_traps_child_registered)

func _process(delta: float) -> void:
	update_hover()
	update_highlight()

func update_hover():
	traps_hover.clear()
	var player_position = GameManager.player.global_position
	highlight_coords = traps_hover.local_to_map(player_position)
	var tile_idx = selected_scene + 1 #always add one when accessing tiles
	if is_idx_valid(tile_idx):
		var no_trap_present = is_cell_unused_by_layer(highlight_coords, traps)
		traps_hover.visible = no_trap_present
		traps_hover.set_cell(highlight_coords, 0, Vector2i(0, 0), tile_idx)
		if can_place():
			traps_hover.modulate = Color("ffffff") * hover_opacity
		else:
			traps_hover.modulate = Color("f5767a") * hover_opacity

func update_highlight():
	match mode:
		MODES.DEFAULT:
			highlight_box.play("default")
			highlight_box.visible = true
			highlight_box.modulate = Color("c0cbdc")
			if not can_place():
				highlight_box.modulate = Color("f5767a")
		MODES.PLACE:
			highlight_box.play("place")
			#highlight_box.visible = is_highlighting()
			highlight_box.modulate = Color("ffffff")
			if not is_highlighting():
				highlight_box.play("default")
				highlight_box.modulate = Color("f5767a")
			if not can_place():
				highlight_box.modulate = Color("f5767a")
		MODES.REMOVE:
			highlight_box.play("remove")
			highlight_box.visible = true
			highlight_box.modulate = Color("63c74d")
			if not can_remove():
				highlight_box.modulate = Color("f5767a")
	if highlight_box.visible:
		var highlight_pos = traps.map_to_local(highlight_coords)
		highlight_box.global_position = highlight_pos

func place_trap(cost : int) -> void:
	var tile_idx = selected_scene + 1
	if is_idx_valid(tile_idx):
		GameManager.spend_currency(cost)
		traps.set_cell(highlight_coords, 0, Vector2i(0, 0), tile_idx)

func remove_trap(cost : int) -> void:
	traps.erase_cell(highlight_coords)
	var refund_amount = int(cost * refund_percent)
	GameManager.gain_currency(refund_amount)

func get_highlighted_scene_as_packed() -> PackedScene:
	var tile_idx = traps.get_cell_alternative_tile(highlight_coords)
	var trap_tiles : TileSet = traps.tile_set
	var scene_collection : TileSetScenesCollectionSource = trap_tiles.get_source(0)
	var trap = scene_collection.get_scene_tile_scene(tile_idx)
	return trap

func get_highlighted_scene() -> Node2D:
	return traps.get_cell_scene(highlight_coords)


# SIGNALS ----------------------------------------------------------------------
func _on_traps_child_registered(child) -> void:
	# Enable traps after they are placed on the trap layer
	child.enabled = true


# SETUP ------------------------------------------------------------------------
func add_trap_tile(scene : PackedScene) -> void:
	var trap_tiles : TileSet = traps.tile_set
	var scene_collection: TileSetScenesCollectionSource = trap_tiles.get_source(0)
	scene_collection.create_scene_tile(scene)


# CHECKS -----------------------------------------------------------------------
func is_cell_valid(coords : Vector2i) -> bool:
	var valid = true
	# Check against track
	if ground.track_tiles.has(coords):
		valid = false
	# Check against additional layers
	var layers_to_check : Array[TileMapLayer] = [traps]
	for layer in layers_to_check:
		if not is_cell_unused_by_layer(coords, layer):
			valid = false
			break
	return valid

func is_cell_unused_by_layer(coords : Vector2i, map : TileMapLayer) -> bool:
	var usable_coords : Array = ground.get_used_cells()
	var map_coords : Array = map.get_used_cells()
	for c in map_coords:
		usable_coords.erase(c)
	return usable_coords.has(coords)

func is_idx_valid(idx : int) -> bool:
	var hover_tiles : TileSet = traps.tile_set
	var scene_collection: TileSetScenesCollectionSource = hover_tiles.get_source(0)
	return scene_collection.has_scene_tile_id(idx)

func is_highlighting() -> bool:
	return traps_hover.get_used_cells().size() > 0

func can_place() -> bool:
	return is_cell_valid(highlight_coords)

func can_remove() -> bool:
	return traps.get_used_cells().has(highlight_coords)
