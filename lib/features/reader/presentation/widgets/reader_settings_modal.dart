import 'package:epub_audio/features/reader/domain/entities/reader_preferences.dart';
import 'package:flutter/material.dart';

/// Modal sheet for customizing reader typography, spacing, and color theme.
class ReaderSettingsModal extends StatelessWidget {
  final ReaderPreferences preferences;
  final ValueChanged<ReaderPreferences> onPreferencesChanged;

  const ReaderSettingsModal({
    super.key,
    required this.preferences,
    required this.onPreferencesChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = preferences.colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colors.secondaryText.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'Reading Appearance',
            style: TextStyle(
              color: colors.text,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // Theme Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildThemeButton(
                context,
                title: 'Light',
                mode: ReaderThemeMode.light,
                bgColor: const Color(0xFFFAF9F6),
                textColor: const Color(0xFF1C1917),
              ),
              _buildThemeButton(
                context,
                title: 'Sepia',
                mode: ReaderThemeMode.sepia,
                bgColor: const Color(0xFFF4ECD8),
                textColor: const Color(0xFF382F24),
              ),
              _buildThemeButton(
                context,
                title: 'Night',
                mode: ReaderThemeMode.night,
                bgColor: const Color(0xFF1E2022),
                textColor: const Color(0xFFE2E8F0),
              ),
              _buildThemeButton(
                context,
                title: 'OLED',
                mode: ReaderThemeMode.oledBlack,
                bgColor: const Color(0xFF000000),
                textColor: const Color(0xFFD4D4D8),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Font Size Controls
          Row(
            children: [
              Text(
                'Font Size',
                style: TextStyle(
                  color: colors.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${preferences.fontSize.round()} px',
                style: TextStyle(
                  color: colors.secondaryText,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: Text(
                  'A-',
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: preferences.fontSize > 12
                    ? () => onPreferencesChanged(
                          preferences.copyWith(
                            fontSize: preferences.fontSize - 1,
                          ),
                        )
                    : null,
              ),
              Expanded(
                child: Slider(
                  value: preferences.fontSize,
                  min: 12.0,
                  max: 32.0,
                  divisions: 20,
                  activeColor: colors.accent,
                  inactiveColor: colors.divider,
                  onChanged: (val) {
                    onPreferencesChanged(preferences.copyWith(fontSize: val));
                  },
                ),
              ),
              IconButton(
                icon: Text(
                  'A+',
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: preferences.fontSize < 32
                    ? () => onPreferencesChanged(
                          preferences.copyWith(
                            fontSize: preferences.fontSize + 1,
                          ),
                        )
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Line Spacing
          Row(
            children: [
              Text(
                'Line Spacing',
                style: TextStyle(
                  color: colors.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${preferences.lineHeight.toStringAsFixed(1)}x',
                style: TextStyle(
                  color: colors.secondaryText,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          Slider(
            value: preferences.lineHeight,
            min: 1.2,
            max: 2.4,
            divisions: 6,
            activeColor: colors.accent,
            inactiveColor: colors.divider,
            onChanged: (val) {
              onPreferencesChanged(preferences.copyWith(lineHeight: val));
            },
          ),
          const SizedBox(height: 16),

          // Font Family
          Text(
            'Font Family',
            style: TextStyle(
              color: colors.text,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'Default', label: Text('System')),
              ButtonSegment(value: 'Serif', label: Text('Serif')),
              ButtonSegment(value: 'Sans-Serif', label: Text('Sans')),
              ButtonSegment(value: 'Monospace', label: Text('Mono')),
            ],
            selected: {preferences.fontFamily},
            onSelectionChanged: (newSelection) {
              onPreferencesChanged(
                preferences.copyWith(fontFamily: newSelection.first),
              );
            },
            style: ButtonStyle(
              foregroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? colors.cardBackground
                    : colors.text,
              ),
              backgroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? colors.accent
                    : colors.cardBackground,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeButton(
    BuildContext context, {
    required String title,
    required ReaderThemeMode mode,
    required Color bgColor,
    required Color textColor,
  }) {
    final isSelected = preferences.themeMode == mode;
    final activeBorderColor = preferences.colors.accent;

    return GestureDetector(
      onTap: () {
        onPreferencesChanged(preferences.copyWith(themeMode: mode));
      },
      child: Column(
        children: [
          Container(
            width: 64,
            height: 48,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? activeBorderColor : Colors.grey.withValues(alpha: 0.3),
                width: isSelected ? 2.5 : 1.0,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              'Aa',
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              color: isSelected ? activeBorderColor : preferences.colors.text,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
