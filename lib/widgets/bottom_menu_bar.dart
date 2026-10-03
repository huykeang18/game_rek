import 'package:flutter/material.dart';

class BottomMenuBar extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback? onSave;
  final VoidCallback onPlay;
  final VoidCallback onChat;
  final VoidCallback? onCall;
  final bool isPlaying;
  final String labelSave;
  final String labelPlay;
  final String labelCall;
  final bool showSave;
  final bool showCallButton;
  final bool isCallActive;

  const BottomMenuBar({
    super.key,
    required this.onBack,
    this.onSave,
    required this.onPlay,
    required this.onChat,
    this.onCall,
    this.isPlaying = false,
    this.labelSave = 'Save',
    this.labelPlay = 'Play',
    this.labelCall = 'Call',
    this.showSave = true,
    this.showCallButton = false,
    this.isCallActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Yellow back arrow in the bottom left corner
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onBack,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFFFD54F).withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFFFFD54F),
                      size: 22,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Center Buttons: "Save" (if showSave), "Call" (if showCallButton), and "Play"
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showSave && onSave != null) ...[
                    _buildBottomButton(
                      label: labelSave,
                      onTap: onSave!,
                      backgroundColor: const Color(0xFF37474F),
                    ),
                    const SizedBox(width: 10),
                  ],
                  if (showCallButton && onCall != null) ...[
                    _buildCallBottomButton(),
                    const SizedBox(width: 10),
                  ],
                  _buildBottomButton(
                    label: labelPlay,
                    onTap: onPlay,
                    backgroundColor: isPlaying
                        ? const Color(0xFFE65100)
                        : const Color(0xFF2E7D32),
                    highlight: true,
                  ),
                ],
              ),

              const SizedBox(width: 16),

              // White chat bubble icon in the bottom right corner
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onChat,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.chat_bubble,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButton({
    required String label,
    required VoidCallback onTap,
    required Color backgroundColor,
    bool highlight = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: backgroundColor.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: highlight
                  ? (isPlaying ? const Color(0xFFFFB74D) : const Color(0xFF81C784))
                  : Colors.white.withValues(alpha: 0.3),
              width: highlight ? 1.5 : 1,
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
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCallBottomButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onCall,
        borderRadius: BorderRadius.circular(6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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
                blurRadius: isCallActive ? 8 : 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.bolt,
                color: Colors.white,
                size: 15,
              ),
              const SizedBox(width: 4),
              Text(
                labelCall,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
