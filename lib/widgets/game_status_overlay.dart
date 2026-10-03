import 'package:flutter/material.dart';
import '../models/rek_piece.dart';
import '../logic/rek_rules.dart';
import '../services/language_service.dart';

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
  final RekRuleMode ruleMode;
  final VoidCallback? onCall;
  final bool isCallActive;

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
    this.ruleMode = RekRuleMode.hao,
    this.onCall,
    this.isCallActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LanguageService.instance,
      builder: (context, _) {
        final lang = LanguageService.instance;

        if (!isPlayMode) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.edit, size: 16, color: Color(0xFFFFD54F)),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    lang.setupModeHint,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
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

        final turnDetail = isTeal
            ? (vsAi ? lang.aiTeal : lang.p2Teal)
            : lang.limePlayer(avatar, name);

        final turnLabel = '${lang.turn}: $turnDetail';

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
              Flexible(
                flex: lastNotification != null ? 2 : 1,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
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
              const SizedBox(width: 6),
              Flexible(
                flex: lastNotification != null ? 3 : 0,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (lastNotification != null) ...[
                      Flexible(
                        child: Text(
                          lastNotification!,
                          style: const TextStyle(
                            color: Color(0xFFFFD54F),
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    if (lastNotification == null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: ruleMode == RekRuleMode.hao ? const Color(0xFFFFD54F) : const Color(0xFF81C784),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        ruleMode == RekRuleMode.hao ? lang.ruleModeBadgeHao : lang.ruleModeBadgeRek,
                        style: TextStyle(
                          color: ruleMode == RekRuleMode.hao ? const Color(0xFFFFD54F) : const Color(0xFF81C784),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (ruleMode == RekRuleMode.hao && onCall != null) ...[
                    const SizedBox(width: 8),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onCall,
                        borderRadius: BorderRadius.circular(6),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isCallActive
                                  ? const [Color(0xFFFF3D00), Color(0xFFFF9100)]
                                  : const [Color(0xFFE65100), Color(0xFFFF8F00)],
                            ),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isCallActive ? const Color(0xFFFFD54F) : const Color(0xFFFFB74D),
                              width: isCallActive ? 1.8 : 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF8F00).withValues(alpha: isCallActive ? 0.6 : 0.35),
                                blurRadius: isCallActive ? 6 : 3,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.bolt, color: Colors.white, size: 13),
                              const SizedBox(width: 3),
                              Text(
                                lang.isKhmer ? 'ហៅ (Call)' : 'Call',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
      },
    );
  }
}
