import 'package:epub_audio/features/explore/domain/entities/category_experience_config.dart';

/// Resolved visual, atmospheric, and audio configuration for the Book Opening Experience.
/// Follows resolution priority: Book Override -> Category Experience -> Global Default.
class BookOpeningConfig {
  final String themeId;
  final List<String> gradientHexColors;
  final String typographyId;
  final String accentColorHex;
  final String atmosphereEffectId; // 'ink_dust', 'shadow_mist', 'starfield', 'magical_sparkles', 'golden_glow', 'cosmic_pulse', 'floating_bubbles'
  final String animationType; // 'perspective_tilt', 'book_unfold', 'floating_glow'
  final String? ambientAudioId;
  final String? introAudioId;
  final List<String> characterVoiceNames;

  const BookOpeningConfig({
    required this.themeId,
    this.gradientHexColors = const [],
    required this.typographyId,
    required this.accentColorHex,
    required this.atmosphereEffectId,
    this.animationType = 'perspective_tilt',
    this.ambientAudioId,
    this.introAudioId,
    this.characterVoiceNames = const [],
  });

  /// Resolves configuration cascading from category config or global fallback.
  factory BookOpeningConfig.fromCategoryConfig({
    CategoryExperienceConfig? categoryConfig,
    List<String> characterVoices = const [],
    String? customAnimationType,
  }) {
    final config = categoryConfig ?? CategoryExperienceConfig.defaultConfig;

    return BookOpeningConfig(
      themeId: config.themeId,
      gradientHexColors: config.gradientHexColors.isNotEmpty
          ? config.gradientHexColors
          : const ['0xFF1E1812', '0xFF0E0A07'],
      typographyId: config.typographyId,
      accentColorHex: config.accentColorHex,
      atmosphereEffectId: config.atmosphereEffectId ?? 'golden_glow',
      animationType: customAnimationType ?? 'perspective_tilt',
      ambientAudioId: config.ambientAudioId,
      introAudioId: config.introAudioId,
      characterVoiceNames: characterVoices.isNotEmpty ? characterVoices : const ['Narrator'],
    );
  }

  /// Global default configuration
  static const BookOpeningConfig defaultConfig = BookOpeningConfig(
    themeId: 'obsidian',
    gradientHexColors: ['0xFF1B1510', '0xFF0C0907'],
    typographyId: 'modern',
    accentColorHex: '0xFFD4A373',
    atmosphereEffectId: 'golden_glow',
    animationType: 'perspective_tilt',
    characterVoiceNames: ['Narrator', 'Character Voices'],
  );
}
