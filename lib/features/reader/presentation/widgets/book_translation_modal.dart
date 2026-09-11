import 'package:epub_audio/features/reader/data/services/translation_service.dart';
import 'package:epub_audio/features/reader/domain/entities/reader_preferences.dart';
import 'package:epub_audio/features/session/presentation/controllers/book_session_controller.dart';
import 'package:flutter/material.dart';

enum TranslationScope {
  currentChapter('Current Chapter', 'Translates only what you are currently reading (fastest)'),
  entireBook('Entire Book', 'Translates all chapters across the entire book');

  final String title;
  final String description;
  const TranslationScope(this.title, this.description);
}

/// Action modal for translating full chapter or entire book with dynamic TTS voice switching.
class BookTranslationModal extends StatefulWidget {
  final BookSessionController session;
  final ReaderPreferences preferences;

  const BookTranslationModal({
    super.key,
    required this.session,
    required this.preferences,
  });

  static Future<void> show(
    BuildContext context, {
    required BookSessionController session,
    required ReaderPreferences preferences,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BookTranslationModal(
        session: session,
        preferences: preferences,
      ),
    );
  }

  @override
  State<BookTranslationModal> createState() => _BookTranslationModalState();
}

class _BookTranslationModalState extends State<BookTranslationModal> {
  late String _selectedLangCode;
  TranslationScope _selectedScope = TranslationScope.currentChapter;
  bool _isTranslating = false;
  double _progress = 0.0;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _selectedLangCode = widget.session.activeTranslationLanguage ?? 'ml';
  }

  Future<void> _startTranslation() async {
    setState(() {
      _isTranslating = true;
      _progress = 0.05;
      _statusMessage = 'Preparing translation...';
    });

    try {
      if (_selectedScope == TranslationScope.currentChapter) {
        await widget.session.translateCurrentChapter(
          _selectedLangCode,
          onProgress: (prog, status) {
            if (mounted) {
              setState(() {
                _progress = prog;
                _statusMessage = status;
              });
            }
          },
        );
      } else {
        await widget.session.translateEntireBook(
          _selectedLangCode,
          onProgress: (prog, status) {
            if (mounted) {
              setState(() {
                _progress = prog;
                _statusMessage = status;
              });
            }
          },
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Translated to ${TranslationService().getLanguageName(_selectedLangCode)}! TTS voice updated.',
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTranslating = false;
          _statusMessage = 'Error: $e';
        });
      }
    }
  }

  Future<void> _revertToOriginal() async {
    await widget.session.revertToOriginalLanguage();
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reverted to original book language & voice.'),
          backgroundColor: Color(0xFF3B82F6),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.preferences.themeMode == ReaderThemeMode.night ||
        widget.preferences.themeMode == ReaderThemeMode.oledBlack;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Modal Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.translate_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Translate Book & Audio',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Translate reading text & switch TTS voice',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.session.isTranslated)
                  TextButton.icon(
                    icon: const Icon(Icons.undo_rounded, size: 16),
                    label: const Text('Original', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                    ),
                    onPressed: _isTranslating ? null : _revertToOriginal,
                  ),
              ],
            ),
            const SizedBox(height: 18),

            if (_isTranslating) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Color(0xFF3B82F6),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _statusMessage,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        Text(
                          '${(_progress * 100).round()}%',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3B82F6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _progress > 0 ? _progress : null,
                        backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ] else ...[
              // 1. Language Target Selection
              Text(
                'Select Target Language:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: TranslationService.languages.map((lang) {
                    final isSelected = _selectedLangCode == lang.code;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: ChoiceChip(
                        avatar: Text(lang.flag, style: const TextStyle(fontSize: 13)),
                        label: Text(lang.displayName),
                        selected: isSelected,
                        onSelected: (val) {
                          setState(() {
                            _selectedLangCode = lang.code;
                          });
                        },
                        selectedColor: const Color(0xFF3B82F6),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155)),
                          fontSize: 11.5,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                        backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        side: BorderSide(
                          color: isSelected
                              ? const Color(0xFF2563EB)
                              : (isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // 2. Translation Scope (Chapter vs Entire Book)
              Text(
                'Translation Scope:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildScopeOption(
                      scope: TranslationScope.currentChapter,
                      title: 'Current Chapter',
                      subtitle: 'Fast & Instant reading',
                      icon: Icons.article_rounded,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildScopeOption(
                      scope: TranslationScope.entireBook,
                      title: 'Entire Book',
                      subtitle: '${widget.session.book.chapterCount} Chapters',
                      icon: Icons.auto_stories_rounded,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 3. Audio TTS Sync Information Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.headphones_rounded, color: Color(0xFF3B82F6), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Continuous audiobook narration will automatically speak the translated text using native ${_selectedLangCode.toUpperCase()} speech voice with word highlighting.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E40AF),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.translate_rounded, size: 18),
                  label: Text(
                    'Translate to ${TranslationService().getLanguageName(_selectedLangCode)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: _startTranslation,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScopeOption({
    required TranslationScope scope,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isDark,
  }) {
    final isSelected = _selectedScope == scope;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedScope = scope;
        });
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF3B82F6).withValues(alpha: 0.12)
              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF3B82F6)
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF64748B),
                ),
                const Spacer(),
                if (isSelected)
                  const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF3B82F6)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
