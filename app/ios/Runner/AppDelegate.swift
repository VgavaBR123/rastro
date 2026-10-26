import Flutter
import UIKit
import workmanager_apple

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Sync em segundo plano (pacote workmanager). As tarefas rodam num engine
    // Flutter separado; ele precisa dos plugins (path_provider, sqlite3, ...)
    // para abrir o banco e enviar as atividades.
    WorkmanagerPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
    // Identificador do BGAppRefreshTask: tem que bater com
    // BGTaskSchedulerPermittedIdentifiers (Info.plist) e com
    // kPeriodicSyncTaskId (lib/sync/background/background_sync_scheduler.dart).
    WorkmanagerPlugin.registerPeriodicTask(
      withIdentifier: "com.stravaestudo.stravaEstudoApp.backgroundSync",
      earliestBeginInSeconds: NSNumber(value: 60 * 60)
    )
    // App com UIScene: os handlers do BGTaskScheduler precisam ser
    // registrados antes de didFinishLaunching retornar.
    WorkmanagerPlugin.registerLaunchHandlers()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
