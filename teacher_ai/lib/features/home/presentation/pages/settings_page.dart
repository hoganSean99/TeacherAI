import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

final themePaletteProvider = StateProvider<ThemePalette>((ref) => ThemePalette.aiPurple);
final darkModeProvider = StateProvider<bool>((ref) => false);
final fontSizeProvider = StateProvider<FontSizeOption>((ref) => FontSizeOption.medium);
final languageProvider = StateProvider<String>((ref) => 'en');
final notificationsProvider = StateProvider<bool>((ref) => true);

enum ThemePalette { aiPurple, softBlue, modernTeal, sunsetOrange, forestGreen, slateGray, custom }
enum FontSizeOption { small, medium, large }

final themePalettes = {
  ThemePalette.aiPurple: AppColorPalette(
    name: 'AI Purple',
    primary: Color(0xFF7B1FA2),
    secondary: Color(0xFF9F5DE2),
    background: Color(0xFFF5F7FA),
    surface: Color(0xFFF0F4F8),
    accent: Color(0xFFE040FB),
  ),
  ThemePalette.softBlue: AppColorPalette(
    name: 'Soft Blue',
    primary: Color(0xFF4F8FFF),
    secondary: Color(0xFF6EC6CA),
    background: Color(0xFFF5F7FA),
    surface: Color(0xFFF0F4F8),
    accent: Color(0xFFB2CFFF),
  ),
  ThemePalette.modernTeal: AppColorPalette(
    name: 'Modern Teal',
    primary: Color(0xFF009688),
    secondary: Color(0xFF6EC6CA),
    background: Color(0xFFF5F7FA),
    surface: Color(0xFFF0F4F8),
    accent: Color(0xFF00BFAE),
  ),
  ThemePalette.sunsetOrange: AppColorPalette(
    name: 'Sunset Orange',
    primary: Color(0xFFFF7043),
    secondary: Color(0xFFFFA726),
    background: Color(0xFFFFF3E0),
    surface: Color(0xFFFFE0B2),
    accent: Color(0xFFFFB300),
  ),
  ThemePalette.forestGreen: AppColorPalette(
    name: 'Forest Green',
    primary: Color(0xFF388E3C),
    secondary: Color(0xFF81C784),
    background: Color(0xFFF1F8E9),
    surface: Color(0xFFDCEDC8),
    accent: Color(0xFF43A047),
  ),
  ThemePalette.slateGray: AppColorPalette(
    name: 'Slate Gray',
    primary: Color(0xFF455A64),
    secondary: Color(0xFF90A4AE),
    background: Color(0xFFF5F7FA),
    surface: Color(0xFFCFD8DC),
    accent: Color(0xFF607D8B),
  ),
  ThemePalette.custom: AppColorPalette(
    name: 'Custom',
    primary: Color(0xFF7B1FA2),
    secondary: Color(0xFF9F5DE2),
    background: Color(0xFFF5F7FA),
    surface: Color(0xFFF0F4F8),
    accent: Color(0xFFE040FB),
  ),
};

class AppColorPalette {
  final String name;
  final Color primary;
  final Color secondary;
  final Color background;
  final Color surface;
  final Color accent;
  const AppColorPalette({
    required this.name,
    required this.primary,
    required this.secondary,
    required this.background,
    required this.surface,
    required this.accent,
  });
}

class CustomThemeColors {
  Color primary;
  Color secondary;
  Color background;
  Color surface;
  Color accent;
  CustomThemeColors({
    required this.primary,
    required this.secondary,
    required this.background,
    required this.surface,
    required this.accent,
  });
  CustomThemeColors copyWith({
    Color? primary,
    Color? secondary,
    Color? background,
    Color? surface,
    Color? accent,
  }) => CustomThemeColors(
    primary: primary ?? this.primary,
    secondary: secondary ?? this.secondary,
    background: background ?? this.background,
    surface: surface ?? this.surface,
    accent: accent ?? this.accent,
  );
}

class CustomThemeNotifier extends StateNotifier<CustomThemeColors> {
  CustomThemeNotifier()
      : super(CustomThemeColors(
          primary: Color(0xFF7B1FA2),
          secondary: Color(0xFF9F5DE2),
          background: Color(0xFFF5F7FA),
          surface: Color(0xFFF0F4F8),
          accent: Color(0xFFE040FB),
        ));
  void updateColor(String key, Color color) {
    state = state.copyWith(
      primary: key == 'primary' ? color : null,
      secondary: key == 'secondary' ? color : null,
      background: key == 'background' ? color : null,
      surface: key == 'surface' ? color : null,
      accent: key == 'accent' ? color : null,
    );
  }
}

