import 'package:epub_audio/features/audio/data/services/flutter_tts_audio_engine.dart';
import 'package:epub_audio/features/reader/data/services/translation_service.dart';
import 'package:epub_audio/features/reader/domain/entities/reader_preferences.dart';
import 'package:epub_audio/features/reader/domain/entities/translation_result.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Modal bottom sheet displaying translation of selected text with TTS and language options.
class TranslationModal extends StatefulWidget {
  final String text;
  final ReaderPreferences preferences;
  final String? bookLanguage;
  final void Function(String translatedText)? onSaveAsNote;

  const TranslationModal({
    super.key,
    required this.text,
    required this.preferences,
    this.bookLanguage,
    this.onSaveAsNote,
  });

  @override
  State<TranslationModal> createState() => _TranslationModalState();
}

class _TranslationModalState extends State<TranslationModal> {
  final TranslationService _translationService = TranslationService();
  final FlutterTtsAudioEngine _ttsEngine = FlutterTtsAudioEngine();

  late String _sourceLang;
  late String _targetLang;
  TranslationResult? _result;
  bool _isLoading = true;
  bool _isSpeakingOriginal = false;
  bool _isSpeakingTranslated = false;

  @override
  void initState() {
    super.initState();
    _sourceLang = _translationService.detectLanguage(widget.text);
    _targetLang = _sourceLang == 'ml' ? 'en' : 'ml';
    _performTranslation();
  }

  @override
  void dispose() {
    _ttsEngine.dispose();
    super.dispose();
  }

  Future<void> _performTranslation() async {
    setState(() {
      _isLoading = true;
    });

    final res = await _translationService.translate(
      widget.text,
      sourceLang: _sourceLang,
      targetLang: _targetLang,
    );

    if (mounted) {
      setState(() {
        _result = res;
        _isLoading = false;
      });
    }
  }

  Future<void> _speakText(String text, String lang, {required bool isOriginal}) async {
    if (isOriginal) {
      setState(() => _isSpeakingOriginal = true);
    } else {
      setState(() => _isSpeakingTranslated = true);
    }

    await _ttsEngine.speakParagraph(text, language: lang);

    if (mounted) {
      setState(() {
        if (isOriginal) _isSpeakingOriginal = false;
        if (!isOriginal) _isSpeakingTranslated = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.preferences.colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
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
                color: colors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header with Language Selectors
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.translate_rounded, color: colors.accent, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Translation',
                    style: TextStyle(
                      color: colors.text,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _buildLanguageDropdown(_sourceLang, (val) {
                    if (val != null && val != _sourceLang) {
                      setState(() => _sourceLang = val);
                      _performTranslation();
                    }
                  }, colors),
                  Icon(Icons.arrow_forward_rounded, size: 16, color: colors.secondaryText),
                  _buildLanguageDropdown(_targetLang, (val) {
                    if (val != null && val != _targetLang) {
                      setState(() => _targetLang = val);
                      _performTranslation();
                    }
                  }, colors),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Original Text Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      TranslationService.supportedLanguages[_sourceLang] ?? _sourceLang.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: colors.secondaryText,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _isSpeakingOriginal ? Icons.stop_circle_rounded : Icons.volume_up_rounded,
                        size: 20,
                        color: colors.accent,
                      ),
                      tooltip: 'Pronounce original text',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _speakText(widget.text, _sourceLang, isOriginal: true),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  widget.text,
                  style: TextStyle(
                    fontSize: 15,
                    color: colors.text,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Translation Result Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.accent.withValues(alpha: 0.3)),
            ),
            child: _isLoading
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: colors.accent),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Translating...',
                            style: TextStyle(color: colors.secondaryText, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            TranslationService.supportedLanguages[_targetLang] ?? _targetLang.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: colors.accent,
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  _isSpeakingTranslated ? Icons.stop_circle_rounded : Icons.volume_up_rounded,
                                  size: 20,
                                  color: colors.accent,
                                ),
                                tooltip: 'Pronounce translation',
                                visualDensity: VisualDensity.compact,
                                onPressed: _result?.translatedText.isNotEmpty == true
                                    ? () => _speakText(_result!.translatedText, _targetLang, isOriginal: false)
                                    : null,
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy_rounded, size: 18),
                                color: colors.text,
                                tooltip: 'Copy translation',
                                visualDensity: VisualDensity.compact,
                                onPressed: _result?.translatedText.isNotEmpty == true
                                    ? () {
                                        Clipboard.setData(ClipboardData(text: _result!.translatedText));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Translation copied to clipboard'),
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      }
                                    : null,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _result?.isSuccess == true
                            ? _result!.translatedText
                            : (_result?.errorMessage ?? 'Translation unavailable'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _result?.isSuccess == true ? colors.text : Colors.redAccent,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 16),

          // Action Buttons
          if (widget.onSaveAsNote != null && _result?.isSuccess == true)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.bookmark_add_rounded, size: 18),
                label: const Text('Save as Highlight Note'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  widget.onSaveAsNote?.call(_result!.translatedText);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLanguageDropdown(String current, ValueChanged<String?> onChanged, ReaderThemeColors colors) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: current,
        icon: Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: colors.secondaryText),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: colors.text,
        ),
        dropdownColor: colors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        items: TranslationService.supportedLanguages.entries.map((e) {
          return DropdownMenuItem<String>(
            value: e.key,
            child: Text(e.key.toUpperCase(), style: TextStyle(color: colors.text)),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
