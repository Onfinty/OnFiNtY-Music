import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/song_model.dart';
import '../screens/album_detail_screen.dart';
import 'package:on_audio_query/on_audio_query.dart' show AlbumModel;
import '../screens/home_screen.dart';
import '../screens/player_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/splash_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/player',
        pageBuilder: (context, state) {
          final song = state.extra as SongModel?;
          return CustomTransitionPage(
            key: state.pageKey,
            child: PlayerScreen(song: song),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  const begin = Offset(0.0, 1.0);
                  const end = Offset.zero;
                  const curve = Curves.easeInOut;

                  var tween = Tween(
                    begin: begin,
                    end: end,
                  ).chain(CurveTween(curve: curve));

                  return SlideTransition(
                    position: animation.drive(tween),
                    child: child,
                  );
                },
          );
        },
      ),
      GoRoute(
        path: '/album',
        builder: (context, state) {
          final album = state.extra as AlbumModel;
          return AlbumDetailScreen(album: album);
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});
