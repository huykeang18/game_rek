import '../models/rek_piece.dart';
import '../models/move.dart';

class RekRules {
  static const int boardSize = 8;

  /// Creates the standard initial Cambodian Rek board setup as specified:
  /// Teal (Top):
  /// - Row 0: 7 plain pieces (cols 0..6, col 7 empty)
  /// - Row 1: 1 crowned piece at far right (col 7)
  /// - Row 2: 8 plain pieces (cols 0..7)
  /// Lime Green (Bottom):
  /// - Row 5: 8 plain pieces (cols 0..7)
  /// - Row 6: 1 crowned piece at far left (col 0)
  /// - Row 7: 7 plain pieces (cols 1..7, col 0 empty)
  static List<List<RekPiece?>> createInitialBoard() {
    final board = List.generate(
      boardSize,
      (_) => List<RekPiece?>.filled(boardSize, null),
    );

    int idCounter = 1;

    // Teal (Top)
    for (int col = 0; col < 7; col++) {
      board[0][col] = RekPiece(
        id: 'teal_${idCounter++}',
        player: PlayerColor.teal,
        type: PieceType.plain,
      );
    }
    board[1][7] = RekPiece(
      id: 'teal_king',
      player: PlayerColor.teal,
      type: PieceType.crowned,
    );
    for (int col = 0; col < 8; col++) {
      board[2][col] = RekPiece(
        id: 'teal_${idCounter++}',
        player: PlayerColor.teal,
        type: PieceType.plain,
      );
    }

    // Lime Green (Bottom)
    for (int col = 0; col < 8; col++) {
      board[5][col] = RekPiece(
        id: 'lime_${idCounter++}',
        player: PlayerColor.lime,
        type: PieceType.plain,
      );
    }
    board[6][0] = RekPiece(
      id: 'lime_king',
      player: PlayerColor.lime,
      type: PieceType.crowned,
    );
    for (int col = 1; col < 8; col++) {
      board[7][col] = RekPiece(
        id: 'lime_${idCounter++}',
        player: PlayerColor.lime,
        type: PieceType.plain,
      );
    }

    return board;
  }

  /// Clones a 2D board
  static List<List<RekPiece?>> cloneBoard(List<List<RekPiece?>> board) {
    return List.generate(
      boardSize,
      (r) => List.generate(boardSize, (c) => board[r][c]),
    );
  }

  /// Gets all legal destination positions for a piece at [pos]
  /// Pieces move orthogonally like a Chess Rook (any unobstructed distance)
  static List<BoardPosition> getLegalMoves(
    List<List<RekPiece?>> board,
    BoardPosition pos,
  ) {
    final piece = board[pos.row][pos.col];
    if (piece == null) return [];

    final moves = <BoardPosition>[];
    const directions = [
      [-1, 0], // Up
      [1, 0],  // Down
      [0, -1], // Left
      [0, 1],  // Right
    ];

    for (final dir in directions) {
      int r = pos.row + dir[0];
      int c = pos.col + dir[1];

      while (r >= 0 && r < boardSize && c >= 0 && c < boardSize) {
        if (board[r][c] == null) {
          moves.add(BoardPosition(r, c));
        } else {
          // Blocked by another piece
          break;
        }
        r += dir[0];
        c += dir[1];
      }
    }

    return moves;
  }

  /// Evaluates captures for a move from [from] to [to]
  /// 1. "Rek" Capture: Sandwiched between two enemy pieces
  /// 2. Surround Capture: Enemy pieces with no legal orthogonal moves
  static RekMove simulateMove(
    List<List<RekPiece?>> board,
    BoardPosition from,
    BoardPosition to,
  ) {
    final movingPiece = board[from.row][from.col];
    if (movingPiece == null) {
      throw ArgumentError('No piece at from position $from');
    }

    final enemyPlayer = movingPiece.player == PlayerColor.teal
        ? PlayerColor.lime
        : PlayerColor.teal;

    // Temporary copy of board
    final tempBoard = cloneBoard(board);
    tempBoard[from.row][from.col] = null;
    tempBoard[to.row][to.col] = movingPiece;

    final rekCaptures = <BoardPosition>[];

    // Check Horizontal Rek: Enemy - MovingPiece - Enemy
    if (to.col > 0 && to.col < boardSize - 1) {
      final leftPiece = tempBoard[to.row][to.col - 1];
      final rightPiece = tempBoard[to.row][to.col + 1];
      if (leftPiece != null &&
          leftPiece.player == enemyPlayer &&
          rightPiece != null &&
          rightPiece.player == enemyPlayer) {
        rekCaptures.add(BoardPosition(to.row, to.col - 1));
        rekCaptures.add(BoardPosition(to.row, to.col + 1));
      }
    }

    // Check Vertical Rek: Enemy - MovingPiece - Enemy
    if (to.row > 0 && to.row < boardSize - 1) {
      final topPiece = tempBoard[to.row - 1][to.col];
      final bottomPiece = tempBoard[to.row + 1][to.col];
      if (topPiece != null &&
          topPiece.player == enemyPlayer &&
          bottomPiece != null &&
          bottomPiece.player == enemyPlayer) {
        rekCaptures.add(BoardPosition(to.row - 1, to.col));
        rekCaptures.add(BoardPosition(to.row + 1, to.col));
      }
    }

    // Remove REK captured pieces before checking surrounding
    for (final cap in rekCaptures) {
      tempBoard[cap.row][cap.col] = null;
    }

    // Check Surround Captures (Enemy pieces with no legal moves)
    final surroundCaptures = findSurroundCaptures(tempBoard, enemyPlayer);

    bool kingCaptured = false;
    for (final cap in [...rekCaptures, ...surroundCaptures]) {
      final target = board[cap.row][cap.col];
      if (target != null && target.isCrowned) {
        kingCaptured = true;
      }
    }

    return RekMove(
      from: from,
      to: to,
      piece: movingPiece,
      rekCaptures: rekCaptures,
      surroundCaptures: surroundCaptures,
      capturedKing: kingCaptured,
    );
  }

