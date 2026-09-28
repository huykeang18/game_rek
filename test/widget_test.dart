import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_rek/main.dart';
import 'package:game_rek/logic/rek_rules.dart';
import 'package:game_rek/models/rek_piece.dart';

void main() {
  testWidgets('Rek board game UI initial elements test', (WidgetTester tester) async {
    await tester.pumpWidget(const RekGameApp());
    await tester.pumpAndSettle();

    // Verify Top Menu elements
    expect(find.text('Erase all'), findsOneWidget);
    expect(find.text('Erase'), findsOneWidget);
    expect(find.text('Rotate Baord'), findsOneWidget);
    expect(find.byIcon(Icons.wifi), findsOneWidget);

    // Verify Bottom Menu elements
    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Load Game'), findsOneWidget);
    expect(find.text('Play'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    expect(find.byIcon(Icons.chat_bubble), findsOneWidget);
  });

  test('Standard Cambodian Rek initial setup verification', () {
    final board = RekRules.createInitialBoard();

    // Teal (Top):
    // Row 0: 7 plain pieces
    int tealRow0Plain = 0;
    for (int c = 0; c < 8; c++) {
      final p = board[0][c];
      if (p != null && p.player == PlayerColor.teal && !p.isCrowned) {
        tealRow0Plain++;
      }
    }
    expect(tealRow0Plain, 7);
    expect(board[0][7], isNull);

    // Row 1: 1 crowned piece at far right (col 7)
    expect(board[1][7]?.isCrowned, isTrue);
    expect(board[1][7]?.player, PlayerColor.teal);

    // Row 2: 8 plain pieces
    for (int c = 0; c < 8; c++) {
      expect(board[2][c]?.player, PlayerColor.teal);
      expect(board[2][c]?.isCrowned, isFalse);
    }

    // Lime Green (Bottom):
    // Row 5: 8 plain pieces
    for (int c = 0; c < 8; c++) {
      expect(board[5][c]?.player, PlayerColor.lime);
      expect(board[5][c]?.isCrowned, isFalse);
    }

    // Row 6: 1 crowned piece at far left (col 0)
    expect(board[6][0]?.isCrowned, isTrue);
    expect(board[6][0]?.player, PlayerColor.lime);

    // Row 7: 7 plain pieces (cols 1..7)
    int limeRow7Plain = 0;
    for (int c = 0; c < 8; c++) {
      final p = board[7][c];
      if (p != null && p.player == PlayerColor.lime && !p.isCrowned) {
        limeRow7Plain++;
      }
    }
    expect(limeRow7Plain, 7);
    expect(board[7][0], isNull);
  });

  test('Rek capture sandwich mechanic test', () {
    final board = List.generate(
      RekRules.boardSize,
      (_) => List<RekPiece?>.filled(RekRules.boardSize, null),
    );

    // Setup: Enemy pieces at (3, 2) and (3, 4)
    board[3][2] = const RekPiece(id: 't1', player: PlayerColor.teal, type: PieceType.plain);
    board[3][4] = const RekPiece(id: 't2', player: PlayerColor.teal, type: PieceType.plain);

    // Friendly piece moves from (1, 3) to (3, 3)
    board[1][3] = const RekPiece(id: 'l1', player: PlayerColor.lime, type: PieceType.plain);

    final move = RekRules.simulateMove(
      board,
      const BoardPosition(1, 3),
      const BoardPosition(3, 3),
    );

    expect(move.rekCaptures.length, 2);
    expect(move.rekCaptures.contains(const BoardPosition(3, 2)), isTrue);
    expect(move.rekCaptures.contains(const BoardPosition(3, 4)), isTrue);
  });
}