final customThemeProvider = StateNotifierProvider<CustomThemeNotifier, CustomThemeColors>((ref) => CustomThemeNotifier());

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPalette = ref.watch(themePaletteProvider);
    final customColors = ref.watch(customThemeProvider);
    final isDarkMode = ref.watch(darkModeProvider);
    final fontSize = ref.watch(fontSizeProvider);
    final notificationsEnabled = ref.watch(notificationsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: themePalettes[selectedPalette]!.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ListView(
          children: [
            Text('General', style: GoogleFonts.montserrat(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.dark_mode_outlined, color: Theme.of(context).colorScheme.primary),
                      title: Text('Dark Mode', style: GoogleFonts.montserrat(fontSize: 16)),
                      trailing: Switch(
                        value: isDarkMode,
                        onChanged: (v) => ref.read(darkModeProvider.notifier).state = v,
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                    Divider(height: 1, color: Theme.of(context).dividerColor),
                    ListTile(
                      leading: Icon(Icons.text_fields, color: Theme.of(context).colorScheme.primary),
                      title: Text('Font Size', style: GoogleFonts.montserrat(fontSize: 16)),
                      trailing: DropdownButton<FontSizeOption>(
                        value: fontSize,
                        onChanged: (v) => ref.read(fontSizeProvider.notifier).state = v!,
                        items: [
                          DropdownMenuItem(value: FontSizeOption.small, child: Text('Small')),
                          DropdownMenuItem(value: FontSizeOption.medium, child: Text('Medium')),
                          DropdownMenuItem(value: FontSizeOption.large, child: Text('Large')),
                        ],
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                    Divider(height: 1, color: Theme.of(context).dividerColor),
                    ListTile(
                      leading: Icon(Icons.notifications_active_outlined, color: Theme.of(context).colorScheme.primary),
                      title: Text('Enable Notifications', style: GoogleFonts.montserrat(fontSize: 16)),
                      trailing: Switch(
                        value: notificationsEnabled,
                        onChanged: (v) => ref.read(notificationsProvider.notifier).state = v,
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Divider(height: 32, thickness: 1, color: Colors.grey),
            Text('Color Theme',
                style: GoogleFonts.montserrat(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                )),
            const SizedBox(height: 16),
            Wrap(
              spacing: 20,
              runSpacing: 20,
              children: themePalettes.entries.map((entry) {
                final palette = entry.value;
                final isSelected = selectedPalette == entry.key;
                return GestureDetector(
                  onTap: () => ref.read(themePaletteProvider.notifier).state = entry.key,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    width: 170,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: palette.background,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected ? palette.primary : Theme.of(context).dividerColor,
                        width: isSelected ? 2.5 : 1.2,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: palette.primary.withOpacity(0.13),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _ColorDot(color: palette.primary),
                            const SizedBox(width: 6),
                            _ColorDot(color: palette.secondary),
                            const SizedBox(width: 6),
                            _ColorDot(color: palette.accent),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          palette.name,
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        if (isSelected)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle, color: palette.primary, size: 20),
                                const SizedBox(width: 6),
                                Text('Selected', style: TextStyle(color: palette.primary, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            if (selectedPalette == ThemePalette.custom) ...[
              const SizedBox(height: 24),
              Text('Customize Colors', style: GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 16)),
              const SizedBox(height: 4),
              Text('Edit your custom palette. Changes apply instantly.', style: GoogleFonts.montserrat(fontSize: 13, color: Theme.of(context).textTheme.bodyMedium?.color)),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                icon: const Icon(Icons.palette_outlined),
                label: const Text('Edit Custom Colors'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themePalettes[ThemePalette.custom]!.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  textStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w500, fontSize: 15),
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => _CustomColorsDialog(),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  final Color color;
  const _ColorDot({required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.18),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
}

class _CustomColorRow extends StatelessWidget {
  final String label;
  final Color color;
  final ValueChanged<Color> onChanged;
  const _CustomColorRow({required this.label, required this.color, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w500)),
          ),
          GestureDetector(
            onTap: () async {
              Color picked = color;
              await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Pick $label Color'),
                  content: SingleChildScrollView(
                    child: ColorPicker(
                      pickerColor: color,
                      onColorChanged: (c) => picked = c,
                      enableAlpha: false,
                      showLabel: false,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        onChanged(picked);
                        Navigator.of(context).pop();
                      },
                      child: const Text('Select'),
                    ),
                  ],
                ),
              );
            },
            child: Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Theme.of(context).dividerColor, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.13),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '#${color.value.toRadixString(16).padLeft(8, '0').toUpperCase()}',
            style: GoogleFonts.montserrat(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color),
          ),
        ],
      ),
    );
  }
}

// Modal dialog for editing custom colors
class _CustomColorsDialog extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customColors = ref.watch(customThemeProvider);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 120),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Edit Custom Colors', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 17)),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Close',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _CustomColorRow(
                  label: 'Primary',
                  color: customColors.primary,
                  onChanged: (c) => ref.read(customThemeProvider.notifier).updateColor('primary', c),
                ),
                _CustomColorRow(
                  label: 'Secondary',
                  color: customColors.secondary,
                  onChanged: (c) => ref.read(customThemeProvider.notifier).updateColor('secondary', c),
                ),
                _CustomColorRow(
                  label: 'Background',
                  color: customColors.background,
                  onChanged: (c) => ref.read(customThemeProvider.notifier).updateColor('background', c),
                ),
                _CustomColorRow(
                  label: 'Surface',
                  color: customColors.surface,
                  onChanged: (c) => ref.read(customThemeProvider.notifier).updateColor('surface', c),
                ),
                _CustomColorRow(
                  label: 'Accent',
                  color: customColors.accent,
                  onChanged: (c) => ref.read(customThemeProvider.notifier).updateColor('accent', c),
                ),
                const SizedBox(height: 8),
                Divider(height: 24, thickness: 1, color: Theme.of(context).dividerColor),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 