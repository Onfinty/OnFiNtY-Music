package com.onfinity.music

import android.content.Context
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import com.ryanheise.audioservice.AudioServicePlugin
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private var audioFxController: AudioFxController? = null
    private var audioFxChannel: MethodChannel? = null

    override fun provideFlutterEngine(context: Context): FlutterEngine? {
        return AudioServicePlugin.getFlutterEngine(context)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        audioFxController = AudioFxController()
        audioFxChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "onfinity/audio_fx")
        audioFxChannel?.setMethodCallHandler(audioFxController)
    }

    override fun onDestroy() {
        audioFxController?.release()
        audioFxChannel?.setMethodCallHandler(null)
        audioFxChannel = null
        audioFxController = null
        super.onDestroy()
    }
}
