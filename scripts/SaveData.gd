extends Node
## SaveData — persistent game data autoload for Guess the Dots
## Stores XP, levels, coins, stats, streaks, achievements, and cosmetic unlocks.
## Call SaveData.save() after any mutation. Data lives in user://save_data.cfg.

const SAVE_PATH := "user://save_data.cfg"
const CURRENT_VERSION := 1

# ── XP / Level ───────────────────────────────────────────────────────────────
var xp: int = 0
var level: int = 1

# XP required to reach each level (index = level number, value = cumulative XP needed)
# Levels 1-10: 200xp each, 11-20: 400xp each, 21-30: 700xp each,
# 31-40: 1000xp each, 41-50: 1500xp each
const XP_TABLE: Array[int] = [
	0,    200,  400,  600,  800,  1000, 1200, 1400, 1600, 1800,  # 1-10
	2200, 2600, 3000, 3400, 3800, 4200, 4600, 5000, 5400, 5800,  # 11-20
	6500, 7200, 7900, 8600, 9300,10000,10700,11400,12100,12800,  # 21-30
	13800,14800,15800,16800,17800,18800,19800,20800,21800,22800, # 31-40
	24300,25800,27300,28800,30300,31800,33300,34800,36300,37800, # 41-50
]
const MAX_LEVEL := 50

# ── Economy ──────────────────────────────────────────────────────────────────
var coins: int = 0
var hint_tokens: int = 0          # stored hints purchased with coins
var ads_removed: bool = false     # set true after Remove-Ads IAP
var daily_ad_coin_count: int = 0  # "Earn Coins" ad uses today (resets daily)
var daily_ad_coin_date: String = ""

# ── Game Stats ────────────────────────────────────────────────────────────────
var games_played: int = 0
var games_won: int = 0
var current_win_streak: int = 0
var max_win_streak: int = 0
## Guess distribution: index 0 = won in 1 guess, index 9 = won in 10 guesses
var guess_distribution: Array = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
var hints_used: int = 0
var ads_watched: int = 0
var perfect_wins: int = 0      # won in ≤ 3 guesses
var total_xp_earned: int = 0   # lifetime XP (even if level is capped)

# ── Daily Challenge ───────────────────────────────────────────────────────────
var daily_last_date: String = ""       # last completed daily challenge date "YYYY-MM-DD"
var daily_streak: int = 0
var daily_max_streak: int = 0
## date string → {won: bool, guesses_used: int, slots: int}
var daily_history: Dictionary = {}

# ── Login Streak ──────────────────────────────────────────────────────────────
var last_login_date: String = ""
var login_streak: int = 0
var login_max_streak: int = 0

# ── Cosmetic Unlocks ──────────────────────────────────────────────────────────
var unlocked_themes: Array = ["neon_core"]
var active_theme: String = "neon_core"
var unlocked_shapes: Array = ["circle"]
var active_shape: String = "circle"

# ── Achievements ──────────────────────────────────────────────────────────────
## achievement_id (String) → true once unlocked
var achievements: Dictionary = {}

# ── Settings (migrated from settings.cfg) ─────────────────────────────────────
var colorblind_enabled: bool = false
var sound_enabled: bool = true
var haptics_enabled_migrated: bool = true

# ── Easy mode ─────────────────────────────────────────────────────────────────
var easy_wins: int = 0

# ── Custom puzzles ─────────────────────────────────────────────────────────────
var custom_puzzles_played: int = 0

# ── Daily best time (ms) ──────────────────────────────────────────────────────
var daily_best_time_ms: int = 0

# ── Guess distribution per mode ───────────────────────────────────────────────
var guess_distribution_classic: Array = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
var guess_distribution_easy: Array    = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

# ── Campaign ──────────────────────────────────────────────────────────────────
## level_number (String) → {stars: int}
var campaign_progress: Dictionary = {}
var campaign_max_unlocked: int = 1   # highest level the player may start

# ── Ad system ─────────────────────────────────────────────────────────────────
var loss_count_since_ad: int = 0
var next_ad_after_losses: int = 3

# ── Consumable tokens ─────────────────────────────────────────────────────────
# hint_tokens already exists; add the rest:
var second_chance_tokens: int = 0
var extra_guess_tokens: int = 0
var streak_freezes: int = 0

