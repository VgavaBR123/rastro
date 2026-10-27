package com.stravaestudo.strava_estudo_app

import android.app.Activity
import android.content.ClipData
import android.content.Intent
import androidx.core.content.FileProvider
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * Canal `stravaestudo/share`: abre a folha de compartilhamento do sistema.
 * - `shareText`: Intent ACTION_SEND text/plain dentro de um chooser.
 * - `shareImage`: PNG gerado pelo app em cache/share/, exposto por
 *   FileProvider (res/xml/share_paths.xml) com permissao de leitura
 *   temporaria; o texto opcional vai junto em EXTRA_TEXT.
 */
object ShareChannel {
    const val CHANNEL = "stravaestudo/share"

    fun register(activity: Activity, messenger: BinaryMessenger) {
        MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "shareText" -> {
                    val text = call.argument<String>("text")
                    if (text.isNullOrEmpty()) {
                        result.error("bad_args", "texto vazio", null)
                        return@setMethodCallHandler
                    }
                    val send = Intent(Intent.ACTION_SEND).apply {
                        type = "text/plain"
                        putExtra(Intent.EXTRA_TEXT, text)
                    }
                    start(activity, send, result)
                }
                "shareImage" -> {
                    val path = call.argument<String>("path")
                    val file = path?.let { File(it) }
                    if (file == null || !file.isFile) {
                        result.error("bad_args", "imagem inexistente", null)
                        return@setMethodCallHandler
                    }
                    val uri = try {
                        FileProvider.getUriForFile(
                            activity, "${activity.packageName}.share", file,
                        )
                    } catch (t: IllegalArgumentException) {
                        // Arquivo fora das pastas de share_paths.xml.
                        result.error("bad_args", t.message, null)
                        return@setMethodCallHandler
                    }
                    val send = Intent(Intent.ACTION_SEND).apply {
                        type = "image/png"
                        putExtra(Intent.EXTRA_STREAM, uri)
                        call.argument<String>("text")?.takeIf { it.isNotEmpty() }?.let {
                            putExtra(Intent.EXTRA_TEXT, it)
                        }
                        // ClipData faz a permissao de leitura valer tambem
                        // para a previa do chooser.
                        clipData = ClipData.newRawUri(null, uri)
                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    }
                    start(activity, send, result)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun start(activity: Activity, send: Intent, result: MethodChannel.Result) {
        try {
            activity.startActivity(Intent.createChooser(send, null))
            result.success(null)
        } catch (t: Throwable) {
            result.error("share_failed", t.message, null)
        }
    }
}
