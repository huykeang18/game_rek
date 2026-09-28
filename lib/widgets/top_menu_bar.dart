import 'package:flutter/material.dart';

class TopMenuBar extends StatelessWidget {
  final VoidCallback onEraseAll;
  final VoidCallback onToggleErase;
  final bool isEraserActive;
  final VoidCallback onRotateBoard;
  final bool isWifiConnected;

  const TopMenuBar({
    super.key,
    required this.onEraseAll,
    required this.onToggleErase,
    required this.isEraserActive,
    required this.onRotateBoard,
    this.isWifiConnected = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          // Green Wi-Fi connection icon in the top left corner
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.wifi,
              color: isWifiConnected ? const Color(0xFF00E676) : Colors.grey,
              size: 24,
            ),
          ),
          const Spacer(),
          // Action Buttons: "Erase all", "Erase", "Rotate Baord"
          _buildMenuButton(
            label: 'Erase all',
            onTap: onEraseAll,
            isDestructive: true,
          ),
          const SizedBox(width: 8),
          _buildMenuButton(
            label: 'Erase',
            onTap: onToggleErase,
            isActive: isEraserActive,
          ),
          const SizedBox(width: 8),
          _buildMenuButton(
            label: 'Rotate Baord',
            onTap: onRotateBoard,
          ),
        ],
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
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
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
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}
