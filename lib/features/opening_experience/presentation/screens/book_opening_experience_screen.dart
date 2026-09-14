import 'package:epub_audio/features/audio/presentation/screens/audiobook_player_screen.dart';
import 'package:epub_audio/features/epub/domain/entities/book.dart';
import 'package:epub_audio/features/opening_experience/data/repositories/book_opening_repository_impl.dart';
import 'package:epub_audio/features/opening_experience/domain/entities/book_opening_config.dart';
import 'package:epub_audio/features/opening_experience/domain/repositories/book_opening_repository.dart';
import 'package:epub_audio/features/opening_experience/presentation/widgets/atmosphere_particles_painter.dart';
import 'package:epub_audio/features/opening_experience/presentation/widgets/book_cover_3d_stage.dart';
import 'package:epub_audio/features/reader/presentation/screens/reader_screen.dart';
import 'package:epub_audio/features/session/presentation/controllers/book_session_controller.dart';
import 'package:epub_audio/features/voice/data/providers/device_tts_provider.dart';
import 'package:epub_audio/features/voice/domain/services/voice_engine.dart';
import 'package:epub_audio/features/voice/presentation/widgets/book_voice_audition_modal.dart';
import 'package:flutter/material.dart';

/// Immersive Book Opening Experience screen before launching into Reader or Audio engines.
/// Features 3D cover staging, dynamic theme backdrop, atmospheric particles, voice cast chips,
/// and instant Read / Listen triggers.
class BookOpeningExperienceScreen extends StatefulWidget {
  final Book book;
  final String? categoryId;
  final BookOpeningRepository? repository;
  final VoidCallback? onReadNow;
  final VoidCallback? onListenNow;

  const BookOpeningExperienceScreen({
    super.key,
    required this.book,
    this.categoryId,
    this.repository,
    this.onReadNow,
    this.onListenNow,
  });

  @override
  State<BookOpeningExperienceScreen> createState() => _BookOpeningExperienceScreenState();
}

class _BookOpeningExperienceScreenState extends State<BookOpeningExperienceScreen> {
  late final BookOpeningRepository _repository;
  late final VoiceEngine _voiceEngine;
  BookOpeningConfig _config = BookOpeningConfig.defaultConfig;
  bool _isLoading = true;
  bool _isAmbientAudioActive = true;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? BookOpeningRepositoryImpl();
    _voiceEngine = VoiceEngine(ttsProvider: DeviceTtsProvider());
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final config = await _repository.resolveOpeningConfig(
      book: widget.book,
      categoryId: widget.categoryId,
    );

