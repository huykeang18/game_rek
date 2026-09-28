import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
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
  static const int _sfxPoolSize = 4;
  final List<AudioPlayer> _sfxPool = List.generate(
    _sfxPoolSize,
    (i) => AudioPlayer(playerId: 'sfx_player_$i'),
  );
  int _sfxPoolIndex = 0;

  static final Map<String, String> _localAssetPaths = {};
  int _bgmGeneration = 0;
  Process? _macBgmProcess;
  Process? _lastSfxProcess;

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

      if (!kIsWeb && Platform.isMacOS) {
        Process.run('/usr/bin/killall', ['afplay']).catchError((_) => ProcessResult(0, 0, '', ''));
      }

      if (!kIsWeb) {
        await _prepareAudioAssets();
      }

      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer.setVolume(_bgmEnabled ? _bgmVolume : 0.0);

      for (final p in _sfxPool) {
        await p.setReleaseMode(ReleaseMode.stop);
        await p.setVolume(_sfxVolume);
      }

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

  Future<void> _prepareAudioAssets() async {
    try {
      final tempDir = Directory('${Directory.systemTemp.path}/game_rek_audio');
      if (!tempDir.existsSync()) {
        tempDir.createSync(recursive: true);
      }
      for (final track in availableTracks) {
        await _extractLocalAsset(track.assetPath, tempDir);
      }
      const sfxList = [
        'audio/move.wav',
        'audio/select.wav',
        'audio/place.wav',
        'audio/capture.wav',
        'audio/trap.wav',
        'audio/invalid.wav',
        'audio/rotate.wav',
        'audio/erase.wav',
        'audio/clear.wav',
        'audio/ai_move.wav',
        'audio/win.wav',
        'audio/defeat.wav',
        'audio/click.wav',
      ];
      for (final sfx in sfxList) {
        await _extractLocalAsset(sfx, tempDir);
      }
    } catch (e) {
      debugPrint('Error preparing audio assets: $e');
    }
  }

  Future<void> _extractLocalAsset(String assetPath, Directory tempDir) async {
    final localFile = File('assets/$assetPath');
    if (localFile.existsSync() && localFile.lengthSync() > 0) {
      _localAssetPaths[assetPath] = localFile.absolute.path;
      return;
    }
    final fileName = assetPath.split('/').last;
    final targetFile = File('${tempDir.path}/$fileName');
    if (targetFile.existsSync() && targetFile.lengthSync() > 0) {
      _localAssetPaths[assetPath] = targetFile.path;
      return;
    }
    try {
      final data = await rootBundle.load('assets/$assetPath');
      await targetFile.writeAsBytes(data.buffer.asUint8List());
      _localAssetPaths[assetPath] = targetFile.path;
    } catch (e) {
      debugPrint('Failed to extract asset ($assetPath): $e');
    }
  }

  Future<void> _startBgm() async {
    _bgmGeneration++;
    final gen = _bgmGeneration;
    _macBgmProcess?.kill();
    _macBgmProcess = null;

    if (!_bgmEnabled) {
      _isPlayingBgm = false;
      notifyListeners();
      return;
    }

    final track = currentTrack;

    if (!kIsWeb && Platform.isMacOS) {
      final path = _localAssetPaths[track.assetPath] ?? 'assets/${track.assetPath}';
      if (File(path).existsSync()) {
        _isPlayingBgm = true;
        notifyListeners();
        _runMacBgmLoop(path, gen);
        return;
      }
    }

    try {
      await _bgmPlayer.stop();
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer.setVolume(_bgmVolume);
      final localPath = _localAssetPaths[track.assetPath];
      final Source source = (localPath != null && File(localPath).existsSync())
          ? DeviceFileSource(localPath)
          : AssetSource(track.assetPath);
      await _bgmPlayer.play(source);
      _isPlayingBgm = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to start BGM: $e');
      _isPlayingBgm = false;
    }
  }

  void _runMacBgmLoop(String path, int gen) async {
    while (_bgmGeneration == gen && _bgmEnabled && _isPlayingBgm) {
      try {
        final proc = await Process.start('/usr/bin/afplay', ['-v', _bgmVolume.toString(), path]);
        if (_bgmGeneration != gen) {
          proc.kill();
          break;
        }
        _macBgmProcess = proc;
        await proc.exitCode;
        if (_bgmGeneration != gen || !_bgmEnabled || !_isPlayingBgm) {
          break;
        }
        await Future.delayed(const Duration(milliseconds: 200));
      } catch (e) {
        debugPrint('Mac BGM loop error: $e');
        break;
      }
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
        await _startBgm();
      } else {
        await pauseBgm();
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

  /// Refresh active macOS BGM process with the newly set volume without breaking loop
  Future<void> refreshBgmVolume() async {
    if (!kIsWeb && Platform.isMacOS && _bgmEnabled && _isPlayingBgm) {
      await _startBgm();
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
      for (final p in _sfxPool) {
        await p.setVolume(clamped);
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_keySfxVolume, clamped);
    } catch (e) {
      debugPrint('Error setting SFX volume: $e');
    }
  }

  // --- Sound Effects Playback ---

  void _playSfx(String assetPath, {double volumeMultiplier = 1.0}) {
    if (!_sfxEnabled) return;
    final vol = (_sfxVolume * volumeMultiplier).clamp(0.0, 1.0);

    // On macOS, native afplay guarantees instant, zero-latency playback
    if (!kIsWeb && Platform.isMacOS) {
      final path = _localAssetPaths[assetPath] ?? 'assets/$assetPath';
      if (File(path).existsSync()) {
        _lastSfxProcess?.kill();
        Process.start('/usr/bin/afplay', ['-v', vol.toString(), path]).then((proc) {
          _lastSfxProcess = proc;
          proc.exitCode.then((_) {
            if (_lastSfxProcess == proc) {
              _lastSfxProcess = null;
            }
          });
        }).catchError((e) {
          debugPrint('afplay error ($assetPath): $e');
        });
        return;
      }
    }

    try {
      final player = _sfxPool[_sfxPoolIndex % _sfxPool.length];
      _sfxPoolIndex++;

      final localPath = _localAssetPaths[assetPath];
      final Source source = (localPath != null && File(localPath).existsSync())
          ? DeviceFileSource(localPath)
          : AssetSource(assetPath);

      player.setVolume(vol).then((_) {
        player.play(source).catchError((e) {
          debugPrint('SFX play error ($assetPath): $e');
        });
      }).catchError((_) {
        player.play(source).catchError((e) {
          debugPrint('SFX fallback play error ($assetPath): $e');
        });
      });
    } catch (e) {
      debugPrint('Error playing SFX ($assetPath): $e');
    }
  }

  /// Play game start flourish chime
  void playGameStart() => _playSfx('audio/clear.wav', volumeMultiplier: 0.95);

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
    _bgmGeneration++;
    _macBgmProcess?.kill();
    _macBgmProcess = null;
    _isPlayingBgm = false;
    notifyListeners();
    try {
      await _bgmPlayer.pause();
    } catch (e) {
      debugPrint('Error pausing BGM: $e');
    }
  }

  /// Resume BGM
  Future<void> resumeBgm() async {
    try {
      if (_bgmEnabled && !_isPlayingBgm) {
        await _startBgm();
      }
    } catch (e) {
      debugPrint('Error resuming BGM: $e');
    }
  }

  @override
  void dispose() {
    _bgmGeneration++;
    _macBgmProcess?.kill();
    _macBgmProcess = null;
    _lastSfxProcess?.kill();
    _lastSfxProcess = null;
    _bgmPlayer.dispose();
    for (final p in _sfxPool) {
      p.dispose();
    }
    super.dispose();
  }
}
