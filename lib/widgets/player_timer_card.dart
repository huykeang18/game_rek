import 'package:flutter/material.dart';
import '../models/rek_piece.dart';
import '../services/language_service.dart';

class PlayerTimerCard extends StatelessWidget {
  final PlayerColor player;
  final String name;
  final String avatar;
  final int piecesCount;
  final int timeSeconds;
  final bool isTurn;
  final bool isAi;
  final bool isUntimed;
  final VoidCallback? onTimerTap;
  final bool isCompact;
  final VoidCallback? onCall;
  final bool showCallButton;
  final bool isCallActive;

  const PlayerTimerCard({
    super.key,
    required this.player,
    required this.name,
    required this.avatar,
    required this.piecesCount,
    required this.timeSeconds,
    required this.isTurn,
    this.isAi = false,
    this.isUntimed = false,
    this.onTimerTap,
    this.isCompact = false,
    this.onCall,
    this.showCallButton = false,
    this.isCallActive = false,
  });

  String get formattedTime {
    final minutes = timeSeconds ~/ 60;
    final seconds = timeSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  bool get isLowTime => !isUntimed && timeSeconds <= 30 && timeSeconds > 0;
  bool get isCriticalTime => !isUntimed && timeSeconds <= 10 && timeSeconds > 0;

  @override
  Widget build(BuildContext context) {
    final lang = LanguageService.instance;
    final isTeal = player == PlayerColor.teal;
    final primaryColor = isTeal ? const Color(0xFF26A69A) : const Color(0xFF8BC34A);
    final borderColor = isTurn
        ? (isCriticalTime
            ? Colors.redAccent
            : (isLowTime ? Colors.orangeAccent : (isTeal ? const Color(0xFF80CBC4) : const Color(0xFFC5E1A5))))
        : Colors.white12;

    final bgColor = isTurn
        ? (isTeal
            ? const Color(0xFF004D40).withValues(alpha: 0.85)
            : const Color(0xFF33691E).withValues(alpha: 0.85))
        : const Color(0xFF212C31).withValues(alpha: 0.9);

    if (isCompact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: isTurn ? 1.8 : 1.0),
          boxShadow: isTurn
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(avatar, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    name,
                    style: TextStyle(
                      color: isTurn ? Colors.white : Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '$piecesCount ${lang.piecesWord}',
              style: const TextStyle(color: Colors.white54, fontSize: 10),
            ),
            if (showCallButton && onCall != null) ...[
              const SizedBox(height: 5),
              _buildCallButton(lang),
            ],
            const SizedBox(height: 5),
            InkWell(
              onTap: onTimerTap,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isTurn
                        ? (isCriticalTime
                            ? Colors.redAccent
                            : (isLowTime ? Colors.orangeAccent : primaryColor.withValues(alpha: 0.8)))
                        : Colors.white24,
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 12,
                        color: isTurn
                            ? (isCriticalTime
                                ? Colors.redAccent
                                : (isLowTime ? Colors.orangeAccent : primaryColor))
                            : Colors.white54,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        formattedTime,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          color: isCriticalTime
                              ? Colors.redAccent
                              : (isLowTime ? Colors.orangeAccent : (isTurn ? Colors.white : Colors.white70)),
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 520),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: isTurn ? 1.8 : 1.0),
        boxShadow: isTurn
            ? [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // Player Avatar and Active Dot
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.35),
                  border: Border.all(
                    color: isTurn ? primaryColor : Colors.white24,
                    width: 1.5,
                  ),
                ),
                child: Text(avatar, style: const TextStyle(fontSize: 16)),
              ),
              if (isTurn)
                Positioned(
                  right: -1,
                  bottom: -1,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryColor,
                      border: Border.all(color: Colors.black, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),

          // Player Name & Piece Count
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: TextStyle(
                          color: isTurn ? Colors.white : Colors.white70,
                          fontWeight: isTurn ? FontWeight.bold : FontWeight.w600,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isTurn) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: primaryColor.withValues(alpha: 0.6), width: 0.8),
                        ),
                        child: Text(
                          lang.turn,
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primaryColor.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$piecesCount ${lang.piecesWord}',
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Call Button (when in Call/Hao mode)
          if (showCallButton && onCall != null) ...[
            _buildCallButton(lang),
            const SizedBox(width: 8),
          ],

          // Player Digital Timer Box
          InkWell(
            onTap: onTimerTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isTurn
                      ? (isCriticalTime
                          ? Colors.redAccent
                          : (isLowTime ? Colors.orangeAccent : primaryColor.withValues(alpha: 0.8)))
                      : Colors.white24,
                  width: isTurn ? 1.4 : 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 15,
                    color: isTurn
                        ? (isCriticalTime
                            ? Colors.redAccent
                            : (isLowTime ? Colors.orangeAccent : primaryColor))
                        : Colors.white54,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    formattedTime,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      color: isCriticalTime
                          ? Colors.redAccent
                          : (isLowTime ? Colors.orangeAccent : (isTurn ? Colors.white : Colors.white70)),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallButton(LanguageService lang) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onCall,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isCallActive
                  ? const [Color(0xFFFF3D00), Color(0xFFFF9100)]
                  : const [Color(0xFFE65100), Color(0xFFFF8F00)],
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isCallActive ? const Color(0xFFFFD54F) : const Color(0xFFFFB74D),
              width: isCallActive ? 1.8 : 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF8F00).withValues(alpha: isCallActive ? 0.6 : 0.35),
                blurRadius: isCallActive ? 8 : 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.bolt,
                color: Colors.white,
                size: 14,
              ),
              const SizedBox(width: 3),
              Text(
                lang.isKhmer ? 'ហៅ (Call)' : 'Call',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