    if (mounted) {
      setState(() {
        _config = config;
        _isLoading = false;
      });
    }
  }

  void _showVoiceAuditionModal() {
    BookVoiceAuditionModal.show(
      context,
      book: widget.book,
      voiceEngine: _voiceEngine,
      characterVoiceNames: _config.characterVoiceNames,
      accentColor: _parseColor(_config.accentColorHex, const Color(0xFFD4A373)),
    );
  }

  void _handleRead() {
    if (widget.onReadNow != null) {
      widget.onReadNow!();
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ReaderScreen(book: widget.book),
      ),
    );
  }

  void _handleListen() {
    if (widget.onListenNow != null) {
      widget.onListenNow!();
      return;
    }
    final session = BookSessionController(book: widget.book);
    session.playAudio();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => AudiobookPlayerScreen(session: session),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = _parseColor(_config.accentColorHex, const Color(0xFFD4A373));
    final gradientColors = _config.gradientHexColors.isNotEmpty
        ? _config.gradientHexColors
            .map((h) => _parseColor(h, isDark ? const Color(0xFF19130D) : const Color(0xFFF9F3EA)))
            .toList()
        : [
            isDark ? const Color(0xFF201811) : const Color(0xFFF6EDE2),
            isDark ? const Color(0xFF0E0906) : const Color(0xFFE8DACB),
          ];

    final titleColor = isDark ? const Color(0xFFF8F3ED) : const Color(0xFF261D13);
    final subColor = isDark ? const Color(0xFFA89F93) : const Color(0xFF7A6E5F);

    return Scaffold(
      backgroundColor: gradientColors.last,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // 1. Dynamic Atmosphere Gradient Background
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: gradientColors,
                    ),
                  ),
                ),

                // 2. Atmospheric Particle Effect System
                Positioned.fill(
                  child: AtmosphereParticlesOverlay(
                    effectId: _config.atmosphereEffectId,
                    accentColor: accentColor,
                  ),
                ),

                // 3. Main Content Scroll View
                SafeArea(
                  child: Column(
                    children: [
                      // Top Bar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.close_rounded),
                              color: titleColor,
                              tooltip: 'Close',
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.auto_awesome_rounded, size: 12, color: accentColor),
                                  const SizedBox(width: 5),
                                  Text(
                                    _config.themeId.replaceAll('_', ' ').toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: accentColor,
                                      letterSpacing: 0.7,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() => _isAmbientAudioActive = !_isAmbientAudioActive);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    duration: const Duration(seconds: 1),
                                    content: Text(
                                      _isAmbientAudioActive
                                          ? 'Atmospheric Ambience Enabled'
                                          : 'Ambience Muted',
                                    ),
                                  ),
                                );
                              },
                              icon: Icon(
                                _isAmbientAudioActive
                                    ? Icons.volume_up_rounded
                                    : Icons.volume_off_rounded,
                                color: _isAmbientAudioActive ? accentColor : subColor,
                              ),
                              tooltip: 'Toggle Ambience',
                            ),
                          ],
                        ),
                      ),

                      // Center 3D Stage & Details
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: [
                              const SizedBox(height: 12),

                              // 3D Book Stage
                              BookCover3DStage(
                                book: widget.book,
                                accentColor: accentColor,
                                isDark: isDark,
                                animationType: _config.animationType,
                              ),

                              const SizedBox(height: 28),

                              // Title & Author
                              Text(
                                widget.book.metadata.title,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: titleColor,
                                  height: 1.2,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                widget.book.metadata.author,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: accentColor,
                                ),
                              ),

                              const SizedBox(height: 14),

                              // Metadata Pills
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildMetaChip(
                                    widget.book.metadata.language == 'ml' ? 'Malayalam' : 'English',
                                    Icons.translate_rounded,
                                    accentColor,
                                    isDark,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildMetaChip(
                                    '${widget.book.chapterCount} Chapters',
                                    Icons.format_list_numbered_rounded,
                                    accentColor,
                                    isDark,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildMetaChip(
                                    'TTS Sync',
                                    Icons.mic_none_rounded,
                                    accentColor,
                                    isDark,
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // Description snippet
                              if (widget.book.metadata.description != null &&
                                  widget.book.metadata.description!.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF1E1711).withValues(alpha: 0.8)
                                        : const Color(0xFFFAF2E6).withValues(alpha: 0.9),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: accentColor.withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: Text(
                                    widget.book.metadata.description!,
                                    textAlign: TextAlign.center,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: subColor,
                                      height: 1.35,
                                    ),
                                  ),
                                ),

                              const SizedBox(height: 18),

                              // Character Cast Chips & Audition Trigger
                              if (_config.characterVoiceNames.isNotEmpty) ...[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Voice & Narrator Cast',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: titleColor,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: _showVoiceAuditionModal,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.tune_rounded, size: 14, color: accentColor),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Audition Cast',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                              color: accentColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _config.characterVoiceNames.map((voice) {
                                    return GestureDetector(
                                      onTap: _showVoiceAuditionModal,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF261D15) : const Color(0xFFEFE2D2),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: accentColor.withValues(alpha: 0.25)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.record_voice_over_rounded, size: 12, color: accentColor),
                                            const SizedBox(width: 5),
                                            Text(
                                              voice,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: isDark ? Colors.white70 : const Color(0xFF3B2E21),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],

                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),

                      // 4. Bottom Action Launch Bar
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF17110B) : const Color(0xFFF7EFE4),
                          border: Border(
                            top: BorderSide(
                              color: isDark ? const Color(0xFF2E2217) : const Color(0xFFE2D4C3),
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Read Button
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _handleRead,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: titleColor,
                                  side: BorderSide(color: accentColor, width: 1.3),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                icon: const Icon(Icons.auto_stories_rounded, size: 18),
                                label: const Text(
                                  'Read Book',
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Listen Button
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _handleListen,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: accentColor,
                                  foregroundColor: const Color(0xFF1E140A),
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                icon: const Icon(Icons.headphones_rounded, size: 18),
                                label: const Text(
                                  'Listen Audio',
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMetaChip(String label, IconData icon, Color accent, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF261D15) : const Color(0xFFEFE2D2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: accent),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFE8DCCE) : const Color(0xFF382C1E),
            ),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String hexStr, Color fallback) {
    try {
      final clean = hexStr.replaceAll('#', '').replaceAll('0x', '');
      if (clean.length == 6) {
        return Color(int.parse('FF$clean', radix: 16));
      } else if (clean.length == 8) {
        return Color(int.parse(clean, radix: 16));
      }
      return fallback;
    } catch (_) {
      return fallback;
    }
  }
}
