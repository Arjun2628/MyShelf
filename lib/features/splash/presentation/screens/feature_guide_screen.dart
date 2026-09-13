import 'package:epub_audio/features/library/data/datasources/hive_storage_service.dart';
import 'package:epub_audio/features/library/presentation/screens/library_screen.dart';
import 'package:flutter/material.dart';

/// Interactive feature guide and onboarding walkthrough.
/// Explains the 4 core pillars: Reader, Audiobooks, OCR Scanner, and Translation.
class FeatureGuideScreen extends StatefulWidget {
  final VoidCallback? onCompleted;

  const FeatureGuideScreen({
    super.key,
    this.onCompleted,
  });

  @override
  State<FeatureGuideScreen> createState() => _FeatureGuideScreenState();
}

class _FeatureGuideScreenState extends State<FeatureGuideScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_GuidePageData> _pages = const [
    _GuidePageData(
      icon: Icons.auto_stories_rounded,
      tag: 'READING EXPERIENCE',
      title: 'Immersive EPUB & PDF Reader',
      description:
          'Enjoy quiet, distraction-free reading with customizable fonts, margin controls, rich PDF viewing, and gorgeous themes (Dark, Sepia, Cream, Forest, Midnight).',
      highlights: [
        'Interactive text selection & multi-color highlights',
        'Personal bookmarks & chapter navigation',
        'Seamless EPUB & PDF document rendering',
      ],
      accentGradient: [Color(0xFFE5C07B), Color(0xFF98C379)],
    ),
    _GuidePageData(
      icon: Icons.headphones_rounded,
      tag: 'AUDIOBOOK MODE',
      title: 'Live Synchronized Audiobooks',
      description:
          'Convert any book into an audiobook. Listen to continuous high-clarity voice narration with real-time glowing word tracking and lyrics-style upward auto-scroll.',
      highlights: [
        'Word-by-word glowing audio synchronization',
        'Background audio with lockscreen controls',
        'Speed multiplier (0.5x – 2.0x) & sleep timer',
      ],
      accentGradient: [Color(0xFF61AFEF), Color(0xFFC678DD)],
    ),
    _GuidePageData(
      icon: Icons.document_scanner_rounded,
      tag: 'SMART DIGITIZATION',
      title: 'Camera OCR Book Scanner',
      description:
          'Digitize physical books and printed documents in seconds. Uses on-device machine learning with smart paragraph segmentation and automatic regional language detection.',
      highlights: [
        'Auto-detection for Malayalam, Hindi, Tamil & English',
        'Smart paragraph merging without broken lines',
        'Direct multi-page camera & gallery batch scan',
      ],
      accentGradient: [Color(0xFF98C379), Color(0xFFE5C07B)],
    ),
    _GuidePageData(
      icon: Icons.translate_rounded,
      tag: 'GLOBAL LANGUAGES',
      title: 'Real-Time Translation & Notes',
      description:
          'Break language barriers across 30+ languages. Translate whole chapters or individual words, hear native pronunciations, and save multilingual notes.',
      highlights: [
        'Full chapter & selection instant translation',
        'Save translated excerpts directly as notes',
        'Bilingual voice playback support',
      ],
      accentGradient: [Color(0xFFE06C75), Color(0xFFE5C07B)],
    ),
  ];

  Future<void> _finishGuide() async {
    try {
      HiveStorageService().setHasSeenOnboarding(true);
    } catch (_) {}

    if (widget.onCompleted != null) {
      widget.onCompleted!();
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LibraryScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finishGuide();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];

    return Scaffold(
      backgroundColor: const Color(0xFF0F0D0B),
      body: Stack(
        children: [
          // Background ambient gradient
          AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.2),
                radius: 1.1,
                colors: [
                  page.accentGradient.first.withValues(alpha: 0.18),
                  page.accentGradient.last.withValues(alpha: 0.08),
                  const Color(0xFF0F0D0B),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top Bar: Logo & Skip
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.menu_book_rounded,
                            color: Color(0xFFF1D49B),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Welcome Guide',
                            style: TextStyle(
                              fontFamily: 'serif',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              color: const Color(0xFFFAF6EE),
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: _finishGuide,
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFB5A791),
                        ),
                        child: const Text(
                          'Skip',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),

                // Page View
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (idx) {
                      setState(() {
                        _currentPage = idx;
                      });
                    },
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      final item = _pages[index];
                      return SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 10),

                            // Glowing Emblem Card
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: item.accentGradient,
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: item.accentGradient.first.withValues(alpha: 0.35),
                                    blurRadius: 28,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Icon(
                                item.icon,
                                size: 46,
                                color: const Color(0xFF140D07),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Tag pill
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1D49B).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFFF1D49B).withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                item.tag,
                                style: const TextStyle(
                                  color: Color(0xFFF1D49B),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),

                            const SizedBox(height: 14),

                            // Title
                            Text(
                              item.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFAF6EE),
                                height: 1.25,
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Description
                            Text(
                              item.description,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14.5,
                                color: Color(0xFFC7B89E),
                                height: 1.45,
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Feature Bullet Cards
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1C1712),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFF332920),
                                ),
                              ),
                              child: Column(
                                children: item.highlights.map((h) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.check_circle_rounded,
                                          size: 16,
                                          color: Color(0xFFF1D49B),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            h,
                                            style: const TextStyle(
                                              color: Color(0xFFE4D9C6),
                                              fontSize: 13,
                                              height: 1.3,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Bottom Indicator & Next Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Page Dots
                      Row(
                        children: List.generate(
                          _pages.length,
                          (idx) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(right: 6),
                            width: _currentPage == idx ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _currentPage == idx
                                  ? const Color(0xFFF1D49B)
                                  : const Color(0xFF3D3227),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),

                      // Next / Explore Button
                      ElevatedButton(
                        onPressed: _nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF1D49B),
                          foregroundColor: const Color(0xFF1E140A),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          elevation: 6,
                          shadowColor: const Color(0xFFF1D49B).withValues(alpha: 0.35),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _currentPage == _pages.length - 1
                                  ? 'Get Started'
                                  : 'Next',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E140A),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 16,
                              color: Color(0xFF1E140A),
                            ),
                          ],
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
}

class _GuidePageData {
  final IconData icon;
  final String tag;
  final String title;
  final String description;
  final List<String> highlights;
  final List<Color> accentGradient;

  const _GuidePageData({
    required this.icon,
    required this.tag,
    required this.title,
    required this.description,
    required this.highlights,
    required this.accentGradient,
  });
}
