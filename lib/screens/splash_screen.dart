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
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Opacity(
                    opacity: _logoFade.value,
                    child: Transform.scale(
                      scale: _logoScale.value,
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF8B5CF6), Color(0xFF4F46E5)],
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
                          size: 44,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
