import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MusicTrack {
  final String key;
  final String title;
  final String subtitle;
  final String assetPath;
  final String icon;

  const MusicTrack({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.assetPath,
    required this.icon,
  });
}

/// Service managing background music (BGM) and sound effects (SFX),
/// with persistence via SharedPreferences.
class AudioService extends ChangeNotifier {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  static AudioService get instance => _instance;

  AudioService._internal();

  static const String _keyBgmEnabled = 'rek_bgm_enabled';
  static const String _keyBgmVolume = 'rek_bgm_volume';
  static const String _keyCurrentTrack = 'rek_current_track';
  static const String _keySfxEnabled = 'rek_sfx_enabled';
  static const String _keySfxVolume = 'rek_sfx_volume';

  static const List<MusicTrack> availableTracks = [
    MusicTrack(
      key: 'roneat',
      title: 'Roneat Melody',
      subtitle: 'Traditional Cambodian Xylophone',
      assetPath: 'audio/roneat_melody.wav',
      icon: '🎵',
    ),
    MusicTrack(
      key: 'angkor',
      title: 'Angkor Ambient',
      subtitle: 'Zen Singing Bowl & Bells',
      assetPath: 'audio/angkor_ambient.wav',
      icon: '🪷',
    ),
    MusicTrack(
      key: 'bamboo',
      title: 'Peaceful Bamboo',
      subtitle: 'Relaxing Meditation Chimes',
      assetPath: 'audio/peaceful_bamboo.wav',
      icon: '🎋',
    ),
  ];

  final AudioPlayer _bgmPlayer = AudioPlayer(playerId: 'bgm_player');
  final AudioPlayer _sfxPlayer = AudioPlayer(playerId: 'sfx_player');

  bool _bgmEnabled = true;
  double _bgmVolume = 0.6;
  String _currentTrackKey = 'roneat';
  bool _sfxEnabled = true;
  double _sfxVolume = 0.8;
  bool _initialized = false;
  bool _isPlayingBgm = false;

  bool get bgmEnabled => _bgmEnabled;
  double get bgmVolume => _bgmVolume;
  String get currentTrackKey => _currentTrackKey;
  bool get sfxEnabled => _sfxEnabled;
  double get sfxVolume => _sfxVolume;
  bool get isPlayingBgm => _isPlayingBgm;
  bool get isInitialized => _initialized;

  MusicTrack get currentTrack {
    return availableTracks.firstWhere(
      (t) => t.key == _currentTrackKey,
      orElse: () => availableTracks.first,
    );
  }

  /// Initialize audio system, load saved preferences, and start BGM if enabled
  Future<void> init() async {
    if (_initialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      _bgmEnabled = prefs.getBool(_keyBgmEnabled) ?? true;
      _bgmVolume = prefs.getDouble(_keyBgmVolume) ?? 0.6;
      _currentTrackKey = prefs.getString(_keyCurrentTrack) ?? 'roneat';
      _sfxEnabled = prefs.getBool(_keySfxEnabled) ?? true;
      _sfxVolume = prefs.getDouble(_keySfxVolume) ?? 0.8;

      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer.setVolume(_bgmEnabled ? _bgmVolume : 0.0);
      await _sfxPlayer.setVolume(_sfxVolume);

      _initialized = true;
      notifyListeners();

      if (_bgmEnabled) {
        await _startBgm();
      }
    } catch (e) {
      debugPrint('AudioService init error (graceful fallback): $e');
      _initialized = true;
    }
  }

  Future<void> _startBgm() async {
    try {
      final track = currentTrack;
      await _bgmPlayer.setSource(AssetSource(track.assetPath));
      await _bgmPlayer.setVolume(_bgmVolume);
      await _bgmPlayer.resume();
      _isPlayingBgm = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to start BGM: $e');
      _isPlayingBgm = false;
    }
  }

