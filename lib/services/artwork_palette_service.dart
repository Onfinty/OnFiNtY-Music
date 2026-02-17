import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart'
    show ArtworkType, OnAudioQuery;
import 'package:palette_generator/palette_generator.dart';

import 'preferences_service.dart';

@immutable
class SongPalette {
  final Color glowColor;
  final Color gradientPrimary;
  final Color gradientSecondary;

  const SongPalette({
    required this.glowColor,
    required this.gradientPrimary,
    required this.gradientSecondary,
  });

  static const SongPalette fallback = SongPalette(
    glowColor: Color(0xFF8B5CF6),
    gradientPrimary: Color(0xFF8B5CF6),
    gradientSecondary: Color(0xFF4C1D95),
  );

  Map<String, int> toStorageMap() {
    return <String, int>{
      'glow': glowColor.value,
      'primary': gradientPrimary.value,
      'secondary': gradientSecondary.value,
    };
  }

  factory SongPalette.fromStorageMap(Map<String, int> map) {
    final glow = map['glow'];
    final primary = map['primary'];
    final secondary = map['secondary'];
    if (glow == null || primary == null || secondary == null) {
      return SongPalette.fallback;
    }

    return SongPalette(
      glowColor: Color(glow),
      gradientPrimary: Color(primary),
      gradientSecondary: Color(secondary),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is SongPalette &&
        other.glowColor == glowColor &&
        other.gradientPrimary == gradientPrimary &&
        other.gradientSecondary == gradientSecondary;
  }

  @override
  int get hashCode =>
      Object.hash(glowColor, gradientPrimary, gradientSecondary);
}

class ArtworkPaletteService {
  ArtworkPaletteService({OnAudioQuery? audioQuery})
    : _audioQuery = audioQuery ?? OnAudioQuery() {
    unawaited(_ensureCacheRestored());
  }

  final OnAudioQuery _audioQuery;

  final Map<int, SongPalette> _paletteCache = <int, SongPalette>{};
  final Map<int, Future<SongPalette>> _inFlight = <int, Future<SongPalette>>{};

  static const int _maxCacheEntries = 320;
  static const Duration _persistDebounceDuration = Duration(milliseconds: 300);

  bool _cacheRestored = false;
  Future<void>? _restoreCacheFuture;
  Timer? _persistDebounceTimer;
  int _cacheVersion = 0;

  SongPalette? getCachedPalette(int songId) {
    if (!_cacheRestored && _restoreCacheFuture == null) {
      unawaited(_ensureCacheRestored());
    }

    final cached = _paletteCache[songId];
    if (cached != null) {
      _touchCacheEntry(songId, cached);
    }
    return cached;
  }

  Future<SongPalette> getPalette(int songId) async {
    await _ensureCacheRestored();

    final cached = _paletteCache[songId];
    if (cached != null) {
      _touchCacheEntry(songId, cached);
      return cached;
    }

    final inFlight = _inFlight[songId];
    if (inFlight != null) {
      return inFlight;
    }

    final future = _loadPalette(songId);
    _inFlight[songId] = future;
    return future.whenComplete(() {
      _inFlight.remove(songId);
    });
  }

  Future<void> prefetchPalette(int songId) async {
    await _ensureCacheRestored();
    if (_paletteCache.containsKey(songId) || _inFlight.containsKey(songId)) {
      return;
    }

    try {
      await getPalette(songId);
    } catch (_) {}
  }

  Future<void> clearCache() async {
    _cacheVersion++;
    _persistDebounceTimer?.cancel();
    _persistDebounceTimer = null;
    _inFlight.clear();
    _paletteCache.clear();
    _cacheRestored = true;
    _restoreCacheFuture = null;
    await PreferencesService.clearArtworkPaletteCache();
  }

  Future<void> _ensureCacheRestored() {
    if (_cacheRestored) {
      return Future<void>.value();
    }

    final existing = _restoreCacheFuture;
    if (existing != null) {
      return existing;
    }

    final cacheVersion = _cacheVersion;
    final future = _restoreCacheFromDisk(cacheVersion);
    _restoreCacheFuture = future;
    return future;
  }

