import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages user profile state, including username and avatar,
/// persisted with SharedPreferences.
class UserService extends ChangeNotifier {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  static UserService get instance => _instance;

  UserService._internal();

  static const String _keyUsername = 'rek_username';
  static const String _keyAvatar = 'rek_avatar';
  static const String _keyPoints = 'rek_points';
  static const String _keyWins = 'rek_wins';
  static const String _defaultUsername = 'RekMaster';
  static const String _defaultAvatar = '👑';

  String _username = _defaultUsername;
  String _avatar = _defaultAvatar;
  int _points = 0;
  int _wins = 0;
  bool _initialized = false;

  String get username => _username;
  String get avatar => _avatar;
  int get points => _points;
  int get wins => _wins;
  bool get isInitialized => _initialized;

  /// Available avatar options for selection
  static const List<String> availableAvatars = [
    '👑', // Crown / King
    '🪷', // Sacred Lotus (Khmer national flower)
    '⚔️', // Crossed Swords / Warrior
    '🛡️', // Guard Shield
    '🐯', // Khmer Jungle Tiger
    '🐘', // Royal Elephant (Angkor)
    '🌟', // Shining Star
    '🎯', // Tactical Rek Target
  ];

  /// Initialize user preferences from storage
  Future<void> init() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _username = prefs.getString(_keyUsername) ?? _defaultUsername;
      _avatar = prefs.getString(_keyAvatar) ?? _defaultAvatar;
      _points = prefs.getInt(_keyPoints) ?? 0;
      _wins = prefs.getInt(_keyWins) ?? 0;
      _initialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing UserService: $e');
      _username = _defaultUsername;
      _avatar = _defaultAvatar;
      _points = 0;
      _wins = 0;
      _initialized = true;
    }
  }

  /// Update and persist the player's username
  Future<void> setUsername(String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty || trimmed == _username) return;
    _username = trimmed;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyUsername, _username);
    } catch (e) {
      debugPrint('Error saving username: $e');
    }
  }

  /// Update and persist the player's avatar
  Future<void> setAvatar(String newAvatar) async {
    if (newAvatar == _avatar) return;
    _avatar = newAvatar;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyAvatar, _avatar);
    } catch (e) {
      debugPrint('Error saving avatar: $e');
    }
  }

  /// Update both username and avatar at once
  Future<void> updateProfile({required String newName, required String newAvatar}) async {
    final trimmed = newName.trim();
    bool changed = false;
    if (trimmed.isNotEmpty && trimmed != _username) {
      _username = trimmed;
      changed = true;
    }
    if (newAvatar.isNotEmpty && newAvatar != _avatar) {
      _avatar = newAvatar;
      changed = true;
    }

    if (changed) {
      notifyListeners();
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyUsername, _username);
        await prefs.setString(_keyAvatar, _avatar);
      } catch (e) {
        debugPrint('Error saving profile: $e');
      }
    }
  }

  /// Award points and increment win count when the player wins a match
  Future<void> addWinPoints(int earnedPoints) async {
    if (earnedPoints <= 0) return;
    _points += earnedPoints;
    _wins += 1;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyPoints, _points);
      await prefs.setInt(_keyWins, _wins);
    } catch (e) {
      debugPrint('Error saving points: $e');
    }
  }

  /// Reset points and wins (useful for testing or profile reset)
  Future<void> resetPoints() async {
    _points = 0;
    _wins = 0;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyPoints, 0);
      await prefs.setInt(_keyWins, 0);
    } catch (e) {
      debugPrint('Error resetting points: $e');
    }
  }
}