# ── XP Boost ──────────────────────────────────────────────────────────────────
var xp_boost_end_time: int = 0   # Unix timestamp; 0 = inactive

# ── Season ────────────────────────────────────────────────────────────────────
var season_xp: int = 0
var season_number: int = 1
var season_claimed: Array[bool] = [false, false, false, false, false]
var season_badge: String = ""
var season_config_cache: Dictionary = {}

# ── Retention ─────────────────────────────────────────────────────────────────
var consecutive_losses: int = 0
var last_first_win_date: String = ""
var weekly_last_week: int = 0
var personal_bests: Dictionary = {}   # "MODE_NAME" -> {min_guesses, min_time_ms}
var current_combo: int = 0

# ── Resume ────────────────────────────────────────────────────────────────────
var resume_mode: int = -1
var resume_secret: Array = []
var resume_history: Array = []        # each entry: Dictionary — {values, exact, misplaced, per_dot}
var resume_campaign_level: int = 0

# ── Puzzle history ────────────────────────────────────────────────────────────
var puzzle_history: Array = []        # capped at 200

# ── Shop cosmetics ────────────────────────────────────────────────────────────
var active_sound_pack: String = "default"
var active_share_emoji: String = "default"
var active_board_skin: String = "default"
var unlocked_sound_packs: Array = []
var unlocked_share_emoji: Array = []
var unlocked_board_skins: Array = []

# ── Internal ──────────────────────────────────────────────────────────────────
var _cfg := ConfigFile.new()

# =============================================================================
func _ready() -> void:
	load_data()
	_check_login_streak()