  Future<void> _restoreCacheFromDisk(int cacheVersion) async {
    try {
      final cachedMap = await PreferencesService.getArtworkPaletteCache();
      if (cacheVersion != _cacheVersion) {
        return;
      }

      if (cachedMap.isNotEmpty) {
        for (final entry in cachedMap.entries) {
          final palette = SongPalette.fromStorageMap(entry.value);
          _cachePalette(entry.key, palette, persist: false);
        }
      }
    } catch (_) {
      // Ignore malformed cache and continue with in-memory extraction.
    } finally {
      if (cacheVersion == _cacheVersion) {
        _cacheRestored = true;
        _restoreCacheFuture = null;
      }
    }
  }

  Future<SongPalette> _loadPalette(int songId) async {
    try {
      final artwork = await _audioQuery.queryArtwork(
        songId,
        ArtworkType.AUDIO,
        quality: 100,
        size: 500,
      );

      if (artwork == null || artwork.isEmpty) {
        _cachePalette(songId, SongPalette.fallback);
        return SongPalette.fallback;
      }

      final palette = await _extractPalette(artwork);
      _cachePalette(songId, palette);
      return palette;
    } catch (_) {
      _cachePalette(songId, SongPalette.fallback);
      return SongPalette.fallback;
    }
  }

  Future<SongPalette> _extractPalette(Uint8List artworkBytes) async {
    final palette = await PaletteGenerator.fromImageProvider(
      MemoryImage(artworkBytes),
      maximumColorCount: 30,
    );

    final dominantColor = _pickAnchorColor(palette);
    final glowColor = _pickGlowColor(palette, dominantColor);
    final secondaryColor = _pickSecondaryColor(
      palette,
      dominantColor,
      glowColor,
    );

    return SongPalette(
      glowColor: _tuneGlowColor(glowColor),
      gradientPrimary: _tunePrimaryColor(dominantColor),
      gradientSecondary: _tuneSecondaryColor(secondaryColor),
    );
  }

  Color _pickAnchorColor(PaletteGenerator palette) {
    final swatches = palette.paletteColors;
    if (swatches.isEmpty) {
      return SongPalette.fallback.gradientPrimary;
    }

    final maxPopulation = swatches.fold<int>(
      1,
      (max, swatch) => swatch.population > max ? swatch.population : max,
    );

    final preferred = <int>{
      palette.vibrantColor?.color.value ?? -1,
      palette.lightVibrantColor?.color.value ?? -1,
      palette.darkVibrantColor?.color.value ?? -1,
      palette.mutedColor?.color.value ?? -1,
    };

    PaletteColor? winner;
    var bestScore = -1.0;

    for (final swatch in swatches) {
      final hsl = HSLColor.fromColor(swatch.color);
      final populationScore = (swatch.population / maxPopulation).clamp(
        0.0,
        1.0,
      );
      final lightnessBalance = (1.0 - ((hsl.lightness - 0.48).abs() * 1.7))
          .clamp(0.0, 1.0);
      final preferredBonus = preferred.contains(swatch.color.value) ? 0.1 : 0.0;
      final score =
          (populationScore * 0.48) +
          (hsl.saturation * 0.32) +
          (lightnessBalance * 0.2) +
          preferredBonus;

      if (score > bestScore) {
        bestScore = score;
        winner = swatch;
      }
    }

    return winner?.color ??
        palette.vibrantColor?.color ??
        palette.dominantColor?.color ??
        SongPalette.fallback.gradientPrimary;
  }

  Color _pickGlowColor(PaletteGenerator palette, Color anchorColor) {
    final swatches = palette.paletteColors;
    if (swatches.isEmpty) {
      return SongPalette.fallback.glowColor;
    }

    final maxPopulation = swatches.fold<int>(
      1,
      (max, swatch) => swatch.population > max ? swatch.population : max,
    );

    final prioritizedGlow = <PaletteColor>[
      if (palette.vibrantColor != null) palette.vibrantColor!,
      if (palette.lightVibrantColor != null) palette.lightVibrantColor!,
      if (palette.darkVibrantColor != null) palette.darkVibrantColor!,
      if (palette.dominantColor != null) palette.dominantColor!,
    ];

    PaletteColor? winner;
    var bestScore = -1.0;

    for (final swatch in swatches) {
      final score = _glowScore(
        swatch,
        maxPopulation: maxPopulation,
        anchorColor: anchorColor,
        isPreferred: prioritizedGlow.any(
          (preferred) => preferred.color.value == swatch.color.value,
        ),
      );
      if (score > bestScore) {
        bestScore = score;
        winner = swatch;
      }
    }

    return winner?.color ??
        palette.vibrantColor?.color ??
        palette.dominantColor?.color ??
        SongPalette.fallback.glowColor;
  }

