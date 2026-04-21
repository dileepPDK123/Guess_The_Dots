extends Node
## ComboManager — tracks consecutive wins without hint use and multiplies XP rewards.

signal combo_changed(new_count: int)

var _hint_used_this_round: bool = false

func _ready() -> void:
	pass  # current_combo loaded from SaveData in start_new_round()

## Call at the start of every new round.
func start_round() -> void:
	_hint_used_this_round = false

## Call when a hint is used (token or rewarded ad).
func mark_hint_used() -> void:
	_hint_used_this_round = true

## Call at game end. did_win = outcome, mode_name used to block ineligible modes.
## Returns XP multiplier to apply.
func on_game_finished(did_win: bool, mode_name: String) -> float:
	var ineligible := ["SANDBOX"]  # modes that don't affect combo
	if ineligible.has(mode_name):
		return 1.0

	if did_win and not _hint_used_this_round:
		SaveData.current_combo += 1
	else:
		SaveData.current_combo = 0

	SaveData.save()
	combo_changed.emit(SaveData.current_combo)
	return get_multiplier()

## Returns the XP multiplier for the current combo.
func get_multiplier() -> float:
	match SaveData.current_combo:
		0, 1: return 1.0
		2:    return 1.5
		3:    return 2.0
		_:    return 2.5  # 4+
