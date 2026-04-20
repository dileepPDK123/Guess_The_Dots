extends Node
## DailyChallenge — date-seeded daily puzzle generator
## Same sequence worldwide for the same date (UTC).
## Autoloaded as "DailyChallenge".

const DAILY_SLOTS  := 4   # always 4 slots for daily
const DAILY_COLORS := 5   # 5 colors same as classic
const DAILY_MAX_GUESSES := 8

signal daily_completed(did_win: bool, guesses_used: int)

# =============================================================================
# Sequence generation — deterministic from date string
# =============================================================================

## Returns the secret sequence for a given date string "YYYY-MM-DD".
func get_sequence_for_date(date: String) -> Array[int]:
	var seed_val := _hash_date(date)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	var seq: Array[int] = []
	for _i in range(DAILY_SLOTS):
		seq.append(rng.randi_range(0, DAILY_COLORS - 1))
	return seq

## Returns today's sequence.
func get_today_sequence() -> Array[int]:
	return get_sequence_for_date(_today_str())

## Returns how many daily challenges have been issued since the epoch date.
## Used as the challenge number shown to the player (#42, etc.)
func get_today_number() -> int:
	var epoch := "2026-04-01"  # launch date
	var epoch_unix := Time.get_unix_time_from_datetime_string(epoch + "T00:00:00")
	var today_unix := Time.get_unix_time_from_datetime_string(_today_str() + "T00:00:00")
	var diff := int(today_unix - epoch_unix)
	return max(1, int(diff / 86400) + 1)

# =============================================================================
# Shareable result text (Wordle-style)
# =============================================================================

## Builds a shareable text grid from a completed daily game.
## guess_rows: Array of {values: Array[int], exact: int, misplaced: int}
## secret: Array[int]
func build_share_text(guess_rows: Array, secret: Array[int], did_win: bool, guesses_used: int) -> String:
	var number := get_today_number()
	var result := "NEURAL DOTS — Daily #%d\n" % number
	if did_win:
		result += "Solved in %d/%d\n" % [guesses_used, DAILY_MAX_GUESSES]
	else:
		result += "Failed ✗\n"
	result += "\n"

	for row_item in guess_rows:
		var row_values: Array = row_item["values"]
		var line := ""
		for i in range(row_values.size()):
			var placed_idx := int(row_values[i])
			if placed_idx == secret[i]:
				line += "🟢"   # exact
			elif secret.has(placed_idx):
				line += "🟡"   # misplaced
			else:
				line += "⬛"   # no match
		result += line + "\n"

	if did_win:
		result += "\n🔐 " + "Daily streak: %d 🔥" % SaveData.daily_streak
	result += "\n#NeuralDots"
	return result

# =============================================================================
# Helpers
# =============================================================================
func _today_str() -> String:
	return Time.get_date_string_from_system()

func _hash_date(date: String) -> int:
	# Deterministic non-cryptographic hash from date string
	var h := 5381
	for ch in date:
		h = ((h << 5) + h) + ch.unicode_at(0)
		h = h & 0x7FFFFFFF  # keep positive 31-bit
	return h
