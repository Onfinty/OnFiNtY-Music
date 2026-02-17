import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

/// A cached artwork widget with improved quality and memory management
class CachedArtworkWidget extends StatefulWidget {
  final int id;
  final ArtworkType type;
  final double width;
  final double height;
  final int quality;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? nullArtworkWidget;

  const CachedArtworkWidget({
    super.key,
    required this.id,
    required this.type,
    this.width = 50,
    this.height = 50,
    this.quality = 100,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.nullArtworkWidget,
  });

  @override
  State<CachedArtworkWidget> createState() => _CachedArtworkWidgetState();

  // Public static methods
  static void clearCache() {
    _CachedArtworkWidgetState._clearCacheStatic();
  }

  static int getCacheSize() {
    return _CachedArtworkWidgetState._getCurrentCacheSize();
  }

  static int getCacheCount() {
    return _CachedArtworkWidgetState._getCacheCountStatic();
  }
}

class _CachedArtworkWidgetState extends State<CachedArtworkWidget> {
  static final Map<String, Uint8List> _artworkCache = {};
  static const int _maxCacheSize = 50 * 1024 * 1024; // 50MB max cache
  static int _currentCacheSize = 0;

  Uint8List? _cachedImage;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadArtwork();
  }

  @override
  void didUpdateWidget(CachedArtworkWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) {
      _loadArtwork();
    }
  }

  String get _cacheKey =>
      '${widget.type.name}_${widget.id}_${widget.width.toInt()}x${widget.height.toInt()}';

  Future<void> _loadArtwork() async {
    // Check cache first
    if (_artworkCache.containsKey(_cacheKey)) {
      if (mounted) {
        setState(() {
          _cachedImage = _artworkCache[_cacheKey];
          _isLoading = false;
          _hasError = false;
        });
      }
      return;
    }

    try {
      // Request higher quality for larger images
      final requestedQuality = widget.width > 200
          ? 100
          : widget.width > 100
          ? 90
          : 80;

      final artwork = await OnAudioQuery().queryArtwork(
        widget.id,
        widget.type,
        quality: requestedQuality,
        size: widget.width > 200 ? 500 : 200, // Request larger source image
      );

      if (artwork != null && artwork.isNotEmpty) {
        // Check cache size and clean if necessary
        if (_currentCacheSize + artwork.length > _maxCacheSize) {
          _cleanCache();
        }

        _artworkCache[_cacheKey] = artwork;
        _currentCacheSize += artwork.length;

        if (mounted) {
          setState(() {
            _cachedImage = artwork;
            _isLoading = false;
            _hasError = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasError = true;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  /// Clean oldest cache entries to free memory
  static void _cleanCache() {
    if (_artworkCache.isEmpty) return;

    // Remove 30% of cache
    final entriesToRemove = (_artworkCache.length * 0.3).ceil();
    final keys = _artworkCache.keys.take(entriesToRemove).toList();

    for (var key in keys) {
      final data = _artworkCache.remove(key);
      if (data != null) {
        _currentCacheSize -= data.length;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget child;

    if (_isLoading) {
      child =
          widget.nullArtworkWidget ??
          Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                  const Color(0xFF6D28D9).withValues(alpha: 0.3),
                ],
              ),
              borderRadius: widget.borderRadius,
            ),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
                ),
              ),
            ),
          );
    } else if (_hasError || _cachedImage == null) {
      child =
          widget.nullArtworkWidget ??
          Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                  const Color(0xFF6D28D9).withValues(alpha: 0.3),
                ],
              ),
              borderRadius: widget.borderRadius,
            ),
            child: Icon(
              Icons.music_note,
              color: const Color(0xFF8B5CF6),
              size: widget.width * 0.5,
            ),
          );
    } else {
      child = Image.memory(
        _cachedImage!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        gaplessPlayback: true,
        filterQuality: FilterQuality.high,
        isAntiAlias: true,
        errorBuilder: (context, error, stackTrace) {
          return widget.nullArtworkWidget ??
              Container(
                width: widget.width,
                height: widget.height,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                      const Color(0xFF6D28D9).withValues(alpha: 0.3),
                    ],
                  ),
                  borderRadius: widget.borderRadius,
                ),
                child: Icon(
                  Icons.music_note,
                  color: const Color(0xFF8B5CF6),
                  size: widget.width * 0.5,
                ),
              );
        },
      );
    }

    return RepaintBoundary(
      child: widget.borderRadius != null
          ? ClipRRect(borderRadius: widget.borderRadius!, child: child)
          : child,
    );
  }

  // Static accessors for cache management
  static void _clearCacheStatic() {
    _artworkCache.clear();
    _currentCacheSize = 0;
  }

  static int _getCurrentCacheSize() => _currentCacheSize;

  static int _getCacheCountStatic() => _artworkCache.length;
}
