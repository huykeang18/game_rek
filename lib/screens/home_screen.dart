import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/rek_piece.dart';
import '../logic/rek_rules.dart';
import '../logic/rek_ai.dart';
import '../logic/storage_service.dart';
import '../services/audio_service.dart';
import '../services/user_service.dart';
import '../services/language_service.dart';
import '../widgets/piece_token_widget.dart';
import '../widgets/profile_edit_dialog.dart';
import '../widgets/points_dialog.dart';
import '../widgets/rules_dialog.dart';
import '../widgets/settings_dialog.dart';
import '../widgets/language_button.dart';
import '../widgets/interactive_board_dialog.dart';
import 'rek_game_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  AiDifficulty _selectedDifficulty = AiDifficulty.medium;
  RekRuleMode _selectedRuleMode = RekRuleMode.hao;
  int _selectedTimerSeconds = 300;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _openSettings() {
    AudioService.instance.playClick();
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (_) => const SettingsDialog(),
    );
  }

  void _openProfile() {
    AudioService.instance.playClick();
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (_) => const ProfileEditDialog(),
    );
  }

  void _openPointsDialog() {
    AudioService.instance.playClick();
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (_) => const PointsDialog(),
    );
  }

  void _openInteractiveBoardDialog() {
    AudioService.instance.playClick();
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (_) => InteractiveBoardDialog(
        initialRuleMode: _selectedRuleMode,
        onStartMatch: ([RekRuleMode? mode]) => _navigateToGame(
          startInPlayMode: true,
          vsAi: true,
          ruleMode: mode ?? _selectedRuleMode,
          timeLimitSeconds: _selectedTimerSeconds,
        ),
      ),
    );
  }

  void _navigateToGame({
    bool startInPlayMode = false,
    bool vsAi = true,
    int timeLimitSeconds = 300,
    RekRuleMode? ruleMode,
    SavedGameState? initialSavedState,
  }) {
    AudioService.instance.playClick();
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RekGameScreen(
          startInPlayMode: startInPlayMode,
          vsAi: vsAi,
          aiDifficulty: _selectedDifficulty,
          ruleMode: ruleMode ?? _selectedRuleMode,
          initialSavedState: initialSavedState,
          initialTimeLimitSeconds: timeLimitSeconds,
        ),
      ),
    ).then((_) {
      if (AudioService.instance.bgmEnabled) {
        AudioService.instance.ensureBgmPlaying();
      }
    });
  }

  void _showRules() {
    AudioService.instance.playClick();
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (_) => const RulesDialog(moveHistory: []),
    );
  }

  void _showAiDifficultyPicker() {
    AudioService.instance.playClick();
    final lang = LanguageService.instance;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF263238),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: StatefulBuilder(
            builder: (context, setModalState) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lang.selectAiDifficulty,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),
                _buildDifficultyOption(
                  setModalState,
                  AiDifficulty.easy,
                  lang.easyDifficulty,
                  lang.easyDifficultyDesc,
                ),
                _buildDifficultyOption(
                  setModalState,
                  AiDifficulty.medium,
                  lang.mediumDifficulty,
                  lang.mediumDifficultyDesc,
                ),
                _buildDifficultyOption(
                  setModalState,
                  AiDifficulty.hard,
                  lang.hardDifficulty,
                  lang.hardDifficultyDesc,
                ),
                const SizedBox(height: 16),
                _buildRuleModeSelector(
                  setModalState,
                  _selectedRuleMode,
                  (mode) {
                    setModalState(() => _selectedRuleMode = mode);
                    setState(() => _selectedRuleMode = mode);
                  },
                  lang,
                ),
                const SizedBox(height: 16),
                _buildTimerSelector(
                  setModalState,
                  _selectedTimerSeconds,
                  (sec) {
                    setModalState(() => _selectedTimerSeconds = sec);
                    setState(() => _selectedTimerSeconds = sec);
                  },
                  lang,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _navigateToGame(
                        startInPlayMode: true,
                        vsAi: true,
                        ruleMode: _selectedRuleMode,
                        timeLimitSeconds: _selectedTimerSeconds,
                      );
                    },
                    child: Text(
                      lang.startMatch,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPassAndPlayPicker() {
    AudioService.instance.playClick();
    final lang = LanguageService.instance;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF263238),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: StatefulBuilder(
            builder: (context, setModalState) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4DB6AC).withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.people_outline, color: Color(0xFF4DB6AC), size: 22),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lang.passAndPlayTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            lang.passAndPlaySubtitle,
                            style: const TextStyle(color: Colors.white60, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _buildRuleModeSelector(
                  setModalState,
                  _selectedRuleMode,
                  (mode) {
                    setModalState(() => _selectedRuleMode = mode);
                    setState(() => _selectedRuleMode = mode);
                  },
                  lang,
                ),
                const SizedBox(height: 16),
                _buildTimerSelector(
                  setModalState,
                  _selectedTimerSeconds,
                  (sec) {
                    setModalState(() => _selectedTimerSeconds = sec);
                    setState(() => _selectedTimerSeconds = sec);
                  },
                  lang,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00796B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _navigateToGame(
                        startInPlayMode: true,
                        vsAi: false,
                        ruleMode: _selectedRuleMode,
                        timeLimitSeconds: _selectedTimerSeconds,
                      );
                    },
                    child: Text(
                      lang.startMatch,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRuleModeSelector(
    StateSetter setModalState,
    RekRuleMode selectedMode,
    ValueChanged<RekRuleMode> onChanged,
    LanguageService lang,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.rule_folder_outlined, size: 16, color: Color(0xFFFFD54F)),
            const SizedBox(width: 6),
            Text(
              lang.selectGameMode,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Option 1: Rek Mode
            Expanded(
              child: InkWell(
                onTap: () {
                  AudioService.instance.playClick();
                  setModalState(() => onChanged(RekRuleMode.rek));
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  decoration: BoxDecoration(
                    color: selectedMode == RekRuleMode.rek
                        ? const Color(0xFF2E7D32).withValues(alpha: 0.35)
                        : const Color(0xFF1E272C),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selectedMode == RekRuleMode.rek
                          ? const Color(0xFF81C784)
                          : Colors.white12,
                      width: selectedMode == RekRuleMode.rek ? 1.8 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.sports_kabaddi,
                            size: 16,
                            color: selectedMode == RekRuleMode.rek
                                ? const Color(0xFF81C784)
                                : Colors.white60,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              lang.modeRekTitle,
                              style: TextStyle(
                                color: selectedMode == RekRuleMode.rek
                                    ? const Color(0xFF81C784)
                                    : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (selectedMode == RekRuleMode.rek)
                            const Icon(Icons.check_circle, size: 15, color: Color(0xFF81C784)),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        lang.modeRekSubtitle,
                        style: TextStyle(
                          color: selectedMode == RekRuleMode.rek ? Colors.white70 : Colors.white38,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Option 2: Hao Mode
            Expanded(
              child: InkWell(
                onTap: () {
                  AudioService.instance.playClick();
                  setModalState(() => onChanged(RekRuleMode.hao));
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  decoration: BoxDecoration(
                    color: selectedMode == RekRuleMode.hao
                        ? const Color(0xFFE65100).withValues(alpha: 0.35)
                        : const Color(0xFF1E272C),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selectedMode == RekRuleMode.hao
                          ? const Color(0xFFFFB74D)
                          : Colors.white12,
                      width: selectedMode == RekRuleMode.hao ? 1.8 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.bolt,
                            size: 16,
                            color: selectedMode == RekRuleMode.hao
                                ? const Color(0xFFFFB74D)
                                : Colors.white60,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              lang.modeHaoTitle,
                              style: TextStyle(
                                color: selectedMode == RekRuleMode.hao
                                    ? const Color(0xFFFFB74D)
                                    : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (selectedMode == RekRuleMode.hao)
                            const Icon(Icons.check_circle, size: 15, color: Color(0xFFFFB74D)),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        lang.modeHaoSubtitle,
                        style: TextStyle(
                          color: selectedMode == RekRuleMode.hao ? Colors.white70 : Colors.white38,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimerSelector(
    StateSetter setModalState,
    int selectedSeconds,
    ValueChanged<int> onChanged,
    LanguageService lang,
  ) {
    final options = [
      (300, '5 mn', lang.isKhmer ? 'ស្តង់ដារ' : 'Standard'),
      (900, '15 mn', lang.isKhmer ? 'មធ្យម' : 'Medium'),
      (1800, '30 mn', lang.isKhmer ? 'វែង' : 'Long'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.timer_outlined, size: 16, color: Color(0xFFFFD54F)),
            const SizedBox(width: 6),
            Text(
              lang.selectTimer,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: options.map((opt) {
            final isSelected = selectedSeconds == opt.$1;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: InkWell(
                  onTap: () {
                    AudioService.instance.playClick();
                    setModalState(() => onChanged(opt.$1));
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF2E7D32).withValues(alpha: 0.35)
                          : const Color(0xFF1E272C),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF81C784) : Colors.white12,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          opt.$2,
                          style: TextStyle(
                            color: isSelected ? const Color(0xFF81C784) : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          opt.$3,
                          style: TextStyle(
                            color: isSelected ? Colors.white70 : Colors.white38,
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDifficultyOption(
    StateSetter setModalState,
    AiDifficulty difficulty,
    String title,
    String subtitle,
  ) {
    final isSelected = _selectedDifficulty == difficulty;
    return ListTile(
      onTap: () {
        setModalState(() {
          _selectedDifficulty = difficulty;
        });
        setState(() {
          _selectedDifficulty = difficulty;
        });
      },
      leading: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
        color: isSelected ? const Color(0xFFFFD54F) : Colors.white38,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.white60, fontSize: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LanguageService.instance,
      builder: (context, _) {
        final lang = LanguageService.instance;

        return Scaffold(
          backgroundColor: const Color(0xFF192227),
          body: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  _buildTopBar(),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 680;
                        return SingleChildScrollView(
                          child: Center(
                            child: isWide
                                ? _buildWideLayout(constraints, lang)
                                : _buildCompactLayout(constraints, lang),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF141C20).withValues(alpha: 0.7),
        border: const Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 1) USERNAME BUTTON (Left side - dedicated player profile button)
          Flexible(
            child: ListenableBuilder(
              listenable: UserService.instance,
              builder: (context, _) {
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _openProfile,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF263238).withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(UserService.instance.avatar, style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              UserService.instance.username,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(width: 6),

          // 2) POINT BUTTON (Between Username and Language button)
          ListenableBuilder(
            listenable: UserService.instance,
            builder: (context, _) {
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _openPointsDialog,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B3B2B).withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFFFD54F).withValues(alpha: 0.6),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD54F).withValues(alpha: 0.15),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, size: 13, color: Color(0xFFFFD54F)),
                        const SizedBox(width: 3.5),
                        Text(
                          '${UserService.instance.points}',
                          style: const TextStyle(
                            color: Color(0xFFFFD54F),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(width: 6),

          // 3) QUICK CONTROLS (Language, Music, Settings)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Language Switcher button
              const LanguageToggleButton(isCompact: true),
              const SizedBox(width: 2),

              // Music toggle button
              ListenableBuilder(
                listenable: AudioService.instance,
                builder: (context, _) {
                  final audio = AudioService.instance;
                  return IconButton(
                    padding: const EdgeInsets.all(5),
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      audio.bgmEnabled ? Icons.music_note : Icons.music_off,
                      color: audio.bgmEnabled ? const Color(0xFF81C784) : Colors.white38,
                      size: 20,
                    ),
                    tooltip: audio.bgmEnabled ? 'Music: ON' : 'Music: OFF',
                    onPressed: () {
                      audio.playClick();
                      audio.setBgmEnabled(!audio.bgmEnabled);
                    },
                  );
                },
              ),
              const SizedBox(width: 2),
              // Settings button
              IconButton(
                padding: const EdgeInsets.all(5),
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.settings, color: Color(0xFFFFD54F), size: 20),
                tooltip: 'Settings & Audio',
                onPressed: _openSettings,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWideLayout(BoxConstraints constraints, LanguageService lang) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: constraints.maxHeight,
        maxWidth: 860,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left Hero Section
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildHeroEmblem(),
                  const SizedBox(height: 18),
                  Text(
                    lang.khmerTitle,
                    style: const TextStyle(
                      color: Color(0xFFFFD54F),
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'GAME REK',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    lang.englishTitle,
                    style: const TextStyle(
                      color: Color(0xFFFFD54F),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    lang.appSubtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    lang.appDescription,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white30, fontSize: 11),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 32),

            // Right Action Menu Cards
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildMenuCard(
                    icon: Icons.smart_toy_outlined,
                    iconColor: const Color(0xFF81C784),
                    title: lang.playVsAiTitle,
                    subtitle: lang.playVsAiSubtitle(_selectedDifficulty.name),
                    onTap: _showAiDifficultyPicker,
                    primary: true,
                  ),
                  const SizedBox(height: 10),
                  _buildMenuCard(
                    icon: Icons.people_outline,
                    iconColor: const Color(0xFF4DB6AC),
                    title: lang.passAndPlayTitle,
                    subtitle: lang.passAndPlaySubtitle,
                    onTap: _showPassAndPlayPicker,
                  ),
                  const SizedBox(height: 10),
                  _buildMenuCard(
                    icon: Icons.dashboard_customize_outlined,
                    iconColor: const Color(0xFFFFD54F),
                    title: lang.boardSetupTitle,
                    subtitle: lang.boardSetupSubtitle,
                    onTap: () => _navigateToGame(startInPlayMode: false, vsAi: true),
                  ),
                  const SizedBox(height: 10),
                  _buildMenuCard(
                    icon: Icons.menu_book_outlined,
                    iconColor: const Color(0xFFFFD54F),
                    title: lang.rulesAndGuideTitle,
                    subtitle: lang.rulesAndGuideSubtitle,
                    onTap: _showRules,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactLayout(BoxConstraints constraints, LanguageService lang) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: constraints.maxHeight,
        maxWidth: 480,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 10),
            _buildHeroEmblem(),
            const SizedBox(height: 16),

            // Khmer Title
            Text(
              lang.khmerTitle,
              style: const TextStyle(
                color: Color(0xFFFFD54F),
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
                shadows: [
                  Shadow(
                    color: Color(0x66FFD54F),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 4),

            // English Title
            const Text(
              'GAME REK',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 3.0,
              ),
            ),

            const SizedBox(height: 2),

            Text(
              lang.englishTitle,
              style: const TextStyle(
                color: Color(0xFFFFD54F),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),

            const SizedBox(height: 6),

            // Tagline
            Text(
              lang.appSubtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 13,
                letterSpacing: 0.3,
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons List
            _buildMenuCard(
              icon: Icons.smart_toy_outlined,
              iconColor: const Color(0xFF81C784),
              title: lang.playVsAiTitle,
              subtitle: lang.playVsAiSubtitle(_selectedDifficulty.name),
              onTap: _showAiDifficultyPicker,
              primary: true,
            ),

            const SizedBox(height: 10),

            _buildMenuCard(
              icon: Icons.people_outline,
              iconColor: const Color(0xFF4DB6AC),
              title: lang.passAndPlayTitle,
              subtitle: lang.passAndPlaySubtitle,
              onTap: _showPassAndPlayPicker,
            ),

            const SizedBox(height: 10),

            _buildMenuCard(
              icon: Icons.dashboard_customize_outlined,
              iconColor: const Color(0xFFFFD54F),
              title: lang.boardSetupTitle,
              subtitle: lang.boardSetupSubtitle,
              onTap: () => _navigateToGame(startInPlayMode: false, vsAi: true),
            ),

            const SizedBox(height: 10),
            _buildMenuCard(
              icon: Icons.menu_book_outlined,
              iconColor: const Color(0xFFFFD54F),
              title: lang.rulesAndGuideTitle,
              subtitle: lang.rulesAndGuideSubtitle,
              onTap: _showRules,
            ),

            const SizedBox(height: 24),

            // Footer
            Text(
              lang.appDescription,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white30,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroEmblem() {
    return _InteractiveHeroBoardEmblem(
      onTap: _openInteractiveBoardDialog,
    );
  }


  Widget _buildMenuCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool primary = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: primary
                ? const Color(0xFF1B5E20).withValues(alpha: 0.6)
                : const Color(0xFF263238).withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: primary
                  ? const Color(0xFF81C784).withValues(alpha: 0.8)
                  : Colors.white.withValues(alpha: 0.12),
              width: primary ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: iconColor.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: primary ? FontWeight.bold : FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: primary ? Colors.white70 : Colors.white54,
                        fontSize: 11.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios,
                color: primary ? const Color(0xFF81C784) : Colors.white30,
                size: 15,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InteractiveHeroBoardEmblem extends StatefulWidget {
  final VoidCallback onTap;

  const _InteractiveHeroBoardEmblem({required this.onTap});

  @override
  State<_InteractiveHeroBoardEmblem> createState() => _InteractiveHeroBoardEmblemState();
}

class _InteractiveHeroBoardEmblemState extends State<_InteractiveHeroBoardEmblem> {
  bool _isPressed = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final lang = LanguageService.instance;
    final scale = _isPressed ? 0.92 : (_isHovered ? 1.05 : 1.0);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutBack,
          child: Tooltip(
            message: lang.tapToInteractHint,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isHovered || _isPressed
                      ? const Color(0xFFFFE082)
                      : const Color(0xFFD4AF37),
                  width: 3.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD4AF37).withValues(
                      alpha: _isHovered || _isPressed ? 0.55 : 0.35,
                    ),
                    blurRadius: _isHovered || _isPressed ? 20 : 16,
                    spreadRadius: _isHovered || _isPressed ? 2 : 1,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 110,
                  height: 110,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Center(
                    child: SizedBox(
                      width: 74,
                      height: 74,
                      child: Stack(
                        alignment: Alignment.center,
                        children: const [
                          Positioned(
                            bottom: 6,
                            right: 6,
                            child: PieceTokenWidget(
                              player: PlayerColor.lime,
                              type: PieceType.crowned,
                              size: 40,
                              isSelected: true,
                            ),
                          ),
                          Positioned(
                            top: 6,
                            left: 6,
                            child: PieceTokenWidget(
                              player: PlayerColor.teal,
                              type: PieceType.crowned,
                              size: 40,
                              isSelected: false,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