# =============================================================================
# Load / Save
# =============================================================================
func load_data() -> void:
	if _cfg.load(SAVE_PATH) != OK:
		return  # first launch — defaults are already set above

	# Progression
	xp            = _cfg.get_value("progression", "xp", 0)
	level         = _cfg.get_value("progression", "level", 1)
	coins         = _cfg.get_value("progression", "coins", 0)
	hint_tokens   = _cfg.get_value("progression", "hint_tokens", 0)
	ads_removed   = _cfg.get_value("progression", "ads_removed", false)
	total_xp_earned = _cfg.get_value("progression", "total_xp_earned", 0)

	# Economy recharge
	daily_ad_coin_count = _cfg.get_value("progression", "daily_ad_coin_count", 0)
	daily_ad_coin_date  = _cfg.get_value("progression", "daily_ad_coin_date", "")

	# Stats
	games_played        = _cfg.get_value("stats", "games_played", 0)
	games_won           = _cfg.get_value("stats", "games_won", 0)
	current_win_streak  = _cfg.get_value("stats", "current_win_streak", 0)
	max_win_streak      = _cfg.get_value("stats", "max_win_streak", 0)
	guess_distribution  = _cfg.get_value("stats", "guess_distribution", [0,0,0,0,0,0,0,0,0,0])
	hints_used          = _cfg.get_value("stats", "hints_used", 0)
	ads_watched         = _cfg.get_value("stats", "ads_watched", 0)
	perfect_wins        = _cfg.get_value("stats", "perfect_wins", 0)

	# Daily
	daily_last_date  = _cfg.get_value("daily", "last_date", "")
	daily_streak     = _cfg.get_value("daily", "streak", 0)
	daily_max_streak = _cfg.get_value("daily", "max_streak", 0)
	daily_history    = _cfg.get_value("daily", "history", {})

	# Login
	last_login_date  = _cfg.get_value("login", "last_date", "")
	login_streak     = _cfg.get_value("login", "streak", 0)
	login_max_streak = _cfg.get_value("login", "max_streak", 0)

	# Unlocks
	unlocked_themes = _cfg.get_value("unlocks", "themes", ["neon_core"])
	active_theme    = _cfg.get_value("unlocks", "active_theme", "neon_core")
	unlocked_shapes = _cfg.get_value("unlocks", "shapes", ["circle"])
	active_shape    = _cfg.get_value("unlocks", "active_shape", "circle")

	# Achievements
	achievements = _cfg.get_value("achievements", "unlocked", {})

	# Campaign
	campaign_progress     = _cfg.get_value("campaign", "progress", {})
	campaign_max_unlocked = _cfg.get_value("campaign", "max_unlocked", 1)

	# Settings (migrated from settings.cfg)
	colorblind_enabled = _cfg.get_value("settings", "colorblind_enabled", false)
	sound_enabled      = _cfg.get_value("settings", "sound_enabled", true)

	# Easy mode / Custom
	easy_wins             = _cfg.get_value("stats", "easy_wins", 0)
	custom_puzzles_played = _cfg.get_value("stats", "custom_puzzles_played", 0)
	daily_best_time_ms    = _cfg.get_value("daily", "best_time_ms", 0)
	guess_distribution_classic = _cfg.get_value("stats", "guess_dist_classic", [0,0,0,0,0,0,0,0,0,0])
	guess_distribution_easy    = _cfg.get_value("stats", "guess_dist_easy",    [0,0,0,0,0,0,0,0,0,0])

	# Ad system
	loss_count_since_ad   = _cfg.get_value("progression", "loss_count_since_ad",   0)
	next_ad_after_losses  = _cfg.get_value("progression", "next_ad_after_losses",  3)

	# Tokens
	second_chance_tokens  = _cfg.get_value("tokens", "second_chance_tokens",  0)
	extra_guess_tokens    = _cfg.get_value("tokens", "extra_guess_tokens",     0)
	streak_freezes        = _cfg.get_value("tokens", "streak_freezes",         0)
	xp_boost_end_time     = _cfg.get_value("tokens", "xp_boost_end_time",      0)

	# Season
	season_xp             = _cfg.get_value("season", "season_xp",       0)
	season_number         = _cfg.get_value("season", "season_number",    1)
	season_claimed        = _cfg.get_value("season", "season_claimed",   [false,false,false,false,false])
	season_badge          = _cfg.get_value("season", "season_badge",     "")
	season_config_cache   = _cfg.get_value("season", "config_cache",     {})

	# Retention
	consecutive_losses    = _cfg.get_value("retention", "consecutive_losses",   0)
	last_first_win_date   = _cfg.get_value("retention", "last_first_win_date",  "")
	weekly_last_week      = _cfg.get_value("retention", "weekly_last_week",     0)
	personal_bests        = _cfg.get_value("retention", "personal_bests",       {})
	current_combo         = _cfg.get_value("retention", "current_combo",        0)

	# Resume
	resume_mode           = _cfg.get_value("resume", "mode",           -1)
	resume_secret         = _cfg.get_value("resume", "secret",          [])
	resume_history        = _cfg.get_value("resume", "history",         [])
	resume_campaign_level = _cfg.get_value("resume", "campaign_level",  0)

	# Puzzle history
	puzzle_history = _cfg.get_value("history", "puzzle_history", [])

	# Shop cosmetics
	active_sound_pack     = _cfg.get_value("shop", "active_sound_pack",  "default")
	active_share_emoji    = _cfg.get_value("shop", "active_share_emoji", "default")
	active_board_skin     = _cfg.get_value("shop", "active_board_skin",  "default")
	unlocked_sound_packs  = _cfg.get_value("shop", "unlocked_sound_packs",  [])
	unlocked_share_emoji  = _cfg.get_value("shop", "unlocked_share_emoji",  [])
	unlocked_board_skins  = _cfg.get_value("shop", "unlocked_board_skins",  [])

	# One-time migration: pull haptics from old settings.cfg if present
	if not _cfg.get_value("settings", "haptics_migrated", false):
		var old_cfg := ConfigFile.new()
		if old_cfg.load("user://settings.cfg") == OK:
			haptics_enabled_migrated = old_cfg.get_value("settings", "haptics", true)
			_cfg.set_value("settings", "haptics_migrated", true)
			_cfg.save(SAVE_PATH)

