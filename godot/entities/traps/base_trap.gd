class_name BaseTrap
extends Node2D

signal charge_updated

## The values cycled between when the trap is interacted with.[br]
## These could represent rotations, spin directions, etc.
@export var interaction_states : Array[Variant] = []

## The times between activations.
@export var active_interval : float = 1.0
## How long activity lasts.
@export var active_duration : float = 2.0

@onready var interaction_area : InteractionArea = $InteractionArea
@onready var interact_display : InteractPrompt = $InteractCost

var interaction_state_idx = 0 : set = set_interaction_state_idx
var active : bool = false : set = set_active
var enabled : bool = false : set = set_enabled
var activate_on_enable : bool = true
var activity_timer : SceneTreeTimer = null


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	interaction_area.interacted.connect(_on_interaction_area_interacted)
	interaction_area.can_interact_changed.connect(_on_can_interact_changed)
	interact_display.hide()
	_connect_signals()
	TrapManager.reset_ranks(self)


func _process(delta: float) -> void:
	charge_updated.emit(get_charge())

func get_charge() -> float:
	if not activity_timer:
		return 0.0
	var charge : float = 0.0
	var timer_length = active_duration if active else active_interval
	if timer_length != 0:
		charge = activity_timer.time_left / timer_length
	if not active:
		charge = 1.0 - charge
	return charge


# OVERRIDES --------------------------------------------------------------------
func _on_activate() -> void:
	pass

func _on_deactivate() -> void:
	pass

func _on_interact() -> void:
	pass

func _connect_signals() -> void:
	pass


# INTERACTION STATE ------------------------------------------------------------
func get_current_interaction_state() -> Variant:
	return interaction_states[interaction_state_idx]

func cycle_interaction_state() -> void:
	interaction_state_idx += 1


# SETTERS ----------------------------------------------------------------------
func set_interaction_state_idx(value : int) -> void:
	value = wrapi(value, 0, interaction_states.size())
	interaction_state_idx = value
	interact_display.update_action_icon(interaction_state_idx)

func set_active(state : bool) -> void:
	active = state
	if active:
		_on_activate()
	else:
		_on_deactivate()

func set_enabled(state : bool) -> void:
	enabled = state
	if enabled and activate_on_enable:
		start_active_duration()
	else:
		set_active(false)
		cancel_activity_timer()


# SIGNALS ----------------------------------------------------------------------
func _on_active_interval_timeout() -> void:
	start_active_duration()

func _on_active_duration_timeout() -> void:
	start_active_interval()

func _on_interaction_area_interacted() -> void:
	cycle_interaction_state()
	_on_interact()

func _on_can_interact_changed(state : bool) -> void:
	interact_display.visible = state


# TIMERS -----------------------------------------------------------------------
func start_active_interval():
	set_active(false)
	activity_timer = get_tree().create_timer(active_interval)
	activity_timer.timeout.connect(_on_active_interval_timeout)

func start_active_duration():
	set_active(true)
	activity_timer = get_tree().create_timer(active_duration)
	activity_timer.timeout.connect(_on_active_duration_timeout)

func cancel_activity_timer() -> void:
	activity_timer.free()
