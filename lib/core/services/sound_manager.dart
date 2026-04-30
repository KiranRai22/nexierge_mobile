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
/// Handles audio playback with preloading for low latency.
class SoundManager {
  SoundManager._();

  static final SoundManager instance = SoundManager._();

  final AudioPlayer _player = AudioPlayer();
  bool _isInitialized = false;
  bool _isEnabled = true;

  /// Audio file paths for each sound category
  /// Note: AssetSource automatically adds 'assets/' prefix, so paths are relative to assets folder
  final Map<SoundCategory, String> _soundPaths = {
    SoundCategory.button: 'media/button1.mp3',
    SoundCategory.back: 'media/button2.mp3',
    SoundCategory.navigation: 'media/button3.mp3',
    SoundCategory.card: 'media/button4.mp3',
    SoundCategory.preference: 'media/button5.mp3',
  };

  /// Initialize the sound manager
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Set player mode for low latency
      await _player.setReleaseMode(ReleaseMode.release);

      _isInitialized = true;
      debugPrint('SoundManager: Initialization complete');
    } catch (e) {
      // Log error but don't crash - sounds are optional
      debugPrint('SoundManager initialization error: $e');
    }
  }

  /// Enable or disable sound playback
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  /// Check if sounds are enabled
  bool get isEnabled => _isEnabled;

  /// Play a sound for the given category
  /// Returns immediately for low latency, sound plays asynchronously
  Future<void> play(SoundCategory category) async {
    debugPrint(
      'SoundManager: play called for $category, enabled: $_isEnabled, initialized: $_isInitialized',
    );

    if (!_isEnabled) {
      debugPrint('SoundManager: Sounds are disabled, skipping playback');
      return;
    }

    if (!_isInitialized) {
      debugPrint('SoundManager: Not initialized, initializing now');
      // Try to initialize on first play if not already done
      await initialize();
    }

    final path = _soundPaths[category];
    if (path == null) {
      debugPrint('SoundManager: No sound path found for $category');
      return;
    }

    try {
      debugPrint('SoundManager: Playing $path');
      // Stop any currently playing sound to prevent overlap
      await _player.stop();

      // Play the sound
      await _player.play(AssetSource(path));
      debugPrint('SoundManager: Playback started');
    } catch (e) {
      debugPrint('SoundManager play error for $category: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _player.dispose();
    _isInitialized = false;
  }
}