func save() -> void:
	# Progression
	_cfg.set_value("progression", "xp", xp)
	_cfg.set_value("progression", "level", level)
	_cfg.set_value("progression", "coins", coins)
	_cfg.set_value("progression", "hint_tokens", hint_tokens)
	_cfg.set_value("progression", "ads_removed", ads_removed)
	_cfg.set_value("progression", "total_xp_earned", total_xp_earned)
	_cfg.set_value("progression", "daily_ad_coin_count", daily_ad_coin_count)
	_cfg.set_value("progression", "daily_ad_coin_date", daily_ad_coin_date)

	# Stats
	_cfg.set_value("stats", "games_played", games_played)
	_cfg.set_value("stats", "games_won", games_won)
	_cfg.set_value("stats", "current_win_streak", current_win_streak)
	_cfg.set_value("stats", "max_win_streak", max_win_streak)
	_cfg.set_value("stats", "guess_distribution", guess_distribution)
	_cfg.set_value("stats", "hints_used", hints_used)
	_cfg.set_value("stats", "ads_watched", ads_watched)
	_cfg.set_value("stats", "perfect_wins", perfect_wins)

	# Daily
	_cfg.set_value("daily", "last_date", daily_last_date)
	_cfg.set_value("daily", "streak", daily_streak)
	_cfg.set_value("daily", "max_streak", daily_max_streak)
	_cfg.set_value("daily", "history", daily_history)

	# Login
	_cfg.set_value("login", "last_date", last_login_date)
	_cfg.set_value("login", "streak", login_streak)
	_cfg.set_value("login", "max_streak", login_max_streak)

	# Unlocks
	_cfg.set_value("unlocks", "themes", unlocked_themes)
	_cfg.set_value("unlocks", "active_theme", active_theme)
	_cfg.set_value("unlocks", "shapes", unlocked_shapes)
	_cfg.set_value("unlocks", "active_shape", active_shape)

	# Achievements
	_cfg.set_value("achievements", "unlocked", achievements)

	# Campaign
	_cfg.set_value("campaign", "progress",     campaign_progress)
	_cfg.set_value("campaign", "max_unlocked", campaign_max_unlocked)

	# Settings
	_cfg.set_value("settings", "colorblind_enabled", colorblind_enabled)
	_cfg.set_value("settings", "sound_enabled",      sound_enabled)
	_cfg.set_value("stats", "easy_wins",             easy_wins)
	_cfg.set_value("stats", "custom_puzzles_played", custom_puzzles_played)
	_cfg.set_value("daily", "best_time_ms",          daily_best_time_ms)
	_cfg.set_value("stats", "guess_dist_classic",    guess_distribution_classic)
	_cfg.set_value("stats", "guess_dist_easy",       guess_distribution_easy)

	# Ad system
	_cfg.set_value("progression", "loss_count_since_ad",  loss_count_since_ad)
	_cfg.set_value("progression", "next_ad_after_losses", next_ad_after_losses)

	# Tokens
	_cfg.set_value("tokens", "second_chance_tokens", second_chance_tokens)
	_cfg.set_value("tokens", "extra_guess_tokens",   extra_guess_tokens)
	_cfg.set_value("tokens", "streak_freezes",       streak_freezes)
	_cfg.set_value("tokens", "xp_boost_end_time",    xp_boost_end_time)

	# Season
	_cfg.set_value("season", "season_xp",      season_xp)
	_cfg.set_value("season", "season_number",  season_number)
	_cfg.set_value("season", "season_claimed", season_claimed)
	_cfg.set_value("season", "season_badge",   season_badge)
	_cfg.set_value("season", "config_cache",   season_config_cache)

	# Retention
	_cfg.set_value("retention", "consecutive_losses",  consecutive_losses)
	_cfg.set_value("retention", "last_first_win_date", last_first_win_date)
	_cfg.set_value("retention", "weekly_last_week",    weekly_last_week)
	_cfg.set_value("retention", "personal_bests",      personal_bests)
	_cfg.set_value("retention", "current_combo",       current_combo)

	# Resume
	_cfg.set_value("resume", "mode",           resume_mode)
	_cfg.set_value("resume", "secret",         resume_secret)
	_cfg.set_value("resume", "history",        resume_history)
	_cfg.set_value("resume", "campaign_level", resume_campaign_level)

	# Puzzle history
	_cfg.set_value("history", "puzzle_history", puzzle_history)

	# Shop cosmetics
	_cfg.set_value("shop", "active_sound_pack",     active_sound_pack)
	_cfg.set_value("shop", "active_share_emoji",    active_share_emoji)
	_cfg.set_value("shop", "active_board_skin",     active_board_skin)
	_cfg.set_value("shop", "unlocked_sound_packs",  unlocked_sound_packs)
	_cfg.set_value("shop", "unlocked_share_emoji",  unlocked_share_emoji)
	_cfg.set_value("shop", "unlocked_board_skins",  unlocked_board_skins)

	_cfg.save(SAVE_PATH)

