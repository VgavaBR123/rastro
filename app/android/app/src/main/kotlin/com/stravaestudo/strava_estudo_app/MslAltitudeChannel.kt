package com.stravaestudo.strava_estudo_app

import android.content.Context
import android.location.Location
import android.os.Handler
import android.os.Looper
import androidx.core.location.LocationCompat
import androidx.core.location.altitude.AltitudeConverterCompat
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import kotlin.math.floor

/**
 * Canal `com.stravaestudo/msl_altitude`: converte altitude elipsoidal (WGS84)
 * em altitude acima do nivel medio do mar com o conversor da AndroidX
 * (core-location-altitude). No Android 14+ ele delega ao conversor da
 * plataforma; abaixo disso usa o modelo de geoide embutido na biblioteca.
 *
 * O conversor faz I/O (carrega o modelo na primeira chamada), entao roda numa
 * thread propria e o resultado volta na main thread. Qualquer falha devolve
 * null: o Dart cai na altitude crua.
 */
object MslAltitudeChannel {
    const val CHANNEL = "com.stravaestudo/msl_altitude"

    // Uma thread so: as chamadas chegam a ~1 Hz e o conversor guarda estado.
    private val worker: ExecutorService = Executors.newSingleThreadExecutor { r ->
        Thread(r, "msl-altitude").apply { isDaemon = true }
    }
    private val mainHandler = Handler(Looper.getMainLooper())

    // Cache do deslocamento (MSL - elipsoidal) por celula de 0,01 grau (~1 km).
    // O geoide varia devagar, entao o erro dentro da celula e desprezivel.
    private const val CELL_DEG = 0.01
    private const val CACHE_MAX = 256
    private val offsetCache = object : LinkedHashMap<Long, Double>(64, 0.75f, true) {
        override fun removeEldestEntry(eldest: MutableMap.MutableEntry<Long, Double>?) =
            size > CACHE_MAX
    }

    fun register(context: Context, messenger: BinaryMessenger) {
        val appContext = context.applicationContext
        MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "toMsl") {
                handleToMsl(appContext, call, result)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun handleToMsl(context: Context, call: MethodCall, result: MethodChannel.Result) {
        val lat = (call.argument<Any>("latitude") as? Number)?.toDouble()
        val lon = (call.argument<Any>("longitude") as? Number)?.toDouble()
        val alt = (call.argument<Any>("ellipsoidAltitudeMeters") as? Number)?.toDouble()
        if (lat == null || lon == null || alt == null ||
            !lat.isFinite() || !lon.isFinite() || !alt.isFinite() ||
            lat < -90.0 || lat > 90.0 || lon < -180.0 || lon > 180.0
        ) {
            result.success(null)
            return
        }
        worker.execute {
            val msl = try {
                convert(context, lat, lon, alt)
            } catch (t: Throwable) {
                // IOException (modelo indisponivel), IllegalArgumentException etc.
                null
            }
            mainHandler.post { result.success(msl) }
        }
    }

    /** Roda na thread do worker. */
    private fun convert(context: Context, lat: Double, lon: Double, alt: Double): Double? {
        val key = cellKey(lat, lon)
        synchronized(offsetCache) { offsetCache[key] }?.let { return alt + it }

        val probe = Location("msl").apply {
            latitude = lat
            longitude = lon
            altitude = alt
        }
        AltitudeConverterCompat.addMslAltitudeToLocation(context, probe)
        if (!LocationCompat.hasMslAltitude(probe)) return null
        val msl = LocationCompat.getMslAltitudeMeters(probe)
        if (!msl.isFinite()) return null
        synchronized(offsetCache) { offsetCache[key] = msl - alt }
        return msl
    }

    private fun cellKey(lat: Double, lon: Double): Long {
        val i = floor((lat + 90.0) / CELL_DEG).toLong()
        val j = floor((lon + 180.0) / CELL_DEG).toLong()
        return i * 100_000L + j
    }
}
