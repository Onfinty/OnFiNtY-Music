import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/music_provider.dart';
import 'router/app_router.dart';
import 'services/audio_handler.dart';
import 'services/artwork_palette_service.dart';
import 'services/performance_service.dart';
import 'services/preferences_service.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences BEFORE running the app
  await PreferencesService.initialize();

  // Initialize AudioHandler via AudioService.init() for background playback
  OnFinityAudioHandler? audioHandler;
  var initializedWithAudioService = false;

  for (var attempt = 1; attempt <= 2 && audioHandler == null; attempt++) {
    try {
      audioHandler = await AudioService.init(
        builder: () => OnFinityAudioHandler(),
        config: AudioServiceConfig(
          androidNotificationChannelId: 'com.onfinity.music.audio',
          androidNotificationChannelName: 'OnFiNtY Music',
          androidNotificationOngoing: false,
          androidStopForegroundOnPause: false,
          androidNotificationIcon: 'drawable/ic_stat_onfinty_logo_nobg',
        ),
      );
      initializedWithAudioService = true;
      debugPrint(
        '[OnFiNtY] AudioService initialized successfully (attempt $attempt)',
      );
    } catch (e, st) {
      debugPrint('[OnFiNtY] AudioService init error (attempt $attempt): $e');
      debugPrint('[OnFiNtY] Stack trace: $st');
      if (attempt == 1) {
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
    }
  }

  if (!initializedWithAudioService) {
    debugPrint(
      '[OnFiNtY] Falling back to local audio handler. '
      'Background notification controls may be unavailable.',
    );
    audioHandler = OnFinityAudioHandler();
  }

  final resolvedAudioHandler = audioHandler ?? OnFinityAudioHandler();

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
      overrides: [audioHandlerProvider.overrideWithValue(resolvedAudioHandler)],
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
    final useFullArtworkGradientTheme = ref.watch(
      artworkFullGradientThemeProvider,
    );
    final dynamicPalette = ref.watch(currentThemePaletteProvider);
    final themeAnimationDuration = PerformanceService.tunedDuration(
      const Duration(milliseconds: 620),
      lowFidelityScale: 0.5,
      minMs: 180,
    );
    final systemUiStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    );
    final dynamicGradientStops = _buildDynamicGradientStops(
      dynamicPalette,
      isDark: isDark,
      useFullGradient: useDynamicArtworkTheme && useFullArtworkGradientTheme,
    );
    final transitionKey = ValueKey<String>(
      '${isDark ? 'dark' : 'light'}|'
      '${useDynamicArtworkTheme ? 1 : 0}|'
      '${useFullArtworkGradientTheme ? 1 : 0}|'
      '${dynamicPalette.hashCode}',
    );

    return MaterialApp.router(
      title: 'OnFiNtY',
      debugShowCheckedModeBanner: false,
      theme: _buildLightTheme(
        dynamicPalette: useDynamicArtworkTheme ? dynamicPalette : null,
        useFullGradient: useFullArtworkGradientTheme,
      ),
      darkTheme: _buildDarkTheme(
        dynamicPalette: useDynamicArtworkTheme ? dynamicPalette : null,
        useFullGradient: useFullArtworkGradientTheme,
      ),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      routerConfig: router,
      themeAnimationDuration: themeAnimationDuration,
      themeAnimationCurve: Curves.easeInOutCubic,
      builder: (context, child) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: systemUiStyle,
          child: _ThemeTransitionShell(
            transitionSeed: transitionKey.value,
            isDark: isDark,
            enabled: useDynamicArtworkTheme,
            useFullGradient: useFullArtworkGradientTheme,
            colors: dynamicGradientStops,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }

  List<Color> _buildDynamicGradientStops(
    SongPalette palette, {
    required bool isDark,
    required bool useFullGradient,
  }) {
    if (useFullGradient && palette.gradientColors.length >= 3) {
      return ArtworkPaletteService.buildDetailedGradient(
        palette.gradientColors,
        targetCount: 70,
      );
    }

    final source = <Color>[
      palette.gradientPrimary,
      palette.glowColor,
      palette.gradientSecondary,
    ];

    final stops = <Color>[];
    for (var index = 0; index < source.length; index++) {
      final progress = source.length <= 1 ? 0.0 : index / (source.length - 1);
      final blendTarget = isDark ? Colors.black : Colors.white;
      final blendAmount = isDark
          ? (0.26 + (progress * 0.46)).clamp(0.0, 0.92)
          : (0.5 + (progress * 0.34)).clamp(0.0, 0.94);
      stops.add(Color.lerp(source[index], blendTarget, blendAmount)!);
    }

    if (stops.length < 3) {
      return <Color>[
        palette.gradientPrimary,
        palette.glowColor,
        palette.gradientSecondary,
      ];
    }
    return stops;
  }

  ThemeData _buildDarkTheme({
    SongPalette? dynamicPalette,
    required bool useFullGradient,
  }) {
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

    final gradientStops = _buildDynamicGradientStops(
      dynamicPalette,
      isDark: true,
      useFullGradient: useFullGradient,
    );
    final primaryColor = dynamicPalette.gradientPrimary;
    final secondaryColor = gradientStops[gradientStops.length ~/ 2];
    final tertiaryColor = gradientStops.last;
    final seededScheme =
        ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: Brightness.dark,
        ).copyWith(
          primary: primaryColor,
          secondary: secondaryColor,
          tertiary: tertiaryColor,
          surface: Color.lerp(tertiaryColor, Colors.black, 0.72)!,
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
      scaffoldBackgroundColor: Color.lerp(tertiaryColor, Colors.black, 0.74),
      colorScheme: colorScheme,
      cardTheme: CardThemeData(
        color: colorScheme.surface.withValues(alpha: 0.92),
        elevation: 2,
        shadowColor: secondaryColor.withValues(alpha: 0.22),
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

  ThemeData _buildLightTheme({
    SongPalette? dynamicPalette,
    required bool useFullGradient,
  }) {
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

    final gradientStops = _buildDynamicGradientStops(
      dynamicPalette,
      isDark: false,
      useFullGradient: useFullGradient,
    );
    final primaryColor = Color.lerp(
      dynamicPalette.gradientPrimary,
      Colors.black,
      0.1,
    );
    final secondaryColor = gradientStops[gradientStops.length ~/ 2];
    final tertiaryColor = gradientStops.last;
    final seededScheme =
        ColorScheme.fromSeed(
          seedColor: primaryColor ?? dynamicPalette.gradientPrimary,
          brightness: Brightness.light,
        ).copyWith(
          primary: primaryColor,
          secondary: secondaryColor,
          tertiary: tertiaryColor,
          surface: Color.lerp(gradientStops.first, Colors.white, 0.9)!,
          onSurface: const Color(0xFF1C1B1F),
          surfaceContainerHighest: Color.lerp(
            tertiaryColor,
            Colors.white,
            0.84,
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
        gradientStops.first,
        Colors.white,
        0.52,
      ),
      colorScheme: colorScheme,
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 2,
        shadowColor: secondaryColor.withValues(alpha: 0.12),
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

class _ThemeTransitionShell extends StatelessWidget {
  const _ThemeTransitionShell({
    required this.transitionSeed,
    required this.isDark,
    required this.enabled,
    required this.useFullGradient,
    required this.colors,
    required this.child,
  });

  final Object transitionSeed;
  final bool isDark;
  final bool enabled;
  final bool useFullGradient;
  final List<Color> colors;
  final Widget child;

  List<double> _evenStops(int count) {
    if (count <= 1) {
      return const <double>[0.0];
    }
    return List<double>.generate(count, (index) => index / (count - 1));
  }

  @override
  Widget build(BuildContext context) {
    if (!enabled || colors.isEmpty) {
      return child;
    }

    final overlayOpacity = isDark
        ? (useFullGradient ? 0.22 : 0.16)
        : (useFullGradient ? 0.16 : 0.1);

    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedSwitcher(
              duration: PerformanceService.tunedDuration(
                const Duration(milliseconds: 560),
                lowFidelityScale: 0.52,
                minMs: 180,
              ),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (transitionChild, animation) {
                final slide = Tween<Offset>(
                  begin: const Offset(0, 0.06),
                  end: Offset.zero,
                ).animate(animation);
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: slide,
                    child: transitionChild,
                  ),
                );
              },
              child: KeyedSubtree(
                key: ValueKey<Object>(transitionSeed),
                child: AnimatedOpacity(
                  duration: PerformanceService.tunedDuration(
                    const Duration(milliseconds: 520),
                    lowFidelityScale: 0.55,
                    minMs: 170,
                  ),
                  curve: Curves.easeInOutCubic,
                  opacity: overlayOpacity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: colors,
                        stops: _evenStops(colors.length),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
