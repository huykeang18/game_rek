import 'dart:math';
import '../models/rek_piece.dart';
import '../models/move.dart';
import 'rek_rules.dart';

enum AiDifficulty {
  easy,
  medium,
  hard,
}

class RekAi {
  final PlayerColor aiPlayer;
  final AiDifficulty difficulty;
  final RekRuleMode ruleMode;
  final Random _rng = Random();

  RekAi({
    required this.aiPlayer,
    this.difficulty = AiDifficulty.medium,
    this.ruleMode = RekRuleMode.hao,
  });

  PlayerColor get opponent =>
      aiPlayer == PlayerColor.teal ? PlayerColor.lime : PlayerColor.teal;

  /// Selects the best move according to the AI's difficulty.
  /// If [isCallActive] is true (opponent clicked the Call button), the AI is strictly forced to capture.
  /// If [isCallActive] is false, the AI can decide whether it wants to Rek or make another move.
  RekMove? selectMove(List<List<RekPiece?>> board, {bool isCallActive = false}) {
    final moves = RekRules.getAllValidMoves(board, aiPlayer, ruleMode: ruleMode, isCallActive: isCallActive);
    if (moves.isEmpty) return null;

    // 1. If any move captures the enemy "Me" (King), take it immediately!
    for (final move in moves) {
      if (move.capturedKing) return move;
    }

    switch (difficulty) {
      case AiDifficulty.easy:
        // Prioritize any capture, else random
        final captureMoves = moves.where((m) => m.hasCapture).toList();
        if (captureMoves.isNotEmpty) {
          return captureMoves[_rng.nextInt(captureMoves.length)];
        }
        return moves[_rng.nextInt(moves.length)];

      case AiDifficulty.medium:
        // 1-ply evaluation with tactical scoring
        moves.shuffle(_rng);
        moves.sort((a, b) => _evaluateMoveScore(board, b).compareTo(_evaluateMoveScore(board, a)));
        return moves.first;

      case AiDifficulty.hard:
        // 2-ply minimax evaluation with alpha-beta pruning
        RekMove? bestMove;
        double bestVal = -999999.0;
        moves.shuffle(_rng);

        for (final move in moves) {
          final tempBoard = RekRules.cloneBoard(board);
          RekRules.applyMove(tempBoard, move.from, move.to);

          if (move.capturedKing) return move;

          final val = _minimax(tempBoard, 1, false, -999999.0, 999999.0);
          if (val > bestVal) {
            bestVal = val;
            bestMove = move;
          }
        }
        return bestMove ?? moves.first;
    }
  }

  double _minimax(
    List<List<RekPiece?>> board,
    int depth,
    bool isMaximizing,
    double alpha,
    double beta,
  ) {
    final player = isMaximizing ? aiPlayer : opponent;
    final gameOver = RekRules.checkGameOver(board, player);
    if (gameOver != null) {
      if (gameOver.winner == aiPlayer) return 10000.0 + depth;
      return -10000.0 - depth;
    }

    if (depth <= 0) {
      return _evaluateBoard(board);
    }

    if (isMaximizing) {
      double maxEval = -999999.0;
      final moves = RekRules.getAllValidMoves(board, aiPlayer, ruleMode: ruleMode);
      if (moves.isEmpty) return -10000.0;

      for (final m in moves) {
        final nextBoard = RekRules.cloneBoard(board);
        RekRules.applyMove(nextBoard, m.from, m.to);

        final ev = _minimax(nextBoard, depth - 1, false, alpha, beta);
        maxEval = max(maxEval, ev);
        alpha = max(alpha, ev);
        if (beta <= alpha) break;
      }
      return maxEval;
    } else {
      double minEval = 999999.0;
      final moves = RekRules.getAllValidMoves(board, opponent, ruleMode: ruleMode);
      if (moves.isEmpty) return 10000.0;

      for (final m in moves) {
        final nextBoard = RekRules.cloneBoard(board);
        RekRules.applyMove(nextBoard, m.from, m.to);

        final ev = _minimax(nextBoard, depth - 1, true, alpha, beta);
        minEval = min(minEval, ev);
        beta = min(beta, ev);
        if (beta <= alpha) break;
      }
      return minEval;
    }
  }

  double _evaluateMoveScore(List<List<RekPiece?>> board, RekMove move) {
    double score = 0;

    if (move.capturedKing) score += 5000;
    score += move.totalCaptures * 200;

    // Moving King into center is risky in Rek
    if (move.piece.isCrowned) {
      score -= 20;
    }

    // Prefer advancing forward
    final forwardDist = aiPlayer == PlayerColor.teal
        ? (move.to.row - move.from.row)
        : (move.from.row - move.to.row);
    score += forwardDist * 5;

    return score;
  }

  double _evaluateBoard(List<List<RekPiece?>> board) {
    double score = 0;

    for (int r = 0; r < RekRules.boardSize; r++) {
      for (int c = 0; c < RekRules.boardSize; c++) {
        final p = board[r][c];
        if (p == null) continue;

        double pieceVal = p.isCrowned ? 1000.0 : 50.0;

        // Central control bonus
        final centerDist = (r - 3.5).abs() + (c - 3.5).abs();
        pieceVal += (7 - centerDist) * 3;

        if (p.player == aiPlayer) {
          score += pieceVal;
        } else {
          score -= pieceVal;
        }
      }
    }

    return score;
  }
}
