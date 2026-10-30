package com.stravaestudo.strava_estudo_app

import android.app.Activity
import android.content.ComponentName
import android.content.Intent
import android.os.Build
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * Canal `stravaestudo/device` do checklist "Gravacao confiavel" (F01).
 * - `manufacturer`: Build.MANUFACTURER, para as instrucoes por fabricante.
 * - `openComponent`: abre uma tela de ajuste de outro app (ex.: inicio
 *   automatico do fabricante) por componente explicito. Devolve false se a
 *   tela nao existe ou nao pode ser aberta; o Dart cai nos ajustes do app.
 */
object DeviceSettingsChannel {
    const val CHANNEL = "stravaestudo/device"

    fun register(activity: Activity, messenger: BinaryMessenger) {
        MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "manufacturer" -> result.success(Build.MANUFACTURER)
                "openComponent" -> {
                    val pkg = call.argument<String>("package")
                    val cls = call.argument<String>("class")
                    if (pkg.isNullOrEmpty() || cls.isNullOrEmpty()) {
                        result.success(false)
                        return@setMethodCallHandler
                    }
                    val intent = Intent().apply {
                        component = ComponentName(pkg, cls)
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    try {
                        activity.startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        // ActivityNotFoundException, SecurityException etc.
                        result.success(false)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
