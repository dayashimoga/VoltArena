class_name StrikeAudioDirector
extends Node

## Dynamic music and audio state director for Strike Vector.
## Manages exploration, alert, combat escalation, boss themes, and victory fanfares.

enum AudioState {
	EXPLORATION,
	ALERT,
	COMBAT,
	INTENSE,
	BOSS,
	VICTORY
}

var current_state: AudioState = AudioState.EXPLORATION

func set_audio_state(state: AudioState) -> void:
	if current_state == state:
		return
	current_state = state

	var am = GameConstants.get_autoload(self, "AudioManager")
	if not am or not am.has_method("play_music"):
		return

	match state:
		AudioState.EXPLORATION:
			am.play_music("iron_crucible")
		AudioState.COMBAT, AudioState.INTENSE:
			am.play_music("metro_siege")
		AudioState.BOSS:
			am.play_music("drift_storm")
		AudioState.VICTORY:
			if am.has_method("play_sound"):
				am.play_sound("goal", 1.0)