# =============================================================================
# XP & Level helpers
# =============================================================================
## Add xp_amount and return how many levels were gained (0 or more).
func add_xp(xp_amount: int) -> int:
	if level >= MAX_LEVEL:
		total_xp_earned += xp_amount
		save()
		return 0
	xp += xp_amount
	total_xp_earned += xp_amount
	var levels_gained := 0
	while level < MAX_LEVEL and xp >= xp_for_level(level + 1):
		level += 1
		levels_gained += 1
		_on_level_up(level)
	save()
	return levels_gained

## XP required to reach `target_level` (cumulative from 0).
func xp_for_level(target_level: int) -> int:
	if target_level <= 1:
		return 0
	if target_level - 1 < XP_TABLE.size():
		return XP_TABLE[target_level - 1]
	return XP_TABLE[XP_TABLE.size() - 1]

## XP progress within the current level [0.0, 1.0].
func level_progress() -> float:
	if level >= MAX_LEVEL:
		return 1.0
	var start := xp_for_level(level)
	var end   := xp_for_level(level + 1)
	if end == start:
		return 1.0
	return clampf(float(xp - start) / float(end - start), 0.0, 1.0)

## XP needed to reach next level from current xp.
func xp_to_next_level() -> int:
	if level >= MAX_LEVEL:
		return 0
	return xp_for_level(level + 1) - xp

func _on_level_up(new_level: int) -> void:
	# Award 100 coins per level-up
	coins += 100
	# Unlock cosmetics at specific levels
	match new_level:
		5:  _unlock_theme("synthwave")
		10: _unlock_theme("matrix");    _unlock_shape("hexagon")
		15: _unlock_shape("diamond")
		20: _unlock_theme("solar_flare")
		25: _unlock_shape("star")
		30: _unlock_theme("void_protocol")
		50: _unlock_theme("golden_circuit")

# =============================================================================
# Economy helpers
# =============================================================================
func add_coins(amount: int) -> void:
	coins += amount
	save()

func spend_coins(amount: int) -> bool:
	if coins < amount:
		return false
	coins -= amount
	save()
	return true

## Returns how many "Earn Coins" rewarded ads are still available today.
func earn_coins_ads_remaining() -> int:
	var today := _today_str()
	if daily_ad_coin_date != today:
		daily_ad_coin_count = 0
		daily_ad_coin_date  = today
		save()
	return max(0, 5 - daily_ad_coin_count)

func record_earn_coins_ad() -> void:
	var today := _today_str()
	if daily_ad_coin_date != today:
		daily_ad_coin_count = 0
		daily_ad_coin_date  = today
	daily_ad_coin_count += 1
	ads_watched += 1
	coins += 50
	save()

# =============================================================================
# Game stats helpers
# =============================================================================
## Call after every completed game (win or lose).
func record_game(did_win: bool, guesses_used: int) -> void:
	games_played += 1
	if did_win:
		games_won += 1
		current_win_streak += 1
		if current_win_streak > max_win_streak:
			max_win_streak = current_win_streak
		# Guess distribution (cap index to 0-9)
		var idx := clampi(guesses_used - 1, 0, 9)
		guess_distribution[idx] += 1
		if guesses_used <= 3:
			perfect_wins += 1
	else:
		current_win_streak = 0
	save()

func win_rate() -> float:
	if games_played == 0:
		return 0.0
	return float(games_won) / float(games_played)

# =============================================================================
# Daily Challenge helpers
# =============================================================================
## Returns true if today's daily challenge is already completed.
func is_daily_done_today() -> bool:
	return daily_last_date == _today_str()

