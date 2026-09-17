import 'package:epub_audio/features/audio/presentation/screens/audiobook_player_screen.dart';
import 'package:epub_audio/features/epub/domain/entities/book.dart';
import 'package:epub_audio/features/explore/data/repositories/explore_repository_impl.dart';
import 'package:epub_audio/features/explore/domain/repositories/explore_repository.dart';
import 'package:epub_audio/features/explore/presentation/screens/explore_screen.dart';
import 'package:epub_audio/features/library/presentation/screens/library_screen.dart';
import 'package:epub_audio/features/opening_experience/presentation/screens/book_opening_experience_screen.dart';
import 'package:epub_audio/features/profile/presentation/screens/profile_screen.dart';
import 'package:epub_audio/features/reader/presentation/screens/reader_screen.dart';
import 'package:epub_audio/features/session/presentation/controllers/book_session_controller.dart';
import 'package:flutter/material.dart';

/// Root navigation shell hosting the Explore discovery hub, the core Library, and User Profile.
class MainNavigationShell extends StatefulWidget {
  final ExploreRepository? exploreRepository;

  const MainNavigationShell({
    super.key,
    this.exploreRepository,
  });

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentTabIndex = 0;
  late final ExploreRepository _exploreRepository;

  @override
  void initState() {
    super.initState();
    _exploreRepository = widget.exploreRepository ?? ExploreRepositoryImpl();
  }

  void _openBookExperience(Book book, {String? categoryId}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookOpeningExperienceScreen(
          book: book,
          categoryId: categoryId,
        ),
      ),
    );
  }

  void _openReader(Book book, {int? chapterIndex, int? paragraphIndex}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReaderScreen(
          book: book,
          initialChapterIndex: chapterIndex,
          initialParagraphIndex: paragraphIndex,
        ),
      ),
    );
  }

  void _openAudiobook(Book book) async {
    final session = BookSessionController(book: book);
    session.playAudio();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AudiobookPlayerScreen(session: session),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canvasBg = isDark ? const Color(0xFF14161A) : const Color(0xFFF8FAFC);
    final navBarBg = isDark ? const Color(0xFF1A1D24) : Colors.white.withValues(alpha: 0.96);
    final navBarActive = isDark ? const Color(0xFFEADBCE) : const Color(0xFF2563EB);
    final navBarInactive = isDark ? const Color(0xFF8C93A0) : const Color(0xFF64748B);
    final navBorderColor = isDark ? const Color(0xFF2B313D) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: canvasBg,
      body: IndexedStack(
        index: _currentTabIndex,
        children: [
          // Tab 0: Explore Discovery Hub
          ExploreScreen(
            repository: _exploreRepository,
            onBookSelected: (book) => _openBookExperience(book),
            onReadBook: (book) => _openReader(book),
            onListenBook: (book) => _openAudiobook(book),
            onProfileTap: () => setState(() => _currentTabIndex = 2),
          ),

          // Tab 1: Library & Bookshelves
          const LibraryScreen(hideInternalNavBar: true),

          // Tab 2: User Profile & Identity
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        color: canvasBg,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
        child: Container(
          decoration: BoxDecoration(
            color: navBarBg,
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.16),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(
              color: navBorderColor,
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              _buildNavTabItem(
                index: 0,
                label: 'Explore',
                icon: Icons.explore_rounded,
                inactiveIcon: Icons.explore_outlined,
                isActive: _currentTabIndex == 0,
                isDark: isDark,
                activeColor: navBarActive,
                inactiveColor: navBarInactive,
              ),
              _buildNavTabItem(
                index: 1,
                label: 'Library',
                icon: Icons.auto_stories_rounded,
                inactiveIcon: Icons.auto_stories_outlined,
                isActive: _currentTabIndex == 1,
                isDark: isDark,
                activeColor: navBarActive,
                inactiveColor: navBarInactive,
              ),
              _buildNavTabItem(
                index: 2,
                label: 'Profile',
                icon: Icons.person_rounded,
                inactiveIcon: Icons.person_outline_rounded,
                isActive: _currentTabIndex == 2,
                isDark: isDark,
                activeColor: navBarActive,
                inactiveColor: navBarInactive,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavTabItem({
    required int index,
    required String label,
    required IconData icon,
    required IconData inactiveIcon,
    required bool isActive,
    required bool isDark,
    required Color activeColor,
    required Color inactiveColor,
  }) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _currentTabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? (isDark ? const Color(0xFF2C313D) : const Color(0xFFEFF6FF))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isActive ? icon : inactiveIcon,
                size: 18,
                color: isActive ? activeColor : inactiveColor,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                  color: isActive ? activeColor : inactiveColor,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