  /// Toggle background music ON or OFF
  Future<void> setBgmEnabled(bool enabled) async {
    if (_bgmEnabled == enabled) return;
    _bgmEnabled = enabled;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyBgmEnabled, enabled);

      if (enabled) {
        await _bgmPlayer.setVolume(_bgmVolume);
        await _startBgm();
      } else {
        await _bgmPlayer.pause();
        _isPlayingBgm = false;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error toggling BGM: $e');
    }
  }

  /// Set BGM volume (0.0 to 1.0)
  Future<void> setBgmVolume(double volume) async {
    final clamped = volume.clamp(0.0, 1.0);
    _bgmVolume = clamped;
    notifyListeners();

    try {
      if (_bgmEnabled) {
        await _bgmPlayer.setVolume(_bgmVolume);
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_keyBgmVolume, clamped);
    } catch (e) {
      debugPrint('Error setting BGM volume: $e');
    }
  }

  /// Switch the active background music track
  Future<void> setTrack(String trackKey) async {
    if (_currentTrackKey == trackKey) return;
    _currentTrackKey = trackKey;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyCurrentTrack, trackKey);

      if (_bgmEnabled) {
        await _startBgm();
      }
    } catch (e) {
      debugPrint('Error switching music track: $e');
    }
  }

  /// Toggle Sound Effects ON or OFF
  Future<void> setSfxEnabled(bool enabled) async {
    if (_sfxEnabled == enabled) return;
    _sfxEnabled = enabled;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keySfxEnabled, enabled);
    } catch (e) {
      debugPrint('Error toggling SFX: $e');
    }
  }

  /// Set SFX volume (0.0 to 1.0)
  Future<void> setSfxVolume(double volume) async {
    final clamped = volume.clamp(0.0, 1.0);
    _sfxVolume = clamped;
    notifyListeners();

    try {
      await _sfxPlayer.setVolume(clamped);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_keySfxVolume, clamped);
    } catch (e) {
      debugPrint('Error setting SFX volume: $e');
    }
  }

  // --- Sound Effects Playback ---

  /// Play wooden piece placement sound
  Future<void> playMove() async {
    if (!_sfxEnabled) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.setVolume(_sfxVolume);
      await _sfxPlayer.play(AssetSource('audio/move.wav'));
    } catch (e) {
      debugPrint('Error playing move SFX: $e');
    }
  }

  /// Play capture gong / strike sound
  Future<void> playCapture() async {
    if (!_sfxEnabled) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.setVolume(_sfxVolume);
      await _sfxPlayer.play(AssetSource('audio/capture.wav'));
    } catch (e) {
      debugPrint('Error playing capture SFX: $e');
    }
  }

  /// Play victory fanfare
  Future<void> playWin() async {
    if (!_sfxEnabled) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.setVolume(_sfxVolume);
      await _sfxPlayer.play(AssetSource('audio/win.wav'));
    } catch (e) {
      debugPrint('Error playing win SFX: $e');
    }
  }

  /// Play button tap click
  Future<void> playClick() async {
    if (!_sfxEnabled) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.setVolume(_sfxVolume * 0.7);
      await _sfxPlayer.play(AssetSource('audio/click.wav'));
    } catch (e) {
      debugPrint('Error playing click SFX: $e');
    }
  }

  /// Pause BGM temporarily (e.g. app lifecycle background)
  Future<void> pauseBgm() async {
    try {
      if (_isPlayingBgm) {
        await _bgmPlayer.pause();
        _isPlayingBgm = false;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error pausing BGM: $e');
    }
  }

  /// Resume BGM
  Future<void> resumeBgm() async {
    try {
      if (_bgmEnabled && !_isPlayingBgm) {
        await _bgmPlayer.resume();
        _isPlayingBgm = true;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error resuming BGM: $e');
    }
  }

  @override
  void dispose() {
    _bgmPlayer.dispose();
    _sfxPlayer.dispose();
    super.dispose();
  }
}
