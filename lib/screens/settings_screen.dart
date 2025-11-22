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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Music library refreshed successfully!'),
            backgroundColor: Color(0xFF8B5CF6),
            duration: Duration(seconds: 2),
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
      // Clear artwork cache
      CachedArtworkWidget.clearCache();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cache cleared! Freed ${(CachedArtworkWidget.getCacheSize() / 1024 / 1024).toStringAsFixed(2)} MB',
            ),
            backgroundColor: const Color(0xFF8B5CF6),
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
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            fontFamily: 'Lobster',
            fontSize: 28,
            color: Color(0xFF8B5CF6),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            title: 'Library',
            children: [
              _buildListTile(
                icon: Icons.refresh,
                title: 'Scan Music',
                subtitle: _isScanning
                    ? 'Scanning...'
                    : _lastScanTime != null
                        ? 'Last scanned: ${_formatLastScanTime()}'
                        : 'Refresh music library',
                trailing: _isScanning
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF8B5CF6),
                          ),
                        ),
                      )
                    : null,
                onTap: _isScanning ? null : _scanMusicLibrary,
              ),
              _buildListTile(
                icon: Icons.storage,
                title: 'Cache Size',
                subtitle: '${(cacheSize / 1024 / 1024).toStringAsFixed(2)} MB ($cacheCount images)',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Current cache: ${(cacheSize / 1024 / 1024).toStringAsFixed(2)} MB\n'
                        'Cached images: $cacheCount\n'
                        'Max cache size: 50 MB',
                      ),
                      backgroundColor: const Color(0xFF8B5CF6),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                },
              ),
              _buildListTile(
                icon: Icons.clear_all,
                title: 'Clear Cache',
                subtitle: 'Free up space',
                onTap: () => _showClearCacheDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSection(
            title: 'Audio',
            children: [
              _buildListTile(
                icon: Icons.equalizer,
                title: 'Equalizer',
                subtitle: 'Coming soon',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Equalizer feature coming soon!'),
                      backgroundColor: Color(0xFF8B5CF6),
                    ),
                  );
                },
              ),
              _buildListTile(
                icon: Icons.high_quality,
                title: 'Audio Quality',
                subtitle: 'High (AAC 320kbps)',
                onTap: () {
                  _showAudioQualityDialog(context);
                },
              ),
              _buildListTile(
                icon: Icons.headphones,
                title: 'Headphone Detection',
                subtitle: 'Auto-pause when disconnected',
                trailing: Switch(
                  value: true,
                  onChanged: (value) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          value
                              ? 'Headphone detection enabled'
                              : 'Headphone detection disabled',
                        ),
                        backgroundColor: const Color(0xFF8B5CF6),
                      ),
                    );
                  },
                  activeColor: const Color(0xFF8B5CF6),
                ),
                onTap: null,
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSection(
            title: 'Privacy',
            children: [
              _buildListTile(
                icon: Icons.visibility_off,
                title: 'Hidden Songs',
                subtitle: 'Manage hidden songs',
                onTap: () {
                  _showHiddenSongsDialog(context);
                },
              ),
              _buildListTile(
                icon: Icons.delete_outline,
                title: 'Clear All Data',
                subtitle: 'Reset all settings and favorites',
                onTap: () {
                  _showClearAllDataDialog(context);
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSection(
            title: 'About',
            children: [
              _buildListTile(
                icon: Icons.music_note,
                title: 'OnFiNtY',
                subtitle: 'Version 1.0.6',
                onTap: () {},
              ),
              _buildListTile(
                icon: Icons.info_outline,
                title: 'About App',
                subtitle: 'Lightweight music player',
                onTap: () {
                  _showAboutDialog(context);
                },
              ),
              _buildListTile(
                icon: Icons.code,
                title: 'Developer',
                subtitle: 'Made by Kyrillos Sameh',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Thanks for using OnFiNtY! 🎵'),
                      backgroundColor: Color(0xFF8B5CF6),
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF8B5CF6),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
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
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF8B5CF6)),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[600])),
      trailing: trailing ?? 
          (onTap != null 
              ? const Icon(Icons.chevron_right, color: Colors.grey)
              : null),
      onTap: onTap,
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'OnFiNtY',
            style: TextStyle(
              fontFamily: 'Lobster',
              fontSize: 32,
              color: Color(0xFF8B5CF6),
            ),
          ),
          content: const SingleChildScrollView(
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
              'Version 1.0.6',
              style: TextStyle(color: Colors.white70, height: 1.5),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Close',
                style: TextStyle(color: Color(0xFF8B5CF6)),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showClearCacheDialog(BuildContext context) {
    final cacheSize = CachedArtworkWidget.getCacheSize();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Clear Cache',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'This will clear ${(cacheSize / 1024 / 1024).toStringAsFixed(2)} MB of cached album artwork.\n\n'
            'Artwork will be reloaded as needed.',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _clearCache();
                setState(() {}); // Refresh cache size display
              },
              child: const Text(
                'Clear',
                style: TextStyle(color: Color(0xFF8B5CF6)),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAudioQualityDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Audio Quality',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildQualityOption(
                context,
                'Low',
                '128 kbps • Saves data',
                false,
              ),
              _buildQualityOption(
                context,
                'Normal',
                '192 kbps • Balanced',
                false,
              ),
              _buildQualityOption(
                context,
                'High',
                '320 kbps • Best quality',
                true,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQualityOption(
    BuildContext context,
    String title,
    String subtitle,
    bool isSelected,
  ) {
    return ListTile(
      leading: Icon(
        isSelected ? Icons.check_circle : Icons.circle_outlined,
        color: isSelected ? const Color(0xFF8B5CF6) : Colors.grey,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? const Color(0xFF8B5CF6) : Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey[600], fontSize: 12),
      ),
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Audio quality set to $title'),
            backgroundColor: const Color(0xFF8B5CF6),
          ),
        );
      },
    );
  }

  void _showHiddenSongsDialog(BuildContext context) {
    final hiddenSongs = ref.read(hiddenSongsProvider);
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Hidden Songs',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            hiddenSongs.isEmpty
                ? 'You have no hidden songs.'
                : 'You have ${hiddenSongs.length} hidden song${hiddenSongs.length > 1 ? 's' : ''}.\n\n'
                    'You can view and unhide them from the "Hidden" tab on the home screen.',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            if (hiddenSongs.isNotEmpty)
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showClearHiddenSongsDialog(context);
                },
                child: const Text(
                  'Unhide All',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Close',
                style: TextStyle(color: Color(0xFF8B5CF6)),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showClearHiddenSongsDialog(BuildContext context) {
    final hiddenSongs = ref.read(hiddenSongsProvider);
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Unhide All Songs',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'This will unhide all ${hiddenSongs.length} hidden songs.\n\n'
            'Are you sure?',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () async {
                await ref.read(hiddenSongsProvider.notifier).clearAll();
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('All songs unhidden!'),
                      backgroundColor: Color(0xFF8B5CF6),
                    ),
                  );
                }
              },
              child: const Text(
                'Unhide All',
                style: TextStyle(color: Color(0xFF8B5CF6)),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showClearAllDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Clear All Data',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'This will permanently delete:\n\n'
            '• All favorite songs\n'
            '• All favorite albums\n'
            '• All hidden songs\n'
            '• All settings\n'
            '• Cached artwork\n\n'
            'This action cannot be undone!',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () async {
                // Clear all data
                await PreferencesService.clearAll();
                CachedArtworkWidget.clearCache();
                
                // Refresh providers
                ref.invalidate(favoritesProvider);
                ref.invalidate(favoriteAlbumsProvider);
                ref.invalidate(hiddenSongsProvider);
                
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('All data cleared successfully!'),
                      backgroundColor: Color(0xFF8B5CF6),
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