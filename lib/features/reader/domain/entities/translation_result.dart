/// Model representing the result of translating text.
class TranslationResult {
  final String originalText;
  final String translatedText;
  final String sourceLanguage;
  final String targetLanguage;
  final bool isSuccess;
  final String? errorMessage;

  const TranslationResult({
    required this.originalText,
    required this.translatedText,
    required this.sourceLanguage,
    required this.targetLanguage,
    this.isSuccess = true,
    this.errorMessage,
  });

  factory TranslationResult.failure({
    required String originalText,
    required String sourceLanguage,
    required String targetLanguage,
    required String errorMessage,
  }) {
    return TranslationResult(
      originalText: originalText,
      translatedText: '',
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
      isSuccess: false,
      errorMessage: errorMessage,
    );
  }
}