  double _glowScore(
    PaletteColor swatch, {
    required int maxPopulation,
    required Color anchorColor,
    required bool isPreferred,
  }) {
    final hsl = HSLColor.fromColor(swatch.color);
    final populationScore = (swatch.population / maxPopulation).clamp(0.0, 1.0);
    final distance = _colorDistance(anchorColor, swatch.color);
    final relatedness = (1.0 - ((distance - 0.24).abs() * 2.2)).clamp(0.0, 1.0);
    final lightnessBalance = (1.0 - ((hsl.lightness - 0.55).abs() * 1.6)).clamp(
      0.0,
      1.0,
    );
    final preferenceBonus = isPreferred ? 0.12 : 0.0;

    return (hsl.saturation * 0.5) +
        (populationScore * 0.26) +
        (relatedness * 0.16) +
        (lightnessBalance * 0.08) +
        preferenceBonus;
  }

  Color _pickSecondaryColor(
    PaletteGenerator palette,
    Color primary,
    Color glow,
  ) {
    final swatches = palette.paletteColors;
    if (swatches.isEmpty) {
      return _darken(primary, factor: 0.62);
    }

    final maxPopulation = swatches.fold<int>(
      1,
      (max, swatch) => swatch.population > max ? swatch.population : max,
    );

    PaletteColor? winner;
    var bestScore = -1.0;

    for (final swatch in swatches) {
      if (!_isDistinctColor(primary, swatch.color)) {
        continue;
      }

      final hsl = HSLColor.fromColor(swatch.color);
      final populationScore = (swatch.population / maxPopulation).clamp(
        0.0,
        1.0,
      );
      final primaryDistance = _colorDistance(
        primary,
        swatch.color,
      ).clamp(0.0, 1.0);
      final glowDistance = _colorDistance(glow, swatch.color).clamp(0.0, 1.0);
      final relationScore = (1.0 - ((primaryDistance - 0.36).abs() * 1.8))
          .clamp(0.0, 1.0);
      final glowRelation = (1.0 - ((glowDistance - 0.34).abs() * 1.8)).clamp(
        0.0,
        1.0,
      );
      final score =
          (populationScore * 0.52) +
          (relationScore * 0.24) +
          (glowRelation * 0.14) +
          (hsl.saturation * 0.1);

      if (score > bestScore) {
        bestScore = score;
        winner = swatch;
      }
    }

    if (winner != null) {
      return winner.color;
    }

    return _darken(primary, factor: 0.62);
  }

  Color _tuneGlowColor(Color source) {
    final hsl = HSLColor.fromColor(source);
    return hsl
        .withSaturation((hsl.saturation * 1.15 + 0.05).clamp(0.4, 1.0))
        .withLightness(hsl.lightness.clamp(0.26, 0.82))
        .toColor();
  }

  Color _tunePrimaryColor(Color source) {
    final hsl = HSLColor.fromColor(source);
    return hsl
        .withSaturation((hsl.saturation * 1.08).clamp(0.22, 0.95))
        .withLightness(hsl.lightness.clamp(0.2, 0.74))
        .toColor();
  }

  Color _tuneSecondaryColor(Color source) {
    final hsl = HSLColor.fromColor(source);
    return hsl
        .withSaturation((hsl.saturation * 1.02).clamp(0.16, 0.92))
        .withLightness(hsl.lightness.clamp(0.1, 0.58))
        .toColor();
  }

