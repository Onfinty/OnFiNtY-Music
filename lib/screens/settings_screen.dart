import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/music_provider.dart';
import '../services/preferences_service.dart';
import '../widgets/cached_artwork_widget.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isScanning = false;
  DateTime? _lastScanTime;

  @override
  void initState() {
    super.initState();
    _loadLastScanTime();
  }

  Future<void> _loadLastScanTime() async {
    final time = await PreferencesService.getLastScanTime();
    if (mounted) {
      setState(() {
        _lastScanTime = time;
      });
    }
  }

  Future<void> _scanMusicLibrary() async {
    if (_isScanning) return;

    setState(() {
      _isScanning = true;
    });

    try {
      // Check permissions
      var audioStatus = await Permission.audio.status;
      if (!audioStatus.isGranted) {
        audioStatus = await Permission.audio.request();
        if (!audioStatus.isGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Audio permission is required to scan music'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      // Trigger refresh by incrementing the provider
      ref.read(libraryRefreshProvider.notifier).state++;

      // Invalidate songs and albums providers to force reload
      ref.invalidate(songsProvider);
      ref.invalidate(albumsProvider);

      // Save scan time
      await PreferencesService.saveLastScanTime(DateTime.now());
      await _loadLastScanTime();

      if (mounted) {
        final accentColor = Theme.of(context).colorScheme.primary;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Music library refreshed successfully!'),
            backgroundColor: accentColor,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error scanning library: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  Future<void> _clearCache() async {
    try {
      final freedBytes = CachedArtworkWidget.getCacheSize();
      CachedArtworkWidget.clearCache();
      await ref.read(artworkPaletteServiceProvider).clearCache();

      if (mounted) {
        final accentColor = Theme.of(context).colorScheme.primary;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cache cleared! Freed ${(freedBytes / 1024 / 1024).toStringAsFixed(2)} MB',
            ),
            backgroundColor: accentColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error clearing cache: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cacheSize = CachedArtworkWidget.getCacheSize();
    final cacheCount = CachedArtworkWidget.getCacheCount();
    final isDark = ref.watch(isDarkModeProvider);
    final useDynamicArtworkTheme = ref.watch(dynamicArtworkThemeProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final backgroundColor = theme.scaffoldBackgroundColor;
    final textColor = colorScheme.onSurface;
    final subtitleColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final iconColor = colorScheme.primary;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Settings',
          style: TextStyle(
            fontFamily: 'Lobster',
            fontSize: 28,
            color: iconColor,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            title: 'Library',
            isDark: isDark,
            children: [
              _buildListTile(
                icon: Icons.refresh,
                title: 'Scan Music',
                subtitle: _isScanning
                    ? 'Scanning...'
                    : _lastScanTime != null
                    ? 'Last scanned: ${_formatLastScanTime()}'
                    : 'Refresh music library',
                isDark: isDark,
                trailing: _isScanning
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                        ),
                      )
                    : null,
                onTap: _isScanning ? null : _scanMusicLibrary,
              ),
              _buildListTile(
                icon: Icons.storage,
                title: 'Cache Size',
                subtitle:
                    '${(cacheSize / 1024 / 1024).toStringAsFixed(2)} MB ($cacheCount images)',
                isDark: isDark,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Current cache: ${(cacheSize / 1024 / 1024).toStringAsFixed(2)} MB\n'
                        'Cached images: $cacheCount\n'
                        'Max cache size: 50 MB',
                      ),
                      backgroundColor: iconColor,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                },
              ),
              _buildListTile(
                icon: Icons.clear_all,
                title: 'Clear Cache',
                subtitle: 'Free up space',
                isDark: isDark,
                onTap: () => _showClearCacheDialog(context, isDark),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSection(
            title: 'Appearance',
            isDark: isDark,
            children: [
              Consumer(
                builder: (context, ref, child) {
                  return ListTile(
                    leading: Icon(
                      isDark
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded,
                      color: iconColor,
                    ),
                    title: Text('Theme', style: TextStyle(color: textColor)),
                    subtitle: Text(
                      isDark ? 'Dark Mode' : 'Light Mode',
                      style: TextStyle(color: subtitleColor),
                    ),
                    trailing: Switch(
                      value: !isDark,
                      onChanged: (value) {
                        ref.read(themeModeProvider.notifier).toggle();
                      },
                      activeColor: iconColor,
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.auto_awesome_rounded, color: iconColor),
                title: Text(
                  'Dynamic Artwork Theme',
                  style: TextStyle(color: textColor),
                ),
                subtitle: Text(
                  useDynamicArtworkTheme
                      ? 'Using current song cover colors'
                      : 'Use default app theme colors',
                  style: TextStyle(color: subtitleColor),
                ),
                trailing: Switch(
                  value: useDynamicArtworkTheme,
                  onChanged: (value) {
                    ref
                        .read(dynamicArtworkThemeProvider.notifier)
                        .setEnabled(value);
                  },
                  activeColor: iconColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSection(
            title: 'Privacy',
            isDark: isDark,
            children: [
              _buildListTile(
                icon: Icons.visibility_off,
                title: 'Hidden Songs',
                subtitle: 'Manage hidden songs',
                isDark: isDark,
                onTap: () {
                  _showHiddenSongsDialog(context, isDark);
                },
              ),
              _buildListTile(
                icon: Icons.delete_outline,
                title: 'Clear All Data',
                subtitle: 'Reset all settings and favorites',
                isDark: isDark,
                onTap: () {
                  _showClearAllDataDialog(context, isDark);
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSection(
            title: 'About',
            isDark: isDark,
            children: [
              _buildListTile(
                icon: Icons.music_note,
                title: 'OnFiNtY',
                subtitle: 'Version 2.0.0',
                isDark: isDark,
                onTap: () {},
              ),
              _buildListTile(
                icon: Icons.info_outline,
                title: 'About App',
                subtitle: 'Lightweight music player',
                isDark: isDark,
                onTap: () {
                  _showAboutDialog(context, isDark);
                },
              ),
              _buildListTile(
                icon: Icons.code,
                title: 'Developer',
                subtitle: 'Made by Kyrillos Sameh',
                isDark: isDark,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Thanks for using OnFiNtY! 🎵'),
                      backgroundColor: iconColor,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  String _formatLastScanTime() {
    if (_lastScanTime == null) return 'Never';

    final now = DateTime.now();
    final difference = now.difference(_lastScanTime!);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else {
      return '${_lastScanTime!.day}/${_lastScanTime!.month}/${_lastScanTime!.year}';
    }
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
    required bool isDark,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              color: colorScheme.primary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textColor = isDark ? Colors.white : const Color(0xFF1C1B1F);
    final subtitleColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final iconColor = colorScheme.primary;

    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title, style: TextStyle(color: textColor)),
      subtitle: Text(subtitle, style: TextStyle(color: subtitleColor)),
      trailing:
          trailing ??
          (onTap != null
              ? const Icon(Icons.chevron_right, color: Colors.grey)
              : null),
      onTap: onTap,
    );
  }

  void _showAboutDialog(BuildContext context, bool isDark) {
    final bgColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final textColor = isDark ? Colors.white70 : Colors.black87;
    final iconColor = Theme.of(context).colorScheme.primary;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: bgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'OnFiNtY',
            style: TextStyle(
              fontFamily: 'Lobster',
              fontSize: 32,
              color: iconColor,
            ),
          ),
          content: SingleChildScrollView(
            child: Text(
              'A lightweight and smooth music player built with Flutter.\n\n'
              'Features:\n'
              '• Beautiful UI with glassmorphism\n'
              '• Background playback\n'
              '• Notification controls\n'
              '• Fast search\n'
              '• Favorite songs & albums\n'
              '• Hide unwanted songs\n'
              '• Playback speed control\n'
              '• Memory optimized (50MB cache limit)\n'
              '• High-quality album artwork\n'
              '• Smooth animations\n\n'
              'Made by Kyrillos Sameh\n'
              'Version 2.0.0',
              style: TextStyle(color: textColor, height: 1.5),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close', style: TextStyle(color: iconColor)),
            ),
          ],
        );
      },
    );
  }

  void _showClearCacheDialog(BuildContext context, bool isDark) {
    final cacheSize = CachedArtworkWidget.getCacheSize();
    final bgColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final textColor = isDark ? Colors.white70 : Colors.black87;
    final titleColor = isDark ? Colors.white : Colors.black;
    final iconColor = Theme.of(context).colorScheme.primary;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: bgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text('Clear Cache', style: TextStyle(color: titleColor)),
          content: Text(
            'This will clear ${(cacheSize / 1024 / 1024).toStringAsFixed(2)} MB of cached album artwork and saved cover-color palettes.\n\n'
            'Artwork and colors will be rebuilt as needed.',
            style: TextStyle(color: textColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _clearCache();
                setState(() {}); // Refresh cache size display
              },
              child: Text('Clear', style: TextStyle(color: iconColor)),
            ),
          ],
        );
      },
    );
  }

  void _showHiddenSongsDialog(BuildContext context, bool isDark) {
    final hiddenSongs = ref.read(hiddenSongsProvider);
    final bgColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final textColor = isDark ? Colors.white70 : Colors.black87;
    final titleColor = isDark ? Colors.white : Colors.black;
    final iconColor = Theme.of(context).colorScheme.primary;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: bgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text('Hidden Songs', style: TextStyle(color: titleColor)),
          content: Text(
            hiddenSongs.isEmpty
                ? 'You have no hidden songs.'
                : 'You have ${hiddenSongs.length} hidden song${hiddenSongs.length > 1 ? 's' : ''}.\n\n'
                      'You can view and unhide them from the "Hidden" tab on the home screen.',
            style: TextStyle(color: textColor),
          ),
          actions: [
            if (hiddenSongs.isNotEmpty)
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showClearHiddenSongsDialog(context, isDark);
                },
                child: const Text(
                  'Unhide All',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close', style: TextStyle(color: iconColor)),
            ),
          ],
        );
      },
    );
  }

  void _showClearHiddenSongsDialog(BuildContext context, bool isDark) {
    final hiddenSongs = ref.read(hiddenSongsProvider);
    final bgColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final textColor = isDark ? Colors.white70 : Colors.black87;
    final titleColor = isDark ? Colors.white : Colors.black;
    final iconColor = Theme.of(context).colorScheme.primary;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: bgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text('Unhide All Songs', style: TextStyle(color: titleColor)),
          content: Text(
            'This will unhide all ${hiddenSongs.length} hidden songs.\n\n'
            'Are you sure?',
            style: TextStyle(color: textColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                await ref.read(hiddenSongsProvider.notifier).clearAll();
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('All songs unhidden!'),
                      backgroundColor: iconColor,
                    ),
                  );
                }
              },
              child: Text('Unhide All', style: TextStyle(color: iconColor)),
            ),
          ],
        );
      },
    );
  }

  void _showClearAllDataDialog(BuildContext context, bool isDark) {
    final bgColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final textColor = isDark ? Colors.white70 : Colors.black87;
    final titleColor = isDark ? Colors.white : Colors.black;
    final iconColor = Theme.of(context).colorScheme.primary;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: bgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text('Clear All Data', style: TextStyle(color: titleColor)),
          content: Text(
            'This will permanently delete:\n\n'
            '• All favorite songs\n'
            '• All favorite albums\n'
            '• All hidden songs\n'
            '• All settings\n'
            '• Cached artwork\n\n'
            'This action cannot be undone!',
            style: TextStyle(color: textColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                // Clear all data
                await PreferencesService.clearAll();
                CachedArtworkWidget.clearCache();
                await ref.read(artworkPaletteServiceProvider).clearCache();

                // Refresh providers
                ref.invalidate(favoritesProvider);
                ref.invalidate(favoriteAlbumsProvider);
                ref.invalidate(hiddenSongsProvider);
                ref.invalidate(themeModeProvider);
                ref.invalidate(dynamicArtworkThemeProvider);

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('All data cleared successfully!'),
                      backgroundColor: iconColor,
                    ),
                  );

                  setState(() {
                    _lastScanTime = null;
                  });
                }
              },
              child: const Text(
                'Clear All',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}