## Record the result of a daily challenge.
func record_daily(did_win: bool, guesses_used: int, slots: int) -> void:
	var today := _today_str()
	daily_history[today] = {"won": did_win, "guesses_used": guesses_used, "slots": slots}

	# Streak: +1 if previous entry was yesterday, else reset to 1
	var yesterday := _date_offset(-1)
	if daily_last_date == yesterday or daily_last_date == "":
		daily_streak += 1
	else:
		daily_streak = 1
	daily_last_date = today
	if daily_streak > daily_max_streak:
		daily_max_streak = daily_streak
	save()

# =============================================================================
# Login streak
# =============================================================================
signal login_streak_updated(streak: int, coins_awarded: int)

func _check_login_streak() -> void:
	var today := _today_str()
	if last_login_date == today:
		return  # already checked today
	var yesterday := _date_offset(-1)
	if last_login_date == yesterday:
		login_streak += 1
	elif last_login_date == "":
		login_streak = 1
	else:
		# Check if a streak freeze can absorb a single missed day
		var two_days_ago := _date_offset(-2)
		if last_login_date == two_days_ago and login_streak >= 2 and streak_freezes > 0:
			streak_freezes -= 1
			last_login_date = today
			save()
			if login_streak > login_max_streak:
				login_max_streak = login_streak
			login_streak_updated.emit(login_streak, 0)
			return
		login_streak = 1  # missed a day — reset
	if login_streak > login_max_streak:
		login_max_streak = login_streak
	last_login_date = today

	# Award coins based on streak day (cycle 1-7)
	var day_in_cycle := ((login_streak - 1) % 7) + 1
	var award := _login_reward_coins(day_in_cycle)
	coins += award
	save()
	login_streak_updated.emit(login_streak, award)

func _login_reward_coins(day_in_cycle: int) -> int:
	match day_in_cycle:
		1: return 20
		2: return 30
		3: return 50
		4: return 70
		5: return 100
		6: return 150
		7: return 250
	return 20

# =============================================================================
# Cosmetic unlock helpers
# =============================================================================
func _unlock_theme(theme_id: String) -> void:
	if not unlocked_themes.has(theme_id):
		unlocked_themes.append(theme_id)

func _unlock_shape(shape_id: String) -> void:
	if not unlocked_shapes.has(shape_id):
		unlocked_shapes.append(shape_id)

func has_theme(theme_id: String) -> bool:
	return unlocked_themes.has(theme_id)

func has_shape(shape_id: String) -> bool:
	return unlocked_shapes.has(shape_id)

# =============================================================================
# Achievement helpers
# =============================================================================
signal achievement_unlocked(achievement_id: String)

func unlock_achievement(achievement_id: String) -> bool:
	if achievements.get(achievement_id, false):
		return false  # already unlocked
	achievements[achievement_id] = true
	save()
	achievement_unlocked.emit(achievement_id)
	return true

func has_achievement(achievement_id: String) -> bool:
	return achievements.get(achievement_id, false)

# =============================================================================
# Campaign helpers
# =============================================================================
## Record the result of a campaign level. Keeps the best star rating.
## Unlocks the next level automatically when a level is beaten (stars > 0).
func record_campaign_level(level: int, stars: int) -> void:
	var key := str(level)
	var prev_stars: int = 0
	if campaign_progress.has(key):
		prev_stars = int(campaign_progress[key].get("stars", 0))
	if stars > prev_stars:
		campaign_progress[key] = {"stars": stars}
	if stars > 0 and level >= campaign_max_unlocked:
		campaign_max_unlocked = min(level + 1, 100)
	save()

# =============================================================================
# Date utilities
# =============================================================================
func _today_str() -> String:
	return Time.get_date_string_from_system()

func _date_offset(days: int) -> String:
	var unix := Time.get_unix_time_from_system() + days * 86400
	return Time.get_date_string_from_unix_time(int(unix))

# ── Puzzle history ──────────────────────────────────────────────────────────
func record_puzzle_history(mode_name: String, guesses: int, won: bool,
		secret: Array, slots: int, time_ms: int) -> void:
	puzzle_history.append({
		"date":   _today_str(),
		"mode":   mode_name,
		"guesses": guesses,
		"won":    won,
		"secret": secret,
		"slots":  slots,
		"time_ms": time_ms
	})
	if puzzle_history.size() > 200:
		puzzle_history.pop_front()
	save()
