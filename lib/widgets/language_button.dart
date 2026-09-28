import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/audio_service.dart';
import '../services/language_service.dart';

class LanguageToggleButton extends StatelessWidget {
  final bool isCompact;

  const LanguageToggleButton({
    super.key,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LanguageService.instance,
      builder: (context, _) {
        final lang = LanguageService.instance;
        final isKhmer = lang.isKhmer;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              AudioService.instance.playClick();
              HapticFeedback.lightImpact();
              lang.toggleLanguage();
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 8 : 10,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF263238).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Flag indicator
                  Text(
                    isKhmer ? '🇰🇭' : '🇬🇧',
                    style: const TextStyle(fontSize: 15),
                  ),
                  const SizedBox(width: 5),
                  // Current language label
                  Text(
                    isKhmer ? 'ខ្មែរ' : 'EN',
                    style: const TextStyle(
                      color: Color(0xFFFFD54F),
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Icon(
                    Icons.sync,
                    size: 13,
                    color: Colors.white60,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A segmented dual-choice language selector used in Settings or dialogs
class LanguageSegmentedSelector extends StatelessWidget {
  const LanguageSegmentedSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LanguageService.instance,
      builder: (context, _) {
        final lang = LanguageService.instance;

        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFF263238),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            children: [
              // English Option
              Expanded(
                child: _buildOption(
                  isSelected: lang.isEnglish,
                  flag: '🇬🇧',
                  label: 'English',
                  onTap: () {
                    AudioService.instance.playClick();
                    lang.setLanguage(AppLanguage.english);
                  },
                ),
              ),
              const SizedBox(width: 4),
              // Khmer Option
              Expanded(
                child: _buildOption(
                  isSelected: lang.isKhmer,
                  flag: '🇰🇭',
                  label: 'ភាសាខ្មែរ',
                  onTap: () {
                    AudioService.instance.playClick();
                    lang.setLanguage(AppLanguage.khmer);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOption({
    required bool isSelected,
    required String flag,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2E7D32)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: const Color(0xFF81C784), width: 1.2)
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(flag, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
