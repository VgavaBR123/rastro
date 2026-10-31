package com.stravaestudo.strava_estudo_app

import android.os.SystemClock
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * Canal `stravaestudo/clock` do plano 5 km (F06).
 * - `elapsedRealtime`: SystemClock.elapsedRealtime() em ms. Conta o tempo com
 *   a CPU suspensa (tela desligada), ao contrario do Stopwatch do Dart, para o
 *   plano nao congelar quando o aparelho dorme.
 */
object PlanClockChannel {
    const val CHANNEL = "stravaestudo/clock"

    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "elapsedRealtime" -> result.success(SystemClock.elapsedRealtime())
                else -> result.notImplemented()
            }
        }
    }
}
