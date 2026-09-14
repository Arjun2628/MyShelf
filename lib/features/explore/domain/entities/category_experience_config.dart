/// Domain entity representing the visual and atmospheric identity of a category.
/// Pure Dart entity with zero Flutter UI dependencies.
class CategoryExperienceConfig {
  final String id;
  final String themeId; // e.g. 'parchment', 'dark_mystery', 'night_sky', 'fantasy', 'illustrated'
  final String? backgroundAsset;
  final List<String> gradientHexColors;
  final String typographyId; // e.g. 'classical', 'suspense', 'soft', 'playful', 'fantasy'
  final String accentColorHex;
  final String? atmosphereEffectId; // e.g. 'ink_dust', 'shadow_mist', 'starfield', 'magical_sparkles', 'clouds'
  final String? animationId;
  final String? ambientAudioId;
  final String? introAudioId;
  final String transitionType;

  const CategoryExperienceConfig({
    required this.id,
    required this.themeId,
    this.backgroundAsset,
    this.gradientHexColors = const [],
    required this.typographyId,
    required this.accentColorHex,
    this.atmosphereEffectId,
    this.animationId,
    this.ambientAudioId,
    this.introAudioId,
    this.transitionType = 'fade_scale',
  });

  /// Default fallback configuration
  static const CategoryExperienceConfig defaultConfig = CategoryExperienceConfig(
    id: 'default_config',
    themeId: 'obsidian',
    gradientHexColors: ['0xFF181512', '0xFF0E0C0A'],
    typographyId: 'modern',
    accentColorHex: '0xFFD4A373',
    atmosphereEffectId: 'subtle_glow',
    transitionType: 'fade_scale',
  );
}
