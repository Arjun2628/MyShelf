import 'package:epub_audio/features/profile/domain/entities/user_profile.dart';
import 'package:flutter/material.dart';

/// Modal bottom sheet allowing users to customize their avatar emoji, moniker, and color gradient.
class AvatarPickerModal extends StatefulWidget {
  final UserProfile currentProfile;
  final ValueChanged<UserProfile> onProfileUpdated;

  const AvatarPickerModal({
    super.key,
    required this.currentProfile,
    required this.onProfileUpdated,
  });

  static Future<void> show(
    BuildContext context, {
    required UserProfile currentProfile,
    required ValueChanged<UserProfile> onProfileUpdated,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AvatarPickerModal(
        currentProfile: currentProfile,
        onProfileUpdated: onProfileUpdated,
      ),
    );
  }

  @override
  State<AvatarPickerModal> createState() => _AvatarPickerModalState();
}

class _AvatarPickerModalState extends State<AvatarPickerModal> {
  late TextEditingController _nameController;
  late String _selectedEmoji;
  late String _startGradient;
  late String _endGradient;

  final List<String> _emojis = [
    '🦉', '🦊', '🦁', '🚀', '🐉', '✨', '⚡', '🌙',
    '🧙‍♂️', '👑', '🌌', '📜', '🌊', '🔥', '🛡️', '⚔️',
  ];

  final List<List<String>> _gradients = [
    ['0xFFD4A373', '0xFFA8764B'], // Gold Amber
    ['0xFF6366F1', '0xFF4338CA'], // Royal Indigo
    ['0xFFEC4899', '0xFFBE185D'], // Rose Quartz
    ['0xFF10B981', '0xFF047857'], // Emerald
    ['0xFF06B6D4', '0xFF0E7490'], // Cyan Cosmic
    ['0xFFF59E0B', '0xFFB45309'], // Warm Flame
    ['0xFF8B5CF6', '0xFF6D28D9'], // Deep Violet
    ['0xFF64748B', '0xFF334155'], // Slate Steel
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentProfile.displayName);
    _selectedEmoji = widget.currentProfile.avatarEmoji;
    _startGradient = widget.currentProfile.avatarGradientStart;
    _endGradient = widget.currentProfile.avatarGradientEnd;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Color _parseHex(String hex) {
    try {
      final clean = hex.replaceAll('#', '').replaceAll('0x', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return const Color(0xFFD4A373);
    }
  }

  void _handleSave() {
    final updated = widget.currentProfile.copyWith(
      displayName: _nameController.text.trim().isNotEmpty
          ? _nameController.text.trim()
          : widget.currentProfile.displayName,
      avatarEmoji: _selectedEmoji,
      avatarGradientStart: _startGradient,
      avatarGradientEnd: _endGradient,
    );
    widget.onProfileUpdated(updated);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF18130E) : const Color(0xFFFBF7F2);
    final cardBg = isDark ? const Color(0xFF241C15) : const Color(0xFFEFE6DA);
    final textPrimary = isDark ? const Color(0xFFF7F2EB) : const Color(0xFF261D13);
    final startColor = _parseHex(_startGradient);
    final endColor = _parseHex(_endGradient);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(
            color: startColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 42,
                height: 4.5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Customize Avatar & Identity',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded, color: textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Live Preview Avatar
            Center(
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [startColor, endColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: startColor.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _selectedEmoji,
                    style: const TextStyle(fontSize: 44),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Moniker Text Field
            Text(
              'Reader Moniker',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                filled: true,
                fillColor: cardBg,
                hintText: 'Enter your reader name',
                hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Emoji Picker Grid
            Text(
              'Avatar Icon',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _emojis.map((emoji) {
                final isSelected = _selectedEmoji == emoji;
                return GestureDetector(
                  onTap: () => setState(() => _selectedEmoji = emoji),
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? startColor.withValues(alpha: 0.25)
                          : cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? startColor : Colors.transparent,
                        width: 1.8,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Color Palette Picker
            Text(
              'Aura Gradient',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _gradients.map((grad) {
                final c1 = _parseHex(grad[0]);
                final c2 = _parseHex(grad[1]);
                final isSelected = _startGradient == grad[0] && _endGradient == grad[1];

                return GestureDetector(
                  onTap: () => setState(() {
                    _startGradient = grad[0];
                    _endGradient = grad[1];
                  }),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [c1, c2]),
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 2.2,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: c1.withValues(alpha: 0.5),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Save Button
            ElevatedButton(
              onPressed: _handleSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: startColor,
                foregroundColor: const Color(0xFF1E140A),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Save Profile Identity',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
