package com.stravaestudo.strava_estudo_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Ponte da altitude MSL (relatorio 03, "Decisao para o nosso app").
        MslAltitudeChannel.register(applicationContext, flutterEngine.dartExecutor.binaryMessenger)
    }
}
