import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../features/timer/domain/session_phase.dart';

/// Plays the completion chimes bundled in assets/audio.
class SoundService {
  final AudioPlayer _player = AudioPlayer(playerId: 'pomodoro_chime');

  Future<void> playFor(SessionPhase completed) async {
    final asset = completed == SessionPhase.focus
        ? 'audio/focus_complete.wav'
        : 'audio/break_complete.wav';
    try {
      // Restart rather than layer, in case two completions land close together.
      await _player.stop();
      await _player.play(AssetSource(asset));
    } catch (error) {
      // Audio is a nicety; a device with no working output must not break the
      // timer, and on web playback may be blocked until the first interaction.
      debugPrint('Chime failed: $error');
    }
  }

  Future<void> dispose() => _player.dispose();
}
