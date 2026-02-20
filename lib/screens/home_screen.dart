// ignore_for_file: prefer_single_quotes

import 'dart:math' as math;
import 'dart:ui';
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
import '../services/performance_service.dart';
import '../widgets/beautiful_draggable_scrollbar.dart';
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
  static const int _initialSongBatchSize = 28;
  static const int _songBatchSize = 20;
  static const double _songLoadMoreThreshold = 320;

  MusicTab _currentTab = MusicTab.songs;
  int _lastTabIndex = 0;
  bool _tabSwitchForward = true;
  int _tabTransitionTick = 0;
  final ScrollController _scrollController = ScrollController();
  late TabController _tabController;
  bool _showSearch = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  int _visibleSongCount = 0;
  int _songListTotalCount = 0;
  String _songListToken = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleSongListScroll);
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final targetIndex = _tabController.index;
        setState(() {
          _tabSwitchForward = targetIndex >= _lastTabIndex;
          _lastTabIndex = targetIndex;
          _tabTransitionTick++;
          _currentTab = MusicTab.values[targetIndex];
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !_scrollController.hasClients) {
            return;
          }
          _scrollController.jumpTo(_scrollController.position.minScrollExtent);
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleSongListScroll);
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

  List<double> _buildEvenStops(int count) {
    if (count <= 1) {
      return const <double>[0.0];
    }
    return List<double>.generate(count, (index) => index / (count - 1));
  }

  List<Color> _buildHomeBackgroundGradient(
    SongPalette palette,
    bool isDark, {
    required bool useFullGradient,
  }) {
    if (useFullGradient && palette.gradientColors.length >= 3) {
      return ArtworkPaletteService.buildDetailedGradient(
        palette.gradientColors,
        targetCount: 70,
      );
    }

    final source = <Color>[palette.gradientPrimary, palette.gradientSecondary];
    final gradient = <Color>[];

    for (var index = 0; index < source.length; index++) {
      final progress = source.length <= 1 ? 0.0 : index / (source.length - 1);
      final blend = isDark
          ? (0.22 + (progress * 0.58)).clamp(0.0, 0.92)
          : (0.56 + (progress * 0.34)).clamp(0.0, 0.94);
      gradient.add(
        Color.lerp(source[index], isDark ? Colors.black : Colors.white, blend)!,
      );
    }

    if (gradient.length < 3) {
      return isDark
          ? <Color>[
              palette.gradientPrimary.withValues(alpha: 0.42),
              Color.lerp(palette.gradientSecondary, Colors.black, 0.38)!,
              const Color(0xFF040404),
            ]
          : <Color>[
              Color.lerp(palette.gradientPrimary, Colors.white, 0.66)!,
              Color.lerp(palette.gradientSecondary, Colors.white, 0.84)!,
              Colors.white,
            ];
    }

    return gradient;
  }

  void _syncSongPagination({
    required String listToken,
    required int totalSongs,
  }) {
    _songListTotalCount = totalSongs;

    if (_songListToken != listToken) {
      _songListToken = listToken;
      _visibleSongCount = math.min(totalSongs, _initialSongBatchSize);
      return;
    }

    if (_visibleSongCount > totalSongs) {
      _visibleSongCount = totalSongs;
    }
  }

  void _handleSongListScroll() {
    _loadMoreSongsIfNeeded();
  }

  void _loadMoreSongsIfNeeded({bool force = false}) {
    if (!mounted || _currentTab == MusicTab.albums) {
      return;
    }

    if (_visibleSongCount >= _songListTotalCount) {
      return;
    }

    if (_scrollController.hasClients) {
      final position = _scrollController.position;
      final remainingExtent = position.maxScrollExtent - position.pixels;
      if (!force && remainingExtent > _songLoadMoreThreshold) {
        return;
      }
    } else if (!force) {
      return;
    }

    final nextCount = math.min(
      _visibleSongCount + _songBatchSize,
      _songListTotalCount,
    );
    if (nextCount == _visibleSongCount) {
      return;
    }

    setState(() {
      _visibleSongCount = nextCount;
    });
  }

  Widget _buildBackgroundDecor({
    required SongPalette palette,
    required bool isDark,
  }) {
    Widget buildOrb({required double size, required Color color}) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: <Color>[color, color.withValues(alpha: 0)],
          ),
        ),
      );
    }

    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -120,
            right: -90,
            child: buildOrb(
              size: 320,
              color: palette.gradientPrimary.withValues(
                alpha: isDark ? 0.24 : 0.2,
              ),
            ),
          ),
          Positioned(
            top: 140,
            left: -120,
            child: buildOrb(
              size: 260,
              color: palette.gradientSecondary.withValues(
                alpha: isDark ? 0.2 : 0.16,
              ),
            ),
          ),
          Positioned(
            bottom: 60,
            right: -130,
            child: buildOrb(
              size: 300,
              color: palette.glowColor.withValues(alpha: isDark ? 0.18 : 0.14),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredSongs = ref.watch(filteredSongsProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final currentSongAsync = ref.watch(currentSongProvider);
    final hiddenSongs = ref.watch(hiddenSongsProvider);
    final currentSong = currentSongAsync.value;
    final isDark = ref.watch(isDarkModeProvider);
    final useDynamicArtworkTheme = ref.watch(dynamicArtworkThemeProvider);
    final useFullArtworkGradientTheme = ref.watch(
      artworkFullGradientThemeProvider,
    );
    final dynamicPalette = ref.watch(currentThemePaletteProvider);
    final activePalette = useDynamicArtworkTheme
        ? dynamicPalette
        : SongPalette.fallback;
    final homeGradient = _buildHomeBackgroundGradient(
      activePalette,
      isDark,
      useFullGradient: useDynamicArtworkTheme && useFullArtworkGradientTheme,
    );
    final headerBackground = Color.lerp(homeGradient[0], homeGradient[1], 0.3)!;
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
    final songCount = filteredSongs.maybeWhen(
      data: (songs) => songs.where((song) => song.duration >= 60000).length,
      orElse: () => 0,
    );
    final lowFidelityMode = PerformanceService.useLowFidelityMode;
    final homeAnimationDuration = PerformanceService.tunedDuration(
      const Duration(milliseconds: 360),
      lowFidelityScale: 0.55,
      minMs: 120,
    );
    final tabSwitchDuration = PerformanceService.tunedDuration(
      const Duration(milliseconds: 280),
      lowFidelityScale: 0.55,
      minMs: 120,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedContainer(
        duration: homeAnimationDuration,
        curve: Curves.easeInOutCubic,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: _buildEvenStops(homeGradient.length),
            colors: homeGradient,
          ),
        ),
        child: Stack(
          children: [
            _buildBackgroundDecor(palette: activePalette, isDark: isDark),
            Column(
              children: [
                _buildHeader(
                  isDark: isDark,
                  palette: activePalette,
                  songCount: songCount,
                  accentColor: accentColor,
                  surfaceColor: surfaceColor,
                  borderColor: borderColor,
                ),
                _buildTabBar(
                  isDark: isDark,
                  palette: activePalette,
                  accentColor: accentColor,
                  surfaceColor: surfaceColor,
                  borderColor: borderColor,
                ),
                _buildSearchBar(
                  isDark: isDark,
                  palette: activePalette,
                  accentColor: accentColor,
                  surfaceColor: surfaceColor,
                  borderColor: borderColor,
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: tabSwitchDuration,
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      if (lowFidelityMode) {
                        return FadeTransition(opacity: animation, child: child);
                      }

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
                        filteredSongs: filteredSongs,
                        hiddenSongs: hiddenSongs,
                        isDark: isDark,
                        accentColor: accentColor,
                        surfaceColor: surfaceColor,
                        searchQuery: searchQuery,
                      ),
                    ),
                  ),
                ),
                if (currentSong != null) const MiniPlayer(),
              ],
            ),
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
    required int songCount,
    required Color accentColor,
    required Color surfaceColor,
    required Color borderColor,
  }) {
    final topPadding = MediaQuery.of(context).padding.top + 8;
    final lowFidelityMode = PerformanceService.useLowFidelityMode;
    final blurSigma = PerformanceService.tunedBlurSigma(18);
    final titleColor = ArtworkPaletteService.readableAccent(
      palette.gradientPrimary,
      surfaceColor,
    );
    final subtitleColor = ArtworkPaletteService.readableAccent(
      palette.gradientSecondary,
      surfaceColor,
    ).withValues(alpha: 0.9);
    final iconColor = ArtworkPaletteService.readableAccent(
      palette.glowColor,
      surfaceColor,
    );
    final logoForeground = ArtworkPaletteService.readableText(iconColor);

    final headerPanel = Container(
      decoration: BoxDecoration(
        color: surfaceColor.withValues(alpha: isDark ? 0.2 : 0.42),
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            palette.gradientPrimary.withValues(alpha: isDark ? 0.22 : 0.16),
            palette.gradientSecondary.withValues(alpha: isDark ? 0.12 : 0.08),
            Colors.white.withValues(alpha: isDark ? 0.02 : 0.24),
          ],
        ),
        border: Border.all(
          color: borderColor.withValues(alpha: isDark ? 0.58 : 0.74),
          width: 1,
        ),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.24),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ]
            : [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 18,
            right: 18,
            top: 0,
            child: Container(
              height: 1.1,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(
                  colors: <Color>[
                    Colors.transparent,
                    iconColor.withValues(alpha: 0.66),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[iconColor, palette.gradientPrimary],
                    ),
                  ),
                  child: Icon(
                    Icons.graphic_eq_rounded,
                    color: logoForeground,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'OnFiNtY',
                        style: TextStyle(
                          color: titleColor,
                          fontFamily: 'Orbitron',
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$songCount songs in your library',
                        style: TextStyle(
                          color: subtitleColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeaderButton(
                      icon: _showSearch ? Icons.close : Icons.search_rounded,
                      onTap: _toggleSearch,
                      isDark: isDark,
                      accentColor: accentColor,
                      backgroundColor: surfaceColor,
                      borderColor: borderColor,
                      iconColor: iconColor,
                    ),
                    const SizedBox(width: 8),
                    _buildHeaderButton(
                      icon: Icons.settings_rounded,
                      onTap: () => context.push('/settings'),
                      isDark: isDark,
                      accentColor: accentColor,
                      backgroundColor: surfaceColor,
                      borderColor: borderColor,
                      iconColor: iconColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(16, topPadding, 16, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: lowFidelityMode || blurSigma <= 0
            ? headerPanel
            : BackdropFilter(
                filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
                child: headerPanel,
              ),
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
    return SizedBox(
      width: 40,
      height: 40,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: backgroundColor.withValues(alpha: isDark ? 0.24 : 0.44),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor.withValues(alpha: isDark ? 0.62 : 0.78),
              width: 1,
            ),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Icon(icon, color: iconColor, size: 21),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SEARCH BAR
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildSearchBar({
    required bool isDark,
    required SongPalette palette,
    required Color accentColor,
    required Color surfaceColor,
    required Color borderColor,
  }) {
    final lowFidelityMode = PerformanceService.useLowFidelityMode;
    final blurSigma = PerformanceService.tunedBlurSigma(16);
    final textColor = ArtworkPaletteService.readableAccent(
      palette.gradientPrimary,
      surfaceColor,
    );
    final hintColor = ArtworkPaletteService.readableAccent(
      palette.gradientSecondary,
      surfaceColor,
    ).withValues(alpha: 0.7);
    final searchIconColor = ArtworkPaletteService.readableAccent(
      palette.glowColor,
      surfaceColor,
    );

    final searchPanel = Container(
      decoration: BoxDecoration(
        color: surfaceColor.withValues(alpha: isDark ? 0.22 : 0.42),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: borderColor.withValues(alpha: isDark ? 0.58 : 0.76),
          width: 1,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        cursorColor: searchIconColor,
        onChanged: (value) {
          ref.read(searchQueryProvider.notifier).state = value;
        },
        style: TextStyle(color: textColor, fontSize: 15),
        decoration: InputDecoration(
          hintText: 'Search your library...',
          hintStyle: TextStyle(color: hintColor, fontSize: 14),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: searchIconColor,
            size: 21,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 11,
          ),
        ),
      ),
    );

    return AnimatedContainer(
      duration: PerformanceService.tunedDuration(
        const Duration(milliseconds: 280),
      ),
      curve: Curves.easeOutCubic,
      height: _showSearch ? 56 : 0,
      padding: _showSearch
          ? const EdgeInsets.symmetric(horizontal: 16, vertical: 6)
          : EdgeInsets.zero,
      child: AnimatedOpacity(
        opacity: _showSearch ? 1.0 : 0.0,
        duration: PerformanceService.tunedDuration(
          const Duration(milliseconds: 220),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: lowFidelityMode || blurSigma <= 0
              ? searchPanel
              : BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: blurSigma,
                    sigmaY: blurSigma,
                  ),
                  child: searchPanel,
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
    final lowFidelityMode = PerformanceService.useLowFidelityMode;
    final blurSigma = PerformanceService.tunedBlurSigma(14);
    final unselectedLabelColor = ArtworkPaletteService.readableAccent(
      palette.gradientSecondary,
      surfaceColor,
    ).withValues(alpha: 0.74);
    final selectedLabelColor = ArtworkPaletteService.readableAccent(
      palette.gradientPrimary,
      surfaceColor,
    );

    final tabPanel = Container(
      margin: const EdgeInsets.fromLTRB(16, 2, 16, 2),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: surfaceColor.withValues(alpha: isDark ? 0.2 : 0.38),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor.withValues(alpha: isDark ? 0.56 : 0.72),
          width: 1,
        ),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[
              palette.gradientPrimary.withValues(alpha: isDark ? 0.68 : 0.42),
              palette.glowColor.withValues(alpha: isDark ? 0.62 : 0.4),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: accentColor.withValues(alpha: isDark ? 0.42 : 0.28),
            width: 1,
          ),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: selectedLabelColor,
        unselectedLabelColor: unselectedLabelColor,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13.5,
          letterSpacing: 0.2,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 13.5,
        ),
        tabs: const [
          Tab(text: 'Songs'),
          Tab(text: 'Albums'),
          Tab(text: 'Hidden'),
        ],
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: lowFidelityMode || blurSigma <= 0
          ? tabPanel
          : BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
              child: tabPanel,
            ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB CONTENT
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildTabContent({
    required AsyncValue<List<SongModel>> filteredSongs,
    required List<int> hiddenSongs,
    required bool isDark,
    required Color accentColor,
    required Color surfaceColor,
    required String searchQuery,
  }) {
    if (_currentTab == MusicTab.albums) {
      _syncSongPagination(listToken: 'albums', totalSongs: 0);
      return _buildAlbumsView(isDark, accentColor);
    }

    return filteredSongs.when(
      data: (songs) {
        final hiddenSongIds = hiddenSongs.toSet();
        final displaySongs = _currentTab == MusicTab.hidden
            ? songs
                  .where(
                    (song) =>
                        hiddenSongIds.contains(song.id) ||
                        song.duration < 60000,
                  )
                  .toList()
            : songs
                  .where(
                    (song) =>
                        !hiddenSongIds.contains(song.id) &&
                        song.duration >= 60000,
                  )
                  .toList();

        if (displaySongs.isEmpty) {
          _syncSongPagination(
            listToken: '${_currentTab.index}|${searchQuery.trim()}|empty',
            totalSongs: 0,
          );
          return _buildEmptyState(isDark, accentColor);
        }

        final listToken =
            '${_currentTab.index}|'
            '${searchQuery.trim().toLowerCase()}|'
            '${displaySongs.length}|'
            '${displaySongs.first.id}|'
            '${displaySongs.last.id}';
        _syncSongPagination(
          listToken: listToken,
          totalSongs: displaySongs.length,
        );
        final visibleSongCount = math.min(
          _visibleSongCount,
          displaySongs.length,
        );
        final hasMoreSongs = visibleSongCount < displaySongs.length;

        return BeautifulDraggableScrollbar(
          controller: _scrollController,
          thumbColor: accentColor,
          thumbGlowColor: accentColor,
          trackColor: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.black.withValues(alpha: 0.08),
          rightPadding: 6,
          topBottomPadding: 12,
          child: ListView.builder(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            itemCount: visibleSongCount + (hasMoreSongs ? 1 : 0),
            padding: const EdgeInsets.only(
              top: 8,
              bottom: 100,
              left: 8,
              right: 12,
            ),
            itemBuilder: (context, index) {
              if (index >= visibleSongCount) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) {
                    return;
                  }
                  _loadMoreSongsIfNeeded(force: true);
                });
                return _buildSongLoadMoreIndicator(
                  isDark: isDark,
                  accentColor: accentColor,
                  surfaceColor: surfaceColor,
                );
              }

              return SongTile(
                song: displaySongs[index],
                index: index,
                onTap: () async {
                  final audioHandler = ref.read(audioHandlerProvider);
                  await audioHandler.setPlaylist(displaySongs, index);
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

  Widget _buildSongLoadMoreIndicator({
    required bool isDark,
    required Color accentColor,
    required Color surfaceColor,
  }) {
    final textColor = ArtworkPaletteService.readableMutedText(surfaceColor);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                accentColor.withValues(alpha: isDark ? 0.85 : 0.75),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Loading more songs...',
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
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
