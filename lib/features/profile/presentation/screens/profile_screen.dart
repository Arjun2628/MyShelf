import 'package:epub_audio/main.dart';
import 'package:flutter/material.dart';

/// Initial Profile & Reading Identity foundation screen for Phase 1.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _selectedAvatarIndex = 0;
  final String _userName = 'Arjun (Reader)';
  final String _userEmail = 'reader@scribbleverse.io';
  final int _readingStreak = 5;
  final int _booksRead = 4;
  final double _hoursListened = 6.5;

  final List<String> _avatarEmojis = ['🦉', '🦊', '🦁', '🚀', '🐉', '✨'];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canvasBg = isDark ? const Color(0xFF14100C) : const Color(0xFFFBF7F0);
    final cardBg = isDark ? const Color(0xFF1E1812) : const Color(0xFFFAF4EA);
    final borderColor = isDark ? const Color(0xFF382D21) : const Color(0xFFE2D4C3);
    final titleColor = isDark ? const Color(0xFFF7F2EB) : const Color(0xFF261D13);
    final subColor = isDark ? const Color(0xFFA89F93) : const Color(0xFF7A6E5F);
    const accentColor = Color(0xFFD4A373);

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
                  // Avatar & Name Card
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
                        // Selected Avatar
                        GestureDetector(
                          onTap: _showAvatarPickerModal,
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                width: 84,
                                height: 84,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFD4A373), Color(0xFFA8764B)],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: accentColor.withValues(alpha: 0.35),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    _avatarEmojis[_selectedAvatarIndex],
                                    style: const TextStyle(fontSize: 42),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(5),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF261D13),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.edit_rounded, size: 14, color: accentColor),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _userName,
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: titleColor,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _userEmail,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: subColor,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'READER • TIER 1',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: accentColor,
                              letterSpacing: 0.7,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Reading & Listening Statistics
                  Row(
                    children: [
                      _buildStatCard('🔥 $_readingStreak Days', 'Reading Streak', cardBg, borderColor, titleColor, subColor),
                      const SizedBox(width: 10),
                      _buildStatCard('📚 $_booksRead Books', 'Completed', cardBg, borderColor, titleColor, subColor),
                      const SizedBox(width: 10),
                      _buildStatCard('🎧 ${_hoursListened}h', 'Listening Time', cardBg, borderColor, titleColor, subColor),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Quick Settings & Preferences
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
                              title: Text('Appearance Theme', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: titleColor)),
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
                                },
                              ),
                            );
                          },
                        ),
                        Divider(height: 1, color: borderColor),
                        ListTile(
                          leading: const Icon(Icons.record_voice_over_rounded, color: accentColor),
                          title: Text('Multi-Voice Narration', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: titleColor)),
                          subtitle: Text('Malayalam & English TTS profiles calibrated', style: TextStyle(fontSize: 12, color: subColor)),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                        ),
                        Divider(height: 1, color: borderColor),
                        ListTile(
                          leading: const Icon(Icons.admin_panel_settings_rounded, color: accentColor),
                          title: Text('Account & Authentication', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: titleColor)),
                          subtitle: Text('Phase 5 User & Admin sign in', style: TextStyle(fontSize: 12, color: subColor)),
                          trailing: const Icon(Icons.lock_outline_rounded, size: 16),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 80),
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
    Color bg,
    Color border,
    Color titleColor,
    Color subColor,
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
            Text(
              value,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 3),
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

  void _showAvatarPickerModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1E1812)
          : const Color(0xFFFAF4EA),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose Your Avatar',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(_avatarEmojis.length, (index) {
                  final isSelected = index == _selectedAvatarIndex;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedAvatarIndex = index);
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? const Color(0xFFD4A373).withValues(alpha: 0.3) : Colors.transparent,
                        border: Border.all(
                          color: isSelected ? const Color(0xFFD4A373) : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Text(
                        _avatarEmojis[index],
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}
