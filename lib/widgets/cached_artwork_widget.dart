import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

/// A cached artwork widget that prevents image reloading and shaking
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
}

class _CachedArtworkWidgetState extends State<CachedArtworkWidget>
    with AutomaticKeepAliveClientMixin {
  static final Map<String, Uint8List> _artworkCache = {};
  Uint8List? _cachedImage;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadArtwork();
  }

  @override
  void didUpdateWidget(CachedArtworkWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only reload if the ID actually changed
    if (oldWidget.id != widget.id) {
      _loadArtwork();
    }
  }

  String get _cacheKey => '${widget.type.name}_${widget.id}';

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
      final artwork = await OnAudioQuery().queryArtwork(
        widget.id,
        widget.type,
        quality: widget.quality,
      );

      if (artwork != null && artwork.isNotEmpty) {
        _artworkCache[_cacheKey] = artwork;
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

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    Widget child;

    if (_isLoading) {
      child = widget.nullArtworkWidget ??
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
      child = widget.nullArtworkWidget ??
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
        gaplessPlayback: true, // Critical: prevents flashing between images
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

    // Wrap in RepaintBoundary to prevent unnecessary repaints
    return RepaintBoundary(
      child: widget.borderRadius != null
          ? ClipRRect(
              borderRadius: widget.borderRadius!,
              child: child,
            )
          : child,
    );
  }

  /// Clear all cached artwork (useful for memory management)
  static void clearCache() {
    _artworkCache.clear();
  }

  /// Clear specific artwork from cache
  static void clearArtwork(String key) {
    _artworkCache.remove(key);
  }

  /// Get cache size in bytes
  static int getCacheSize() {
    int totalSize = 0;
    for (var artwork in _artworkCache.values) {
      totalSize += artwork.length;
    }
    return totalSize;
  }
}