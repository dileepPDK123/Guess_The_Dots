extends Node
## SoundManager — procedural SFX via AudioStreamGenerator
## Autoloaded. All sounds are generated at runtime — no audio assets needed.
##
## Public API:
##   SoundManager.play("tap")
##   SoundManager.play("dot_place")
##   SoundManager.play("submit")
##   SoundManager.play("exact")
##   SoundManager.play("misplace")
##   SoundManager.play("win")
##   SoundManager.play("lose")
##   SoundManager.play("level_up")
##   SoundManager.play("achievement")
##   SoundManager.play("coin")
##   SoundManager.play("hint")

var sfx_volume: float = 0.80   # 0.0 – 1.0
var sfx_enabled: bool = true

# One AudioStreamPlayer per channel so overlapping sounds don't cut each other off
var _players: Array[AudioStreamPlayer] = []
const CHANNEL_COUNT := 6
var _next_channel: int = 0

func _ready() -> void:
	for _i in range(CHANNEL_COUNT):
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_players.append(p)

# =============================================================================
# Public
# =============================================================================
func play(sound_id: String) -> void:
	if not sfx_enabled:
		return
	var stream := _build_stream(sound_id)
	if stream == null:
		return
	var player := _players[_next_channel % CHANNEL_COUNT]
	_next_channel += 1
	player.stream = stream
	player.volume_db = linear_to_db(sfx_volume)
	player.play()

# =============================================================================
# Stream builders — pure procedural waveforms
# =============================================================================
func _build_stream(sound_id: String) -> AudioStreamWAV:
	match sound_id:
		"tap":
			return _sine_tone(880.0, 0.06, 0.25)
		"dot_place":
			return _sine_tone(1200.0, 0.08, 0.15)
		"dot_clear":
			return _sine_tone(600.0, 0.06, 0.12)
		"submit":
			return _chord([440.0, 550.0], 0.12, 0.20)
		"exact":
			return _arpeggio([523.0, 659.0, 784.0], 0.08, 0.10)
		"misplace":
			return _sine_tone(370.0, 0.07, 0.15)
		"win":
			return _arpeggio([523.0, 659.0, 784.0, 1047.0], 0.18, 0.14)
		"lose":
			return _descend([440.0, 349.0, 262.0], 0.20, 0.18)
		"level_up":
			return _arpeggio([392.0, 523.0, 659.0, 784.0, 1047.0], 0.22, 0.12)
		"achievement":
			return _chord([523.0, 659.0], 0.18, 0.30)
		"coin":
			return _arpeggio([1047.0, 1319.0], 0.10, 0.06)
		"hint":
			return _arpeggio([440.0, 659.0, 880.0], 0.14, 0.10)
	return null

# =============================================================================
# Waveform generators — all return AudioStreamWAV (16-bit mono, 44100 Hz)
# =============================================================================
const SAMPLE_RATE := 44100

## Single sine tone with linear fade-out envelope.
func _sine_tone(freq: float, amplitude: float, duration: float) -> AudioStreamWAV:
	var frames := int(SAMPLE_RATE * duration)
	var data   := PackedByteArray()
	data.resize(frames * 2)  # 16-bit = 2 bytes per frame
	for i in range(frames):
		var t    := float(i) / SAMPLE_RATE
		var env  := 1.0 - (float(i) / float(frames))  # linear decay
		var sample := amplitude * env * sin(TAU * freq * t)
		var s16  := clampi(int(sample * 32767.0), -32768, 32767)
		data[i * 2]     = s16 & 0xFF
		data[i * 2 + 1] = (s16 >> 8) & 0xFF
	return _make_wav(data, frames)

## Two simultaneous sines (chord).
func _chord(freqs: Array, amplitude: float, duration: float) -> AudioStreamWAV:
	var frames := int(SAMPLE_RATE * duration)
	var data   := PackedByteArray()
	data.resize(frames * 2)
	var per_amp := amplitude / freqs.size()
	for i in range(frames):
		var t   := float(i) / SAMPLE_RATE
		var env := 1.0 - (float(i) / float(frames))
		var s   := 0.0
		for f in freqs:
			s += per_amp * env * sin(TAU * f * t)
		var s16 := clampi(int(s * 32767.0), -32768, 32767)
		data[i * 2]     = s16 & 0xFF
		data[i * 2 + 1] = (s16 >> 8) & 0xFF
	return _make_wav(data, frames)

## Sequential notes (arpeggio) — each note plays for `note_dur` seconds.
func _arpeggio(freqs: Array, amplitude: float, note_dur: float) -> AudioStreamWAV:
	var note_frames := int(SAMPLE_RATE * note_dur)
	var total_frames := note_frames * freqs.size()
	var data := PackedByteArray()
	data.resize(total_frames * 2)
	for ni in range(freqs.size()):
		var freq: float = freqs[ni]
		for fi in range(note_frames):
			var i   := ni * note_frames + fi
			var t   := float(fi) / SAMPLE_RATE
			var env := 1.0 - (float(fi) / float(note_frames))
			var s   := amplitude * env * sin(TAU * freq * t)
			var s16 := clampi(int(s * 32767.0), -32768, 32767)
			data[i * 2]     = s16 & 0xFF
			data[i * 2 + 1] = (s16 >> 8) & 0xFF
	return _make_wav(data, total_frames)

## Descending notes.
func _descend(freqs: Array, amplitude: float, note_dur: float) -> AudioStreamWAV:
	return _arpeggio(freqs, amplitude, note_dur)

func _make_wav(data: PackedByteArray, frame_count: int) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format     = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate   = SAMPLE_RATE
	wav.stereo     = false
	wav.loop_mode  = AudioStreamWAV.LOOP_DISABLED
	wav.data       = data
	return wav
