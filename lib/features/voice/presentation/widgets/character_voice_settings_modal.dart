import 'package:flutter/material.dart';
import '../../domain/entities/character.dart';
import '../../domain/entities/voice_profile.dart';
import '../controllers/multi_voice_session_controller.dart';

/// Modal bottom sheet allowing users to customize pitch, speed, and voice profiles for each character.
class CharacterVoiceSettingsModal extends StatefulWidget {
  final MultiVoiceSessionController controller;

  const CharacterVoiceSettingsModal({
    super.key,
    required this.controller,
  });

  static Future<void> show(
    BuildContext context, {
    required MultiVoiceSessionController controller,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CharacterVoiceSettingsModal(controller: controller),
    );
  }

  @override
  State<CharacterVoiceSettingsModal> createState() =>
      _CharacterVoiceSettingsModalState();
}

class _CharacterVoiceSettingsModalState
    extends State<CharacterVoiceSettingsModal> {
  String? _previewingSpeakerId;
  int _cacheSizeBytes = 0;

  @override
  void initState() {
    super.initState();
    _loadCacheSize();
  }

  Future<void> _loadCacheSize() async {
    final size = await widget.controller.voiceEngine.cacheManager.getCacheSizeBytes();
    if (mounted) {
      setState(() {
        _cacheSizeBytes = size;
      });
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Color _parseColor(String? hexString, Color fallback) {
    if (hexString == null || hexString.isEmpty) return fallback;
    try {
      final hex = hexString.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final characters = widget.controller.voiceEngine.getCharacters();
    final profiles = widget.controller.voiceEngine.getAllProfiles();

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(50),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          padding: EdgeInsets.only(
            top: 16,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title & Multi-voice switch
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withAlpha(30),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.record_voice_over_rounded,
                          color: Color(0xFF6366F1),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Character Voices',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        widget.controller.isMultiVoiceEnabled ? 'Enabled' : 'Single Voice',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: widget.controller.isMultiVoiceEnabled
                              ? const Color(0xFF10B981)
                              : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Switch.adaptive(
                        value: widget.controller.isMultiVoiceEnabled,
                        activeTrackColor: const Color(0xFF6366F1),
                        activeThumbColor: Colors.white,
                        onChanged: (val) {
                          widget.controller.setMultiVoiceEnabled(val);
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Text(
                'Assign personalized pitch, speed, and accents to each character for dynamic storytelling.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              const Divider(height: 24),

              // Character Voice Cards List
              Expanded(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: characters.length,
                  separatorBuilder: (ctx, i) => const SizedBox(height: 14),
                  itemBuilder: (ctx, i) {
                    final character = characters[i];
                    final profile = widget.controller.voiceEngine.getVoiceProfile(character.id);
                    final charColor = _parseColor(character.colorHex, const Color(0xFF6366F1));

                    return _buildCharacterCard(
                      context: context,
                      character: character,
                      profile: profile,
                      profiles: profiles,
                      color: charColor,
                      isDark: isDark,
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),
              // Cache & diagnostics bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF28283E) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.storage_rounded, size: 18, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          'Audio Cache: ${_formatBytes(_cacheSizeBytes)}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      onPressed: () async {
                        await widget.controller.voiceEngine.clearCache();
                        await _loadCacheSize();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Audio cache cleared successfully'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                      label: const Text(
                        'Clear',
                        style: TextStyle(fontSize: 12, color: Colors.redAccent),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCharacterCard({
    required BuildContext context,
    required Character character,
    required VoiceProfile profile,
    required List<VoiceProfile> profiles,
    required Color color,
    required bool isDark,
  }) {
    final isPreviewing = _previewingSpeakerId == character.id;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF28283E) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withAlpha(isDark ? 60 : 40),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Avatar, Name, and Preview Button
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: color.withAlpha(40),
                child: Text(
                  character.name.isNotEmpty ? character.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      character.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    if (character.description != null)
                      Text(
                        character.description!,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                  ],
                ),
              ),
              // Audition Preview Button
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  side: BorderSide(color: color.withAlpha(120)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: () async {
                  setState(() {
                    _previewingSpeakerId = character.id;
                  });
                  final sampleText = character.id == 'narrator'
                      ? 'The ancient story begins under the twilight sky.'
                      : (character.id == 'arjun'
                          ? 'Who goes there? Show yourself!'
                          : 'Careful Arjun, don\'t take another step!');
                  await widget.controller.previewVoice(profile, sampleText: sampleText);
                  if (mounted) {
                    setState(() {
                      _previewingSpeakerId = null;
                    });
                  }
                },
                icon: Icon(
                  isPreviewing ? Icons.graphic_eq_rounded : Icons.play_arrow_rounded,
                  size: 16,
                  color: color,
                ),
                label: Text(
                  isPreviewing ? 'Testing...' : 'Test Voice',
                  style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Voice Profile Dropdown
          Row(
            children: [
              const Text(
                'Voice Profile:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.withAlpha(60)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: profile.id,
                      items: profiles.map((p) {
                        return DropdownMenuItem<String>(
                          value: p.id,
                          child: Text(
                            p.name,
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (newProfileId) {
                        if (newProfileId != null) {
                          widget.controller.assignCharacterVoice(character.id, newProfileId);
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Provider Voice Model Tag
          Row(
            children: [
              Icon(Icons.memory_rounded, size: 12, color: isDark ? Colors.white38 : Colors.black38),
              const SizedBox(width: 4),
              Text(
                'Voice Model: ${profile.providerVoiceId}',
                style: TextStyle(
                  fontSize: 10,
                  fontFamily: 'monospace',
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Sliders: Pitch & Speed
          Row(
            children: [
              // Pitch Slider
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Pitch', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        Text('${profile.pitch.toStringAsFixed(2)}x',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      ),
                      child: Slider(
                        value: profile.pitch,
                        min: 0.5,
                        max: 1.8,
                        activeColor: color,
                        onChanged: (val) {
                          final updated = profile.copyWith(pitch: val);
                          widget.controller.updateVoiceProfile(updated);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              // Speed Slider
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Speed', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        Text('${profile.speed.toStringAsFixed(2)}x',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      ),
                      child: Slider(
                        value: profile.speed,
                        min: 0.6,
                        max: 1.6,
                        activeColor: color,
                        onChanged: (val) {
                          final updated = profile.copyWith(speed: val);
                          widget.controller.updateVoiceProfile(updated);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
