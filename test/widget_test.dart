import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_rek/main.dart';
import 'package:game_rek/logic/rek_rules.dart';
import 'package:game_rek/models/rek_piece.dart';

void main() {
  testWidgets('Rek app home page and navigation to game editor test', (WidgetTester tester) async {
    await tester.pumpWidget(const RekGameApp());
    await tester.pumpAndSettle();

    // 1. Verify Home Page elements
    expect(find.text('ល្បែងរែក'), findsOneWidget);
    expect(find.text('CAMBODIAN REK CHESS'), findsOneWidget);
    expect(find.text('Play vs AI'), findsOneWidget);
    expect(find.text('Pass & Play (2 Players)'), findsOneWidget);
    expect(find.text('Board Setup & Editor'), findsOneWidget);
    expect(find.text('Rules & Guide'), findsOneWidget);

    // 2. Tap "Board Setup & Editor" to navigate into the game screen
    await tester.tap(find.text('Board Setup & Editor'));
    await tester.pumpAndSettle();

    // 3. Verify Top Menu elements on game screen
    expect(find.text('Erase all'), findsOneWidget);
    expect(find.text('Erase'), findsOneWidget);
    expect(find.text('Rotate Baord'), findsOneWidget);
    expect(find.byIcon(Icons.wifi), findsOneWidget);

    // 4. Verify Bottom Menu elements on game screen
    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Play'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    expect(find.byIcon(Icons.chat_bubble), findsOneWidget);

    // 5. Tap Yellow back arrow to return to Home Page
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    // 6. Verify we are back on Home Page
    expect(find.text('CAMBODIAN REK CHESS'), findsOneWidget);
  });

  testWidgets('Responsive layouts verification across multiple device screen sizes', (WidgetTester tester) async {
    final sizes = [
      const Size(320, 568),   // Small compact phone (iPhone SE 1st gen)
      const Size(390, 844),   // Standard modern phone (iPhone 14 / Android)
      const Size(768, 1024),  // Tablet portrait (iPad)
      const Size(844, 390),   // Phone landscape
      const Size(1200, 800),  // Desktop window / Web
    ];

    for (final size in sizes) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const RekGameApp());
      await tester.pumpAndSettle();

      // Home screen renders cleanly on this size
      expect(find.text('CAMBODIAN REK CHESS'), findsOneWidget);

      // Scroll to and navigate to game board
      final setupBtn = find.text('Board Setup & Editor');
      await tester.ensureVisible(setupBtn);
      await tester.pumpAndSettle();
      await tester.tap(setupBtn);
      await tester.pumpAndSettle();

      // Verify essential game elements render with zero exceptions on this screen size
      expect(find.text('Rotate Baord'), findsOneWidget);
      expect(find.byIcon(Icons.wifi), findsOneWidget);

      // Return to home
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
    }
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
