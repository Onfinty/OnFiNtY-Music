import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _titleSlide;
  late final Animation<double> _progressGrow;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _logoFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.86, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOutBack),
      ),
    );
    _titleSlide = Tween<double>(begin: 28, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.62, curve: Curves.easeOutCubic),
      ),
    );
    _progressGrow = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOutCubic),
    );

    _controller.forward();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await Future.delayed(const Duration(milliseconds: 2400));

    final granted = await _requestPermissions();
    if (!granted && mounted) {
      final retry = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF121623),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Permission Required',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'OnFiNtY needs audio access to scan and play your music library.',
            style: TextStyle(color: Color(0xFFB6BDD6)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'Open Settings',
                style: TextStyle(color: Color(0xFF8F97B5)),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Try Again',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );

      if (retry == true && mounted) {
        return _initializeApp();
      } else if (retry == false && mounted) {
        await openAppSettings();
        if (mounted) return _initializeApp();
      }
      return;
    }

    if (mounted) {
      context.go('/home');
    }
  }

  Future<bool> _requestPermissions() async {
    var audioStatus = await Permission.audio.status;
    if (audioStatus.isDenied) {
      audioStatus = await Permission.audio.request();
    }
    if (audioStatus.isGranted) return true;

    var storageStatus = await Permission.storage.status;
    if (storageStatus.isDenied) {
      storageStatus = await Permission.storage.request();
    }
    if (storageStatus.isGranted) return true;

    if (audioStatus.isPermanentlyDenied || storageStatus.isPermanentlyDenied) {
      return false;
    }
    return false;
  }

  double _stagger(double start, double end) {
    final span = (end - start).clamp(0.001, 1.0);
    final t = ((_controller.value - start) / span).clamp(0.0, 1.0);
    return Curves.easeOutCubic.transform(t);
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required double delayStart,
  }) {
    final reveal = _stagger(delayStart, delayStart + 0.28);

    return Opacity(
      opacity: reveal,
      child: Transform.translate(
        offset: Offset((1 - reveal) * 18, 0),
        child: Container(
          width: 140,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: const Color(0xFF121A33).withValues(alpha: 0.78),
            border: Border.all(
              color: const Color(0xFF6C4AC4).withValues(alpha: 0.35),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: const Color(0xFF8B5CF6), size: 20),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF9BA5CC),
                  fontSize: 11,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final driftA = _stagger(0.0, 1.0);
          final driftB = _stagger(0.12, 1.0);

          return DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF070A14),
                  Color(0xFF0E1224),
                  Color(0xFF17133A),
                ],
                stops: [0.0, 0.54, 1.0],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -80 + (driftA * 20),
                  right: -70 + (driftA * 16),
                  child: Container(
                    width: 210,
                    height: 210,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.18),
                    ),
                  ),
                ),
                Positioned(
                  left: -50 + (driftB * 12),
                  bottom: 90 - (driftB * 14),
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF1D4ED8).withValues(alpha: 0.16),
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 26),
                    child: Column(
                      children: [
                        const Spacer(flex: 2),
                        Opacity(
                          opacity: _logoFade.value,
                          child: Transform.scale(
                            scale: _logoScale.value,
                            child: Container(
                              width: 92,
                              height: 92,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF8B5CF6),
                                    Color(0xFF4F46E5),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF8B5CF6,
                                    ).withValues(alpha: 0.35),
                                    blurRadius: 26,
                                    spreadRadius: 3,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.music_note_rounded,
                                color: Colors.white,
                                size: 42,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        Opacity(
                          opacity: _logoFade.value,
                          child: Transform.translate(
                            offset: Offset(0, _titleSlide.value),
                            child: const Text(
                              'OnFiNtY',
                              style: TextStyle(
                                fontFamily: 'Lobster',
                                fontSize: 52,
                                color: Color(0xFFE9D9FF),
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Opacity(
                          opacity: _stagger(0.3, 0.72),
                          child: const Text(
                            'Local music player with dynamic artwork vibes,\nsmart search, and smooth offline playback.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFFB3BEDF),
                              fontSize: 13,
                              height: 1.35,
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          alignment: WrapAlignment.center,
                          children: [
                            _buildFeatureCard(
                              icon: Icons.offline_bolt_rounded,
                              title: 'Offline Ready',
                              subtitle: 'No network needed',
                              delayStart: 0.38,
                            ),
                            _buildFeatureCard(
                              icon: Icons.auto_awesome_rounded,
                              title: 'Smart Colors',
                              subtitle: 'Artwork-driven theme',
                              delayStart: 0.48,
                            ),
                            _buildFeatureCard(
                              icon: Icons.search_rounded,
                              title: 'Fast Search',
                              subtitle: 'Find tracks instantly',
                              delayStart: 0.58,
                            ),
                          ],
                        ),
                        const Spacer(flex: 3),
                        Opacity(
                          opacity: _stagger(0.54, 1.0),
                          child: Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: SizedBox(
                                  width: 170,
                                  child: LinearProgressIndicator(
                                    value: _progressGrow.value,
                                    minHeight: 4,
                                    backgroundColor: const Color(
                                      0xFF283359,
                                    ).withValues(alpha: 0.55),
                                    valueColor: const AlwaysStoppedAnimation(
                                      Color(0xFF8B5CF6),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Preparing your library...',
                                style: TextStyle(
                                  color: Color(0xFF8C97BC),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
