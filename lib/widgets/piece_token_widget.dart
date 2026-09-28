import 'package:flutter/material.dart';
import '../models/rek_piece.dart';

class PieceTokenWidget extends StatelessWidget {
  final PlayerColor player;
  final PieceType type;
  final double size;
  final bool isSelected;
  final bool showShadow;

  const PieceTokenWidget({
    super.key,
    required this.player,
    required this.type,
    this.size = 40.0,
    this.isSelected = false,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final isTeal = player == PlayerColor.teal;
    final isKing = type == PieceType.crowned;

    // Token color palette
    final primaryColor = isTeal ? const Color(0xFF00897B) : const Color(0xFF7CB342);
    final lightColor = isTeal ? const Color(0xFF4DB6AC) : const Color(0xFFAED581);
    final darkColor = isTeal ? const Color(0xFF004D40) : const Color(0xFF33691E);
    final rimColor = isTeal ? const Color(0xFF80CBC4) : const Color(0xFFC5E1A5);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 4,
                  offset: const Offset(1, 3),
                ),
              ]
            : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer beveled disc
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-0.3, -0.3),
                radius: 0.9,
                colors: [lightColor, primaryColor, darkColor],
                stops: const [0.0, 0.65, 1.0],
              ),
              border: Border.all(
                color: rimColor.withValues(alpha: 0.8),
                width: size * 0.045,
              ),
            ),
          ),

          // Inner ring indentation
          Container(
            width: size * 0.76,
            height: size * 0.76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.black.withValues(alpha: 0.25),
                width: size * 0.035,
              ),
            ),
          ),

          // Crown or Plain Center Design
          if (isKing)
            _buildCrownDesign(size)
          else
            _buildPlainDesign(size, lightColor, rimColor),
        ],
      ),
    );
  }

  Widget _buildCrownDesign(double size) {
    return Container(
      width: size * 0.58,
      height: size * 0.58,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withValues(alpha: 0.18),
      ),
      child: Center(
        child: Icon(
          Icons.workspace_premium,
          size: size * 0.44,
          color: const Color(0xFFFFE082),
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 3,
              offset: const Offset(1, 1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlainDesign(double size, Color lightColor, Color rimColor) {
    return Container(
      width: size * 0.38,
      height: size * 0.38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.2, -0.2),
          colors: [
            lightColor.withValues(alpha: 0.9),
            rimColor.withValues(alpha: 0.3),
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
    );
  }
}
