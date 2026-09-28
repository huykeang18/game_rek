import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/rek_piece.dart';
import 'rek_rules.dart';

class SavedGameState {
  final String id;
  final String name;
  final DateTime timestamp;
  final List<List<RekPiece?>> board;
  final PlayerColor currentTurn;
  final bool isPlayMode;

  SavedGameState({
    required this.id,
    required this.name,
    required this.timestamp,
    required this.board,
    required this.currentTurn,
    required this.isPlayMode,
  });

  Map<String, dynamic> toJson() {
    final boardJson = List.generate(
      RekRules.boardSize,
      (r) => List.generate(
        RekRules.boardSize,
        (c) => board[r][c]?.toJson(),
      ),
    );

    return {
      'id': id,
      'name': name,
      'timestamp': timestamp.toIso8601String(),
      'currentTurn': currentTurn.index,
      'isPlayMode': isPlayMode,
      'board': boardJson,
    };
  }

  factory SavedGameState.fromJson(Map<String, dynamic> json) {
    final boardList = json['board'] as List<dynamic>;
    final board = List.generate(
      RekRules.boardSize,
      (r) => List.generate(
        RekRules.boardSize,
        (c) {
          final cell = boardList[r][c];
          if (cell == null) return null;
          return RekPiece.fromJson(cell as Map<String, dynamic>);
        },
      ),
    );

    return SavedGameState(
      id: json['id'] as String,
      name: json['name'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      board: board,
      currentTurn: PlayerColor.values[json['currentTurn'] as int],
      isPlayMode: json['isPlayMode'] as bool? ?? false,
    );
  }
}

class StorageService {
  static const String _keySavedGames = 'rek_saved_games';
  static const String _keyQuickSave = 'rek_quick_save';

  static Future<void> quickSave(SavedGameState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyQuickSave, jsonEncode(state.toJson()));
  }

  static Future<SavedGameState?> quickLoad() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyQuickSave);
    if (jsonStr == null) return null;
    try {
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      return SavedGameState.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  static Future<List<SavedGameState>> getAllSavedGames() async {
    final prefs = await SharedPreferences.getInstance();
    final listStr = prefs.getStringList(_keySavedGames) ?? [];
    final results = <SavedGameState>[];
    for (final str in listStr) {
      try {
        final decoded = jsonDecode(str) as Map<String, dynamic>;
        results.add(SavedGameState.fromJson(decoded));
      } catch (_) {}
    }
    return results;
  }

  static Future<void> saveGame(SavedGameState state) async {
    final prefs = await SharedPreferences.getInstance();
    final games = await getAllSavedGames();
    // remove existing if same id
    games.removeWhere((g) => g.id == state.id);
    games.insert(0, state);

    final listStr = games.map((g) => jsonEncode(g.toJson())).toList();
    await prefs.setStringList(_keySavedGames, listStr);
  }

  static Future<void> deleteSave(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final games = await getAllSavedGames();
    games.removeWhere((g) => g.id == id);
    final listStr = games.map((g) => jsonEncode(g.toJson())).toList();
    await prefs.setStringList(_keySavedGames, listStr);
  }
}
