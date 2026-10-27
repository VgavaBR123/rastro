package com.stravaestudo.strava_estudo_app

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.database.sqlite.SQLiteDatabase
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import java.io.File

/**
 * Recebe BOOT_COMPLETED e MY_PACKAGE_REPLACED. O Android nao deixa religar o
 * GPS em segundo plano a partir daqui sem localizacao em background, entao so
 * avisamos: se houver atividade nao finalizada no banco, posta uma notificacao
 * que abre o app (a Home ja oferece Retomar/Salvar/Descartar).
 */
class RecoveryReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        if (action != Intent.ACTION_BOOT_COMPLETED &&
            action != Intent.ACTION_MY_PACKAGE_REPLACED
        ) {
            return
        }
        val appContext = context.applicationContext
        val pending = goAsync()
        Thread({
            try {
                if (hasUnfinishedActivity(appContext)) postNotification(appContext)
            } catch (_: Throwable) {
                // Nada a avisar: o app trata a recuperacao ao abrir.
            } finally {
                pending.finish()
            }
        }, "recovery-check").start()
    }

    companion object {
        const val CHANNEL_ID = "recovery"
        private const val NOTIFICATION_ID = 4201

        // Mesmo arquivo do Dart: getApplicationSupportDirectory() no Android
        // (path_provider_android) devolve context.filesDir.
        private const val DB_NAME = "recording.sqlite"

        /** Le o banco do Drift so para leitura; erro ou arquivo ausente = false. */
        fun hasUnfinishedActivity(context: Context): Boolean {
            val file = File(context.filesDir, DB_NAME)
            if (!file.isFile) return false
            return try {
                SQLiteDatabase.openDatabase(file.path, null, SQLiteDatabase.OPEN_READONLY)
                    .use { db ->
                        db.rawQuery(
                            "SELECT 1 FROM activities WHERE is_finished = 0 LIMIT 1",
                            null,
                        ).use { it.moveToFirst() }
                    }
            } catch (_: Exception) {
                false
            }
        }

        fun postNotification(context: Context) {
            if (Build.VERSION.SDK_INT >= 33 &&
                ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS)
                != PackageManager.PERMISSION_GRANTED
            ) {
                return
            }
            val manager = NotificationManagerCompat.from(context)
            if (!manager.areNotificationsEnabled()) return

            if (Build.VERSION.SDK_INT >= 26) {
                val channel = NotificationChannel(
                    CHANNEL_ID,
                    "Recuperacao",
                    NotificationManager.IMPORTANCE_DEFAULT,
                ).apply { description = "Aviso de atividade interrompida" }
                context.getSystemService(NotificationManager::class.java)
                    ?.createNotificationChannel(channel)
            }

            val open = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val contentIntent = PendingIntent.getActivity(
                context,
                0,
                open,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            val notification = NotificationCompat.Builder(context, CHANNEL_ID)
                .setSmallIcon(android.R.drawable.stat_sys_warning)
                .setContentTitle("Atividade interrompida")
                .setContentText("Toque para retomar ou salvar")
                .setContentIntent(contentIntent)
                .setAutoCancel(true)
                .setCategory(NotificationCompat.CATEGORY_REMINDER)
                .build()
            try {
                manager.notify(NOTIFICATION_ID, notification)
            } catch (_: SecurityException) {
                // Permissao revogada entre a checagem e o notify.
            }
        }
    }
}
