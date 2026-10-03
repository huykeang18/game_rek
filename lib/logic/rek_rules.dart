import '../models/rek_piece.dart';
import '../models/move.dart';

/// Rule options for Cambodian Rek chess
enum RekRuleMode {
  /// Option 1: Rek Mode (Standard Rek / Free Choice)
  /// - Captures happen via the authentic Rek sandwich mechanic.
  /// - Capturing is OPTIONAL: players can choose whether to capture
  ///   or freely move any other piece.
  rek,

  /// Option 2: Hao Mode (Strict Forced Capture)
  /// - Captures happen via the authentic Rek sandwich mechanic.
  /// - Capturing is MANDATORY: when a capture opening ("Hao") is available,
  ///   the player MUST strictly capture and cannot evade.
  hao,
}

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
  /// Rule 3 (Movement): Each piece moves along straight lines (orthogonal + shape:
  /// forward, backward, left, or right, like a Rook in chess) until obstructed
  /// by another piece or the edge of the board. Pieces cannot move diagonally or jump.
  static List<BoardPosition> getLegalMoves(
    List<List<RekPiece?>> board,
    BoardPosition pos,
  ) {
    final piece = board[pos.row][pos.col];
    if (piece == null) return [];

    final moves = <BoardPosition>[];
    const directions = [
      [-1, 0], // Up / Forward
      [1, 0],  // Down / Backward
      [0, -1], // Left
      [0, 1],  // Right
    ];

    for (final dir in directions) {
      int r = pos.row + dir[0];
      int c = pos.col + dir[1];

      // Runs in a straight line until obstruction (another piece or board boundary)
      while (r >= 0 && r < boardSize && c >= 0 && c < boardSize) {
        if (board[r][c] == null) {
          moves.add(BoardPosition(r, c));
        } else {
          // Blocked / obstructed by another piece
          break;
        }
        r += dir[0];
        c += dir[1];
      }
    }

    return moves;
  }

  /// Evaluates captures for a move from [from] to [to]
  /// Rule 1 (The Rule of "Rek"): A player captures opponent pieces only when moving one of
  /// their own pieces to land exactly in the middle between two opponent pieces (in a straight
  /// horizontal or vertical line). Once captured, both opponent pieces are removed from the board.
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

    // Remove Rek captures from tempBoard before evaluating Surrounding Capture (Khat)
    // because captured pieces are removed from the board immediately.
    for (final cap in rekCaptures) {
      tempBoard[cap.row][cap.col] = null;
    }

    // Evaluate Surrounding Capture (Khat):
    // Any enemy piece or group completely surrounded with zero legal orthogonal moves
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

  /// Evaluates Surrounding Capture (Khat / ស៊ីខាត់):
  /// Any enemy piece or group completely surrounded with zero legal orthogonal moves
  /// (i.e. having zero empty adjacent squares across the entire connected group)
  /// is trapped and removed from the board.
  static List<BoardPosition> findSurroundCaptures(
    List<List<RekPiece?>> board,
    PlayerColor enemyPlayer,
  ) {
    final visited = List.generate(
      boardSize,
      (_) => List<bool>.filled(boardSize, false),
    );
    final trappedPieces = <BoardPosition>[];

    const directions = [
      [-1, 0], // Up
      [1, 0],  // Down
      [0, -1], // Left
      [0, 1],  // Right
    ];

    for (int r = 0; r < boardSize; r++) {
      for (int c = 0; c < boardSize; c++) {
        final piece = board[r][c];
        if (piece != null && piece.player == enemyPlayer && !visited[r][c]) {
          // BFS to explore the entire connected component of enemy pieces
          final group = <BoardPosition>[];
          final queue = <BoardPosition>[BoardPosition(r, c)];
          visited[r][c] = true;
          bool hasLiberty = false;

          while (queue.isNotEmpty) {
            final current = queue.removeLast();
            group.add(current);

            for (final dir in directions) {
              final nr = current.row + dir[0];
              final nc = current.col + dir[1];

              if (nr >= 0 && nr < boardSize && nc >= 0 && nc < boardSize) {
                final neighborPiece = board[nr][nc];
                if (neighborPiece == null) {
                  // Found an adjacent empty square: this group has at least one legal move!
                  hasLiberty = true;
                } else if (neighborPiece.player == enemyPlayer && !visited[nr][nc]) {
                  visited[nr][nc] = true;
                  queue.add(BoardPosition(nr, nc));
                }
              }
            }
          }

          // If the group has NO liberties, the entire group is trapped (Khat)!
          if (!hasLiberty) {
            trappedPieces.addAll(group);
          }
        }
      }
    }

    return trappedPieces;
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

    for (final cap in move.allCaptures) {
      board[cap.row][cap.col] = null;
    }

    return move;
  }

  /// Get all legal sliding moves for a player regardless of capture
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

  /// Rule 2 (The Rule of "Hao" - Setting Traps & Forcing a Capture):
  /// Returns all available moves that execute a capture (Rek or Khat).
  static List<RekMove> getCapturingMoves(
    List<List<RekPiece?>> board,
    PlayerColor player,
  ) {
    return getAllMoves(board, player).where((m) => m.hasCapture).toList();
  }

  /// Checks if "Hao" (mandatory capture) is currently active for [player].
  /// In Cambodian Rek, setting a trap invites a Call. A player is strictly obligated
  /// to Rek ONLY when the opponent calls them by clicking the "Call" button ([isCallActive] = true).
  /// If the opponent has not clicked the Call button, capturing is optional and the player can decide.
  static bool isHaoActive(
    List<List<RekPiece?>> board,
    PlayerColor player, {
    RekRuleMode ruleMode = RekRuleMode.hao,
    bool isCallActive = false,
  }) {
    if (ruleMode != RekRuleMode.hao || !isCallActive) return false;
    return getCapturingMoves(board, player).isNotEmpty;
  }

  /// Returns valid move destinations for a specific piece at [pos],
  /// enforcing the selected [ruleMode] and whether Call was clicked:
  /// - Under [RekRuleMode.hao]:
  ///   - If [isCallActive] is true (opponent clicked Call button) and captures exist:
  ///     ONLY capturing moves are valid! Non-capturing pieces cannot move.
  ///   - If [isCallActive] is false (opponent did NOT click Call button):
  ///     Capturing is optional. Player can freely decide whether they want to Rek or not.
  /// - Under [RekRuleMode.rek]: capturing is always optional.
  static List<BoardPosition> getValidMovesForPiece(
    List<List<RekPiece?>> board,
    BoardPosition pos, {
    RekRuleMode ruleMode = RekRuleMode.hao,
    bool isCallActive = false,
  }) {
    final piece = board[pos.row][pos.col];
    if (piece == null) return [];

    if (ruleMode == RekRuleMode.hao && isCallActive) {
      final captures = getCapturingMoves(board, piece.player);
      if (captures.isNotEmpty) {
        // Hao Call is active: only moves that capture with this piece are legal
        return captures.where((m) => m.from == pos).map((m) => m.to).toList();
      }
    }

    // Call not active, Rek mode, or no captures available: standard sliding orthogonal moves
    return getLegalMoves(board, pos);
  }

  /// Returns all valid legal moves for a player, enforcing [ruleMode]:
  /// - Under [RekRuleMode.hao] when [isCallActive] is true: returns ONLY capturing moves.
  /// - Otherwise (or when Call was not clicked): returns all legal sliding moves (player can decide).
  static List<RekMove> getAllValidMoves(
    List<List<RekPiece?>> board,
    PlayerColor player, {
    RekRuleMode ruleMode = RekRuleMode.hao,
    bool isCallActive = false,
  }) {
    if (ruleMode == RekRuleMode.hao && isCallActive) {
      final capturingMoves = getCapturingMoves(board, player);
      if (capturingMoves.isNotEmpty) {
        return capturingMoves;
      }
    }
    return getAllMoves(board, player);
  }

  /// Rule 4 (Winning and Losing Conditions):
  /// - Winner is player who captures all opponent pieces or captures opponent's "Me" (King/Commander).
  /// - A player also loses if completely blocked in (stalemate) with no valid moves left.
  static GameOverResult? checkGameOver(
    List<List<RekPiece?>> board,
    PlayerColor currentTurn, {
    RekRuleMode ruleMode = RekRuleMode.hao,
  }) {
    bool tealHasMe = false;
    bool limeHasMe = false;
    int tealPieces = 0;
    int limePieces = 0;

    for (int r = 0; r < boardSize; r++) {
      for (int c = 0; c < boardSize; c++) {
        final p = board[r][c];
        if (p != null) {
          if (p.player == PlayerColor.teal) {
            tealPieces++;
            if (p.isCrowned) tealHasMe = true;
          } else {
            limePieces++;
            if (p.isCrowned) limeHasMe = true;
          }
        }
      }
    }

    // 1. Captured the opponent's "Me" (Commander)
    if (!tealHasMe) {
      return GameOverResult(
        winner: PlayerColor.lime,
        reason: 'Lime Green captured Teal\'s "Me" (Commander)!',
      );
    }
    if (!limeHasMe) {
      return GameOverResult(
        winner: PlayerColor.teal,
        reason: 'Teal captured Lime Green\'s "Me" (Commander)!',
      );
    }

    // 2. Captured all opponent pieces
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

    // 3. Completely blocked in (stalemate) with no valid moves left
    final validMoves = getAllValidMoves(board, currentTurn, ruleMode: ruleMode);
    if (validMoves.isEmpty) {
      final winner = currentTurn == PlayerColor.teal
          ? PlayerColor.lime
          : PlayerColor.teal;
      final loserName = currentTurn == PlayerColor.teal ? 'Teal' : 'Lime Green';
      return GameOverResult(
        winner: winner,
        reason: '$loserName is completely blocked with no valid moves left!',
      );
    }

    return null;
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
