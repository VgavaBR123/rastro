package com.stravaestudo.strava_estudo_app

import android.app.Activity
import android.content.Intent
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * Canal `stravaestudo/share`: abre a folha de compartilhamento do sistema com
 * um texto (Intent ACTION_SEND text/plain dentro de um chooser). Usado pelo
 * botao Compartilhar dos cartoes e do detalhe da atividade.
 */
object ShareChannel {
    const val CHANNEL = "stravaestudo/share"

    fun register(activity: Activity, messenger: BinaryMessenger) {
        MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method != "shareText") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            val text = call.argument<String>("text")
            if (text.isNullOrEmpty()) {
                result.error("bad_args", "texto vazio", null)
                return@setMethodCallHandler
            }
            try {
                val send = Intent(Intent.ACTION_SEND).apply {
                    type = "text/plain"
                    putExtra(Intent.EXTRA_TEXT, text)
                }
                activity.startActivity(Intent.createChooser(send, null))
                result.success(null)
            } catch (t: Throwable) {
                result.error("share_failed", t.message, null)
            }
        }
    }
}
