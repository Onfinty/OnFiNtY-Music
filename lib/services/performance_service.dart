import 'dart:io';

import 'package:flutter/foundation.dart';

class PerformanceService {
  static final bool _lowFidelityMode = _resolveLowFidelityMode();

  static bool get useLowFidelityMode => _lowFidelityMode;

  static Duration tunedDuration(
    Duration base, {
    double lowFidelityScale = 0.62,
    int minMs = 90,
  }) {
    if (!useLowFidelityMode) {
      return base;
    }

    final scaled = (base.inMilliseconds * lowFidelityScale).round();
    return Duration(milliseconds: scaled.clamp(minMs, base.inMilliseconds));
  }

  static double tunedBlurSigma(double baseSigma) {
    if (!useLowFidelityMode) {
      return baseSigma;
    }
    return 0.0;
  }

  static bool _resolveLowFidelityMode() {
    if (kIsWeb || !Platform.isAndroid) {
      return false;
    }

    // Prefer performance mode on older Android versions.
    final match = RegExp(
      r'SDK (\d+)',
    ).firstMatch(Platform.operatingSystemVersion);
    final sdk = match != null ? int.tryParse(match.group(1) ?? '') ?? 0 : 0;
    if (sdk == 0) {
      return true;
    }
    return sdk <= 31;
  }
}
