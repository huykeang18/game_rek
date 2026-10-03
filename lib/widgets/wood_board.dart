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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: List.generate(8, (displayRow) {
                    final actualRow = displayRow;
                    return Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
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
    final fromPos = lastMoveFromTo.isNotEmpty ? lastMoveFromTo[0] : null;
    final toPos = lastMoveFromTo.length > 1 ? lastMoveFromTo[1] : null;
    final isFromSquare = fromPos == pos;
    final isToSquare = toPos == pos;
    final isLastMove = isFromSquare || isToSquare || lastMoveFromTo.contains(pos);
    final isCaptured = recentCaptures.contains(pos);

    // Subtle alternating checkered tint on light wood
    final isLightSquare = (row + col) % 2 == 0;
    final squareColor = isLightSquare
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.04);

    return MouseRegion(
      cursor: (isLegalMove || piece != null)
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onSquareTap(row, col),
        child: SizedBox.expand(
          child: Container(
            width: double.infinity,
            height: double.infinity,
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
                // 1. Move Origin square shadow color highlight
                if (isFromSquare)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0x40FFD54F),
                        border: Border.all(
                          color: const Color(0x99FFD54F),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),

                // 2. Move Destination square shadow color highlight
                if (isToSquare)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0x55FFD54F),
                        border: Border.all(
                          color: const Color(0xCCFFD54F),
                          width: 2.0,
                        ),
                      ),
                    ),
                  ),

                // 3. Fallback for any other last move indicator
                if (isLastMove && !isFromSquare && !isToSquare)
                  Positioned.fill(
                    child: Container(
                      color: const Color(0x33FFF59D),
                    ),
                  ),

                // 4. Subtle board coordinates (ranks 1..8 and files a..h)
                if (col == 0 && !isFromSquare && !isToSquare && !isSelected)
                  Positioned(
                    top: 2,
                    left: 3,
                    child: Text(
                      '${8 - row}',
                      style: TextStyle(
                        color: const Color(0xFF5D4037).withValues(alpha: 0.55),
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (row == 7 && !isFromSquare && !isToSquare && !isSelected)
                  Positioned(
                    bottom: 1,
                    right: 3,
                    child: Text(
                      String.fromCharCode('a'.codeUnitAt(0) + col),
                      style: TextStyle(
                        color: const Color(0xFF5D4037).withValues(alpha: 0.55),
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                // 5. Selected square highlight across whole box
                if (isSelected)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFFFFD54F),
                          width: 2.5,
                        ),
                        color: const Color(0x33FFD54F),
                      ),
                    ),
                  ),

                // 6. Legal move highlight across WHOLE BOX
                if (isLegalMove)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: piece == null
                            ? const Color(0x2E4CAF50)
                            : const Color(0x35E53935),
                        border: Border.all(
                          color: piece == null
                              ? const Color(0x8881C784)
                              : const Color(0xCCE53935),
                          width: piece == null ? 1.5 : 2.0,
                        ),
                      ),
                    ),
                  ),

                // 4. Center indicator for legal move
                if (isLegalMove)
                  Center(
                    child: Container(
                      width: piece == null ? 16 : 22,
                      height: piece == null ? 16 : 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: piece == null
                            ? const Color(0xDD4CAF50)
                            : const Color(0xCCE53935),
                        border: Border.all(color: Colors.white, width: 2.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: piece != null
                          ? const Icon(Icons.close, color: Colors.white, size: 14)
                          : null,
                    ),
                  ),

                // 5. Recent capture flash across whole box
                if (isCaptured)
                  Positioned.fill(
                    child: Container(
                      color: const Color(0x66FF1744),
                    ),
                  ),

                // 5b. Stationary King throne highlight across whole box
                if (piece != null && piece.isCrowned)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFFFFD54F).withValues(alpha: 0.35),
                          width: 1.5,
                        ),
                        color: const Color(0xFFFFD54F).withValues(alpha: 0.06),
                      ),
                    ),
                  ),

                // 6. Piece Token
                if (piece != null)
                  Center(
                    child: AnimatedRotation(
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
                  ),
              ],
            ),
          ),
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

