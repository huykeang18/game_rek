import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/rek_piece.dart';
import 'piece_token_widget.dart';

class WoodBoard extends StatelessWidget {
  final List<List<RekPiece?>> board;
  final bool isRotated;
  final BoardPosition? selectedSquare;
  final List<BoardPosition> legalMoves;
  final List<BoardPosition> lastMoveFromTo;
  final List<BoardPosition> recentCaptures;
  final Function(int row, int col) onSquareTap;

  const WoodBoard({
    super.key,
    required this.board,
    required this.isRotated,
    required this.selectedSquare,
    required this.legalMoves,
    required this.lastMoveFromTo,
    required this.recentCaptures,
    required this.onSquareTap,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.55),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: CustomPaint(
            painter: WoodTexturePainter(),
            child: Container(
              padding: const EdgeInsets.all(10), // Wood border frame
              child: AnimatedRotation(
                duration: const Duration(milliseconds: 350),
                turns: isRotated ? 0.5 : 0.0,
                curve: Curves.easeInOutCubic,
                child: Column(
                  children: List.generate(8, (displayRow) {
                    final actualRow = displayRow;
                    return Expanded(
                      child: Row(
                        children: List.generate(8, (displayCol) {
                          final actualCol = displayCol;
                          return Expanded(
                            child: _buildCell(
                              context,
                              actualRow,
                              actualCol,
                            ),
                          );
                        }),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCell(BuildContext context, int row, int col) {
    final piece = board[row][col];
    final pos = BoardPosition(row, col);

    final isSelected = selectedSquare == pos;
    final isLegalMove = legalMoves.contains(pos);
    final isLastMove = lastMoveFromTo.contains(pos);
    final isCaptured = recentCaptures.contains(pos);

    // Subtle alternating checkered tint on light wood
    final isLightSquare = (row + col) % 2 == 0;
    final squareColor = isLightSquare
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.04);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onSquareTap(row, col),
      child: Container(
        decoration: BoxDecoration(
          color: squareColor,
          border: Border.all(
            color: const Color(0x334E342E),
            width: 0.6,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Last move highlight
            if (isLastMove)
              Container(
                color: const Color(0x33FFF59D),
              ),

            // Selected square highlight
            if (isSelected)
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xFFFFD54F),
                    width: 2.5,
                  ),
                  color: const Color(0x33FFD54F),
                ),
              ),

            // Legal move indicator
            if (isLegalMove)
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: piece == null
                      ? const Color(0xAA4CAF50)
                      : const Color(0xCCE53935),
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),

            // Recent capture flash
            if (isCaptured)
              Container(
                color: const Color(0x66FF1744),
              ),

            // Piece Token
            if (piece != null)
              AnimatedRotation(
                // Counter-rotate the token so it remains upright when board is rotated
                duration: const Duration(milliseconds: 350),
                turns: isRotated ? -0.5 : 0.0,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final tokenSize = math.min(constraints.maxWidth, constraints.maxHeight) * 0.84;
                    return PieceTokenWidget(
                      player: piece.player,
                      type: piece.type,
                      size: tokenSize,
                      isSelected: isSelected,
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for light wood grain texture
class WoodTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Base light wood color
    final basePaint = Paint()..color = const Color(0xFFF3E1C3);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), basePaint);

    // Warm radial wood tint
    final gradientPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.9,
        colors: const [
          Color(0xFFFAF1DF),
          Color(0xFFEEDBB9),
          Color(0xFFDCC196),
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), gradientPaint);

    // Procedural subtle wood grain lines
    final grainPaint = Paint()
      ..color = const Color(0x18795548)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final random = math.Random(42); // deterministic seed for natural wood
    for (double y = 0; y < size.height; y += 4.5) {
      final path = Path();
      path.moveTo(0, y);
      double curY = y;
      for (double x = 0; x < size.width; x += 18) {
        curY += (random.nextDouble() - 0.5) * 1.8;
        path.lineTo(x, curY);
      }
      canvas.drawPath(path, grainPaint);
    }

    // Outer dark wood border frame
    final framePaint = Paint()
      ..color = const Color(0xFF5D4037)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(4, 4, size.width - 8, size.height - 8),
        const Radius.circular(8),
      ),
      framePaint,
    );

    // Golden inlay trim
    final trimPaint = Paint()
      ..color = const Color(0x88D7CCC8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRect(
      Rect.fromLTWH(9, 9, size.width - 18, size.height - 18),
      trimPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
