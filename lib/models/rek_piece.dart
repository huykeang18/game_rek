enum PlayerColor {
  teal,
  lime,
}

enum PieceType {
  plain,
  crowned, // King
}

class BoardPosition {
  final int row;
  final int col;

  const BoardPosition(this.row, this.col);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BoardPosition &&
          runtimeType == other.runtimeType &&
          row == other.row &&
          col == other.col;

  @override
  int get hashCode => row.hashCode ^ col.hashCode;

  String get notation {
    final colChar = String.fromCharCode('a'.codeUnitAt(0) + col);
    final rowNum = 8 - row;
    return '$colChar$rowNum';
  }

  @override
  String toString() => notation;
}

class RekPiece {
  final String id;
  final PlayerColor player;
  final PieceType type;

  const RekPiece({
    required this.id,
    required this.player,
    required this.type,
  });

  bool get isCrowned => type == PieceType.crowned;

  RekPiece copyWith({
    String? id,
    PlayerColor? player,
    PieceType? type,
  }) {
    return RekPiece(
      id: id ?? this.id,
      player: player ?? this.player,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'player': player.index,
        'type': type.index,
      };

  factory RekPiece.fromJson(Map<String, dynamic> json) => RekPiece(
        id: json['id'] as String,
        player: PlayerColor.values[json['player'] as int],
        type: PieceType.values[json['type'] as int],
      );
}
