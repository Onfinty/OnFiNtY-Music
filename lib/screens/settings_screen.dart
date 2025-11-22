import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            title: 'About',
            children: [
              _buildListTile(
                icon: Icons.music_note,
                title: 'OnFiNtY',
                subtitle: 'Version 1.0.5',
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
                icon: Icons.headphones,
                title: 'Audio Quality',
                subtitle: 'High quality',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Audio quality set to high!'),
                      backgroundColor: Color(0xFF8B5CF6),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSection(
            title: 'Storage',
            children: [
              _buildListTile(
                icon: Icons.folder_open,
                title: 'Scan Music',
                subtitle: 'Refresh music library',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Music library refreshed!'),
                      backgroundColor: Color(0xFF8B5CF6),
                    ),
                  );
                },
              ),
              _buildListTile(
                icon: Icons.clear_all,
                title: 'Clear Cache',
                subtitle: 'Free up space',
                onTap: () {
                  _showClearCacheDialog(context);
                },
              ),
            ],
          ),
        ],
      ),
    );
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
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF8B5CF6)),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[600])),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
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
          content: const Text(
            'A lightweight and smooth music player built with Flutter.\n\n'
            'Features:\n'
            '• Beautiful UI\n'
            '• Background playback\n'
            '• Notification controls\n'
            '• Fast search\n'
            '• Responsive design\n'
            '• Made by Kyrillos sameh\n'
            'Version 1.0.5',
            style: TextStyle(color: Colors.white70),
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
          content: const Text(
            'This will clear all cached data. Are you sure?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cache cleared successfully!'),
                    backgroundColor: Color(0xFF8B5CF6),
                  ),
                );
              },
              child: const Text('Clear', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
