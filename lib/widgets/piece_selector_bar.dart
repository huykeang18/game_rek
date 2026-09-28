import 'package:flutter/material.dart';
import '../models/rek_piece.dart';
import 'piece_token_widget.dart';

class PieceSelectorBar extends StatelessWidget {
  final PlayerColor player;
  final PieceType? selectedType;
  final bool isSelectedPlayer;
  final ValueChanged<PieceType> onSelect;

  const PieceSelectorBar({
    super.key,
    required this.player,
    required this.selectedType,
    required this.isSelectedPlayer,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildOption(PieceType.plain),
          const SizedBox(width: 24),
          _buildOption(PieceType.crowned),
        ],
      ),
    );
  }

  Widget _buildOption(PieceType type) {
    final isCurrent = isSelectedPlayer && selectedType == type;

    return GestureDetector(
      onTap: () => onSelect(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: isCurrent
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: isCurrent
              ? Border.all(
                  color: Colors.white,
                  width: 2.5,
                )
              : Border.all(
                  color: Colors.transparent,
                  width: 2.5,
                ),
          boxShadow: isCurrent
              ? [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.35),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: PieceTokenWidget(
          player: player,
          type: type,
          size: 42,
          isSelected: isCurrent,
        ),
      ),
    );
  }
}
