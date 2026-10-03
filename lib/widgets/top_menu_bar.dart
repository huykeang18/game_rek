import 'package:flutter/material.dart';

class TopMenuBar extends StatelessWidget {
  final VoidCallback? onEraseAll;
  final VoidCallback? onToggleErase;
  final bool isEraserActive;
  final VoidCallback onRotateBoard;
  final String labelEraseAll;
  final String labelErase;
  final String labelRotateBoard;
  final bool showEditorButtons;

  const TopMenuBar({
    super.key,
    this.onEraseAll,
    this.onToggleErase,
    this.isEraserActive = false,
    required this.onRotateBoard,
    this.labelEraseAll = 'Erase all',
    this.labelErase = 'Erase',
    this.labelRotateBoard = 'Rotate Baord',
    this.showEditorButtons = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Action Buttons: "Erase all", "Erase" (only if showEditorButtons), and "Rotate Baord"
              if (showEditorButtons) ...[
                if (onEraseAll != null) ...[
                  _buildMenuButton(
                    label: labelEraseAll,
                    onTap: onEraseAll!,
                    isDestructive: true,
                  ),
                  const SizedBox(width: 8),
                ],
                if (onToggleErase != null) ...[
                  _buildMenuButton(
                    label: labelErase,
                    onTap: onToggleErase!,
                    isActive: isEraserActive,
                  ),
                  const SizedBox(width: 8),
                ],
              ],
              _buildMenuButton(
                label: labelRotateBoard,
                onTap: onRotateBoard,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton({
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFFE57373)
                : const Color(0xFF2C3E50).withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isActive
                  ? const Color(0xFFFFCDD2)
                  : Colors.white.withValues(alpha: 0.28),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 3,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isDestructive && !isActive
                  ? const Color(0xFFFFCDD2)
                  : Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}
