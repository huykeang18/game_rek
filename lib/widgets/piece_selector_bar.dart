import 'package:flutter/material.dart';
import '../models/rek_piece.dart';
import 'piece_token_widget.dart';

class PieceSelectorBar extends StatelessWidget {
  final PlayerColor player;
  final PieceType? selectedType;
  final bool isSelectedPlayer;
  final ValueChanged<PieceType> onSelect;
  final bool isVertical;
  final double tokenSize;

  const PieceSelectorBar({
    super.key,
    required this.player,
    required this.selectedType,
    required this.isSelectedPlayer,
    required this.onSelect,
    this.isVertical = false,
    this.tokenSize = 40.0,
  });

  @override
  Widget build(BuildContext context) {
    final children = [
      _buildOption(PieceType.plain),
      SizedBox(width: isVertical ? 0 : 20, height: isVertical ? 16 : 0),
      _buildOption(PieceType.crowned),
    ];

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isVertical ? 4 : 8,
        vertical: isVertical ? 6 : 4,
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: isVertical
            ? Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: children,
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: children,
              ),
      ),
    );
  }

  Widget _buildOption(PieceType type) {
    final isCurrent = isSelectedPlayer && selectedType == type;

    return GestureDetector(
      onTap: () => onSelect(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isCurrent
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: isCurrent
              ? Border.all(
                  color: Colors.white,
                  width: 2.2,
                )
              : Border.all(
                  color: Colors.transparent,
                  width: 2.2,
                ),
          boxShadow: isCurrent
              ? [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.35),
                    blurRadius: 7,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: PieceTokenWidget(
          player: player,
          type: type,
          size: tokenSize,
          isSelected: isCurrent,
        ),
      ),
    );
  }
}
