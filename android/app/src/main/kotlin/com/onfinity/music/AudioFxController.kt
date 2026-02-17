package com.onfinity.music

import android.media.audiofx.Equalizer
import android.media.audiofx.PresetReverb
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlin.math.roundToInt

class AudioFxController : MethodChannel.MethodCallHandler {
    private var equalizer: Equalizer? = null
    private var reverb: PresetReverb? = null
    private var currentSessionId: Int? = null

    private var equalizerEnabled: Boolean = false
    private var reverbEnabled: Boolean = false
    private var reverbPreset: Short = PresetReverb.PRESET_MEDIUMROOM
    private val cachedBandLevelsMb: MutableMap<Short, Short> = mutableMapOf()

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "attachSession" -> {
                val sessionId = call.argument<Int>("audioSessionId")
                if (sessionId == null || sessionId <= 0) {
                    result.error("INVALID_SESSION", "Invalid audio session id", null)
                    return
                }
                try {
                    attachToSession(sessionId)
                    result.success(null)
                } catch (e: Throwable) {
                    result.error("ATTACH_FAILED", e.message, null)
                }
            }

            "setEqualizerEnabled" -> {
                equalizerEnabled = call.argument<Boolean>("enabled") ?: false
                applyEqualizerEnabled()
                result.success(null)
            }

            "setReverbEnabled" -> {
                reverbEnabled = call.argument<Boolean>("enabled") ?: false
                applyReverbEnabled()
                result.success(null)
            }

            "setReverbPreset" -> {
                val presetId = call.argument<Int>("presetId")
                if (presetId != null) {
                    reverbPreset = presetId.toShort()
                    reverb?.preset = reverbPreset
                }
                result.success(null)
            }

            "setBandLevel" -> {
                val band = call.argument<Int>("band")
                val levelDb = call.argument<Double>("levelDb")
                if (band == null || levelDb == null) {
                    result.error("INVALID_BAND", "Missing band/levelDb", null)
                    return
                }
                setBandLevel(band, levelDb)
                result.success(null)
            }

            "getBandCount" -> {
                val count = equalizer?.numberOfBands?.toInt() ?: 5
                result.success(count)
            }

            "release" -> {
                release()
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }

    private fun attachToSession(sessionId: Int) {
        if (currentSessionId == sessionId && equalizer != null && reverb != null) {
            applyAllCachedState()
            return
        }

        release()
        currentSessionId = sessionId

        equalizer = Equalizer(0, sessionId)
        reverb = PresetReverb(0, sessionId)

        applyAllCachedState()
    }

    private fun applyAllCachedState() {
        val eq = equalizer ?: return
        val bandCount = eq.numberOfBands.toInt()
        for ((band, level) in cachedBandLevelsMb) {
            if (band.toInt() in 0 until bandCount) {
                eq.setBandLevel(band, level)
            }
        }
        applyEqualizerEnabled()
        reverb?.preset = reverbPreset
        applyReverbEnabled()
    }

    private fun setBandLevel(bandIndex: Int, levelDb: Double) {
        val eq = equalizer ?: return
        val safeBandIndex = bandIndex.coerceIn(0, eq.numberOfBands.toInt() - 1)
        val bandKey = safeBandIndex.toShort()
        val clampedLevel = clampToBandRange(eq, levelDb)
        cachedBandLevelsMb[bandKey] = clampedLevel
        eq.setBandLevel(bandKey, clampedLevel)
    }

    private fun clampToBandRange(equalizer: Equalizer, levelDb: Double): Short {
        val range = equalizer.bandLevelRange
        val minMb = range[0].toInt()
        val maxMb = range[1].toInt()
        val levelMb = (levelDb * 100.0).roundToInt().coerceIn(minMb, maxMb)
        return levelMb.toShort()
    }

    private fun applyEqualizerEnabled() {
        equalizer?.enabled = equalizerEnabled
    }

    private fun applyReverbEnabled() {
        reverb?.enabled = reverbEnabled
    }

    fun release() {
        try {
            equalizer?.enabled = false
            equalizer?.release()
        } catch (_: Throwable) {
        } finally {
            equalizer = null
        }

        try {
            reverb?.enabled = false
            reverb?.release()
        } catch (_: Throwable) {
        } finally {
            reverb = null
        }

        currentSessionId = null
    }
}