  Color _darken(Color color, {required double factor}) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness * factor).clamp(0.08, 0.56))
        .withSaturation((hsl.saturation * 0.92).clamp(0.14, 0.9))
        .toColor();
  }

  bool _isDistinctColor(Color primary, Color candidate) {
    final primaryHsl = HSLColor.fromColor(primary);
    final candidateHsl = HSLColor.fromColor(candidate);
    final rawHueDiff = (primaryHsl.hue - candidateHsl.hue).abs();
    final hueDiff = rawHueDiff > 180 ? 360 - rawHueDiff : rawHueDiff;

    return hueDiff >= 14 || _colorDistance(primary, candidate) >= 0.18;
  }

  double _colorDistance(Color first, Color second) {
    final firstHsl = HSLColor.fromColor(first);
    final secondHsl = HSLColor.fromColor(second);
    final rawHueDiff = (firstHsl.hue - secondHsl.hue).abs();
    final hueDiff = (rawHueDiff > 180 ? 360 - rawHueDiff : rawHueDiff) / 180;
    final saturationDiff = (firstHsl.saturation - secondHsl.saturation).abs();
    final lightnessDiff = (firstHsl.lightness - secondHsl.lightness).abs();

    return (hueDiff * 0.5) + (saturationDiff * 0.3) + (lightnessDiff * 0.2);
  }

  void _cachePalette(int songId, SongPalette palette, {bool persist = true}) {
    _touchCacheEntry(songId, palette);
    if (persist) {
      _schedulePersistCache();
    }
  }

  void _touchCacheEntry(int songId, SongPalette palette) {
    if (_paletteCache.containsKey(songId)) {
      _paletteCache.remove(songId);
    }
    _paletteCache[songId] = palette;
    _trimCache();
  }

  void _trimCache() {
    while (_paletteCache.length > _maxCacheEntries) {
      final oldestKey = _paletteCache.keys.first;
      _paletteCache.remove(oldestKey);
    }
  }

  void _schedulePersistCache() {
    final cacheVersion = _cacheVersion;
    _persistDebounceTimer?.cancel();
    _persistDebounceTimer = Timer(_persistDebounceDuration, () {
      unawaited(_persistCacheToDisk(cacheVersion));
    });
  }

  Future<void> _persistCacheToDisk(int cacheVersion) async {
    try {
      if (cacheVersion != _cacheVersion) {
        return;
      }

      if (_paletteCache.isEmpty) {
        await PreferencesService.clearArtworkPaletteCache();
        return;
      }

      final serialized = <int, Map<String, int>>{};
      for (final entry in _paletteCache.entries) {
        serialized[entry.key] = entry.value.toStorageMap();
      }

      if (cacheVersion != _cacheVersion) {
        return;
      }
      await PreferencesService.saveArtworkPaletteCache(serialized);
    } catch (_) {
      // Ignore cache persistence failures.
    }
  }

  static double contrastRatio(Color first, Color second) {
    final luminanceA = first.computeLuminance();
    final luminanceB = second.computeLuminance();
    final lighter = math.max(luminanceA, luminanceB);
    final darker = math.min(luminanceA, luminanceB);
    return (lighter + 0.05) / (darker + 0.05);
  }

  static Color readableText(
    Color background, {
    double minContrast = 4.5,
    Color light = Colors.white,
    Color dark = const Color(0xFF101114),
  }) {
    final lightContrast = contrastRatio(light, background);
    final darkContrast = contrastRatio(dark, background);

    if (lightContrast >= darkContrast && lightContrast >= minContrast) {
      return light;
    }
    if (darkContrast >= minContrast) {
      return dark;
    }
    return lightContrast >= darkContrast ? light : dark;
  }

  static Color readableMutedText(Color background, {double minContrast = 3.2}) {
    final base = readableText(background);
    final candidate = base.value == Colors.white.value
        ? base.withValues(alpha: 0.78)
        : base.withValues(alpha: 0.72);

    final effective = Color.alphaBlend(candidate, background);
    if (contrastRatio(effective, background) >= minContrast) {
      return candidate;
    }

    return base.value == Colors.white.value
        ? base.withValues(alpha: 0.9)
        : base.withValues(alpha: 0.84);
  }

  static Color readableAccent(
    Color accent,
    Color background, {
    double minContrast = 3.0,
  }) {
    if (contrastRatio(accent, background) >= minContrast) {
      return accent;
    }

    final safeText = readableText(background, minContrast: minContrast);
    return Color.lerp(accent, safeText, 0.36) ?? safeText;
  }

  static Color adaptiveSurfaceColor(Color background, {required bool isDark}) {
    return isDark
        ? Color.alphaBlend(Colors.black.withValues(alpha: 0.28), background)
        : Color.alphaBlend(Colors.white.withValues(alpha: 0.82), background);
  }

  static Color adaptiveBorderColor(Color background, {required bool isDark}) {
    final base = readableText(background, minContrast: 2.0);
    return isDark ? base.withValues(alpha: 0.18) : base.withValues(alpha: 0.14);
  }
}
