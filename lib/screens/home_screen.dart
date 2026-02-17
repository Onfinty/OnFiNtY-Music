// ignore_for_file: prefer_single_quotes

import 'dart:ui';
import 'package:draggable_scrollbar/draggable_scrollbar.dart';
import 'package:fitapp/screens/album_detail_screen.dart';
import 'package:fitapp/widgets/cached_artwork_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:on_audio_query/on_audio_query.dart' hide SongModel;
import 'package:skeletonizer/skeletonizer.dart';

import '../models/song_model.dart';
import '../providers/music_provider.dart';
import '../services/artwork_palette_service.dart';
import '../widgets/mini_player.dart';
import '../widgets/song_tile.dart';

enum MusicTab { songs, albums, hidden }

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  MusicTab _currentTab = MusicTab.songs;
  int _lastTabIndex = 0;
  bool _tabSwitchForward = true;
  int _tabTransitionTick = 0;
  final ScrollController _scrollController = ScrollController();
  late TabController _tabController;
  bool _showSearch = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final targetIndex = _tabController.index;
        setState(() {
          _tabSwitchForward = targetIndex >= _lastTabIndex;
          _lastTabIndex = targetIndex;
          _tabTransitionTick++;
          _currentTab = MusicTab.values[targetIndex];
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(0);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (!_showSearch) {
        _searchController.clear();
        ref.read(searchQueryProvider.notifier).state = '';
        _searchFocusNode.unfocus();
      } else {
        Future.delayed(const Duration(milliseconds: 100), () {
          _searchFocusNode.requestFocus();
        });
      }
    });
  }

  List<Color> _buildHomeBackgroundGradient(SongPalette palette, bool isDark) {
    if (isDark) {
      return <Color>[
        palette.gradientPrimary.withValues(alpha: 0.42),
        Color.lerp(palette.gradientSecondary, Colors.black, 0.38)!,
        const Color(0xFF040404),
      ];
    }

    return <Color>[
      Color.lerp(palette.gradientPrimary, Colors.white, 0.66)!,
      Color.lerp(palette.gradientSecondary, Colors.white, 0.84)!,
      Colors.white,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final filteredSongs = ref.watch(filteredSongsProvider);
    final currentSongAsync = ref.watch(currentSongProvider);
    final hiddenSongs = ref.watch(hiddenSongsProvider);
    final currentSong = currentSongAsync.value;
    final isDark = ref.watch(isDarkModeProvider);
    final useDynamicArtworkTheme = ref.watch(dynamicArtworkThemeProvider);
    final dynamicPalette = ref.watch(currentThemePaletteProvider);
    final activePalette = useDynamicArtworkTheme
        ? dynamicPalette
        : SongPalette.fallback;
    final homeGradient = _buildHomeBackgroundGradient(activePalette, isDark);
    final headerBackground = Color.lerp(homeGradient[0], homeGradient[1], 0.3)!;
    final headerTextColor = ArtworkPaletteService.readableText(
      headerBackground,
    );
    final headerSubtitleColor = ArtworkPaletteService.readableMutedText(
      headerBackground,
    );
    final accentColor = ArtworkPaletteService.readableAccent(
      activePalette.glowColor,
      headerBackground,
    );
    final surfaceColor = ArtworkPaletteService.adaptiveSurfaceColor(
      headerBackground,
      isDark: isDark,
    );
    final borderColor = ArtworkPaletteService.adaptiveBorderColor(
      headerBackground,
      isDark: isDark,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeInOutCubic,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const <double>[0, 0.35, 1],
            colors: homeGradient,
          ),
        ),
        child: Column(
          children: [
            // ─── Premium Header ───
            _buildHeader(
              isDark: isDark,
              palette: activePalette,
              titleColor: headerTextColor,
              subtitleColor: headerSubtitleColor,
              accentColor: accentColor,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
            ),

            // ─── Animated Tab Bar ───
            _buildTabBar(
              isDark: isDark,
              palette: activePalette,
              accentColor: accentColor,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
            ),

            // ─── Search Bar (Animated) ───
            _buildSearchBar(
              isDark: isDark,
              accentColor: accentColor,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
            ),

            // ─── Content ───
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  final slide = Tween<Offset>(
                    begin: Offset(_tabSwitchForward ? 0.05 : -0.05, 0),
                    end: Offset.zero,
                  ).animate(animation);
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(position: slide, child: child),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey<String>(
                    '${_currentTab.name}_$_tabTransitionTick',
                  ),
                  child: _buildTabContent(
                    filteredSongs,
                    hiddenSongs,
                    isDark,
                    accentColor,
                  ),
                ),
              ),
            ),

            // ─── Mini Player ───
            if (currentSong != null) const MiniPlayer(),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildHeader({
    required bool isDark,
    required SongPalette palette,
    required Color titleColor,
    required Color subtitleColor,
    required Color accentColor,
    required Color surfaceColor,
    required Color borderColor,
  }) {
    final filteredSongs = ref.watch(filteredSongsProvider);
    final songCount = filteredSongs.when(
      data: (songs) => songs.where((s) => s.duration >= 60000).length,
      loading: () => 0,
      error: (_, __) => 0,
    );

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 24,
        right: 16,
        bottom: 8,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            palette.gradientPrimary.withValues(alpha: isDark ? 0.3 : 0.24),
            Color.lerp(
              palette.gradientSecondary,
              isDark ? Colors.black : Colors.white,
              isDark ? 0.5 : 0.74,
            )!,
          ],
        ),
      ),
      child: Row(
        children: [
          // Logo & Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: <Color>[accentColor, palette.gradientPrimary],
                  ).createShader(bounds),
                  child: const Text(
                    'OnFiNtY',
                    style: TextStyle(
                      fontFamily: 'Lobster',
                      fontSize: 34,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$songCount songs in your library',
                  style: TextStyle(
                    color: subtitleColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),

          // Action Buttons
          _buildHeaderButton(
            icon: _showSearch ? Icons.close : Icons.search_rounded,
            onTap: _toggleSearch,
            isDark: isDark,
            accentColor: accentColor,
            backgroundColor: surfaceColor,
            borderColor: borderColor,
            iconColor: titleColor,
          ),
          const SizedBox(width: 8),
          _buildHeaderButton(
            icon: Icons.settings_rounded,
            onTap: () => context.push('/settings'),
            isDark: isDark,
            accentColor: accentColor,
            backgroundColor: surfaceColor,
            borderColor: borderColor,
            iconColor: titleColor,
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
    required Color accentColor,
    required Color backgroundColor,
    required Color borderColor,
    required Color iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.14),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SEARCH BAR
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildSearchBar({
    required bool isDark,
    required Color accentColor,
    required Color surfaceColor,
    required Color borderColor,
  }) {
    final textColor = ArtworkPaletteService.readableText(surfaceColor);
    final hintColor = ArtworkPaletteService.readableMutedText(surfaceColor);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      height: _showSearch ? 56 : 0,
      padding: _showSearch
          ? const EdgeInsets.symmetric(horizontal: 20, vertical: 8)
          : EdgeInsets.zero,
      child: AnimatedOpacity(
        opacity: _showSearch ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 250),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: 1),
                boxShadow: isDark
                    ? []
                    : [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.12),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: (value) {
                  ref.read(searchQueryProvider.notifier).state = value;
                },
                style: TextStyle(color: textColor, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Search songs, artists, albums...',
                  hintStyle: TextStyle(color: hintColor, fontSize: 15),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: accentColor,
                    size: 22,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB BAR
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildTabBar({
    required bool isDark,
    required SongPalette palette,
    required Color accentColor,
    required Color surfaceColor,
    required Color borderColor,
  }) {
    final unselectedLabelColor = ArtworkPaletteService.readableMutedText(
      surfaceColor,
    );
    final selectedLabelColor = ArtworkPaletteService.readableText(accentColor);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[accentColor, palette.gradientPrimary],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(4),
        dividerColor: Colors.transparent,
        labelColor: selectedLabelColor,
        unselectedLabelColor: unselectedLabelColor,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          letterSpacing: 0.3,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        tabs: const [
          Tab(text: 'Songs'),
          Tab(text: 'Albums'),
          Tab(text: 'Hidden'),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB CONTENT
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildTabContent(
    AsyncValue<List<SongModel>> filteredSongs,
    List<int> hiddenSongs,
    bool isDark,
    Color accentColor,
  ) {
    if (_currentTab == MusicTab.albums) {
      return _buildAlbumsView(isDark, accentColor);
    }

    return filteredSongs.when(
      data: (songs) {
        List<SongModel> displaySongs;

        if (_currentTab == MusicTab.hidden) {
          displaySongs = songs
              .where(
                (song) =>
                    hiddenSongs.contains(song.id) || song.duration < 60000,
              )
              .toList();
        } else {
          displaySongs = songs
              .where(
                (song) =>
                    !hiddenSongs.contains(song.id) && song.duration >= 60000,
              )
              .toList();
        }

        if (displaySongs.isEmpty) {
          return _buildEmptyState(isDark, accentColor);
        }

        return DraggableScrollbar.semicircle(
          controller: _scrollController,
          backgroundColor: accentColor,
          scrollbarTimeToFade: const Duration(seconds: 2),
          heightScrollThumb: 60.0,
          child: ListView.builder(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            itemCount: displaySongs.length,
            padding: const EdgeInsets.only(
              top: 8,
              bottom: 100,
              left: 8,
              right: 12,
            ),
            itemBuilder: (context, index) {
              return SongTile(
                song: displaySongs[index],
                index: index,
                onTap: () async {
                  final selectedSong = displaySongs[index];
                  final allSongs = _currentTab == MusicTab.hidden
                      ? displaySongs
                      : songs
                            .where(
                              (song) =>
                                  !hiddenSongs.contains(song.id) &&
                                  song.duration >= 60000,
                            )
                            .toList();
                  final selectedIndex = allSongs.indexWhere(
                    (song) => song.id == selectedSong.id,
                  );
                  final startIndex = selectedIndex >= 0 ? selectedIndex : 0;

                  final audioHandler = ref.read(audioHandlerProvider);
                  await audioHandler.setPlaylist(allSongs, startIndex);
                  await audioHandler.play();
                },
                onLongPress: () {
                  _showSongOptions(
                    context,
                    displaySongs[index],
                    isDark,
                    accentColor,
                  );
                },
              );
            },
          ),
        );
      },
      loading: () => _buildLoadingSkeleton(isDark),
      error: (error, stack) => _buildErrorState(error, isDark, accentColor),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EMPTY STATE
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildEmptyState(bool isDark, Color accentColor) {
    final backgroundColor = isDark
        ? Color.alphaBlend(
            accentColor.withValues(alpha: 0.16),
            const Color(0xFF0D0D0D),
          )
        : Color.alphaBlend(
            accentColor.withValues(alpha: 0.1),
            const Color(0xFFF8F7FC),
          );
    final primaryTextColor = ArtworkPaletteService.readableText(
      backgroundColor,
    );
    final secondaryTextColor = ArtworkPaletteService.readableMutedText(
      backgroundColor,
    );

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  accentColor.withValues(alpha: isDark ? 0.28 : 0.24),
                  Color.lerp(
                    accentColor,
                    isDark ? Colors.black : Colors.white,
                    isDark ? 0.65 : 0.82,
                  )!,
                ],
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: isDark
                  ? []
                  : [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
            ),
            child: Icon(
              _currentTab == MusicTab.hidden
                  ? Icons.visibility_off_rounded
                  : Icons.music_off_rounded,
              size: 48,
              color: ArtworkPaletteService.readableAccent(
                accentColor,
                backgroundColor,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _currentTab == MusicTab.hidden
                ? 'No hidden songs'
                : 'No music found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: primaryTextColor,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _currentTab == MusicTab.hidden
                ? 'Long press songs to hide them'
                : 'Add some music to your phone',
            style: TextStyle(fontSize: 14, color: secondaryTextColor),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LOADING SKELETON
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildLoadingSkeleton(bool isDark) {
    return Skeletonizer(
      child: ListView.builder(
        itemCount: 12,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 180, height: 14, color: Colors.grey),
                      const SizedBox(height: 6),
                      Container(width: 120, height: 12, color: Colors.grey),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ERROR STATE
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildErrorState(Object error, bool isDark, Color accentColor) {
    final backgroundColor = isDark
        ? Color.alphaBlend(
            accentColor.withValues(alpha: 0.14),
            const Color(0xFF0D0D0D),
          )
        : Color.alphaBlend(accentColor.withValues(alpha: 0.08), Colors.white);
    final titleColor = ArtworkPaletteService.readableText(backgroundColor);
    final bodyColor = ArtworkPaletteService.readableMutedText(backgroundColor);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: isDark ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              size: 40,
              color: Colors.redAccent,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Error loading songs',
            style: TextStyle(
              color: titleColor,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              error.toString(),
              style: TextStyle(color: bodyColor, fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ALBUMS VIEW
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildAlbumsView(bool isDark, Color accentColor) {
    final albumsAsync = ref.watch(filteredAlbumsProvider);
    final favoriteSongs = ref.watch(favoritesProvider);

    return albumsAsync.when(
      data: (albums) {
        if (albums.isEmpty && favoriteSongs.isEmpty) {
          final emptyTextColor = ArtworkPaletteService.readableMutedText(
            isDark ? const Color(0xFF101010) : const Color(0xFFF6F3FC),
          );
          return Center(
            child: Text(
              'No albums found',
              style: TextStyle(color: emptyTextColor),
            ),
          );
        }

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ─── All Albums Grid ───
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.78,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  if (index == 0) {
                    return _buildLikedSongsPinnedCard(
                      isDark,
                      favoriteSongs.length,
                      accentColor,
                    );
                  }
                  return _buildAlbumCard(
                    albums[index - 1],
                    isDark,
                    accentColor,
                  );
                }, childCount: albums.length + 1),
              ),
            ),
          ],
        );
      },
      loading: () => _buildLoadingSkeleton(isDark),
      error: (error, stack) => _buildErrorState(error, isDark, accentColor),
    );
  }

  Widget _buildLikedSongsPinnedCard(bool isDark, int count, Color accentColor) {
    final cardSurface = ArtworkPaletteService.adaptiveSurfaceColor(
      isDark ? const Color(0xFF101010) : const Color(0xFFF8F7FC),
      isDark: isDark,
    );
    final cardTextColor = ArtworkPaletteService.readableText(cardSurface);
    final cardSubtitleColor = ArtworkPaletteService.readableMutedText(
      cardSurface,
    );

    return GestureDetector(
      onTap: () {
        // Create a virtual AlbumModel for Liked Songs
        final likedSongsAlbum = AlbumModel({
          "_id": -1,
          "album": "Liked Songs",
          "artist": "Your Favorites",
          "num_of_songs": count,
        });
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AlbumDetailScreen(album: likedSongsAlbum),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: cardSurface,
          borderRadius: BorderRadius.circular(20),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      accentColor,
                      Color.lerp(accentColor, Colors.pinkAccent, 0.45)!,
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.favorite_rounded,
                    size: 48,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Liked Songs',
                    style: TextStyle(
                      color: cardTextColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Pinned Album',
                    style: TextStyle(color: cardSubtitleColor, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ALBUM CARD
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildAlbumCard(AlbumModel album, bool isDark, Color accentColor) {
    final favoriteAlbums = ref.watch(favoriteAlbumsProvider);
    final isFavorite = favoriteAlbums.contains(album.id.toString());
    final cardSurface = ArtworkPaletteService.adaptiveSurfaceColor(
      isDark ? const Color(0xFF101010) : const Color(0xFFF8F7FC),
      isDark: isDark,
    );
    final titleColor = ArtworkPaletteService.readableText(cardSurface);
    final subtitleColor = ArtworkPaletteService.readableMutedText(cardSurface);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AlbumDetailScreen(album: album),
          ),
        );
      },
      onLongPress: () {
        ref
            .read(favoriteAlbumsProvider.notifier)
            .toggleFavoriteAlbum(album.id.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isFavorite ? 'Removed from favorites' : 'Added to favorites',
            ),
            backgroundColor: accentColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: cardSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isFavorite
                ? accentColor
                : (isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : const Color(0xFFE8DEF8).withValues(alpha: 0.5)),
            width: isFavorite ? 2 : 1,
          ),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(17),
                    ),
                    child: CachedArtworkWidget(
                      id: album.id,
                      type: ArtworkType.ALBUM,
                      width: double.infinity,
                      height: double.infinity,
                      quality: 100,
                      fit: BoxFit.cover,
                      nullArtworkWidget: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDark
                                ? [
                                    accentColor.withValues(alpha: 0.3),
                                    const Color(
                                      0xFF6D28D9,
                                    ).withValues(alpha: 0.3),
                                  ]
                                : [
                                    const Color(0xFFE8DEF8),
                                    const Color(0xFFD0BCFF),
                                  ],
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.album_rounded,
                            size: 56,
                            color: isDark
                                ? accentColor
                                : const Color(
                                    0xFF7C3AED,
                                  ).withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (isFavorite)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.black : Colors.white)
                              .withValues(alpha: 0.7),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.favorite_rounded,
                          color: accentColor,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    album.album,
                    style: TextStyle(
                      color: titleColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          album.artist ?? 'Unknown',
                          style: TextStyle(color: subtitleColor, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${album.numOfSongs}',
                        style: TextStyle(
                          color: subtitleColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.music_note_rounded,
                        size: 12,
                        color: subtitleColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ALL ALBUMS BOTTOM SHEET
  // ═══════════════════════════════════════════════════════════════════════════

  // ═══════════════════════════════════════════════════════════════════════════
  // SONG OPTIONS BOTTOM SHEET
  // ═══════════════════════════════════════════════════════════════════════════
  void _showSongOptions(
    BuildContext context,
    SongModel song,
    bool isDark,
    Color accentColor,
  ) {
    final hiddenSongs = ref.read(hiddenSongsProvider);
    final isHidden = hiddenSongs.contains(song.id);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[700] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: isDark
                          ? accentColor.withValues(alpha: 0.15)
                          : const Color(0xFFE8DEF8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isHidden
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                      color: accentColor,
                      size: 22,
                    ),
                  ),
                  title: Text(
                    isHidden ? 'Unhide Song' : 'Hide Song',
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF1C1B1F),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    isHidden
                        ? 'Show in your library'
                        : 'Remove from your library',
                    style: TextStyle(
                      color: isDark ? Colors.grey[600] : Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                  onTap: () {
                    ref
                        .read(hiddenSongsProvider.notifier)
                        .toggleHidden(song.id);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isHidden ? 'Song unhidden' : 'Song hidden',
                        ),
                        backgroundColor: accentColor,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}
