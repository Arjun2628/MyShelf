import 'package:epub_audio/features/auth/presentation/controllers/auth_controller.dart';
import 'package:epub_audio/features/auth/presentation/widgets/auth_modal.dart';
import 'package:epub_audio/features/library/data/datasources/hive_storage_service.dart';
import 'package:epub_audio/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:epub_audio/features/profile/domain/entities/reading_stats.dart';
import 'package:epub_audio/features/profile/domain/entities/user_profile.dart';
import 'package:epub_audio/features/profile/domain/repositories/profile_repository.dart';
import 'package:epub_audio/features/profile/presentation/widgets/avatar_picker_modal.dart';
import 'package:epub_audio/features/admin/presentation/screens/admin_catalog_screen.dart';
import 'package:epub_audio/main.dart';
import 'package:flutter/material.dart';

/// Full-featured Profile & Reading Identity Screen with Auth & Role Management.
class ProfileScreen extends StatefulWidget {
  final ProfileRepository? repository;
  final AuthController? authController;

  const ProfileScreen({super.key, this.repository, this.authController});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ProfileRepository _repository;
  late final AuthController _auth;
  UserProfile _profile = const UserProfile();
  ReadingStats _stats = const ReadingStats();
  bool _isLoading = true;
  int _highlightCount = 0;
  int _bookmarkCount = 0;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ProfileRepositoryImpl();
    _auth = widget.authController ?? AuthController.instance;
    _auth.addListener(_handleAuthChanged);
    _loadProfileData();
  }

  @override
  void dispose() {
    _auth.removeListener(_handleAuthChanged);
    super.dispose();
  }

  void _handleAuthChanged() {
    if (mounted) {
      final authUser = _auth.currentUser;
      setState(() {
        _profile = _profile.copyWith(
          displayName: authUser.displayName,
          email: authUser.email ?? 'guest@scribbleverse.io',
          avatarEmoji: authUser.avatarEmoji,
          readerTier: authUser.isAdmin
              ? 'CURATOR • ADMIN TIER'
              : authUser.isGuest
                  ? 'GUEST • ANONYMOUS'
                  : 'READER • TIER 1',
        );
      });
    }
  }

  Future<void> _loadProfileData() async {
    final profile = await _repository.getUserProfile();
    final stats = await _repository.getReadingStats();

    // Check highlights & bookmarks count
    int highlights = 0;
    int bookmarks = 0;
    try {
      final storage = HiveStorageService();
      highlights = storage.getAllHighlights().length;
      bookmarks = storage.getAllBookmarks().length;
    } catch (_) {}

    if (mounted) {
      setState(() {
        _profile = profile;
        _stats = stats;
        _highlightCount = highlights;
        _bookmarkCount = bookmarks;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateProfile(UserProfile updated) async {
    setState(() => _profile = updated);
    await _repository.saveUserProfile(updated);
    await _loadProfileData();
  }

  Color _parseHex(String hex, Color fallback) {
    try {
      final clean = hex.replaceAll('#', '').replaceAll('0x', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  void _showAvatarCustomizer() {
    AvatarPickerModal.show(
      context,
      currentProfile: _profile,
      onProfileUpdated: _updateProfile,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canvasBg = isDark ? const Color(0xFF14100C) : const Color(0xFFFBF7F0);
    final cardBg = isDark ? const Color(0xFF1E1812) : const Color(0xFFFAF4EA);
    final borderColor = isDark ? const Color(0xFF382D21) : const Color(0xFFE2D4C3);
    final titleColor = isDark ? const Color(0xFFF7F2EB) : const Color(0xFF261D13);
    final subColor = isDark ? const Color(0xFFA89F93) : const Color(0xFF7A6E5F);
    final accentColor = _parseHex(_profile.avatarGradientStart, const Color(0xFFD4A373));
    final gradStart = _parseHex(_profile.avatarGradientStart, const Color(0xFFD4A373));
    final gradEnd = _parseHex(_profile.avatarGradientEnd, const Color(0xFFA8764B));

    if (_isLoading) {
      return Scaffold(
        backgroundColor: canvasBg,
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFFD4A373)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: canvasBg,
      body: CustomScrollView(
        slivers: [
          // App Bar Header
          SliverAppBar(
            pinned: true,
            backgroundColor: canvasBg,
            foregroundColor: titleColor,
            elevation: 0,
            title: Text(
              'Profile & Identity',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: titleColor,
                fontSize: 18,
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 12),

                  // 1. Avatar & Identity Header Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: borderColor, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Selected Avatar with edit trigger
                        GestureDetector(
                          onTap: _showAvatarCustomizer,
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                width: 88,
                                height: 88,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [gradStart, gradEnd],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: gradStart.withValues(alpha: 0.4),
                                      blurRadius: 14,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    _profile.avatarEmoji,
                                    style: const TextStyle(fontSize: 44),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF261D13) : Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: borderColor),
                                ),
                                child: Icon(Icons.edit_rounded, size: 14, color: accentColor),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _profile.displayName,
                          style: TextStyle(
                            fontSize: 19.5,
                            fontWeight: FontWeight.w800,
                            color: titleColor,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _profile.email,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: subColor,
                          ),
                        ),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () => AuthModal.show(context, authController: _auth),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: _auth.isAdmin
                                  ? const Color(0xFF8B5CF6).withValues(alpha: 0.2)
                                  : _auth.isGuest
                                      ? Colors.grey.withValues(alpha: 0.2)
                                      : accentColor.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _auth.isAdmin
                                    ? const Color(0xFF8B5CF6).withValues(alpha: 0.4)
                                    : _auth.isGuest
                                        ? Colors.grey.withValues(alpha: 0.3)
                                        : accentColor.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _auth.currentUser.roleBadge,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: _auth.isAdmin
                                        ? const Color(0xFF8B5CF6)
                                        : _auth.isGuest
                                            ? Colors.grey
                                            : accentColor,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.swap_horiz_rounded,
                                  size: 13,
                                  color: _auth.isAdmin
                                      ? const Color(0xFF8B5CF6)
                                      : _auth.isGuest
                                          ? Colors.grey
                                          : accentColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 2. Daily Reading Goal Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 54,
                          height: 54,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircularProgressIndicator(
                                value: _stats.dailyGoalProgress,
                                backgroundColor: isDark ? const Color(0xFF2E2419) : const Color(0xFFE2D4C3),
                                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                                strokeWidth: 5,
                              ),
                              Text(
                                '${(_stats.dailyGoalProgress * 100).toInt()}%',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: titleColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Daily Reading Goal',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  color: titleColor,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${_stats.todayMinutesCompleted} / ${_stats.dailyGoalMinutes} mins read today',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: subColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _showGoalCustomizer,
                          icon: Icon(Icons.tune_rounded, size: 18, color: accentColor),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 3. Streak & 7-Day Activity Matrix
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Text('🔥', style: TextStyle(fontSize: 18)),
                                const SizedBox(width: 8),
                                Text(
                                  '${_stats.currentStreakDays} Day Reading Streak',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: titleColor,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Best: ${_stats.longestStreakDays} days',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: subColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        // 7-day dot matrix
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: _stats.weeklyActivity.map((day) {
                            return Column(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: day.completed
                                        ? accentColor
                                        : (isDark ? const Color(0xFF281E15) : const Color(0xFFE2D4C3)),
                                    border: Border.all(
                                      color: day.completed ? accentColor : Colors.transparent,
                                    ),
                                  ),
                                  child: Center(
                                    child: day.completed
                                        ? const Icon(Icons.check_rounded, size: 16, color: Color(0xFF1E140A))
                                        : Text(
                                            '${day.minutes}',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: subColor,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  day.dayName,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: day.completed ? titleColor : subColor,
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 4. Reading & Listening Statistics Cards
                  Row(
                    children: [
                      _buildStatCard(
                        '${_stats.totalBooksCompleted}',
                        'Books Read',
                        Icons.auto_stories_rounded,
                        cardBg,
                        borderColor,
                        titleColor,
                        subColor,
                        accentColor,
                      ),
                      const SizedBox(width: 10),
                      _buildStatCard(
                        '${_stats.totalChaptersRead}',
                        'Chapters',
                        Icons.menu_book_rounded,
                        cardBg,
                        borderColor,
                        titleColor,
                        subColor,
                        accentColor,
                      ),
                      const SizedBox(width: 10),
                      _buildStatCard(
                        '${_stats.totalHoursListened.toStringAsFixed(1)}h',
                        'Audio Time',
                        Icons.headphones_rounded,
                        cardBg,
                        borderColor,
                        titleColor,
                        subColor,
                        accentColor,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 5. Highlights & Bookmarks Quick Cards
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderColor),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.highlight_rounded, size: 20, color: accentColor),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$_highlightCount Highlights',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: titleColor),
                                  ),
                                  Text('Saved in library', style: TextStyle(fontSize: 10.5, color: subColor)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderColor),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.bookmark_rounded, size: 20, color: accentColor),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$_bookmarkCount Bookmarks',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: titleColor),
                                  ),
                                  Text('Fast navigation', style: TextStyle(fontSize: 10.5, color: subColor)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 6. Preferences & Settings List
                  Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      children: [
                        ValueListenableBuilder<ThemeMode>(
                          valueListenable: appThemeModeNotifier,
                          builder: (context, themeMode, _) {
                            final isDarkMode = themeMode == ThemeMode.dark ||
                                (themeMode == ThemeMode.system &&
                                    MediaQuery.of(context).platformBrightness == Brightness.dark);
                            return ListTile(
                              leading: Icon(
                                isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                                color: accentColor,
                              ),
                              title: Text(
                                'Appearance Theme',
                                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: titleColor),
                              ),
                              subtitle: Text(
                                themeMode == ThemeMode.system
                                    ? 'System default'
                                    : (themeMode == ThemeMode.dark ? 'Dark Obsidian' : 'Warm Linen'),
                                style: TextStyle(fontSize: 12, color: subColor),
                              ),
                              trailing: Switch(
                                value: isDarkMode,
                                activeColor: accentColor,
                                onChanged: (val) {
                                  appThemeModeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
                                  _updateProfile(_profile.copyWith(
                                    preferredThemeMode: val ? 'dark' : 'light',
                                  ));
                                },
                              ),
                            );
                          },
                        ),
                        Divider(height: 1, color: borderColor),
                        ListTile(
                          leading: Icon(Icons.record_voice_over_rounded, color: accentColor),
                          title: Text(
                            'Multi-Voice Narration',
                            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: titleColor),
                          ),
                          subtitle: Text(
                            'English & Malayalam characters distinct voices',
                            style: TextStyle(fontSize: 12, color: subColor),
                          ),
                          trailing: const Icon(Icons.check_circle_rounded, size: 18, color: Color(0xFF10B981)),
                        ),
                        Divider(height: 1, color: borderColor),
                        ListTile(
                          onTap: () => AuthModal.show(context, authController: _auth),
                          leading: Icon(
                            _auth.isAdmin
                                ? Icons.admin_panel_settings_rounded
                                : _auth.isGuest
                                    ? Icons.person_outline_rounded
                                    : Icons.verified_user_rounded,
                            color: _auth.isAdmin
                                ? const Color(0xFF8B5CF6)
                                : _auth.isGuest
                                    ? Colors.grey
                                    : accentColor,
                          ),
                          title: Text(
                            'Account & Authentication',
                            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: titleColor),
                          ),
                          subtitle: Text(
                            '${_auth.currentUser.roleLabel} • ${_auth.currentUser.email ?? "Offline Guest"}',
                            style: TextStyle(fontSize: 12, color: subColor),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _auth.isAdmin
                                  ? const Color(0xFF8B5CF6).withValues(alpha: 0.15)
                                  : cardBg,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _auth.isAdmin
                                    ? const Color(0xFF8B5CF6).withValues(alpha: 0.4)
                                    : borderColor,
                              ),
                            ),
                            child: Text(
                              'Switch',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _auth.isAdmin ? const Color(0xFF8B5CF6) : accentColor,
                              ),
                            ),
                          ),
                        ),
                        if (_auth.isAdmin) ...[
                          Divider(height: 1, color: borderColor),
                          ListTile(
                            leading: const Icon(Icons.auto_stories_rounded, color: Color(0xFF8B5CF6)),
                            title: const Text(
                              'Curator & Catalog Tools',
                              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: Color(0xFF8B5CF6)),
                            ),
                            subtitle: Text(
                              'Curate shelves, edit categories & manage remote books',
                              style: TextStyle(fontSize: 12, color: subColor),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF8B5CF6)),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (ctx) => const AdminCatalogScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Sign Out / Switch Session Button
                  Center(
                    child: TextButton.icon(
                      onPressed: () => AuthModal.show(context, authController: _auth),
                      icon: Icon(
                        _auth.isGuest ? Icons.login_rounded : Icons.logout_rounded,
                        size: 16,
                        color: subColor,
                      ),
                      label: Text(
                        _auth.isGuest ? 'Sign In / Register Cloud Account' : 'Switch Persona or Sign Out',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: subColor),
                      ),
                    ),
                  ),

                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String value,
    String label,
    IconData icon,
    Color bg,
    Color border,
    Color titleColor,
    Color subColor,
    Color accent,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: accent),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: subColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGoalCustomizer() {
    showDialog(
      context: context,
      builder: (ctx) {
        int selected = _profile.dailyGoalMinutes;
        return StatefulBuilder(
          builder: (context, setDlgState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1E1812)
                  : const Color(0xFFFAF4EA),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Set Daily Reading Goal', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [15, 30, 45, 60].map((mins) {
                  return RadioListTile<int>(
                    title: Text('$mins minutes / day'),
                    value: mins,
                    groupValue: selected,
                    onChanged: (val) {
                      if (val != null) {
                        setDlgState(() => selected = val);
                      }
                    },
                  );
                }).toList(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _updateProfile(_profile.copyWith(dailyGoalMinutes: selected));
                    Navigator.pop(ctx);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
