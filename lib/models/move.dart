import 'rek_piece.dart';

class RekMove {
  final BoardPosition from;
  final BoardPosition to;
  final RekPiece piece;
  final List<BoardPosition> rekCaptures;
  final List<BoardPosition> surroundCaptures;
  final bool capturedKing;

  const RekMove({
    required this.from,
    required this.to,
    required this.piece,
    this.rekCaptures = const [],
    this.surroundCaptures = const [],
    this.capturedKing = false,
  });

  int get totalCaptures => rekCaptures.length + surroundCaptures.length;
  bool get hasCapture => totalCaptures > 0;

  String get description {
    final capText = hasCapture
        ? ' (Captured $totalCaptures${capturedKing ? " incl. King!" : ""})'
        : '';
    return '${piece.player.name.toUpperCase()} ${piece.isCrowned ? "King" : "Man"}: ${from.notation} → ${to.notation}$capText';
  }
}
