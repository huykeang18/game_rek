import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/audio_service.dart';
import '../services/user_service.dart';
import 'profile_edit_dialog.dart';

class SettingsDialog extends StatelessWidget {
  const SettingsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E262C),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.settings, color: Color(0xFFFFD54F), size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Settings & Audio',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(color: Colors.white12, height: 1),
              const SizedBox(height: 16),

              // --- Player Profile Section ---
              ListenableBuilder(
                listenable: UserService.instance,
                builder: (context, _) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF263238),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            UserService.instance.avatar,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Player Username',
                                style: TextStyle(color: Colors.white54, fontSize: 11),
                              ),
                              Text(
                                UserService.instance.username,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () {
                            AudioService.instance.playClick();
                            showDialog(
                              context: context,
                              builder: (_) => const ProfileEditDialog(),
                            );
                          },
                          icon: const Icon(Icons.edit, size: 14, color: Color(0xFFFFD54F)),
                          label: const Text(
                            'Edit',
                            style: TextStyle(color: Color(0xFFFFD54F), fontSize: 12),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFD4AF37), width: 1),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            minimumSize: Size.zero,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // --- Music & Sound Section ---
              ListenableBuilder(
                listenable: AudioService.instance,
                builder: (context, _) {
                  final audio = AudioService.instance;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section Header
                      const Row(
                        children: [
                          Icon(Icons.music_note, color: Color(0xFFFFD54F), size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Background Music (BGM)',
                            style: TextStyle(
                              color: Color(0xFFFFD54F),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // BGM Switch
                      SwitchListTile(
                        value: audio.bgmEnabled,
                        onChanged: (val) {
                          audio.setBgmEnabled(val);
                        },
                        title: const Text('Enable Music', style: TextStyle(color: Colors.white, fontSize: 14)),
                        subtitle: Text(
                          audio.bgmEnabled ? 'Playing traditional soundtrack' : 'Muted',
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                        activeThumbColor: const Color(0xFF81C784),
                        contentPadding: EdgeInsets.zero,
                      ),

                      if (audio.bgmEnabled) ...[
                        // Track Selector
                        const SizedBox(height: 8),
                        const Text(
                          'Select Soundtrack Track',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        Column(
                          children: AudioService.availableTracks.map((track) {
                            final isSelected = audio.currentTrackKey == track.key;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: InkWell(
                                onTap: () {
                                  audio.setTrack(track.key);
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF2E7D32).withValues(alpha: 0.3)
                                        : const Color(0xFF263238),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected ? const Color(0xFF81C784) : Colors.white12,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(track.icon, style: const TextStyle(fontSize: 18)),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              track.title,
                                              style: TextStyle(
                                                color: isSelected ? Colors.white : Colors.white70,
                                                fontSize: 13,
                                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                              ),
                                            ),
                                            Text(
                                              track.subtitle,
                                              style: const TextStyle(color: Colors.white38, fontSize: 11),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isSelected)
                                        const Icon(Icons.check_circle, color: Color(0xFF81C784), size: 18),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 10),

                        // BGM Volume Slider
                        Row(
                          children: [
                            Icon(
                              audio.bgmVolume == 0 ? Icons.volume_off : Icons.volume_up,
                              color: Colors.white70,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            const Text('BGM Volume', style: TextStyle(color: Colors.white70, fontSize: 13)),
                            const Spacer(),
                            Text(
                              '${(audio.bgmVolume * 100).round()}%',
                              style: const TextStyle(color: Color(0xFFFFD54F), fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: const Color(0xFF81C784),
                            inactiveTrackColor: Colors.white12,
                            thumbColor: const Color(0xFF81C784),
                            trackHeight: 3,
                          ),
                          child: Slider(
                            value: audio.bgmVolume,
                            min: 0.0,
                            max: 1.0,
                            onChanged: (val) {
                              audio.setBgmVolume(val);
                            },
                          ),
                        ),
                      ],

                      const SizedBox(height: 14),
                      const Divider(color: Colors.white12, height: 1),
                      const SizedBox(height: 14),

                      // --- Sound Effects (SFX) ---
                      const Row(
                        children: [
                          Icon(Icons.surround_sound, color: Color(0xFFFFD54F), size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Sound Effects (SFX)',
                            style: TextStyle(
                              color: Color(0xFFFFD54F),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      SwitchListTile(
                        value: audio.sfxEnabled,
                        onChanged: (val) {
                          audio.setSfxEnabled(val);
                        },
                        title: const Text('Move & Rek Capture Sounds', style: TextStyle(color: Colors.white, fontSize: 14)),
                        subtitle: Text(
                          audio.sfxEnabled ? 'Clacks, captures & fanfare active' : 'Muted',
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                        activeThumbColor: const Color(0xFF81C784),
                        contentPadding: EdgeInsets.zero,
                      ),

                      if (audio.sfxEnabled) ...[
                        Row(
                          children: [
                            const Icon(Icons.volume_down, color: Colors.white70, size: 18),
                            const SizedBox(width: 8),
                            const Text('SFX Volume', style: TextStyle(color: Colors.white70, fontSize: 13)),
                            const Spacer(),
                            Text(
                              '${(audio.sfxVolume * 100).round()}%',
                              style: const TextStyle(color: Color(0xFFFFD54F), fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: const Color(0xFF81C784),
                            inactiveTrackColor: Colors.white12,
                            thumbColor: const Color(0xFF81C784),
                            trackHeight: 3,
                          ),
                          child: Slider(
                            value: audio.sfxVolume,
                            min: 0.0,
                            max: 1.0,
                            onChanged: (val) {
                              audio.setSfxVolume(val);
                            },
                          ),
                        ),

                        // Test SFX Buttons
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  audio.playMove();
                                },
                                icon: const Icon(Icons.touch_app, size: 14),
                                label: const Text('Test Move', style: TextStyle(fontSize: 11)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white70,
                                  side: const BorderSide(color: Colors.white24),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  audio.playCapture();
                                },
                                icon: const Icon(Icons.flash_on, size: 14),
                                label: const Text('Test Capture', style: TextStyle(fontSize: 11)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white70,
                                  side: const BorderSide(color: Colors.white24),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  );
                },
              ),

              const SizedBox(height: 22),

              // Close / Done Button
              ElevatedButton(
                onPressed: () {
                  AudioService.instance.playClick();
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
