import 'dart:math' as math;
import 'package:epub_audio/features/epub/domain/entities/book.dart';
import 'package:flutter/material.dart';

/// Minimalist classical decorative styles for book spines.
enum SpineDecorativeStyle {
  /// Classic Oxford with clean gold rules and understated embossing.
  classicGoldRules,

  /// Minimal two-tone band with clean contrast.
  twoToneMinimal,

  /// Clean raised leather spine hub with Roman numeral accent.
  raisedHubs,

  /// Modern antiquarian with understated border lines.
  modernAntiquarian,

  /// Clean embossed monogram badge.
  embossedCameo,
}

/// Palette configuration for book spines inspired by classic ancient library collections.
class SpinePalette {
  final Color primary;
  final Color accent;
  final Color text;
  final Color highlight;
  final Color shadow;
  final Color groove;
  final Color foil;

  const SpinePalette({
    required this.primary,
    required this.accent,
    required this.text,
    required this.highlight,
    required this.shadow,
    required this.groove,
    this.foil = const Color(0xFFD4AF37),
  });

  /// Curated harmonious, eye-pleasing classical library bindings
  static const List<SpinePalette> curatedPalettes = [
    // 0: Vintage Calfskin Chestnut (Warm Rich Leather)
    SpinePalette(
      primary: Color(0xFF4A2E1B),
      accent: Color(0xFFE2BE76),
      text: Color(0xFFFAF3E0),
      highlight: Color(0xFF5E3B22),
      shadow: Color(0xFF331E11),
      groove: Color(0xFF1E1008),
      foil: Color(0xFFD4AF37),
    ),
    // 1: Antiquarian Burgundy Morocco (Deep Wine Leather)
    SpinePalette(
      primary: Color(0xFF4C1D24),
      accent: Color(0xFFECD08B),
      text: Color(0xFFFAF2E9),
      highlight: Color(0xFF622730),
      shadow: Color(0xFF311116),
      groove: Color(0xFF1D090C),
      foil: Color(0xFFD9B464),
    ),
    // 2: Oxford Library Navy (Muted Prussian Blue Cloth)
    SpinePalette(
      primary: Color(0xFF203244),
      accent: Color(0xFFDFBF80),
      text: Color(0xFFF1F5F9),
      highlight: Color(0xFF2B4157),
      shadow: Color(0xFF15222E),
      groove: Color(0xFF0C141D),
      foil: Color(0xFFD8B26E),
    ),
    // 3: Antique Forest Moss (Subtle Muted Green Cloth)
    SpinePalette(
      primary: Color(0xFF2A3A2B),
      accent: Color(0xFFE0C895),
      text: Color(0xFFF3F6F2),
      highlight: Color(0xFF374D39),
      shadow: Color(0xFF1A261B),
      groove: Color(0xFF111A12),
      foil: Color(0xFFD0AE60),
    ),
    // 4: Burnt Sienna & Terracotta (Warm Earth Leather)
    SpinePalette(
      primary: Color(0xFF5A301E),
      accent: Color(0xFFF3D492),
      text: Color(0xFFFFF9F0),
      highlight: Color(0xFF723F2A),
      shadow: Color(0xFF3C1E12),
      groove: Color(0xFF26120A),
      foil: Color(0xFFDDB766),
    ),
    // 5: Aged Parchment Vellum & Dark Oak Trim
    SpinePalette(
      primary: Color(0xFFC7B69C),
      accent: Color(0xFF4A2F1B),
      text: Color(0xFF2E1B0E),
      highlight: Color(0xFFD8CCB8),
      shadow: Color(0xFFA59276),
      groove: Color(0xFF7A684F),
      foil: Color(0xFF8B6528),
    ),
    // 6: Deep Chocolate Cordovan (Fine Polished Leather)
    SpinePalette(
      primary: Color(0xFF382318),
      accent: Color(0xFFE5C47D),
      text: Color(0xFFFFF7EA),
      highlight: Color(0xFF4C3122),
      shadow: Color(0xFF24160E),
      groove: Color(0xFF150B07),
      foil: Color(0xFFD4AF37),
    ),
    // 7: Muted Heather Slate (Refined Charcoal Linen)
    SpinePalette(
      primary: Color(0xFF31363D),
      accent: Color(0xFFD6C096),
      text: Color(0xFFEFF2F6),
      highlight: Color(0xFF40474F),
      shadow: Color(0xFF21252A),
      groove: Color(0xFF14161A),
      foil: Color(0xFFCBB078),
    ),
    // 8: Muted Antique Mulberry (Subtle Fig Leather)
    SpinePalette(
      primary: Color(0xFF3E2434),
      accent: Color(0xFFECCB92),
      text: Color(0xFFF9F2F7),
      highlight: Color(0xFF523246),
      shadow: Color(0xFF291723),
      groove: Color(0xFF1A0E16),
      foil: Color(0xFFD5AF64),
    ),
    // 9: Warm Ochre Cloth (Aged Goldenrod Buckram)
    SpinePalette(
      primary: Color(0xFF6B4E22),
      accent: Color(0xFF2A1A0B),
      text: Color(0xFFFFF9EE),
      highlight: Color(0xFF85622D),
      shadow: Color(0xFF483315),
      groove: Color(0xFF30200C),
      foil: Color(0xFFF2D184),
    ),
  ];

