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
    MusicTrack(
      key: 'chapei',
      title: 'Khmer Chapei & Tro',
      subtitle: 'Plucked Lute & Bamboo Drone',
      assetPath: 'audio/chapei_tro.wav',
      icon: '🪕',
    ),
    MusicTrack(
      key: 'kong_vong',
      title: 'Kong Vong Gongs',
      subtitle: 'Harmonic Circular Tuned Gongs',
      assetPath: 'audio/kong_vong.wav',
      icon: '🔔',
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
      await _sfxPlayer.setPlayerMode(PlayerMode.lowLatency);
      await _sfxPlayer.setReleaseMode(ReleaseMode.stop);
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
      await _bgmPlayer.stop();
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer.setVolume(_bgmVolume);
      await _bgmPlayer.play(AssetSource(track.assetPath));
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

  void _playSfx(String assetPath, {double volumeMultiplier = 1.0}) {
    if (!_sfxEnabled) return;
    try {
      final vol = (_sfxVolume * volumeMultiplier).clamp(0.0, 1.0);
      _sfxPlayer.stop().then((_) {
        _sfxPlayer.setVolume(vol).then((_) {
          _sfxPlayer.play(AssetSource(assetPath));
        }).catchError((e) {
          debugPrint('SFX play error ($assetPath): $e');
        });
      }).catchError((e) {
        debugPrint('SFX stop error: $e');
      });
    } catch (e) {
      debugPrint('Error playing SFX ($assetPath): $e');
    }
  }

  /// Play wooden piece move clack
  void playMove() => _playSfx('audio/move.wav');

  /// Play subtle wooden piece selection tap
  void playSelect() => _playSfx('audio/select.wav', volumeMultiplier: 0.9);

  /// Play editor piece placement snap
  void playPlace() => _playSfx('audio/place.wav', volumeMultiplier: 0.95);

  /// Play resonant traditional gong for Rek (shoulder-pole) capture
  void playCapture() => _playSfx('audio/capture.wav', volumeMultiplier: 1.0);

  /// Play Khat (surrounding trap) locking chime and strike
  void playTrap() => _playSfx('audio/trap.wav', volumeMultiplier: 1.0);

  /// Play dull wooden double-knock for illegal move or blocked square
  void playInvalid() => _playSfx('audio/invalid.wav', volumeMultiplier: 0.85);

  /// Play airy whoosh for board rotation
  void playRotate() => _playSfx('audio/rotate.wav', volumeMultiplier: 0.9);

  /// Play swift whisk for erasing an individual piece
  void playErase() => _playSfx('audio/erase.wav', volumeMultiplier: 0.85);

  /// Play cascading chime flourish for Erase All / Reset Board
  void playClear() => _playSfx('audio/clear.wav', volumeMultiplier: 0.95);

  /// Play gentle notification chime when AI executes its move
  void playAiMove() => _playSfx('audio/ai_move.wav', volumeMultiplier: 0.85);

  /// Play glorious victory fanfare when player wins
  void playWin() => _playSfx('audio/win.wav', volumeMultiplier: 1.0);

  /// Play solemn traditional phrase when player is defeated
  void playDefeat() => _playSfx('audio/defeat.wav', volumeMultiplier: 1.0);

  /// Play subtle button click tap
  void playClick() => _playSfx('audio/click.wav', volumeMultiplier: 0.65);

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
