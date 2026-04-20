extends Node

# =============================================================================
# AdManager — Google AdMob integration for Guess the Dots
#
# PLACEHOLDER IDs BELOW are Google's official test IDs.
# They work on any device during development.
#
# Replace each "TEST_*" constant with your real AdMob IDs once you have them:
#   App ID      → Project Settings → Export → Android → AdMob App ID field
#   Banner      → BANNER_UNIT_ID
#   Interstitial→ INTERSTITIAL_UNIT_ID
#   Rewarded    → REWARDED_UNIT_ID
# =============================================================================

# ── Placeholder / test IDs ───────────────────────────────────────────────────
const APP_ID              := "ca-app-pub-5115870903207025~6216914432"
const BANNER_UNIT_ID      := "ca-app-pub-5115870903207025/1646910779"
const INTERSTITIAL_UNIT_ID := "ca-app-pub-5115870903207025/8867128502"
const REWARDED_UNIT_ID    := "ca-app-pub-5115870903207025/6025342743"

# ── Signals ──────────────────────────────────────────────────────────────────
signal rewarded_earned   # emitted after user fully watches a rewarded ad
signal interstitial_closed

# ── Internal state ────────────────────────────────────────────────────────────
var _admob: Object = null          # AdMob singleton (null on desktop/non-Android)
var _interstitial_loaded := false
var _rewarded_loaded     := false
var _banner_visible      := false

var _rng                 := RandomNumberGenerator.new()
var _games_played        := 0      # games finished since last interstitial
var _next_ad_after       := 2      # show interstitial after this many games (2-4, randomised)

# =============================================================================
func _ready() -> void:
	_rng.randomize()
	_next_ad_after = _rng.randi_range(2, 4)

	if not Engine.has_singleton("AdMob"):
		push_warning("AdManager: AdMob singleton not found. Ads disabled (normal on desktop).")
		return

	_admob = Engine.get_singleton("AdMob")

	# Connect AdMob callbacks
	_admob.connect("on_interstitial_ad_loaded",          _on_interstitial_loaded)
	_admob.connect("on_interstitial_ad_failed_to_load",  _on_interstitial_failed)
	_admob.connect("on_interstitial_ad_closed",          _on_interstitial_closed)
	_admob.connect("on_rewarded_ad_loaded",              _on_rewarded_loaded)
	_admob.connect("on_rewarded_ad_failed_to_load",      _on_rewarded_failed)
	_admob.connect("on_rewarded_ad_user_earned_reward",  _on_rewarded_earned)

	# Preload all ad types at startup
	_load_interstitial()
	_load_rewarded()

# =============================================================================
# Banner
# =============================================================================
func show_banner() -> void:
	if _admob == null:
		return
	if not _banner_visible:
		_admob.load_banner(BANNER_UNIT_ID, true, 0)  # 0 = BOTTOM position
		_banner_visible = true

func hide_banner() -> void:
	if _admob == null or not _banner_visible:
		return
	_admob.hide_banner()
	_banner_visible = false

# =============================================================================
# Interstitial — call on_game_finished() after every round
# =============================================================================
func on_game_finished() -> void:
	# Grace period: no interstitials for the first 3 games ever — prevents early churn
	if SaveData.games_played <= 3:
		return
	_games_played += 1
	print("AdManager: games since last ad = %d / %d" % [_games_played, _next_ad_after])
	if _games_played >= _next_ad_after:
		_try_show_interstitial()

func _try_show_interstitial() -> void:
	if _admob == null:
		# On desktop just simulate the reset so logic still works
		_reset_interstitial_counter()
		return
	if _interstitial_loaded:
		_interstitial_loaded = false
		_admob.show_interstitial()
	else:
		# Ad wasn't ready — skip this time, try next game
		push_warning("AdManager: Interstitial not ready, skipping.")
		_reset_interstitial_counter()

func _reset_interstitial_counter() -> void:
	_games_played  = 0
	_next_ad_after = _rng.randi_range(2, 4)
	print("AdManager: Next interstitial after %d games." % _next_ad_after)

func _load_interstitial() -> void:
	if _admob:
		_admob.load_interstitial(INTERSTITIAL_UNIT_ID)

# =============================================================================
# Rewarded — call show_rewarded(), listen for rewarded_earned signal
# =============================================================================
func show_rewarded() -> bool:
	# Returns true if ad was shown, false if not ready
	if _admob == null:
		# Desktop fallback: simulate reward immediately (useful for testing game logic)
		rewarded_earned.emit()
		return true
	if _rewarded_loaded:
		_rewarded_loaded = false
		_admob.show_rewarded()
		return true
	push_warning("AdManager: Rewarded ad not ready yet.")
	return false

func is_rewarded_ready() -> bool:
	return _admob == null or _rewarded_loaded  # on desktop always "ready"

func _load_rewarded() -> void:
	if _admob:
		_admob.load_rewarded(REWARDED_UNIT_ID)

# =============================================================================
# AdMob callbacks
# =============================================================================
func _on_interstitial_loaded() -> void:
	_interstitial_loaded = true
	print("AdManager: Interstitial loaded.")

func _on_interstitial_failed(error_code: int) -> void:
	push_warning("AdManager: Interstitial failed to load (code %d). Retrying in 30s." % error_code)
	await get_tree().create_timer(30.0).timeout
	_load_interstitial()

func _on_interstitial_closed() -> void:
	_reset_interstitial_counter()
	interstitial_closed.emit()
	_load_interstitial()  # preload next one immediately

func _on_rewarded_loaded() -> void:
	_rewarded_loaded = true
	print("AdManager: Rewarded ad loaded.")

func _on_rewarded_failed(error_code: int) -> void:
	push_warning("AdManager: Rewarded ad failed to load (code %d). Retrying in 30s." % error_code)
	await get_tree().create_timer(30.0).timeout
	_load_rewarded()

func _on_rewarded_earned(_currency: String, _amount: int) -> void:
	rewarded_earned.emit()
	_load_rewarded()  # preload next one
