import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Bridge for Android-native audio effects (equalizer + preset reverb).
class AudioFxBridge {
  static const MethodChannel _channel = MethodChannel('onfinity/audio_fx');

  bool get isSupported => !kIsWeb && Platform.isAndroid;

  Future<void> attachToSession(int audioSessionId) async {
    if (!isSupported || audioSessionId <= 0) {
      return;
    }
    await _invokeVoid('attachSession', <String, dynamic>{
      'audioSessionId': audioSessionId,
    });
  }

  Future<void> setEqualizerEnabled(bool enabled) async {
    if (!isSupported) {
      return;
    }
    await _invokeVoid('setEqualizerEnabled', <String, dynamic>{
      'enabled': enabled,
    });
  }

  Future<void> setReverbEnabled(bool enabled) async {
    if (!isSupported) {
      return;
    }
    await _invokeVoid('setReverbEnabled', <String, dynamic>{
      'enabled': enabled,
    });
  }

  Future<void> setReverbPreset(int presetId) async {
    if (!isSupported) {
      return;
    }
    await _invokeVoid('setReverbPreset', <String, dynamic>{
      'presetId': presetId,
    });
  }

  Future<void> setBandLevel(int bandIndex, double levelDb) async {
    if (!isSupported) {
      return;
    }
    await _invokeVoid('setBandLevel', <String, dynamic>{
      'band': bandIndex,
      'levelDb': levelDb,
    });
  }

  Future<int> getBandCount({int fallback = 5}) async {
    if (!isSupported) {
      return fallback;
    }
    try {
      final result = await _channel.invokeMethod<int>('getBandCount');
      if (result == null || result <= 0) {
        return fallback;
      }
      return result;
    } on MissingPluginException {
      return fallback;
    } catch (e) {
      debugPrint('AudioFxBridge getBandCount error: $e');
      return fallback;
    }
  }

  Future<void> release() async {
    if (!isSupported) {
      return;
    }
    await _invokeVoid('release');
  }

  Future<void> _invokeVoid(
    String method, [
    Map<String, dynamic>? arguments,
  ]) async {
    try {
      await _channel.invokeMethod<void>(method, arguments);
    } on MissingPluginException {
      // No-op on unsupported platforms/builds.
    } catch (e) {
      debugPrint('AudioFxBridge $method error: $e');
    }
  }
}
