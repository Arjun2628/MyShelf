import 'package:epub_audio/features/epub/domain/entities/book.dart';
import 'package:epub_audio/features/voice/domain/entities/character.dart';
import 'package:epub_audio/features/voice/domain/entities/voice_profile.dart';
import 'package:epub_audio/features/voice/domain/services/voice_engine.dart';
import 'package:flutter/material.dart';

/// Interactive modal allowing readers to preview, audition, and fine-tune character voices
/// before or during book playback.
class BookVoiceAuditionModal extends StatefulWidget {
  final Book book;
  final VoiceEngine voiceEngine;
  final List<String> characterVoiceNames;
  final Color accentColor;

  const BookVoiceAuditionModal({
    super.key,
    required this.book,
    required this.voiceEngine,
    this.characterVoiceNames = const [],
    this.accentColor = const Color(0xFFD4A373),
  });

  static Future<void> show(
    BuildContext context, {
    required Book book,
    required VoiceEngine voiceEngine,
    List<String> characterVoiceNames = const [],
    Color accentColor = const Color(0xFFD4A373),
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BookVoiceAuditionModal(
        book: book,
        voiceEngine: voiceEngine,
        characterVoiceNames: characterVoiceNames,
        accentColor: accentColor,
      ),
    );
  }

  @override
  State<BookVoiceAuditionModal> createState() => _BookVoiceAuditionModalState();
}

class _BookVoiceAuditionModalState extends State<BookVoiceAuditionModal> {
  String? _currentlyAuditioningId;
  late final List<VoiceProfile> _availableProfiles;
  late List<Character> _bookCharacters;

  @override
  void initState() {
    super.initState();
    _availableProfiles = widget.voiceEngine.getAllProfiles();
    _initBookCharacters();
  }

  void _initBookCharacters() {
    final existing = widget.voiceEngine.getCharacters();
    final names = widget.characterVoiceNames.isNotEmpty
        ? widget.characterVoiceNames
        : ['Narrator (Main Voice)', 'Character Voice'];

    _bookCharacters = [];
    for (int i = 0; i < names.length; i++) {
      final name = names[i];
      final rawKey = name.replaceAll(RegExp(r'\s*\(.*?\)'), '').trim().toLowerCase();
      
      // Match existing or create representative character
      final matched = existing.firstWhere(
        (c) => c.name.toLowerCase().contains(rawKey) || c.id.toLowerCase().contains(rawKey),
        orElse: () {
          // Select default profile based on gender hints
          String profileId = 'voice_narrator';
          if (name.toLowerCase().contains('female') || name.toLowerCase().contains('woman')) {
            profileId = 'voice_maya';
          } else if (name.toLowerCase().contains('male') || name.toLowerCase().contains('man') || name.toLowerCase().contains('watson')) {
            profileId = 'voice_arjun';
          } else if (name.toLowerCase().contains('deep') || name.toLowerCase().contains('elder') || name.toLowerCase().contains('stranger')) {
            profileId = 'voice_stranger';
          }

          return Character(
            id: 'char_${rawKey.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}',
            name: name,
            description: 'Voice cast member for ${widget.book.metadata.title}',
            voiceProfileId: profileId,
            colorHex: _getColorHexForIndex(i),
          );
        },
      );

      _bookCharacters.add(matched.copyWith(name: name));
    }
  }

  String _getColorHexForIndex(int index) {
    const colors = ['#6366F1', '#EC4899', '#3B82F6', '#8B5CF6', '#10B981', '#F59E0B'];
    return colors[index % colors.length];
  }

