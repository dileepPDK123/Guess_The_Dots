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

# =============================================================================
func _ready() -> void:
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
# Interstitial — shown only on loss, using persisted loss counter
# =============================================================================
func on_game_lost() -> void:
	if SaveData.ads_removed:
		return
	SaveData.loss_count_since_ad += 1
	SaveData.save()
	if SaveData.loss_count_since_ad >= SaveData.next_ad_after_losses and SaveData.games_played > 3:
		_try_show_interstitial()
		SaveData.loss_count_since_ad = 0
		SaveData.next_ad_after_losses = randi_range(2, 4)
		SaveData.save()

func _try_show_interstitial() -> void:
	if _admob == null:
		return
	if _interstitial_loaded:
		_interstitial_loaded = false
		_admob.show_interstitial()
	else:
		push_warning("AdManager: Interstitial not ready, skipping.")

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
# Native Ad — stub; actual binding requires AdMob plugin on Android
# =============================================================================
var _native_ad_node: Control = null  # populated by AdMob plugin on Android

func show_native_ad(parent_container: Control) -> void:
	if SaveData.ads_removed:
		return
	if OS.get_name() != "Android":
		return
	# AdMob Native Ads: create via plugin when available
	# This is a stub — actual AdMob Native Ad integration requires plugin bindings
	if _native_ad_node != null and is_instance_valid(_native_ad_node):
		parent_container.add_child(_native_ad_node)

func hide_native_ad() -> void:
	if _native_ad_node != null and is_instance_valid(_native_ad_node):
		if _native_ad_node.get_parent() != null:
			_native_ad_node.get_parent().remove_child(_native_ad_node)

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
