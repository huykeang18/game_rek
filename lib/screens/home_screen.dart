import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/rek_piece.dart';
import '../logic/rek_ai.dart';
import '../logic/storage_service.dart';
import '../widgets/piece_token_widget.dart';
import '../widgets/rules_dialog.dart';
import '../widgets/save_load_dialog.dart';
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

  void _navigateToGame({
    bool startInPlayMode = false,
    bool vsAi = true,
    SavedGameState? initialSavedState,
  }) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RekGameScreen(
          startInPlayMode: startInPlayMode,
          vsAi: vsAi,
          aiDifficulty: _selectedDifficulty,
          initialSavedState: initialSavedState,
        ),
      ),
    );
  }

  void _showRules() {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (_) => const RulesDialog(moveHistory: []),
    );
  }

  void _showLoadDialog() {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (_) => SaveLoadDialog(
        isSaveMode: false,
        currentState: SavedGameState(
          id: '',
          name: '',
          timestamp: DateTime.now(),
          board: [],
          currentTurn: PlayerColor.lime,
          isPlayMode: false,
        ),
        onLoad: (savedState) {
          _navigateToGame(
            startInPlayMode: savedState.isPlayMode,
            vsAi: true,
            initialSavedState: savedState,
          );
        },
      ),
    );
  }

  void _showAiDifficultyPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF263238),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select AI Difficulty',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              _buildDifficultyOption(
                setModalState,
                AiDifficulty.easy,
                'Easy',
                'Casual play with basic capture detection',
              ),
              _buildDifficultyOption(
                setModalState,
                AiDifficulty.medium,
                'Medium (Balanced)',
                'Tactical Rek captures and King safety evaluation',
              ),
              _buildDifficultyOption(
                setModalState,
                AiDifficulty.hard,
                'Master / Hard',
                'Deep 2-ply minimax search with alpha-beta pruning',
              ),
              const SizedBox(height: 12),
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
                    _navigateToGame(startInPlayMode: true, vsAi: true);
                  },
                  child: const Text('Start Match vs AI', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
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
    return Scaffold(
      backgroundColor: const Color(0xFF192227),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                    maxWidth: 480,
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 10),

                          // Top Emblem & Logo
                          _buildHeroEmblem(),

                          const SizedBox(height: 16),

                          // Khmer Title
                          const Text(
                            'ល្បែងរែក',
                            style: TextStyle(
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
                            'CAMBODIAN REK CHESS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2.5,
                            ),
                          ),

                          const SizedBox(height: 6),

                          // Tagline
                          const Text(
                            'Traditional Khmer Board Game & Board Editor',
                            textAlign: TextAlign.center,
                            style: TextStyle(
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
                            title: 'Play vs AI',
                            subtitle: 'Single player vs Computer (${_selectedDifficulty.name.toUpperCase()})',
                            onTap: _showAiDifficultyPicker,
                            primary: true,
                          ),

                          const SizedBox(height: 10),

                          _buildMenuCard(
                            icon: Icons.people_outline,
                            iconColor: const Color(0xFF4DB6AC),
                            title: 'Pass & Play (2 Players)',
                            subtitle: 'Play locally against a friend on one device',
                            onTap: () => _navigateToGame(startInPlayMode: true, vsAi: false),
                          ),

                          const SizedBox(height: 10),

                          _buildMenuCard(
                            icon: Icons.dashboard_customize_outlined,
                            iconColor: const Color(0xFFFFD54F),
                            title: 'Board Setup & Editor',
                            subtitle: 'Custom setup with Erase, Rotate Baord & Selectors',
                            onTap: () => _navigateToGame(startInPlayMode: false, vsAi: true),
                          ),

                          const SizedBox(height: 10),

                          Row(
                            children: [
                              Expanded(
                                child: _buildSecondaryCard(
                                  icon: Icons.folder_open_outlined,
                                  title: 'Load Game',
                                  onTap: _showLoadDialog,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildSecondaryCard(
                                  icon: Icons.menu_book_outlined,
                                  title: 'Rules & Guide',
                                  onTap: _showRules,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Footer
                          const Text(
                            'Traditional Cambodian Cultural Game • 8×8 Rook Moves & Shoulder-Pole Captures',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white30,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeroEmblem() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [
            Color(0xFF2C3E50),
            Color(0xFF1E272C),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFFFD54F).withValues(alpha: 0.6),
          width: 2.5,
        ),
      ),
      child: const Stack(
        alignment: Alignment.center,
        children: [
          // Teal King Token (Left)
          Positioned(
            left: 18,
            top: 28,
            child: PieceTokenWidget(
              player: PlayerColor.teal,
              type: PieceType.crowned,
              size: 48,
              showShadow: true,
            ),
          ),
          // Lime Green King Token (Right)
          Positioned(
            right: 18,
            bottom: 28,
            child: PieceTokenWidget(
              player: PlayerColor.lime,
              type: PieceType.crowned,
              size: 48,
              showShadow: true,
            ),
          ),
          // Center VS or Star
          Icon(
            Icons.flash_on,
            color: Color(0xFFFFD54F),
            size: 26,
          ),
        ],
      ),
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
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: primary
                ? const Color(0xFF2E7D32).withValues(alpha: 0.85)
                : const Color(0xFF263238).withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: primary
                  ? const Color(0xFF81C784)
                  : Colors.white.withValues(alpha: 0.15),
              width: primary ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
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
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white.withValues(alpha: 0.5),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF263238).withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: const Color(0xFFFFD54F), size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