  Color _parseHex(String? hex, Color fallback) {
    if (hex == null || hex.isEmpty) return fallback;
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  String _getAuditionSampleLine(Character character) {
    final name = character.name;
    final lang = widget.book.metadata.language ?? 'en';

    if (lang == 'ml' || name.contains('വിവരണക്കാരൻ')) {
      if (name.contains('കറുത്തമ്മ')) {
        return 'പരീക്കുട്ടി, കടലിന്റെ മക്കൾക്ക് കടലമ്മയാണ് സർവ്വസ്വവും.';
      } else if (name.contains('പരീക്കുട്ടി')) {
        return 'കറുത്തമ്മേ, നിന്നെ പിരിഞ്ഞു ജീവിക്കാൻ എനിക്ക് കഴിയില്ല.';
      }
      return 'ഇതാണ് കഥയിലെ എന്റെ ശബ്ദം.';
    }

    if (name.toLowerCase().contains('sherlock') || name.toLowerCase().contains('holmes')) {
      return 'Elementary, my dear friend. When you eliminate the impossible, whatever remains, must be the truth.';
    } else if (name.toLowerCase().contains('watson')) {
      return 'Holmes, your methods of deduction never cease to astonish me.';
    } else if (name.toLowerCase().contains('dracula')) {
      return 'Listen to them, the children of the night. What music they make!';
    } else if (name.toLowerCase().contains('alice')) {
      return 'Curiouser and curiouser! What a wonderfully strange world this is.';
    }

    return 'Hello, I will be speaking as $name in this audiobook experience.';
  }

  Future<void> _auditionVoice(Character character, VoiceProfile profile) async {
    if (_currentlyAuditioningId == character.id) {
      // Stop preview
      await widget.voiceEngine.ttsProvider.stop();
      if (mounted) setState(() => _currentlyAuditioningId = null);
      return;
    }

    setState(() => _currentlyAuditioningId = character.id);
    final sample = _getAuditionSampleLine(character);

    try {
      await widget.voiceEngine.ttsProvider.speakDirectly(
        sample,
        profile,
        onCompletion: () {
          if (mounted) setState(() => _currentlyAuditioningId = null);
        },
        onError: (err) {
          if (mounted) setState(() => _currentlyAuditioningId = null);
        },
      );
    } catch (_) {
      if (mounted) setState(() => _currentlyAuditioningId = null);
    }
  }

  @override
  void dispose() {
    widget.voiceEngine.ttsProvider.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF18130E) : const Color(0xFFFBF7F2);
    final cardBg = isDark ? const Color(0xFF241C15) : const Color(0xFFEFE6DA);
    final textPrimary = isDark ? const Color(0xFFF7F2EB) : const Color(0xFF261D13);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(
            color: widget.accentColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
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
          // Drag Handle
          Center(
            child: Container(
              width: 42,
              height: 4.5,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.record_voice_over_rounded,
                  color: widget.accentColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Voice Cast & Audition',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      'Listen to character voices and personalize pitch and speed',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : const Color(0xFF5A4936),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close_rounded, color: textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Character Cards
          Expanded(
            child: ListView.separated(
              itemCount: _bookCharacters.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final character = _bookCharacters[i];
                final profile = widget.voiceEngine.getVoiceProfile(character.id);
                final charColor = _parseHex(character.colorHex, widget.accentColor);
                final isAuditioning = _currentlyAuditioningId == character.id;

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isAuditioning
                          ? widget.accentColor
                          : widget.accentColor.withValues(alpha: 0.15),
                      width: isAuditioning ? 1.5 : 1.0,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name & Audition Button
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: charColor.withValues(alpha: 0.2),
                            child: Icon(
                              Icons.person_rounded,
                              size: 16,
                              color: charColor,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              character.name,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _auditionVoice(character, profile),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isAuditioning
                                  ? Colors.redAccent
                                  : widget.accentColor,
                              foregroundColor: isAuditioning
                                  ? Colors.white
                                  : const Color(0xFF1E140A),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: Icon(
                              isAuditioning
                                  ? Icons.stop_rounded
                                  : Icons.volume_up_rounded,
                              size: 15,
                            ),
                            label: Text(
                              isAuditioning ? 'Stop' : 'Audition',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Voice Model Selector
                      Row(
                        children: [
                          Text(
                            'Voice Model:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : const Color(0xFF4A3B2C),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1A130D) : const Color(0xFFE4D7C7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _availableProfiles.any((p) => p.id == character.voiceProfileId)
                                      ? character.voiceProfileId
                                      : 'voice_narrator',
                                  isExpanded: true,
                                  dropdownColor: isDark ? const Color(0xFF2A2016) : Colors.white,
                                  icon: Icon(Icons.arrow_drop_down, color: widget.accentColor),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  onChanged: (newProfileId) {
                                    if (newProfileId != null) {
                                      setState(() {
                                        widget.voiceEngine.assignVoice(character.id, newProfileId);
                                        _bookCharacters[i] = character.copyWith(voiceProfileId: newProfileId);
                                      });
                                    }
                                  },
                                  items: _availableProfiles.map((p) {
                                    return DropdownMenuItem<String>(
                                      value: p.id,
                                      child: Text(p.name, overflow: TextOverflow.ellipsis),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Pitch & Speed sliders
                      Row(
                        children: [
                          // Pitch
                          Expanded(
                            child: Row(
                              children: [
                                Text(
                                  'Pitch',
                                  style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
                                ),
                                Expanded(
                                  child: Slider(
                                    value: profile.pitch,
                                    min: 0.5,
                                    max: 1.8,
                                    activeColor: widget.accentColor,
                                    onChanged: (val) {
                                      final updated = profile.copyWith(pitch: val);
                                      widget.voiceEngine.updateVoiceProfile(updated);
                                      setState(() {});
                                    },
                                  ),
                                ),
                                Text(
                                  profile.pitch.toStringAsFixed(1),
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textPrimary),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Speed
                          Expanded(
                            child: Row(
                              children: [
                                Text(
                                  'Speed',
                                  style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
                                ),
                                Expanded(
                                  child: Slider(
                                    value: profile.speed,
                                    min: 0.5,
                                    max: 2.0,
                                    activeColor: widget.accentColor,
                                    onChanged: (val) {
                                      final updated = profile.copyWith(speed: val);
                                      widget.voiceEngine.updateVoiceProfile(updated);
                                      setState(() {});
                                    },
                                  ),
                                ),
                                Text(
                                  '${profile.speed.toStringAsFixed(1)}x',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textPrimary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),

          // Done Button
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.accentColor,
              foregroundColor: const Color(0xFF1E140A),
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Save Voice Preferences',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
