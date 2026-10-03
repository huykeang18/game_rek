import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage {
  english('en', 'English', '🇬🇧'),
  khmer('km', 'ភាសាខ្មែរ', '🇰🇭');

  final String code;
  final String label;
  final String flag;

  const AppLanguage(this.code, this.label, this.flag);
}

class LanguageService extends ChangeNotifier {
  static final LanguageService _instance = LanguageService._internal();
  factory LanguageService() => _instance;
  static LanguageService get instance => _instance;

  LanguageService._internal();

  static const String _keyLanguage = 'rek_app_language';
  AppLanguage _currentLanguage = AppLanguage.english;
  bool _initialized = false;

  AppLanguage get currentLanguage => _currentLanguage;
  bool get isKhmer => _currentLanguage == AppLanguage.khmer;
  bool get isEnglish => _currentLanguage == AppLanguage.english;
  bool get isInitialized => _initialized;

  Future<void> init() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_keyLanguage);
      if (code == 'km') {
        _currentLanguage = AppLanguage.khmer;
      } else {
        _currentLanguage = AppLanguage.english;
      }
      _initialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('LanguageService init error: $e');
      _currentLanguage = AppLanguage.english;
      _initialized = true;
    }
  }

  Future<void> setLanguage(AppLanguage language) async {
    if (_currentLanguage == language) return;
    _currentLanguage = language;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLanguage, language.code);
    } catch (e) {
      debugPrint('Error saving language preference: $e');
    }
  }

  Future<void> toggleLanguage() async {
    final next = isEnglish ? AppLanguage.khmer : AppLanguage.english;
    await setLanguage(next);
  }

  // --- Localized Strings Dictionary ---

  // App Titles
  String get khmerTitle => 'ល្បែងរែក';
  String get englishTitle => 'CAMBODIAN REK CHESS';
  String get appSubtitle => isKhmer
      ? 'ល្បែងក្តារប្រពៃណីខ្មែរ និងឧបករណ៍រៀបចំក្តារ'
      : 'Traditional Khmer Board Game & Board Editor';
  String get appDescription => isKhmer
      ? 'ល្បែងប្រពៃណីវប្បធម៌ខ្មែរ\nដើរផ្លូវត្រង់៨×៨ និងស៊ីរែកសងខាង'
      : 'Traditional Cambodian Cultural Game\n8×8 Rook Moves & Shoulder-Pole Captures';

  // Home Menu Cards
  String get playVsAiTitle => isKhmer ? 'លេងជាមួយ AI' : 'Play vs AI';
  String playVsAiSubtitle(String diff) => isKhmer
      ? 'លេងម្នាក់ឯងទល់នឹងកុំព្យូទ័រ (${diff.toUpperCase()})'
      : 'Single player vs Computer (${diff.toUpperCase()})';

  String get passAndPlayTitle => isKhmer ? 'លេង២នាក់ (ឧបករណ៍តែមួយ)' : 'Pass & Play (2 Players)';
  String get passAndPlaySubtitle => isKhmer
      ? 'លេងជាមួយមិត្តភក្តិនៅលើទូរស័ព្ទជាមួយគ្នា'
      : 'Play locally against a friend on one device';

  String get boardSetupTitle => isKhmer ? 'រៀបចំ និងកែសម្រួលក្តារ' : 'Board Setup & Editor';
  String get boardSetupSubtitle => isKhmer
      ? 'រៀបចំកូនអុកដោយសេរី បង្វិលក្តារ និងលុប'
      : 'Custom setup with Erase, Rotate Baord & Selectors';

  String get rulesAndGuideTitle => isKhmer ? 'ច្បាប់លេង និងការណែនាំ' : 'Rules & Guide';
  String get rulesAndGuideSubtitle => isKhmer
      ? 'ស្វែងយល់ពីរបៀបស៊ីរែក និងយុទ្ធសាស្ត្រ'
      : 'Learn Rek shoulder-pole captures & tactics';

  // Difficulty Modal
  String get selectAiDifficulty => isKhmer ? 'ជ្រើសរើសកម្រិត AI' : 'Select AI Difficulty';
  String get easyDifficulty => isKhmer ? 'ងាយស្រួល' : 'Easy';
  String get easyDifficultyDesc => isKhmer
      ? 'លេងធម្មតា AI រកមើលតែការស៊ីសាមញ្ញ'
      : 'Casual play with basic capture detection';
  String get mediumDifficulty => isKhmer ? 'មធ្យម (លំនឹង)' : 'Medium (Balanced)';
  String get mediumDifficultyDesc => isKhmer
      ? 'យុទ្ធសាស្ត្រស៊ីរែក និងការពារស្តេច'
      : 'Tactical Rek captures and King safety evaluation';
  String get hardDifficulty => isKhmer ? 'កម្រិតខ្ពស់ / ពិបាក' : 'Master / Hard';
  String get hardDifficultyDesc => isKhmer
      ? 'គិតស៊ីជម្រៅដោយ Minimax និង Alpha-Beta'
      : 'Deep 2-ply minimax search with alpha-beta pruning';
  // Play Options (Rek vs Call)
  String get selectGameMode => isKhmer ? 'ជ្រើសរើសរបៀបលេង' : 'Select Play Option';
  String get modeRekTitle => isKhmer ? 'រែក (Rek)' : 'Rek';
  String get modeRekSubtitle => isKhmer ? 'ស៊ីធម្មតា (មិនបង្ខំ)' : 'Optional capture';
  String get modeRekDesc => isKhmer
      ? 'ស៊ីរែកធម្មតា (មិនបង្ខំស៊ី) - អ្នកលេងមានសេរីភាពដើរកូនអុកណាក៏បាន'
      : 'Standard Rek: Capturing is optional. Free to move any piece.';
  String get modeCallTitle => isKhmer ? 'ហៅ (Call)' : 'Call';
  String get modeCallSubtitle => isKhmer ? 'បង្ខំស៊ី (ដាច់ខាត)' : 'Mandatory capture';
  String get modeCallDesc => isKhmer
      ? 'ច្បាប់ហៅ (បង្ខំស៊ី) - បើគូប្រកួតបើកផ្លូវស៊ី ត្រូវតែស៊ីដាច់ខាត'
      : 'Strict Call: Capturing is mandatory when an opening or trap exists.';
  String get ruleModeBadgeRek => isKhmer ? '🎯 រែក' : '🎯 Rek';
  String get ruleModeBadgeCall => isKhmer ? '⚡ ហៅ' : '⚡ Call';

  // Compatibility aliases
  String get modeHaoTitle => modeCallTitle;
  String get modeHaoSubtitle => modeCallSubtitle;
  String get modeHaoDesc => modeCallDesc;
  String get ruleModeBadgeHao => ruleModeBadgeCall;
  String get gameModeLabel => isKhmer ? 'របៀបលេង' : 'Play Mode';

  String get startMatch => isKhmer ? 'ចាប់ផ្តើមលេង' : 'Start Match';

  // Top Menu Buttons (preserving exact requested English spelling)
  String get eraseAll => isKhmer ? 'លុបទាំងអស់' : 'Erase all';
  String get erase => isKhmer ? 'លុប' : 'Erase';
  String get rotateBoard => isKhmer ? 'បង្វិលក្តារ' : 'Rotate Baord';

  // Bottom Menu Buttons
  String get save => isKhmer ? 'រក្សាទុក' : 'Save';
  String get play => isKhmer ? 'លេង' : 'Play';

  // Status Banner
  String get setupModeHint => isKhmer
      ? 'ទម្រង់រៀបចំក្តារ៖ ចុចលើកូនអុកដើម្បីជ្រើសរើស ចុចលើក្តារដើម្បីដាក់ ឬលុប'
      : 'Board Setup Mode: Tap tokens to select, tap board to place/erase';
  String get turn => isKhmer ? 'វេន' : 'Turn';
  String get aiTeal => isKhmer ? '🤖 AI (បៃតងចាស់)' : '🤖 AI (TEAL)';
  String get p2Teal => isKhmer ? '👥 អ្នកលេងទី២ (បៃតងចាស់)' : '👥 P2 (TEAL)';
  String limePlayer(String avatar, String name) => isKhmer
      ? '$avatar $name (បៃតងខ្ចី)'
      : '$avatar $name (LIME)';

  // Game Over
  String wins(String name) => isKhmer ? '$name ឈ្នះ!' : '$name WINS!';
  String get playAgain => isKhmer ? 'លេងម្តងទៀត' : 'Play Again';
  String get close => isKhmer ? 'បិទ' : 'Close';
  String get kingCannotMove => isKhmer
      ? '👑 មេ (King) ស្ថិតនៅមួយកន្លែងមិនអាចដើរបានទេ!'
      : '👑 The King (Me) is fixed in place and cannot move!';

  // Cancel / Quit Game Warning Dialog
  String get warning => isKhmer ? 'ការព្រមាន' : 'Warning';
  String get cancelGameWarning => isKhmer
      ? 'តើអ្នកពិតជាចង់បោះបង់ការប្រកួត ហើយចាកចេញមែនទេ? ការលេងបច្ចុប្បន្ននឹងត្រូវបាត់បង់។'
      : 'Are you sure you want to cancel the game? Current game progress will be lost.';
  String get ok => isKhmer ? 'យល់ព្រម' : 'OK';

  // Settings & Audio Dialog
  String get settingsAndAudio => isKhmer ? 'ការកំណត់ & សំឡេង' : 'Settings & Audio';
  String get languageSection => isKhmer ? 'ភាសា / Language' : 'Language / ភាសា';
  String get selectLanguage => isKhmer ? 'ជ្រើសរើសភាសា' : 'Select Language';
  String get playerUsername => isKhmer ? 'ឈ្មោះអ្នកលេង' : 'Player Username';
  String get edit => isKhmer ? 'កែប្រែ' : 'Edit';
  String get bgmSection => isKhmer ? 'តន្ត្រីផ្ទៃខាងក្រោយ (BGM)' : 'Background Music (BGM)';
  String get enableMusic => isKhmer ? 'បើកតន្ត្រី' : 'Enable Music';
  String get musicPlayingSub => isKhmer ? 'កំពុងចាក់បទភ្លេងប្រពៃណី' : 'Playing traditional soundtrack';
  String get musicMutedSub => isKhmer ? 'បានបិទសំឡេង' : 'Muted';
  String get selectTrack => isKhmer ? 'ជ្រើសរើសបទភ្លេង' : 'Select Soundtrack Track';
  String get bgmVolume => isKhmer ? 'កម្រិតសំឡេងតន្ត្រី' : 'BGM Volume';
  String get sfxSection => isKhmer ? 'សំឡេងបញ្ជា (SFX)' : 'Sound Effects (SFX)';
  String get sfxSwitch => isKhmer ? 'សំឡេងដើរកូនអុក និងស៊ីរែក' : 'Move & Rek Capture Sounds';
  String get sfxActiveSub => isKhmer ? 'សំឡេងគោះកូនអុក ស៊ីរែក និងជ័យជម្នះ' : 'Clacks, captures & fanfare active';
  String get sfxVolume => isKhmer ? 'កម្រិតសំឡេង SFX' : 'SFX Volume';
  String get testMove => isKhmer ? 'សាកល្បងដើរ' : 'Test Move';
  String get testCapture => isKhmer ? 'សាកល្បងរែក' : 'Test Rek';
  String get testTrap => isKhmer ? 'សាកល្បងខាត់' : 'Test Khat';
  String get testWin => isKhmer ? 'សាកល្បងឈ្នះ' : 'Test Win';
  String get testDefeat => isKhmer ? 'សាកល្បងចាញ់' : 'Test Defeat';
  String get testRotate => isKhmer ? 'បង្វិលក្តារ' : 'Test Rotate';
  String get done => isKhmer ? 'រួចរាល់' : 'Done';

  // Profile Edit Dialog
  String get editProfileTitle => isKhmer ? 'កែប្រែព័ត៌មានអ្នកលេង' : 'Edit Player Profile';
  String get editProfileSubtitle => isKhmer ? 'កំណត់ឈ្មោះ និងរូបតំណាងរបស់អ្នក' : 'Customize your name & avatar';
  String get chooseAvatar => isKhmer ? 'ជ្រើសរើសរូបតំណាង' : 'Choose Avatar';
  String get enterUsernameHint => isKhmer ? 'បញ្ចូលឈ្មោះអ្នកលេង...' : 'Enter username...';
  String get suggested => isKhmer ? 'ឈ្មោះណែនាំ៖' : 'Suggested:';
  String get cancel => isKhmer ? 'បោះបង់' : 'Cancel';
  String get saveProfile => isKhmer ? 'រក្សាទុក' : 'Save Profile';
  String get usernameEmptyError => isKhmer ? 'ឈ្មោះមិនអាចទទេបានទេ' : 'Username cannot be empty';
  String get usernameLengthError => isKhmer ? 'ឈ្មោះត្រូវមានយ៉ាងតិច ២ តួអក្សរ' : 'Name must be at least 2 characters';

  // In-Game Chat Menu
  String get musicSettingsTitle => isKhmer ? 'ការកំណត់តន្ត្រី និងសំឡេង' : 'Music & Audio Settings';
  String get musicSettingsSubtitle => isKhmer ? 'កម្រិតសំឡេង បទភ្លេង និង SFX' : 'Soundtrack tracks, volume & effects';
  String get changeProfileTitle => isKhmer ? 'ប្តូរឈ្មោះ និងរូបតំណាង' : 'Change Username & Avatar';
  String get rulesAndHistoryTitle => isKhmer ? 'ច្បាប់លេង និងប្រវត្តិក្បាច់ដើរ' : 'Rules & Move History';
  String movesPlayed(int count) => isKhmer ? 'បានដើរ $count ក្បាច់' : '$count moves played';
  String get resetBoardTitle => isKhmer ? 'រៀបចំក្តារឡើងវិញ' : 'Reset Board';
  String get resetBoardSubtitle => isKhmer ? 'ត្រឡប់ទៅការរៀបចំដើមនៃល្បែងរែក' : 'Reset back to standard Rek setup';

  // Match Timer Strings
  String get timerSettings => isKhmer ? 'កំណត់ម៉ោងលេង' : 'Match Timer';
  String get timerSettingsSub => isKhmer ? 'កំណត់រយៈពេលគិតសម្រាប់អ្នកលេងម្នាក់ៗ' : 'Choose time control per player';
  String get selectTimer => isKhmer ? 'ម៉ោងលេង' : 'Match Timer';
  String get timer5Mn => isKhmer ? '៥ នាទី (5 mn)' : '5 mn (Standard)';
  String get timer15Mn => isKhmer ? '១៥ នាទី (15 mn)' : '15 mn (Medium)';
  String get timer30Mn => isKhmer ? '៣០ នាទី (30 mn)' : '30 mn (Long)';
  String get timer3Min => isKhmer ? '៣ នាទី (លឿន)' : '3 Minutes (Blitz)';
  String get timer5Min => isKhmer ? '៥ នាទី (ស្តង់ដារ)' : '5 Minutes (Standard)';
  String get timer10Min => isKhmer ? '១០ នាទី (បុរាណ)' : '10 Minutes (Classical)';
  String get timerUnlimited => isKhmer ? 'គ្មានកំណត់ (រាប់ឡើង)' : 'Unlimited (Count Up)';
  String get piecesWord => isKhmer ? 'កូនអុក' : 'pieces';
  String timeOutLoss(String player) => isKhmer
      ? '$player បានអស់ពេលកំណត់!'
      : '$player ran out of time!';

  // Points & Rewards Strings
  String get pointsLabel => isKhmer ? 'ពិន្ទុ' : 'Points';
  String pointsCount(int pts) => isKhmer ? '$pts ពិន្ទុ' : '$pts pts';
  String pointsEarned(int pts) => isKhmer ? '+$pts ពិន្ទុ!' : '+$pts Points!';
  String get victoryPoints => isKhmer ? 'ពិន្ទុជ័យជម្នះ' : 'Victory Reward';
  String get totalPointsTitle => isKhmer ? 'ពិន្ទុសរុប' : 'Total Score';
  String totalWinsCount(int wins) => isKhmer ? 'ឈ្នះ $wins ប្រកួត' : '$wins wins';
  String get playerStats => isKhmer ? 'ស្ថិតិលេង' : 'Player Stats';
  String get pointsDialogTitle => isKhmer ? 'ពិន្ទុ និងរង្វាន់' : 'Points & Rewards';
  String get rankTitle => isKhmer ? 'កម្រិតតំណែង' : 'Player Rank';
  String rankName(String rank) {
    if (!isKhmer) return rank;
    switch (rank) {
      case 'Grandmaster':
        return 'កំពូលជើងឯក';
      case 'Master':
        return 'ជើងឯក';
      case 'Apprentice':
        return 'អ្នកលេងស្ទាត់';
      default:
        return 'អ្នកចាប់ផ្តើម';
    }
  }
  String get howToEarnPointsTitle => isKhmer ? 'របៀបរកពិន្ទុ' : 'How to Earn Points';
  String get winVsAiEasy => isKhmer ? 'ឈ្នះ AI កម្រិតងាយ: +50 ពិន្ទុ' : 'Win vs AI (Easy): +50 pts';
  String get winVsAiMedium => isKhmer ? 'ឈ្នះ AI កម្រិតមធ្យម: +100 ពិន្ទុ' : 'Win vs AI (Medium): +100 pts';
  String get winVsAiHard => isKhmer ? 'ឈ្នះ AI កម្រិតពិបាក: +200 ពិន្ទុ' : 'Win vs AI (Hard): +200 pts';
  String get winPassAndPlay => isKhmer ? 'ឈ្នះ Pass & Play: +100 ពិន្ទុ' : 'Win Pass & Play: +100 pts';

  // Interactive Board Modal
  String get interactiveBoardTitle => isKhmer ? 'ក្ដារល្បែងរែកអន្តរកម្ម' : 'Interactive Rek Board';
  String get interactiveBoardSubtitle => isKhmer ? 'ចុចលើកូនអុកដើម្បីសាកល្បងដើរ និងស៊ីរែក' : 'Tap pieces to test moves & Rek captures';
  String get tapToInteractHint => isKhmer ? 'ចុចដើម្បីលេង' : 'Tap to interact';
}

