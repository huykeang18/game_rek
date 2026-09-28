import 'package:flutter/material.dart';
import '../models/rek_piece.dart';
import '../logic/rek_rules.dart';

class GameStatusBanner extends StatelessWidget {
  final PlayerColor currentTurn;
  final bool isPlayMode;
  final String? lastNotification;
  final GameOverResult? gameOverResult;
  final VoidCallback onReset;
  final VoidCallback onEdit;
  final String? playerName;
  final String? playerAvatar;
  final bool vsAi;

  const GameStatusBanner({
    super.key,
    required this.currentTurn,
    required this.isPlayMode,
    this.lastNotification,
    this.gameOverResult,
    required this.onReset,
    required this.onEdit,
    this.playerName,
    this.playerAvatar,
    this.vsAi = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isPlayMode) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white12),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.edit, size: 16, color: Color(0xFFFFD54F)),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Board Setup Mode: Tap tokens to select, tap board to place/erase',
                style: TextStyle(color: Colors.white70, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    final isTeal = currentTurn == PlayerColor.teal;
    final name = playerName ?? 'Player';
    final avatar = playerAvatar ?? '👤';

    final turnLabel = isTeal
        ? (vsAi ? 'Turn: 🤖 AI (TEAL)' : 'Turn: 👥 P2 (TEAL)')
        : 'Turn: $avatar $name (LIME)';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: isTeal
            ? const Color(0xFF004D40).withValues(alpha: 0.85)
            : const Color(0xFF33691E).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isTeal ? const Color(0xFF80CBC4) : const Color(0xFFC5E1A5),
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isTeal ? const Color(0xFF26A69A) : const Color(0xFF8BC34A),
                    boxShadow: [
                      BoxShadow(
                        color: (isTeal ? Colors.tealAccent : Colors.lightGreenAccent)
                            .withValues(alpha: 0.6),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    turnLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          if (lastNotification != null)
            Text(
              lastNotification!,
              style: const TextStyle(
                color: Color(0xFFFFD54F),
                fontWeight: FontWeight.bold,
                fontSize: 12.5,
              ),
            ),
        ],
      ),
    );
  }
}
