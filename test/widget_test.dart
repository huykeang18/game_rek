import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_rek/main.dart';
import 'package:game_rek/logic/rek_rules.dart';
import 'package:game_rek/models/rek_piece.dart';
import 'package:game_rek/services/user_service.dart';
import 'package:game_rek/services/language_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
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
    expect(find.text('១. ក្តារអុក & គោលដៅនៃការលេង'), findsOneWidget);
    expect(find.text('២. របៀបដើរកូនអុក (ដើរដូចទូកក្នុងអុក)'), findsOneWidget);
    expect(find.text('៣. ក្បាច់ស៊ីរែក (The "Rek" Shoulder-Pole Capture)'), findsOneWidget);
    expect(find.text('៤. ក្បាច់ព័ទ្ធស៊ី (ខាត់)'), findsOneWidget);
    expect(find.text('៥. ផ្ទាំងបញ្ជា និងឧបករណ៍រៀបចំក្តារ'), findsOneWidget);

    // Switch to English dynamically and verify update
    await LanguageService.instance.setLanguage(AppLanguage.english);
    await tester.pumpAndSettle();

    expect(find.text('1. Board & Objective'), findsOneWidget);
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
}
