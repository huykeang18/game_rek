import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_rek/main.dart';
import 'package:game_rek/logic/rek_rules.dart';
import 'package:game_rek/models/rek_piece.dart';
import 'package:game_rek/services/user_service.dart';
import 'package:game_rek/services/language_service.dart';
import 'package:game_rek/services/audio_service.dart';
import 'package:game_rek/screens/home_screen.dart';
import 'package:game_rek/screens/rek_game_screen.dart';
import 'package:game_rek/logic/storage_service.dart';
import 'package:game_rek/widgets/wood_board.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LanguageService.instance.setLanguage(AppLanguage.english);
    await UserService.instance.setUsername('RekMaster');
    await UserService.instance.resetPoints();
  });

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
    expect(find.byIcon(Icons.wifi), findsNothing);

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
      expect(find.byIcon(Icons.wifi), findsNothing);

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

  test('General Movement Rules: pieces move in straight lines (+ shape) until obstruction like a Rook, no diagonals', () {
    final board = List.generate(
      RekRules.boardSize,
      (_) => List<RekPiece?>.filled(RekRules.boardSize, null),
    );

    // 1. On an open board, place a piece at (3, 3)
    board[3][3] = const RekPiece(id: 'p1', player: PlayerColor.lime, type: PieceType.plain);

    final openMoves = RekRules.getLegalMoves(board, const BoardPosition(3, 3));

    // Can slide horizontally across row 3 (cols 0, 1, 2, 4, 5, 6, 7 -> 7 moves)
    // and vertically across col 3 (rows 0, 1, 2, 4, 5, 6, 7 -> 7 moves) = 14 total
    expect(openMoves.length, 14);

    // Check sliding far destinations
    expect(openMoves.contains(const BoardPosition(0, 3)), isTrue); // far up
    expect(openMoves.contains(const BoardPosition(7, 3)), isTrue); // far down
    expect(openMoves.contains(const BoardPosition(3, 0)), isTrue); // far left
    expect(openMoves.contains(const BoardPosition(3, 7)), isTrue); // far right

    // Cannot move diagonally
    expect(openMoves.contains(const BoardPosition(2, 2)), isFalse);
    expect(openMoves.contains(const BoardPosition(4, 4)), isFalse);
    expect(openMoves.contains(const BoardPosition(0, 0)), isFalse);

    // 2. Test obstruction: place an obstacle at (1, 3)
    board[1][3] = const RekPiece(id: 'obstacle', player: PlayerColor.teal, type: PieceType.plain);

    final obstructedMoves = RekRules.getLegalMoves(board, const BoardPosition(3, 3));

    // Can move to (2, 3), but cannot reach (1, 3) or jump past to (0, 3)
    expect(obstructedMoves.contains(const BoardPosition(2, 3)), isTrue);
    expect(obstructedMoves.contains(const BoardPosition(1, 3)), isFalse); // obstructed
    expect(obstructedMoves.contains(const BoardPosition(0, 3)), isFalse); // blocked behind obstacle
  });

  test('Sliding Rek capture: piece slides multiple squares across empty board to execute a Rek sandwich capture', () {
    final board = List.generate(
      RekRules.boardSize,
      (_) => List<RekPiece?>.filled(RekRules.boardSize, null),
    );

    // Setup: Enemy pieces at (3, 2) and (3, 4)
    board[3][2] = const RekPiece(id: 't1', player: PlayerColor.teal, type: PieceType.plain);
    board[3][4] = const RekPiece(id: 't2', player: PlayerColor.teal, type: PieceType.plain);

    // Friendly piece is 3 squares away at (0, 3)
    board[0][3] = const RekPiece(id: 'l1', player: PlayerColor.lime, type: PieceType.plain);

    // Moving piece slides from (0, 3) down to (3, 3)
    final legalMoves = RekRules.getLegalMoves(board, const BoardPosition(0, 3));
    expect(legalMoves.contains(const BoardPosition(3, 3)), isTrue);

    final move = RekRules.applyMove(
      board,
      const BoardPosition(0, 3),
      const BoardPosition(3, 3),
    );

    // Both sandwiched enemy pieces are captured
    expect(move.rekCaptures.length, 2);
    expect(board[3][2], isNull);
    expect(board[3][4], isNull);
    expect(board[3][3]?.id, 'l1');
    expect(board[0][3], isNull);
  });

  test('Rule 1: Rek capture horizontal and vertical sandwich mechanic', () {
    final board = List.generate(
      RekRules.boardSize,
      (_) => List<RekPiece?>.filled(RekRules.boardSize, null),
    );

    // Setup: Enemy pieces at (3, 2) and (3, 4)
    board[3][2] = const RekPiece(id: 't1', player: PlayerColor.teal, type: PieceType.plain);
    board[3][4] = const RekPiece(id: 't2', player: PlayerColor.teal, type: PieceType.plain);

    // Friendly piece at (2, 3) moves 1 square down to (3, 3)
    board[2][3] = const RekPiece(id: 'l1', player: PlayerColor.lime, type: PieceType.plain);

    final move = RekRules.applyMove(
      board,
      const BoardPosition(2, 3),
      const BoardPosition(3, 3),
    );

    // Both enemy pieces removed from board
    expect(move.rekCaptures.length, 2);
    expect(board[3][2], isNull);
    expect(board[3][4], isNull);
    expect(board[3][3]?.id, 'l1');
  });

  test('Rule 1: Simultaneous 4-piece Rek capture (cross pattern)', () {
    final board = List.generate(
      RekRules.boardSize,
      (_) => List<RekPiece?>.filled(RekRules.boardSize, null),
    );

    // Enemy pieces surrounding square (3, 3) in + shape:
    // Left (3, 2), Right (3, 4), Top (2, 3), Bottom (4, 3)
    board[3][2] = const RekPiece(id: 't1', player: PlayerColor.teal, type: PieceType.plain);
    board[3][4] = const RekPiece(id: 't2', player: PlayerColor.teal, type: PieceType.plain);
    board[2][3] = const RekPiece(id: 't3', player: PlayerColor.teal, type: PieceType.plain);
    board[4][3] = const RekPiece(id: 't4', player: PlayerColor.teal, type: PieceType.plain);

    // Friendly piece moves from (3, 1) to (3, 3) -- wait, (3, 1) to (3, 2) is blocked!
    // Friendly piece at (3, 3) is empty; friendly piece starts at (3, 1) ? No, 1 square away:
    // Actually from (3, 2) is occupied by t1. If piece comes from e.g. (3, 3) is empty, but all 4 adjacents are occupied!
    // A piece can't jump over!
    // But in Rek, if piece moves to (3, 3) from another square... wait, 1 square orthogonal away would be (2, 3), (4, 3), (3, 2), (3, 4) which are all occupied!
    // In simulateMove, cross capture logic is verified:
    board[2][3] = const RekPiece(id: 'l_source', player: PlayerColor.lime, type: PieceType.plain);
    // If top is l_source, it can move down to (3, 3), but then top is gone so top isn't enemy.
    // What if enemy is at (2, 3) and (4, 3), and enemy at (3, 2) and (3, 4)?
    // Can a piece move to (3, 3) from 1 square away?
    // Since only 4 orthogonal neighbors exist and 4 are enemy, the piece would have to come from an orthogonal neighbor!
    // That's an insightful geometric fact about 1-square movement: a simultaneous 4-piece capture can only happen if a piece slides from further away, OR in simulation.
    // Let's verify simulateMove with 4 captures:
    final simBoard = List.generate(
      RekRules.boardSize,
      (_) => List<RekPiece?>.filled(RekRules.boardSize, null),
    );
    simBoard[3][2] = const RekPiece(id: 't1', player: PlayerColor.teal, type: PieceType.plain);
    simBoard[3][4] = const RekPiece(id: 't2', player: PlayerColor.teal, type: PieceType.plain);
    simBoard[2][3] = const RekPiece(id: 't3', player: PlayerColor.teal, type: PieceType.plain);
    simBoard[4][3] = const RekPiece(id: 't4', player: PlayerColor.teal, type: PieceType.plain);
    simBoard[3][3] = const RekPiece(id: 'l1', player: PlayerColor.lime, type: PieceType.plain);
    final m4 = RekRules.simulateMove(simBoard, const BoardPosition(3, 3), const BoardPosition(3, 3));
    expect(m4.rekCaptures.length, 4);
  });

  test('Surrounding Capture (Khat): single enemy piece with zero legal orthogonal moves is trapped and removed', () {
    final board = List.generate(
      RekRules.boardSize,
      (_) => List<RekPiece?>.filled(RekRules.boardSize, null),
    );

    // Enemy Teal piece in the corner at (0, 0)
    board[0][0] = const RekPiece(id: 't_corner', player: PlayerColor.teal, type: PieceType.plain);
    // Lime piece at (0, 1)
    board[0][1] = const RekPiece(id: 'l_1', player: PlayerColor.lime, type: PieceType.plain);
    // Lime piece at (5, 0) slides to (1, 0) to completely surround Teal at (0, 0)
    board[5][0] = const RekPiece(id: 'l_slider', player: PlayerColor.lime, type: PieceType.plain);

    final move = RekRules.applyMove(
      board,
      const BoardPosition(5, 0),
      const BoardPosition(1, 0),
    );

    // Teal piece at (0, 0) has 0 liberties/moves: trapped by Khat!
    expect(move.surroundCaptures.length, 1);
    expect(move.surroundCaptures.first, const BoardPosition(0, 0));
    expect(board[0][0], isNull); // Removed from board!
  });

  test('Surrounding Capture (Khat): connected group of enemy pieces completely surrounded is trapped and removed', () {
    final board = List.generate(
      RekRules.boardSize,
      (_) => List<RekPiece?>.filled(RekRules.boardSize, null),
    );

    // Connected group of 2 Teal pieces at (0, 0) and (0, 1)
    board[0][0] = const RekPiece(id: 't_1', player: PlayerColor.teal, type: PieceType.plain);
    board[0][1] = const RekPiece(id: 't_2', player: PlayerColor.teal, type: PieceType.plain);

    // Lime pieces surrounding them:
    // (1, 0) Lime, (1, 1) Lime
    board[1][0] = const RekPiece(id: 'l_1', player: PlayerColor.lime, type: PieceType.plain);
    board[1][1] = const RekPiece(id: 'l_2', player: PlayerColor.lime, type: PieceType.plain);
    // Lime piece slides from (0, 7) to (0, 2) to block the last liberty
    board[0][7] = const RekPiece(id: 'l_closer', player: PlayerColor.lime, type: PieceType.plain);

    final move = RekRules.applyMove(
      board,
      const BoardPosition(0, 7),
      const BoardPosition(0, 2),
    );

    // Both Teal pieces in the group have zero liberties: trapped by Khat!
    expect(move.surroundCaptures.length, 2);
    expect(move.surroundCaptures.contains(const BoardPosition(0, 0)), isTrue);
    expect(move.surroundCaptures.contains(const BoardPosition(0, 1)), isTrue);
    expect(board[0][0], isNull);
    expect(board[0][1], isNull);
  });

  test('Surrounding Capture (Khat): group with at least one liberty is NOT trapped', () {
    final board = List.generate(
      RekRules.boardSize,
      (_) => List<RekPiece?>.filled(RekRules.boardSize, null),
    );

    // Connected group of 2 Teal pieces at (0, 0) and (0, 1)
    board[0][0] = const RekPiece(id: 't_1', player: PlayerColor.teal, type: PieceType.plain);
    board[0][1] = const RekPiece(id: 't_2', player: PlayerColor.teal, type: PieceType.plain);

    // Lime pieces at (1, 0) and (1, 1), but (0, 2) is EMPTY (liberty exists!)
    board[1][0] = const RekPiece(id: 'l_1', player: PlayerColor.lime, type: PieceType.plain);
    board[1][1] = const RekPiece(id: 'l_2', player: PlayerColor.lime, type: PieceType.plain);

    // Friendly lime piece moves elsewhere (e.g. (7, 7) to (7, 6))
    board[7][7] = const RekPiece(id: 'l_other', player: PlayerColor.lime, type: PieceType.plain);

    final move = RekRules.applyMove(
      board,
      const BoardPosition(7, 7),
      const BoardPosition(7, 6),
    );

    // Teal group has liberty at (0, 2): NOT trapped!
    expect(move.surroundCaptures, isEmpty);
    expect(board[0][0], isNotNull);
    expect(board[0][1], isNotNull);
  });

  test('Simultaneous Rek capture and Khat capture on the same move', () {
    final board = List.generate(
      RekRules.boardSize,
      (_) => List<RekPiece?>.filled(RekRules.boardSize, null),
    );

    // Setup Rek capture: Enemy at (3, 2) and (3, 4). Move to (3, 3) Rek captures them.
    board[3][2] = const RekPiece(id: 't_rek1', player: PlayerColor.teal, type: PieceType.plain);
    board[3][4] = const RekPiece(id: 't_rek2', player: PlayerColor.teal, type: PieceType.plain);

    // Setup Khat capture: Enemy at (2, 3) is surrounded on other 3 sides:
    // (1, 3) Lime, (2, 2) Lime, (2, 4) Lime.
    // The only open side of (2, 3) was (3, 3).
    board[1][3] = const RekPiece(id: 'l_top', player: PlayerColor.lime, type: PieceType.plain);
    board[2][2] = const RekPiece(id: 'l_left', player: PlayerColor.lime, type: PieceType.plain);
    board[2][4] = const RekPiece(id: 'l_right', player: PlayerColor.lime, type: PieceType.plain);
    board[2][3] = const RekPiece(id: 't_khat', player: PlayerColor.teal, type: PieceType.plain);

    // Lime piece at (7, 3) slides to (3, 3)
    board[7][3] = const RekPiece(id: 'l_hero', player: PlayerColor.lime, type: PieceType.plain);

    final move = RekRules.applyMove(
      board,
      const BoardPosition(7, 3),
      const BoardPosition(3, 3),
    );

    // Simultaneously Rek captures (3, 2) and (3, 4), AND Khat traps (2, 3)!
    expect(move.rekCaptures.length, 2);
    expect(move.surroundCaptures.length, 1);
    expect(move.surroundCaptures.first, const BoardPosition(2, 3));
    expect(move.totalCaptures, 3);
    expect(board[3][2], isNull);
    expect(board[3][4], isNull);
    expect(board[2][3], isNull);
    expect(board[3][3]?.id, 'l_hero');
  });

  test('Rule 2: Rule of Hao strictly obligates capture and prohibits non-capturing moves when Call is clicked', () {
    final board = List.generate(
      RekRules.boardSize,
      (_) => List<RekPiece?>.filled(RekRules.boardSize, null),
    );

    // Lime piece A at (2, 3) can move to (3, 3) and Rek capture Teal at (3, 2) and (3, 4)
    board[2][3] = const RekPiece(id: 'lime_rekker', player: PlayerColor.lime, type: PieceType.plain);
    board[3][2] = const RekPiece(id: 'teal_1', player: PlayerColor.teal, type: PieceType.plain);
    board[3][4] = const RekPiece(id: 'teal_2', player: PlayerColor.teal, type: PieceType.plain);

    // Lime piece B at (6, 6) is far away and cannot capture anything
    board[6][6] = const RekPiece(id: 'lime_passive', player: PlayerColor.lime, type: PieceType.plain);

    // 1. If opponent did NOT click Call: capturing is optional, player can decide!
    expect(RekRules.isHaoActive(board, PlayerColor.lime, isCallActive: false), isFalse);
    final optionalPassiveMoves = RekRules.getValidMovesForPiece(board, const BoardPosition(6, 6), isCallActive: false);
    expect(optionalPassiveMoves, isNotEmpty); // Can move passive piece freely

    // 2. If opponent clicked Call button (isCallActive = true): strict obligation!
    expect(RekRules.isHaoActive(board, PlayerColor.lime, isCallActive: true), isTrue);

    // Piece B (passive) CANNOT move! (Strict obligation)
    final passiveMoves = RekRules.getValidMovesForPiece(board, const BoardPosition(6, 6), isCallActive: true);
    expect(passiveMoves, isEmpty);

    // Piece A MUST make the capturing move to (3, 3)
    final rekkerMoves = RekRules.getValidMovesForPiece(board, const BoardPosition(2, 3), isCallActive: true);
    expect(rekkerMoves.length, 1);
    expect(rekkerMoves.first, const BoardPosition(3, 3));

    // Overall valid moves only contains the capturing move
    final allValid = RekRules.getAllValidMoves(board, PlayerColor.lime, isCallActive: true);
    expect(allValid.length, 1);
    expect(allValid.first.from, const BoardPosition(2, 3));
    expect(allValid.first.to, const BoardPosition(3, 3));
    expect(allValid.first.rekCaptures.length, 2);
  });

  test('Rek and Hao options for players: Rek allows optional capture while Hao enforces mandatory capture on Call', () {
    final board = List.generate(
      RekRules.boardSize,
      (_) => List<RekPiece?>.filled(RekRules.boardSize, null),
    );

    // Lime piece A at (2, 3) can capture Teal pieces at (3, 2) and (3, 4) by moving to (3, 3)
    board[2][3] = const RekPiece(id: 'lime_rekker', player: PlayerColor.lime, type: PieceType.plain);
    board[3][2] = const RekPiece(id: 'teal_1', player: PlayerColor.teal, type: PieceType.plain);
    board[3][4] = const RekPiece(id: 'teal_2', player: PlayerColor.teal, type: PieceType.plain);

    // Lime piece B at (6, 6) is far away and cannot capture anything
    board[6][6] = const RekPiece(id: 'lime_passive', player: PlayerColor.lime, type: PieceType.plain);

    // 1. Under "Hao" option when opponent clicked Call: strict obligation, capturing is mandatory
    expect(RekRules.isHaoActive(board, PlayerColor.lime, ruleMode: RekRuleMode.hao, isCallActive: true), isTrue);
    expect(RekRules.getValidMovesForPiece(board, const BoardPosition(6, 6), ruleMode: RekRuleMode.hao, isCallActive: true), isEmpty);
    expect(RekRules.getValidMovesForPiece(board, const BoardPosition(2, 3), ruleMode: RekRuleMode.hao, isCallActive: true), [const BoardPosition(3, 3)]);

    // Under "Hao" option when opponent did NOT click Call: player can decide whether they want to Rek or not!
    expect(RekRules.isHaoActive(board, PlayerColor.lime, ruleMode: RekRuleMode.hao, isCallActive: false), isFalse);
    expect(RekRules.getValidMovesForPiece(board, const BoardPosition(6, 6), ruleMode: RekRuleMode.hao, isCallActive: false), isNotEmpty);

    // 2. Under "Rek" option: free choice, capturing is always optional
    expect(RekRules.isHaoActive(board, PlayerColor.lime, ruleMode: RekRuleMode.rek), isFalse);
    final passiveMovesInRek = RekRules.getValidMovesForPiece(board, const BoardPosition(6, 6), ruleMode: RekRuleMode.rek);
    expect(passiveMovesInRek, isNotEmpty); // Piece B can move freely in Rek mode!
    final rekkerMovesInRek = RekRules.getValidMovesForPiece(board, const BoardPosition(2, 3), ruleMode: RekRuleMode.rek);
    expect(rekkerMovesInRek.contains(const BoardPosition(3, 3)), isTrue); // Can capture if player wants
  });

  test('Rule 4: Winning immediately when opponent Me (King) is captured', () {
    final board = List.generate(
      RekRules.boardSize,
      (_) => List<RekPiece?>.filled(RekRules.boardSize, null),
    );

    // Teal Me at (3, 2) and Teal plain at (3, 4)
    board[3][2] = const RekPiece(id: 'teal_me', player: PlayerColor.teal, type: PieceType.crowned);
    board[3][4] = const RekPiece(id: 'teal_plain', player: PlayerColor.teal, type: PieceType.plain);

    // Lime Me at (7, 7) and Lime plain at (2, 3)
    board[7][7] = const RekPiece(id: 'lime_me', player: PlayerColor.lime, type: PieceType.crowned);
    board[2][3] = const RekPiece(id: 'lime_plain', player: PlayerColor.lime, type: PieceType.plain);

    // Lime moves (2, 3) to (3, 3), capturing Teal Me!
    final move = RekRules.applyMove(board, const BoardPosition(2, 3), const BoardPosition(3, 3));
    expect(move.capturedKing, isTrue);

    final result = RekRules.checkGameOver(board, PlayerColor.teal);
    expect(result, isNotNull);
    expect(result!.winner, PlayerColor.lime);
    expect(result.reason, contains('"Me" (Commander)'));
  });

  test('Rule 4: Stalemate (blocked in with no valid moves) causes loss', () {
    final board = List.generate(
      RekRules.boardSize,
      (_) => List<RekPiece?>.filled(RekRules.boardSize, null),
    );

    // Teal Me trapped in corner at (0, 0)
    board[0][0] = const RekPiece(id: 't_me', player: PlayerColor.teal, type: PieceType.crowned);

    // Surrounded by Lime pieces at (0, 1) and (1, 0)
    board[0][1] = const RekPiece(id: 'l_1', player: PlayerColor.lime, type: PieceType.plain);
    board[1][0] = const RekPiece(id: 'l_2', player: PlayerColor.lime, type: PieceType.plain);
    // Lime also has their Me at (7, 7)
    board[7][7] = const RekPiece(id: 'l_me', player: PlayerColor.lime, type: PieceType.crowned);

    // It is Teal's turn, but Teal has zero legal moves
    final result = RekRules.checkGameOver(board, PlayerColor.teal);
    expect(result, isNotNull);
    expect(result!.winner, PlayerColor.lime);
    expect(result.reason, contains('blocked with no valid moves left'));
  });

  testWidgets('Username profile view and editing test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const RekGameApp());
    await tester.pumpAndSettle();

    // Verify default username is displayed on top bar
    expect(find.text(UserService.instance.username), findsOneWidget);

    // Tap on username badge to open ProfileEditDialog
    await tester.tap(find.text(UserService.instance.username));
    await tester.pumpAndSettle();

    // Verify dialog content
    expect(find.text('Edit Player Profile'), findsOneWidget);
    expect(find.text('Choose Avatar'), findsOneWidget);
    expect(find.text('Player Username'), findsOneWidget);

    // Enter a new username
    await tester.enterText(find.byType(TextFormField), 'AngkorChampion');
    await tester.pumpAndSettle();

    // Ensure Save Profile button is visible and tap it
    await tester.ensureVisible(find.text('Save Profile'));
    await tester.tap(find.text('Save Profile'));
    await tester.pumpAndSettle();

    // Verify username is updated
    expect(find.text('AngkorChampion'), findsOneWidget);
    expect(UserService.instance.username, 'AngkorChampion');
  });

  testWidgets('Music and sound settings dialog test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const RekGameApp());
    await tester.pumpAndSettle();

    // Tap Settings icon on the top bar
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    // Verify Settings dialog
    expect(find.text('Settings & Audio'), findsOneWidget);
    expect(find.text('Background Music (BGM)'), findsOneWidget);
    expect(find.text('Enable Music'), findsOneWidget);
    expect(find.text('Roneat Melody'), findsOneWidget);
    expect(find.text('Angkor Ambient'), findsOneWidget);
    expect(find.text('Peaceful Bamboo'), findsOneWidget);
    expect(find.text('Khmer Chapei & Tro'), findsOneWidget);
    expect(find.text('Kong Vong Gongs'), findsOneWidget);
    expect(find.text('Sound Effects (SFX)'), findsOneWidget);
    expect(find.text('Test Move'), findsOneWidget);
    expect(find.text('Test Rek'), findsOneWidget);
    expect(find.text('Test Khat'), findsOneWidget);

    // Ensure Done button is visible and tap it
    await tester.ensureVisible(find.text('Done'));
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    // Verify returned to home screen
    expect(find.text('CAMBODIAN REK CHESS'), findsOneWidget);
  });

  testWidgets('Language button toggle between English and Khmer test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await LanguageService.instance.setLanguage(AppLanguage.english);

    await tester.pumpWidget(const RekGameApp());
    await tester.pumpAndSettle();

    // 1. Initially English
    expect(find.text('Play vs AI'), findsOneWidget);
    expect(find.text('Pass & Play (2 Players)'), findsOneWidget);
    expect(find.text('EN'), findsOneWidget);

    // 2. Tap language button on top bar to switch to Khmer
    await tester.tap(find.text('EN'));
    await tester.pumpAndSettle();

    // 3. Verify switched to Khmer
    expect(LanguageService.instance.isKhmer, isTrue);
    expect(find.text('ខ្មែរ'), findsOneWidget);
    expect(find.text('លេងជាមួយ AI'), findsOneWidget);
    expect(find.text('លេង២នាក់ (ឧបករណ៍តែមួយ)'), findsOneWidget);

    // 4. Tap language button again to switch back to English
    await tester.tap(find.text('ខ្មែរ'));
    await tester.pumpAndSettle();

    // 5. Verify back to English
    expect(LanguageService.instance.isEnglish, isTrue);
    expect(find.text('EN'), findsOneWidget);
    expect(find.text('Play vs AI'), findsOneWidget);
  });

  testWidgets('Rules & Guide details display in Khmer when language is Khmer', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Set to Khmer
    await LanguageService.instance.setLanguage(AppLanguage.khmer);

    await tester.pumpWidget(const RekGameApp());
    await tester.pumpAndSettle();

    // Tap Rules & Guide card in Khmer: "ច្បាប់លេង និងការណែនាំ"
    await tester.tap(find.text('ច្បាប់លេង និងការណែនាំ'));
    await tester.pumpAndSettle();

    // Verify dialog header in Khmer
    expect(find.text('ល្បែងរែក (Cambodian Rek)'), findsOneWidget);
    expect(find.text('ច្បាប់លេង & ការណែនាំ'), findsOneWidget);
    expect(find.text('កំណត់ត្រាក្បាច់ដើរ'), findsOneWidget);

    // Verify detailed section titles in Khmer
    expect(find.text('១. ក្បាច់ស៊ីរែក (1. The Rule of "Rek" - Capturing)'), findsOneWidget);
    expect(find.text('២. ច្បាប់ហៅ (2. The Rule of "Call" - Setting Traps & Forcing a Capture)'), findsOneWidget);
    expect(find.text('៣. ក្បាច់ស៊ីខាត់ (3. The Rule of "Khat" - Surrounding Capture)'), findsOneWidget);
    expect(find.text('៤. ច្បាប់ដើរទូទៅ (4. General Movement Rules)'), findsOneWidget);
    expect(find.text('៥. លក្ខខណ្ឌឈ្នះ និងចាញ់ (5. Winning & Losing Conditions)'), findsOneWidget);
    expect(find.text('៦. ផ្ទាំងបញ្ជា និងឧបករណ៍រៀបចំក្តារ (Controls & Editor)'), findsOneWidget);

    // Switch to English dynamically and verify update
    await LanguageService.instance.setLanguage(AppLanguage.english);
    await tester.pumpAndSettle();

    expect(find.text('1. The Rule of "Rek" (Capturing)'), findsOneWidget);
    expect(find.widgetWithText(Tab, 'Rules & Guide'), findsOneWidget);
  });

  testWidgets('Play vs AI mode removes Erase all, Erase, and Save buttons, and displays player timers', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const RekGameApp());
    await tester.pumpAndSettle();

    // 1. Tap "Play vs AI"
    await tester.tap(find.text('Play vs AI'));
    await tester.pumpAndSettle();

    // 2. Tap "Start Match" on difficulty modal
    await tester.tap(find.text('Start Match'));
    await tester.pumpAndSettle();

    // 3. Verify Erase all, Erase, and Save buttons are NOT present in Play vs AI
    expect(find.text('Erase all'), findsNothing);
    expect(find.text('Erase'), findsNothing);
    expect(find.text('Save'), findsNothing);

    // 4. Verify Rotate Baord, Play, Back arrow, and Wi-Fi ARE present
    expect(find.text('Rotate Baord'), findsOneWidget);
    expect(find.text('Play'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);

    // 5. Verify Player Timer Cards are displayed for both Teal AI and Lime Player
    expect(find.text('05:00'), findsNWidgets(2));
    expect(find.text('16 pieces'), findsNWidgets(2));

    // 6. Verify timer ticks down for Lime player whose turn it is
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('04:58'), findsOneWidget);
    expect(find.text('05:00'), findsOneWidget);

    // Return to home
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
  });

  testWidgets('Pass & Play (2 Players) mode removes Erase all, Erase, and Save buttons, and displays player timers', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const RekGameApp());
    await tester.pumpAndSettle();

    // 1. Tap "Pass & Play (2 Players)"
    await tester.tap(find.text('Pass & Play (2 Players)'));
    await tester.pumpAndSettle();

    // Verify timer options are shown in the bottom modal sheet
    expect(find.text('5 mn'), findsOneWidget);
    expect(find.text('15 mn'), findsOneWidget);
    expect(find.text('30 mn'), findsOneWidget);

    // Tap "Start Match" to launch game
    await tester.tap(find.text('Start Match'));
    await tester.pumpAndSettle();

    // 2. Verify Erase all, Erase, and Save buttons are NOT present
    expect(find.text('Erase all'), findsNothing);
    expect(find.text('Erase'), findsNothing);
    expect(find.text('Save'), findsNothing);

    // 3. Verify Rotate Baord, Play, Back arrow ARE present
    expect(find.text('Rotate Baord'), findsOneWidget);
    expect(find.text('Play'), findsOneWidget);

    // 4. Verify Player Timers are displayed with default 5mn (05:00)
    expect(find.text('05:00'), findsNWidgets(2));
    expect(find.text('16 pieces'), findsNWidgets(2));

    // Return to home
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
  });

  testWidgets('Player can choose 5mn, 15mn, and 30mn timer before starting match and change mid-game', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const RekGameApp());
    await tester.pumpAndSettle();

    // 1. Open Pass & Play picker
    await tester.tap(find.text('Pass & Play (2 Players)'));
    await tester.pumpAndSettle();

    // 2. Verify 5 mn, 15 mn, 30 mn chips exist
    expect(find.text('5 mn'), findsOneWidget);
    expect(find.text('15 mn'), findsOneWidget);
    expect(find.text('30 mn'), findsOneWidget);

    // 3. Select 15 mn
    await tester.tap(find.text('15 mn'));
    await tester.pumpAndSettle();

    // Start match
    await tester.tap(find.text('Start Match'));
    await tester.pumpAndSettle();

    // 4. Verify timers start at 15:00
    expect(find.text('15:00'), findsNWidgets(2));

    // 5. Tap on the Lime timer card to open in-game timer control picker
    await tester.tap(find.text('15:00').last);
    await tester.pumpAndSettle();

    // In modal, choose 30 mn option
    expect(find.text('30 mn (Long)'), findsOneWidget);
    await tester.tap(find.text('30 mn (Long)'));
    await tester.pumpAndSettle();

    // 6. Verify timers update to 30:00
    expect(find.text('30:00'), findsNWidgets(2));

    // Return to home
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
  });

  testWidgets('Player wins and earns points test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await UserService.instance.resetPoints();
    expect(UserService.instance.points, equals(0));
    expect(UserService.instance.wins, equals(0));

    // Award points
    await UserService.instance.addWinPoints(100);
    expect(UserService.instance.points, equals(100));
    expect(UserService.instance.wins, equals(1));

    await tester.pumpWidget(const RekGameApp());
    await tester.pumpAndSettle();

    // 1. Verify username button and point button appear on top bar
    expect(find.text(UserService.instance.username), findsOneWidget);
    expect(find.text('100'), findsOneWidget);

    // 2. Open Profile dialog using username button
    await tester.tap(find.text(UserService.instance.username));
    await tester.pumpAndSettle();

    // Verify Profile dialog opens cleanly for username & avatar editing
    expect(find.text('Edit Player Profile'), findsOneWidget);

    // Close profile dialog
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    // 3. Open dedicated Points Dialog using point button
    await tester.tap(find.text('100'));
    await tester.pumpAndSettle();

    // Verify Points & Rewards dialog is shown
    expect(find.text('Points & Rewards'), findsOneWidget);
    expect(find.text('Total Score'), findsOneWidget);
    expect(find.text('1 wins'), findsOneWidget);

    // Close points dialog
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
  });

  testWidgets('Cancel game warning dialog test: Cancel keeps playing, OK cancels and returns to home', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await LanguageService.instance.setLanguage(AppLanguage.english);

    await tester.pumpWidget(const RekGameApp());
    await tester.pumpAndSettle();

    // 1. Start match vs AI
    await tester.tap(find.text('Play vs AI'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start Match'));
    await tester.pumpAndSettle();

    // 2. Verify we are in the game
    expect(find.text('05:00'), findsNWidgets(2));

    // 3. Attempt to cancel the game by tapping yellow back arrow
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    // 4. Verify Warning alert is formed
    expect(find.text('Warning'), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    expect(find.text('Are you sure you want to cancel the game? Current game progress will be lost.'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('OK'), findsOneWidget);

    // 5. Click "Cancel" ("not click cancle" -> does NOT cancel the game)
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // Verify warning dialog dismissed and we are STILL in the match!
    expect(find.text('Warning'), findsNothing);
    expect(find.text('05:00'), findsNWidgets(2));

    // 6. Attempt to cancel the game again
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('Warning'), findsOneWidget);

    // 7. Click "OK" ("if ok click ok" -> confirms cancel and returns home)
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    // Verify match is cancelled and returned to Home Page
    expect(find.text('CAMBODIAN REK CHESS'), findsOneWidget);
    expect(find.text('Play vs AI'), findsOneWidget);

    // 8. Test Khmer language localization
    await LanguageService.instance.setLanguage(AppLanguage.khmer);
    await tester.pumpAndSettle();

    await tester.tap(find.text('លេងជាមួយ AI'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ចាប់ផ្តើមលេង'));
    await tester.pumpAndSettle();

    // Tap back arrow to cancel game in Khmer
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    // Verify Khmer warning alert
    expect(find.text('ការព្រមាន'), findsOneWidget);
    expect(find.text('បោះបង់'), findsOneWidget); // Cancel
    expect(find.text('យល់ព្រម'), findsOneWidget); // OK

    // Tap Cancel in Khmer
    await tester.tap(find.text('បោះបង់'));
    await tester.pumpAndSettle();
    expect(find.text('ការព្រមាន'), findsNothing);

    // Tap back again and confirm with OK in Khmer
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    await tester.tap(find.text('យល់ព្រម'));
    await tester.pumpAndSettle();

    // Back to Home screen in Khmer
    expect(find.text('ល្បែងរែក'), findsOneWidget);
  });

  testWidgets('When not in app game, music is closed/paused; when returned, music resumes', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const RekGameApp());
    await tester.pumpAndSettle();

    // 1. Initially in the app foreground
    expect(AudioService.instance.isAppInBackground, isFalse);

    // 2. User minimizes or leaves the app (paused)
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pumpAndSettle();

    // Verify music is closed and marked in background
    expect(AudioService.instance.isAppInBackground, isTrue);
    expect(AudioService.instance.isPlayingBgm, isFalse);

    // 3. User returns to the app (resumed)
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    // Verify app marked foreground
    expect(AudioService.instance.isAppInBackground, isFalse);

    // 4. Test inactive state (e.g. app switcher, incoming call, or window focus lost)
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pumpAndSettle();

    expect(AudioService.instance.isAppInBackground, isTrue);
    expect(AudioService.instance.isPlayingBgm, isFalse);

    // Return to app again
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(AudioService.instance.isAppInBackground, isFalse);
  });

  testWidgets('App displays Game Rek title and logo emblem on HomeScreen', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const RekGameApp());
    await tester.pumpAndSettle();

    // Verify "GAME REK" title is rendered prominently
    expect(find.text('GAME REK'), findsOneWidget);

    // Verify logo asset is present in the hero emblem
    final logoFinder = find.byWidgetPredicate(
      (widget) => widget is Image && widget.image is AssetImage && (widget.image as AssetImage).assetName == 'assets/images/logo.png',
    );
    expect(logoFinder, findsOneWidget);
  });

  testWidgets('Tapping hero board emblem opens Interactive Board Dialog with playable WoodBoard', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await LanguageService.instance.setLanguage(AppLanguage.english);

    await tester.pumpWidget(const RekGameApp());
    await tester.pumpAndSettle();

    // Verify touch hand point icon is deleted/not present on the emblem
    expect(find.byIcon(Icons.touch_app), findsNothing);

    // Tap the hero board emblem
    await tester.tap(find.byType(Image).first);
    await tester.pumpAndSettle();

    // Verify Interactive Board Dialog opened
    expect(find.text('Interactive Rek Board'), findsOneWidget);
    expect(find.text('Lime Turn'), findsOneWidget);
    expect(find.text('Rotate Baord'), findsOneWidget);
    expect(find.text('Start Match'), findsOneWidget);

    // Tap Rotate Baord
    await tester.tap(find.text('Rotate Baord'));
    await tester.pumpAndSettle();

    // Close the interactive dialog
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    // Back on HomeScreen
    expect(find.text('GAME REK'), findsOneWidget);
  });

  testWidgets('In game, when game over alert appears, clicking Close returns to home page to start again', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await LanguageService.instance.setLanguage(AppLanguage.english);

    // Prepare a board state where Lime can win on move 1 via Rek capture
    // (0, 0) Teal King, (0, 2) Teal piece, (1, 1) Lime piece, (7, 0) Lime King
    final winningBoard = List.generate(8, (_) => List<RekPiece?>.filled(8, null));
    winningBoard[7][0] = const RekPiece(id: 'l_k', player: PlayerColor.lime, type: PieceType.crowned);
    winningBoard[1][1] = const RekPiece(id: 'l_p1', player: PlayerColor.lime, type: PieceType.plain);
    winningBoard[0][0] = const RekPiece(id: 't_k', player: PlayerColor.teal, type: PieceType.crowned);
    winningBoard[0][2] = const RekPiece(id: 't_p1', player: PlayerColor.teal, type: PieceType.plain);

    final state = SavedGameState(
      id: 'test_win',
      name: 'Test Win',
      timestamp: DateTime.now(),
      board: winningBoard,
      currentTurn: PlayerColor.lime,
      isPlayMode: true,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: HomeScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify on HomeScreen
    expect(find.text('GAME REK'), findsOneWidget);

    // Push RekGameScreen with the near-win setup
    final BuildContext homeContext = tester.element(find.text('GAME REK'));
    Navigator.of(homeContext).push(
      MaterialPageRoute(
        builder: (_) => RekGameScreen(
          startInPlayMode: true,
          vsAi: false,
          initialSavedState: state,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Find squares in the WoodBoard
    final boardSquares = find.descendant(
      of: find.byType(WoodBoard),
      matching: find.byType(GestureDetector),
    );

    // Tap piece at (1, 1) -> index 1 * 8 + 1 = 9
    await tester.tap(boardSquares.at(9));
    await tester.pumpAndSettle();

    // Tap destination at (0, 1) -> index 0 * 8 + 1 = 1
    // This places Lime at (0, 1) between (0, 0) Teal and (0, 2) Teal!
    await tester.tap(boardSquares.at(1));
    await tester.pumpAndSettle();

    // Verify Game Over alert dialog is visible
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);
    expect(find.text('Play Again'), findsOneWidget);

    // Tap "Close" on the alert dialog
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    // Verify we are back on the HomeScreen to start again
    expect(find.text('GAME REK'), findsOneWidget);
    expect(find.text('Play vs AI'), findsOneWidget);
    expect(find.text('Pass & Play (2 Players)'), findsOneWidget);
  });

  testWidgets('User can tap anywhere in the whole box (corners/edges, not just center) to place piece and move', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: HomeScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Start a Pass & Play match
    await tester.tap(find.text('Pass & Play (2 Players)'));
    await tester.pumpAndSettle();

    // Start match from timer modal
    await tester.tap(find.text('Start Match'));
    await tester.pumpAndSettle();

    final boardSquares = find.descendant(
      of: find.byType(WoodBoard),
      matching: find.byType(GestureDetector),
    );

    // Initial Lime pieces are at row 5 (cols 0..7) -> index 5*8 + 0 = 40
    // Tap Lime piece at (5, 0)
    await tester.tap(boardSquares.at(40));
    await tester.pumpAndSettle();

    // Destination (4, 0) -> index 4*8 + 0 = 32 is a legal move
    // Tap specifically at the top-left edge/corner of square (4, 0), NOT the center green point!
    final topLeftCorner = tester.getTopLeft(boardSquares.at(32)) + const Offset(3.0, 3.0);
    await tester.tapAt(topLeftCorner);
    await tester.pumpAndSettle();

    // Verify move succeeded: piece is now moved to square (4, 0)
    // and it is now Player 2 (Teal)'s turn
    expect(find.textContaining('Player 2'), findsWidgets);
  });

  testWidgets('Players can choose between Rek and Call options in Play vs AI and Pass & Play modals', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const RekGameApp());
    await tester.pumpAndSettle();

    // 1. Open Pass & Play picker
    await tester.tap(find.text('Pass & Play (2 Players)'));
    await tester.pumpAndSettle();

    // Verify "Select Play Option" header, and both "Rek" and "Call" options are displayed
    expect(find.text('Select Play Option'), findsOneWidget);
    expect(find.text('Rek'), findsOneWidget);
    expect(find.text('Call'), findsOneWidget);
    expect(find.text('Optional capture'), findsOneWidget);
    expect(find.text('Mandatory capture'), findsOneWidget);

    // Select Rek option
    await tester.tap(find.text('Rek'));
    await tester.pumpAndSettle();

    // Start match
    await tester.tap(find.text('Start Match'));
    await tester.pumpAndSettle();

    // Verify the in-game badge displays Rek mode
    expect(find.text('🎯 Rek'), findsOneWidget);

    // Return to home
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('Warning'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    // 2. Open Play vs AI picker
    await tester.tap(find.text('Play vs AI'));
    await tester.pumpAndSettle();

    // Verify both options also present in AI setup
    expect(find.text('Select Play Option'), findsOneWidget);
    expect(find.text('Rek'), findsOneWidget);
    expect(find.text('Call'), findsOneWidget);

    // Select Call option
    await tester.tap(find.text('Call'));
    await tester.pumpAndSettle();

    // Start match
    await tester.tap(find.text('Start Match'));
    await tester.pumpAndSettle();

    // Verify in-game badge displays Call mode
    expect(find.text('⚡ Call'), findsOneWidget);

    // Return to home
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('Warning'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  });

  testWidgets('Call/Hao button allows players to call opponent to Rek with interactive alert and strict capture obligation', (WidgetTester tester) async {
    await tester.pumpWidget(const RekGameApp());
    await tester.pumpAndSettle();

    // 1. Open Pass & Play modal
    await tester.tap(find.text('Pass & Play (2 Players)'));
    await tester.pumpAndSettle();

    // 2. Select "Call" option and start match
    await tester.tap(find.text('Call'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start Match'));
    await tester.pumpAndSettle();

    // 3. Verify Call buttons are present in the game UI (PlayerTimerCards, Banner, and Menu bar)
    expect(find.text('Call'), findsWidgets);
    expect(find.textContaining('Call'), findsWidgets);

    // 4. Tap the Call button on the initial board (where no immediate Rek capture is open)
    final callButtons = find.text('Call');
    await tester.tap(callButtons.first);
    await tester.pumpAndSettle();

    // Should indicate no Rek opening is available to call
    expect(find.textContaining('No Rek opening available'), findsOneWidget);

    // 5. Test with an active Rek capture scenario using RekGameScreen directly
    // Setup a board where Lime has baited Teal into a Rek capture
    final trapBoard = List.generate(8, (_) => List<RekPiece?>.filled(8, null));
    // Teal piece at (3, 3)
    trapBoard[3][3] = const RekPiece(id: 't1', player: PlayerColor.teal, type: PieceType.plain);
    // Lime piece at (3, 2)
    trapBoard[3][2] = const RekPiece(id: 'l1', player: PlayerColor.lime, type: PieceType.plain);
    // Lime piece at (3, 4)
    trapBoard[3][4] = const RekPiece(id: 'l2', player: PlayerColor.lime, type: PieceType.plain);
    // Teal pieces at (3, 3) is caught in a Rek sandwich!
    // But let's give Teal a piece at (4, 3) that can slide to (3, 3)...
    // Better: Lime piece at (3, 2), Lime piece at (3, 4). Teal piece at (1, 3).
    // When Teal moves from (1, 3) to (3, 3), Teal sandwiches Lime (3, 2) and (3, 4)!
    // Wait: Rek sandwiches opponent pieces. If Teal moves between two Lime pieces (3, 2) and (3, 4), Teal captures both Lime pieces!
    final callBoard = List.generate(8, (_) => List<RekPiece?>.filled(8, null));
    callBoard[3][2] = const RekPiece(id: 'l1', player: PlayerColor.lime, type: PieceType.plain);
    callBoard[3][4] = const RekPiece(id: 'l2', player: PlayerColor.lime, type: PieceType.plain);
    // Teal piece at (1, 3) can slide south to (3, 3) and capture Lime at (3, 2) and (3, 4)!
    callBoard[1][3] = const RekPiece(id: 't1', player: PlayerColor.teal, type: PieceType.plain);
    // Also give Teal another piece at (0, 0) that cannot capture
    callBoard[0][0] = const RekPiece(id: 't2', player: PlayerColor.teal, type: PieceType.plain);
    // Give Lime a king/piece so game is not over
    callBoard[7][7] = const RekPiece(id: 'lk', player: PlayerColor.lime, type: PieceType.crowned);
    callBoard[0][7] = const RekPiece(id: 'tk', player: PlayerColor.teal, type: PieceType.crowned);

    await tester.pumpWidget(MaterialApp(
      home: RekGameScreen(
        startInPlayMode: true,
        vsAi: false,
        ruleMode: RekRuleMode.hao,
        initialSavedState: SavedGameState(
          id: 'test_call',
          name: 'Test Call',
          timestamp: DateTime.now(),
          board: callBoard,
          currentTurn: PlayerColor.teal,
          isPlayMode: true,
          ruleMode: RekRuleMode.hao,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    // 5a. Before Call button is clicked:
    // Capturing is OPTIONAL. Teal can select non-capturing piece at (0, 0).
    final boardSquares = find.descendant(
      of: find.byType(WoodBoard),
      matching: find.byType(GestureDetector),
    );

    // Tap piece at (0, 0) (index 0)
    await tester.tap(boardSquares.at(0));
    await tester.pumpAndSettle();

    // Verify it is selected without error (no "Must capture! Cannot evade" message)
    expect(find.textContaining('Cannot evade'), findsNothing);

    // Deselect (tap square (0, 0) or tap outside)
    await tester.tap(boardSquares.at(0));
    await tester.pumpAndSettle();

    // 5b. Opponent taps Call button to obligate Teal to capture!
    final bannerCallBtn = find.text('Call');
    expect(bannerCallBtn, findsWidgets);
    await tester.tap(bannerCallBtn.first);
    await tester.pumpAndSettle();

    // Check notification confirms CALL was made!
    expect(find.textContaining('must capture with Rek'), findsOneWidget);

    // 5c. After Call is activated:
    // Tapping the non-capturing piece at (0, 0) is blocked!
    await tester.tap(boardSquares.at(0));
    await tester.pumpAndSettle();
    expect(find.textContaining('Must capture! Cannot evade'), findsOneWidget);

    // 5d. Tapping the capturing piece at (1, 3) (index 1*8 + 3 = 11) is allowed
    await tester.tap(boardSquares.at(11));
    await tester.pumpAndSettle();

    // Tap target destination (3, 3) (index 3*8 + 3 = 27)
    await tester.tap(boardSquares.at(27));
    await tester.pumpAndSettle();

    // Notification confirms Rek capture
    expect(find.textContaining('REK'), findsOneWidget);

    // In RekRules:
    final capturingMoves = RekRules.getCapturingMoves(callBoard, PlayerColor.teal);
    expect(capturingMoves.isNotEmpty, isTrue);
    expect(capturingMoves.first.to, equals(const BoardPosition(3, 3)));
  });
}