  /// Finds enemy pieces or groups that are completely immobilized/surrounded
  static List<BoardPosition> findSurroundCaptures(
    List<List<RekPiece?>> board,
    PlayerColor enemyPlayer,
  ) {
    final captured = <BoardPosition>[];
    final visited = List.generate(
      boardSize,
      (_) => List<bool>.filled(boardSize, false),
    );

    for (int r = 0; r < boardSize; r++) {
      for (int c = 0; c < boardSize; c++) {
        final piece = board[r][c];
        if (piece != null &&
            piece.player == enemyPlayer &&
            !visited[r][c]) {
          // Collect connected group of friendly pieces
          final group = <BoardPosition>[];
          bool hasAnyFreeMove = false;

          final queue = <BoardPosition>[BoardPosition(r, c)];
          visited[r][c] = true;

          while (queue.isNotEmpty) {
            final curr = queue.removeAt(0);
            group.add(curr);

            const directions = [
              [-1, 0],
              [1, 0],
              [0, -1],
              [0, 1],
            ];

            for (final dir in directions) {
              final nr = curr.row + dir[0];
              final nc = curr.col + dir[1];

              if (nr >= 0 && nr < boardSize && nc >= 0 && nc < boardSize) {
                final neighbor = board[nr][nc];
                if (neighbor == null) {
                  // Found an empty space adjacent to this group!
                  hasAnyFreeMove = true;
                } else if (neighbor.player == enemyPlayer && !visited[nr][nc]) {
                  visited[nr][nc] = true;
                  queue.add(BoardPosition(nr, nc));
                }
              }
            }
          }

          // If the group has NO free adjacent squares at all, they are trapped!
          if (!hasAnyFreeMove) {
            captured.addAll(group);
          }
        }
      }
    }

    return captured;
  }

  /// Applies a move to the board and returns captured pieces
  static RekMove applyMove(
    List<List<RekPiece?>> board,
    BoardPosition from,
    BoardPosition to,
  ) {
    final move = simulateMove(board, from, to);

    final piece = board[from.row][from.col];
    board[from.row][from.col] = null;
    board[to.row][to.col] = piece;

    for (final cap in move.rekCaptures) {
      board[cap.row][cap.col] = null;
    }
    for (final cap in move.surroundCaptures) {
      board[cap.row][cap.col] = null;
    }

    return move;
  }

  /// Checks if game has ended
  static GameOverResult? checkGameOver(
    List<List<RekPiece?>> board,
    PlayerColor currentTurn,
  ) {
    bool tealHasKing = false;
    bool limeHasKing = false;
    int tealPieces = 0;
    int limePieces = 0;

    for (int r = 0; r < boardSize; r++) {
      for (int c = 0; c < boardSize; c++) {
        final p = board[r][c];
        if (p != null) {
          if (p.player == PlayerColor.teal) {
            tealPieces++;
            if (p.isCrowned) tealHasKing = true;
          } else {
            limePieces++;
            if (p.isCrowned) limeHasKing = true;
          }
        }
      }
    }

    if (!tealHasKing) {
      return GameOverResult(
        winner: PlayerColor.lime,
        reason: 'Lime Green captured the Teal King!',
      );
    }
    if (!limeHasKing) {
      return GameOverResult(
        winner: PlayerColor.teal,
        reason: 'Teal captured the Lime Green King!',
      );
    }

    if (tealPieces == 0) {
      return GameOverResult(
        winner: PlayerColor.lime,
        reason: 'Lime Green captured all Teal pieces!',
      );
    }
    if (limePieces == 0) {
      return GameOverResult(
        winner: PlayerColor.teal,
        reason: 'Teal captured all Lime Green pieces!',
      );
    }

    // Check if current player has any legal moves
    bool hasMoves = false;
    for (int r = 0; r < boardSize; r++) {
      for (int c = 0; c < boardSize; c++) {
        final p = board[r][c];
        if (p != null && p.player == currentTurn) {
          final legalMoves = getLegalMoves(board, BoardPosition(r, c));
          if (legalMoves.isNotEmpty) {
            hasMoves = true;
            break;
          }
        }
      }
      if (hasMoves) break;
    }

    if (!hasMoves) {
      final winner = currentTurn == PlayerColor.teal
          ? PlayerColor.lime
          : PlayerColor.teal;
      return GameOverResult(
        winner: winner,
        reason: '${currentTurn.name.toUpperCase()} has no legal moves remaining!',
      );
    }

    return null;
  }

  /// Get all legal moves for a player
  static List<RekMove> getAllMoves(
    List<List<RekPiece?>> board,
    PlayerColor player,
  ) {
    final allMoves = <RekMove>[];

    for (int r = 0; r < boardSize; r++) {
      for (int c = 0; c < boardSize; c++) {
        final p = board[r][c];
        if (p != null && p.player == player) {
          final from = BoardPosition(r, c);
          final destinations = getLegalMoves(board, from);
          for (final to in destinations) {
            allMoves.add(simulateMove(board, from, to));
          }
        }
      }
    }

    return allMoves;
  }
}

class GameOverResult {
  final PlayerColor winner;
  final String reason;

  GameOverResult({
    required this.winner,
    required this.reason,
  });
}
