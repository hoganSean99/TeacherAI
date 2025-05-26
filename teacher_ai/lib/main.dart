import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teacher_ai/core/providers/providers.dart';
import 'package:teacher_ai/core/routing/app_router.dart';
import 'package:teacher_ai/core/services/database_service.dart';
import 'package:teacher_ai/features/ai_chat/presentation/widgets/ai_chat_wrapper.dart';
import 'package:teacher_ai/features/home/presentation/pages/settings_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseService.initialize();
  runApp(const ProviderScope(child: TeacherAssistantApp()));
}

class TeacherAssistantApp extends ConsumerWidget {
  const TeacherAssistantApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPalette = ref.watch(themePaletteProvider);
    final customColors = ref.watch(customThemeProvider);
    final isDarkMode = ref.watch(darkModeProvider);
    final fontSize = ref.watch(fontSizeProvider);
    final palette = selectedPalette == ThemePalette.custom
        ? AppColorPalette(
            name: 'Custom',
            primary: customColors.primary,
            secondary: customColors.secondary,
            background: customColors.background,
            surface: customColors.surface,
            accent: customColors.accent,
          )
        : themePalettes[selectedPalette]!;

    // Font size scaling
    double scale;
    switch (fontSize) {
      case FontSizeOption.small:
        scale = 0.92;
        break;
      case FontSizeOption.large:
        scale = 1.12;
        break;
      default:
        scale = 1.0;
    }

    final baseTheme = isDarkMode
        ? ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: palette.primary,
              secondary: palette.secondary,
              background: Colors.grey[900]!,
              surface: Colors.grey[850]!,
              error: const Color(0xFFB00020),
              onPrimary: Colors.white,
              onSecondary: Colors.white,
              onBackground: Colors.white,
              onSurface: Colors.white,
              onError: Colors.white,
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: Colors.grey[900],
            appBarTheme: AppBarTheme(
              backgroundColor: palette.primary,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            cardTheme: CardThemeData(
              elevation: 0,
              color: Colors.grey[800],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: palette.secondary.withOpacity(0.18),
                ),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.grey[850],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            dialogBackgroundColor: Colors.grey[850],
            textTheme: GoogleFonts.montserratTextTheme().copyWith(
              bodyLarge: const TextStyle(color: Colors.white),
              bodyMedium: const TextStyle(color: Colors.white),
              bodySmall: TextStyle(color: Colors.grey[200]),
              headlineLarge: const TextStyle(color: Colors.white),
              headlineMedium: const TextStyle(color: Colors.white),
              headlineSmall: const TextStyle(color: Colors.white),
              titleLarge: const TextStyle(color: Colors.white),
              titleMedium: const TextStyle(color: Colors.white),
              titleSmall: TextStyle(color: Colors.grey[200]),
              labelLarge: TextStyle(color: Colors.grey[200]),
              labelMedium: TextStyle(color: Colors.grey[200]),
              labelSmall: TextStyle(color: Colors.grey[200]),
            ),
          )
        : ThemeData(
            colorScheme: ColorScheme(
              brightness: Brightness.light,
              primary: palette.primary,
              onPrimary: Colors.white,
              secondary: palette.secondary,
              onSecondary: Colors.white,
              background: palette.background,
              onBackground: const Color(0xFF22223B),
              surface: palette.surface,
              onSurface: const Color(0xFF22223B),
              error: const Color(0xFFB00020),
              onError: Colors.white,
            ),
            useMaterial3: true,
            scaffoldBackgroundColor: palette.background,
            appBarTheme: AppBarTheme(
              centerTitle: false,
              backgroundColor: palette.primary,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            cardTheme: CardThemeData(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: palette.secondary.withOpacity(0.18),
                ),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: palette.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            dialogBackgroundColor: Colors.white,
          );

    return MaterialApp.router(
      title: 'Teacher Assistant',
      debugShowCheckedModeBanner: false,
      routerConfig: goRouter,
      theme: baseTheme.copyWith(
        textTheme: GoogleFonts.montserratTextTheme(
          Theme.of(context).textTheme.apply(fontSizeFactor: scale),
        ),
      ),
    );
  }
}
