import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Sound categories for UI interactions
enum SoundCategory {
  /// General button clicks
  button,

  /// Back and close actions
  back,

  /// Bottom navigation bar clicks
  navigation,

  /// Card clicks
  card,

  /// Preferences item selections (theme, language, etc.)
  preference,
}

/// Centralized sound manager for UI interactions.
///
/// One [AudioPlayer] per [SoundCategory] preloaded at init in
/// [PlayerMode.lowLatency] (SoundPool on Android). Replays via [AudioPlayer.resume]
/// so we never re-issue `setSource` or `stop` on the hot path — this avoids the
/// `MediaPlayer` state-machine races that surface as `MEDIA_ERROR_UNKNOWN {what:1}`.
class SoundManager {
  SoundManager._();

  static final SoundManager instance = SoundManager._();

  /// Audio file paths for each sound category. Paths are relative to the
  /// `assets/` folder; [AssetSource] adds the prefix internally.
  static const Map<SoundCategory, String> _soundPaths = {
    SoundCategory.button: 'media/button1.mp3',
    SoundCategory.back: 'media/button2.mp3',
    SoundCategory.navigation: 'media/button3.mp3',
    SoundCategory.card: 'media/button4.mp3',
    SoundCategory.preference: 'media/button5.mp3',
  };

  final Map<SoundCategory, AudioPlayer> _players = {};
  bool _isInitialized = false;
  bool _isEnabled = true;

  /// Preload every sound into its own low-latency player. Idempotent.
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    for (final entry in _soundPaths.entries) {
      try {
        final player = AudioPlayer()
          ..setReleaseMode(ReleaseMode.stop);
        await player.setPlayerMode(PlayerMode.lowLatency);
        await player.setSource(AssetSource(entry.value));
        _players[entry.key] = player;
      } catch (e) {
        debugPrint('SoundManager: failed to preload ${entry.key} (${entry.value}): $e');
      }
    }
    debugPrint('SoundManager: initialized ${_players.length}/${_soundPaths.length} sounds');
  }

  void setEnabled(bool enabled) => _isEnabled = enabled;

  bool get isEnabled => _isEnabled;

  /// Play the sound for [category]. Fire-and-forget; never throws.
  Future<void> play(SoundCategory category) async {
    if (!_isEnabled) return;
    if (!_isInitialized) await initialize();

    final player = _players[category];
    if (player == null) return;

    try {
      await player.resume();
    } catch (e) {
      debugPrint('SoundManager: play error for $category: $e');
    }
  }

  Future<void> dispose() async {
    for (final player in _players.values) {
      await player.dispose();
    }
    _players.clear();
    _isInitialized = false;
  }
}
