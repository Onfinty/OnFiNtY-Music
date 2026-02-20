import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/music_provider.dart';
import 'router/app_router.dart';
import 'services/audio_handler.dart';
import 'services/artwork_palette_service.dart';
import 'services/preferences_service.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences BEFORE running the app
  await PreferencesService.initialize();

  // Initialize AudioHandler via AudioService.init() for background playback
  OnFinityAudioHandler? audioHandler;
  try {
    audioHandler = await AudioService.init(
      builder: () => OnFinityAudioHandler(),
      config: AudioServiceConfig(
        androidNotificationChannelId: 'com.onfinity.music.audio',
        androidNotificationChannelName: 'OnFiNtY Music',
        androidNotificationOngoing: false,
        androidStopForegroundOnPause: true,
        androidNotificationIcon: 'drawable/ic_stat_onfinty_logo_nobg',
      ),
    );
    debugPrint('[OnFiNtY] AudioService initialized successfully');
  } catch (e, st) {
    debugPrint('[OnFiNtY] AudioService init error: $e');
    debugPrint('[OnFiNtY] Stack trace: $st');
    // Create a fallback handler so the app still runs
    audioHandler = OnFinityAudioHandler();
  }

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    ProviderScope(
      overrides: [audioHandlerProvider.overrideWithValue(audioHandler)],
      child: const OnFinityApp(),
    ),
  );
}

class OnFinityApp extends ConsumerWidget {
  const OnFinityApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final isDark = ref.watch(isDarkModeProvider);
    final useDynamicArtworkTheme = ref.watch(dynamicArtworkThemeProvider);
    final dynamicPalette = ref.watch(currentThemePaletteProvider);

    // Update status bar based on theme
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
    );

    return MaterialApp.router(
      title: 'OnFiNtY',
      debugShowCheckedModeBanner: false,
      theme: _buildLightTheme(
        dynamicPalette: useDynamicArtworkTheme ? dynamicPalette : null,
      ),
      darkTheme: _buildDarkTheme(
        dynamicPalette: useDynamicArtworkTheme ? dynamicPalette : null,
      ),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      routerConfig: router,
      themeAnimationDuration: const Duration(milliseconds: 420),
      themeAnimationCurve: Curves.easeInOutCubic,
    );
  }

  ThemeData _buildDarkTheme({SongPalette? dynamicPalette}) {
    if (dynamicPalette == null) {
      return ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF8B5CF6),
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF8B5CF6),
          secondary: Color(0xFFA78BFA),
          surface: Color(0xFF1A1A1A),
        ),
        fontFamily: 'Poppins',
        useMaterial3: true,
      );
    }

    final seededScheme =
        ColorScheme.fromSeed(
          seedColor: dynamicPalette.gradientPrimary,
          brightness: Brightness.dark,
        ).copyWith(
          primary: dynamicPalette.gradientPrimary,
          secondary: dynamicPalette.glowColor,
          tertiary: dynamicPalette.gradientSecondary,
          surface: Color.lerp(
            dynamicPalette.gradientSecondary,
            Colors.black,
            0.72,
          )!,
        );
    final colorScheme = seededScheme.copyWith(
      onPrimary: ArtworkPaletteService.readableText(seededScheme.primary),
      onSecondary: ArtworkPaletteService.readableText(seededScheme.secondary),
      onTertiary: ArtworkPaletteService.readableText(seededScheme.tertiary),
      onSurface: ArtworkPaletteService.readableText(seededScheme.surface),
    );

    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: colorScheme.primary,
      scaffoldBackgroundColor: Color.lerp(
        colorScheme.surface,
        Colors.black,
        0.35,
      ),
      colorScheme: colorScheme,
      cardTheme: CardThemeData(
        color: colorScheme.surface.withValues(alpha: 0.92),
        elevation: 2,
        shadowColor: dynamicPalette.glowColor.withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      fontFamily: 'Poppins',
      useMaterial3: true,
    );
  }

  ThemeData _buildLightTheme({SongPalette? dynamicPalette}) {
    if (dynamicPalette == null) {
      return ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFF7C3AED),
        scaffoldBackgroundColor: const Color(0xFFF8F7FC),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF7C3AED),
          secondary: Color(0xFFD0BCFF),
          surface: Colors.white,
          onSurface: Color(0xFF1C1B1F),
          surfaceContainerHighest: Color(0xFFF3EEFB),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shadowColor: const Color(0xFF7C3AED).withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF8F7FC),
          foregroundColor: Color(0xFF1C1B1F),
          elevation: 0,
        ),
        fontFamily: 'Poppins',
        useMaterial3: true,
      );
    }

    final seededScheme =
        ColorScheme.fromSeed(
          seedColor: dynamicPalette.gradientPrimary,
          brightness: Brightness.light,
        ).copyWith(
          primary: Color.lerp(
            dynamicPalette.gradientPrimary,
            Colors.black,
            0.1,
          ),
          secondary: dynamicPalette.glowColor,
          tertiary: dynamicPalette.gradientSecondary,
          surface: Color.lerp(
            dynamicPalette.gradientPrimary,
            Colors.white,
            0.92,
          )!,
          onSurface: const Color(0xFF1C1B1F),
          surfaceContainerHighest: Color.lerp(
            dynamicPalette.gradientSecondary,
            Colors.white,
            0.86,
          ),
        );
    final colorScheme = seededScheme.copyWith(
      onPrimary: ArtworkPaletteService.readableText(seededScheme.primary),
      onSecondary: ArtworkPaletteService.readableText(seededScheme.secondary),
      onTertiary: ArtworkPaletteService.readableText(seededScheme.tertiary),
      onSurface: ArtworkPaletteService.readableText(seededScheme.surface),
    );

    return ThemeData(
      brightness: Brightness.light,
      primaryColor: colorScheme.primary,
      scaffoldBackgroundColor: Color.lerp(
        colorScheme.surface,
        Colors.white,
        0.4,
      ),
      colorScheme: colorScheme,
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 2,
        shadowColor: dynamicPalette.glowColor.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      fontFamily: 'Poppins',
      useMaterial3: true,
    );
  }
}