  static SpinePalette forBook(Book book, int index) {
    final hash = (book.id.hashCode.abs() + index * 7) % curatedPalettes.length;
    return curatedPalettes[hash];
  }
}

/// Minimal, Realistic Classical Book Spine Widget.
class RealisticBookSpineWidget extends StatelessWidget {
  final Book book;
  final int index;
  final bool isSelected;
  final bool isHighlighted;
  final VoidCallback? onTap;
  final double height;
  final double width;
  final double tiltAngle; // in degrees, e.g. -6 to +6
  final bool isHorizontalStack;
  final int stackCount;

  const RealisticBookSpineWidget({
    super.key,
    required this.book,
    required this.index,
    this.isSelected = false,
    this.isHighlighted = false,
    this.onTap,
    this.height = 148,
    this.width = 33,
    this.tiltAngle = 0.0,
    this.isHorizontalStack = false,
    this.stackCount = 1,
  });

  @override
  Widget build(BuildContext context) {
    if (isHorizontalStack) {
      return _buildHorizontalStack(context);
    }

    final palette = SpinePalette.forBook(book, index);
    final style = SpineDecorativeStyle
        .values[(book.id.hashCode.abs() + index) % SpineDecorativeStyle.values.length];

    final radians = tiltAngle * math.pi / 180.0;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()
          ..translateByDouble(0.0, isSelected ? -12.0 : 0.0, 0.0, 1.0)
          ..rotateZ(radians)
          ..scaleByDouble(
            isSelected ? 1.04 : 1.0,
            isSelected ? 1.04 : 1.0,
            1.0,
            1.0,
          ),
        child: Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            // 1. Natural Book Contact Shadow on Wooden Shelf Floor
            Positioned(
              bottom: isSelected ? -8 : -1.5,
              child: Container(
                width: width * (isSelected ? 1.08 : 0.90),
                height: isSelected ? 8 : 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isSelected ? 0.5 : 0.35),
                      blurRadius: isSelected ? 10 : 4,
                      offset: Offset(0, isSelected ? 4 : 1.5),
                    ),
                    if (isHighlighted || isSelected)
                      BoxShadow(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
                        blurRadius: 10,
                        spreadRadius: 1.5,
                      ),
                  ],
                ),
              ),
            ),

            // 2. The Minimal Realistic Cylindrical Spine Body
            Container(
              width: width,
              height: height,
              margin: const EdgeInsets.symmetric(horizontal: 1.2),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(2.5),
                  topRight: Radius.circular(2.5),
                  bottomLeft: Radius.circular(1.5),
                  bottomRight: Radius.circular(1.5),
                ),
                // Smooth, Pleasing Convex Leather Curvature
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    palette.groove,
                    palette.shadow,
                    palette.primary,
                    palette.highlight,
                    palette.primary,
                    palette.shadow,
                    palette.groove,
                  ],
                  stops: const [0.0, 0.08, 0.25, 0.50, 0.75, 0.92, 1.0],
                ),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFECD08B)
                      : palette.groove.withValues(alpha: 0.6),
                  width: isSelected ? 1.2 : 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    offset: const Offset(1.0, 2.0),
                    blurRadius: 3.0,
                  ),
                  if (isSelected || isHighlighted)
                    BoxShadow(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
                      blurRadius: 8,
                      spreadRadius: 1.0,
                    ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(2.2),
                  topRight: Radius.circular(2.2),
                  bottomLeft: Radius.circular(1.5),
                  bottomRight: Radius.circular(1.5),
                ),
                child: Stack(
                  children: [
                    // A. Top Headband Silk Threading (Clean Edge Accent)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 2.2,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF5A161C),
                              palette.foil,
                              const Color(0xFF5A161C),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // B. Bottom Tailband Silk Threading
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 2.0,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              palette.foil,
                              const Color(0xFF1E2833),
                              palette.foil,
                            ],
                          ),
                        ),
                      ),
                    ),

                    // C. Left and Right Subtle Hinge Creases
                    Positioned(
                      top: 2.5,
                      bottom: 2.0,
                      left: 1.8,
                      width: 0.6,
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.25),
                      ),
                    ),
                    Positioned(
                      top: 2.5,
                      bottom: 2.0,
                      right: 1.8,
                      width: 0.6,
                      child: Container(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),

                    // D. Minimal Spine Accents (Top & Bottom Rules / Hubs)
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: _buildSpineAccents(style, palette),
                      ),
                    ),

                    // E. Clean, Debossed Vertical Title
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 2),
                        child: RotatedBox(
                          quarterTurns: 3,
                          child: Text(
                            book.metadata.title.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'serif',
                              fontSize: width > 35 ? 10.0 : 8.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                              color: palette.text,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.7),
                                  offset: const Offset(0.5, 0.5),
                                  blurRadius: 1.2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // F. Dangling Satin Bookmark Ribbon (occasional)
                    if (index % 6 == 0)
                      Positioned(
                        bottom: -4,
                        left: width * 0.44,
                        child: Container(
                          width: 3.0,
                          height: 12,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0xFF8B1A24),
                                Color(0xFFB72834),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(1),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.35),
                                blurRadius: 2.0,
                                offset: const Offset(0.5, 1.5),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Minimal, refined spine accents (clean borders, understated ribs)
  Widget _buildSpineAccents(SpineDecorativeStyle style, SpinePalette palette) {
    switch (style) {
      case SpineDecorativeStyle.classicGoldRules:
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _goldRib(palette.foil),
                  const SizedBox(height: 1.5),
                  _goldRib(palette.foil.withValues(alpha: 0.6)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _goldRib(palette.foil.withValues(alpha: 0.6)),
                  const SizedBox(height: 1.5),
                  _goldRib(palette.foil),
                ],
              ),
            ),
          ],
        );

      case SpineDecorativeStyle.twoToneMinimal:
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              height: 14,
              width: double.infinity,
              decoration: BoxDecoration(
                color: palette.accent.withValues(alpha: 0.75),
                border: Border(
                  bottom: BorderSide(color: palette.foil, width: 0.6),
                ),
              ),
            ),
            Container(
              height: 6,
              width: double.infinity,
              decoration: BoxDecoration(
                color: palette.accent.withValues(alpha: 0.45),
                border: Border(
                  top: BorderSide(color: palette.foil, width: 0.5),
                ),
              ),
            ),
          ],
        );

      case SpineDecorativeStyle.raisedHubs:
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: _embossedHub(palette),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: _embossedHub(palette),
            ),
          ],
        );

      case SpineDecorativeStyle.embossedCameo:
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: palette.foil, width: 0.8),
                  color: palette.accent.withValues(alpha: 0.2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: _goldRib(palette.foil),
            ),
          ],
        );

      case SpineDecorativeStyle.modernAntiquarian:
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 5),
              height: 1.2,
              width: width * 0.70,
              color: palette.foil,
            ),
            Container(
              margin: const EdgeInsets.only(bottom: 5),
              height: 1.2,
              width: width * 0.70,
              color: palette.foil,
            ),
          ],
        );
    }
  }

  Widget _goldRib(Color color) {
    return Container(
      height: 1.0,
      width: width * 0.75,
      decoration: BoxDecoration(
        color: color,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            offset: const Offset(0, 0.5),
            blurRadius: 0.5,
          ),
        ],
      ),
    );
  }

  /// Minimal embossed leather hub
  Widget _embossedHub(SpinePalette palette) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 0.6,
          width: width * 0.80,
          color: Colors.white.withValues(alpha: 0.18),
        ),
        Container(
          height: 1.6,
          width: width * 0.80,
          decoration: BoxDecoration(
            color: palette.primary,
            border: Border.symmetric(
              horizontal: BorderSide(color: palette.foil, width: 0.4),
            ),
          ),
        ),
        Container(
          height: 0.8,
          width: width * 0.80,
          color: Colors.black.withValues(alpha: 0.35),
        ),
      ],
    );
  }

  /// Minimal, Elegant Horizontal Stack of flat laid books with gilded page edges
  Widget _buildHorizontalStack(BuildContext context) {
    const stackWidth = 76.0;
    final count = math.min(3, math.max(2, stackCount));

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()
          ..translateByDouble(0.0, isSelected ? -8.0 : 0.0, 0.0, 1.0)
          ..scaleByDouble(
            isSelected ? 1.03 : 1.0,
            isSelected ? 1.03 : 1.0,
            1.0,
            1.0,
          ),
        margin: const EdgeInsets.symmetric(horizontal: 3),
        child: SizedBox(
          width: stackWidth,
          height: height,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: List.generate(count, (i) {
              final bookIndex = (index + i) % SpinePalette.curatedPalettes.length;
              final palette = SpinePalette.curatedPalettes[bookIndex];
              final isTopBook = i == 0;
              final currentWidth = stackWidth - (i * 4.0);
              const bookHeight = 22.0;

              return Container(
                width: currentWidth,
                height: bookHeight,
                margin: const EdgeInsets.only(bottom: 1.5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2.0),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      palette.highlight,
                      palette.primary,
                      palette.shadow,
                      palette.groove,
                    ],
                    stops: const [0.0, 0.30, 0.80, 1.0],
                  ),
                  border: Border.all(
                    color: isSelected && isTopBook
                        ? const Color(0xFFECD08B)
                        : palette.groove,
                    width: 0.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      offset: const Offset(0, 1.2),
                      blurRadius: 2.0,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Gilded Page Edge Accent
                    Positioned(
                      right: 3,
                      top: 2,
                      bottom: 2,
                      width: 12,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFDFC68A),
                              Color(0xFFFFF9ED),
                              Color(0xFFC7A762),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(1),
                          border: Border.all(
                            color: const Color(0xFF8E733B),
                            width: 0.4,
                          ),
                        ),
                      ),
                    ),

                    // Horizontal Spine Title
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 6, right: 18),
                        child: Row(
                          children: [
                            Container(
                              width: 1.5,
                              height: 8,
                              color: palette.foil,
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                (isTopBook ? book.metadata.title : 'VOL. ${i + 1}')
                                    .toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'serif',
                                  fontSize: 7.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                  color: palette.text,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withValues(alpha: 0.6),
                                      offset: const Offset(0.5, 0.5),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Bookmark Ribbon from top book
                    if (isTopBook)
                      Positioned(
                        left: 10,
                        bottom: -6,
                        child: Container(
                          width: 3.0,
                          height: 12,
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B1A24),
                            borderRadius: BorderRadius.circular(0.5),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
