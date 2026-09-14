import 'package:epub_audio/features/explore/domain/entities/category.dart';
import 'package:epub_audio/features/explore/domain/entities/category_experience_config.dart';
import 'package:flutter/material.dart';

/// Card representing a category with themed gradient, icon, title, and book count.
class CategoryCard extends StatelessWidget {
  final Category category;
  final CategoryExperienceConfig? experienceConfig;
  final int bookCount;
  final VoidCallback? onTap;

  const CategoryCard({
    super.key,
    required this.category,
    this.experienceConfig,
    this.bookCount = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final config = experienceConfig ?? CategoryExperienceConfig.defaultConfig;

    final accentColor = _parseColor(config.accentColorHex, const Color(0xFFD4A373));
    final gradientColors = config.gradientHexColors.isNotEmpty
        ? config.gradientHexColors.map((h) => _parseColor(h, isDark ? const Color(0xFF221C16) : const Color(0xFFFAF4EB))).toList()
        : [
            isDark ? const Color(0xFF241D17) : const Color(0xFFF6EFE5),
            isDark ? const Color(0xFF14100C) : const Color(0xFFEADBCE),
          ];

    final titleColor = isDark ? const Color(0xFFF8F4EE) : const Color(0xFF2B2217);
    final subColor = isDark ? const Color(0xFFA89F93) : const Color(0xFF7A6F62);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          border: Border.all(
            color: accentColor.withValues(alpha: isDark ? 0.35 : 0.25),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _resolveCategoryIcon(category.iconName),
                    size: 20,
                    color: accentColor,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${category.bookIds.isNotEmpty ? category.bookIds.length : bookCount} books',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : const Color(0xFF3E3326),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  category.tagline,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: subColor,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ],
        ),
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

  IconData _resolveCategoryIcon(String iconName) {
    switch (iconName) {
      case 'history_edu_rounded':
        return Icons.history_edu_rounded;
      case 'psychology_alt_rounded':
        return Icons.psychology_alt_rounded;
      case 'menu_book_rounded':
        return Icons.menu_book_rounded;
      case 'rocket_launch_rounded':
        return Icons.rocket_launch_rounded;
      case 'bedtime_rounded':
        return Icons.bedtime_rounded;
      case 'auto_fix_high_rounded':
        return Icons.auto_fix_high_rounded;
      case 'child_care_rounded':
        return Icons.child_care_rounded;
      case 'lightbulb_rounded':
        return Icons.lightbulb_rounded;
      default:
        return Icons.auto_stories_rounded;
    }
  }
}
