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
    // Compartilhar atividade (folha nativa do sistema).
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "StravaEstudoShare") {
      ShareChannel.register(messenger: registrar.messenger())
    }
    // Plano 5 km (F06): relogio que conta o sono do aparelho.
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "StravaEstudoClock") {
      ClockChannel.register(messenger: registrar.messenger())
    }
  }
}

/// Canal `stravaestudo/clock` (plano 5 km, F06): `elapsedRealtime` devolve
/// clock_gettime_nsec_np(CLOCK_MONOTONIC) em ms. No Darwin o CLOCK_MONOTONIC
/// continua contando com o aparelho dormindo (o CLOCK_UPTIME_RAW nao).
enum ClockChannel {
  static let name = "stravaestudo/clock"

  static func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: name, binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "elapsedRealtime":
        let ms = clock_gettime_nsec_np(CLOCK_MONOTONIC) / 1_000_000
        result(NSNumber(value: ms))
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}

/// Canal `stravaestudo/share`: abre o UIActivityViewController com um texto
/// (`shareText`) ou com o PNG gerado pelo app (`shareImage`, texto opcional).
/// No iPad a folha e um popover; ancora no centro da tela de cima.
enum ShareChannel {
  static let name = "stravaestudo/share"

  static func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: name, binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      let args = call.arguments as? [String: Any]
      var items: [Any] = []
      switch call.method {
      case "shareText":
        guard let text = args?["text"] as? String, !text.isEmpty else {
          result(FlutterError(code: "bad_args", message: "texto vazio", details: nil))
          return
        }
        items = [text]
      case "shareImage":
        guard let path = args?["path"] as? String,
              FileManager.default.fileExists(atPath: path) else {
          result(FlutterError(code: "bad_args", message: "imagem inexistente", details: nil))
          return
        }
        items = [URL(fileURLWithPath: path)]
        if let text = args?["text"] as? String, !text.isEmpty {
          items.append(text)
        }
      default:
        result(FlutterMethodNotImplemented)
        return
      }
      guard let presenter = topViewController() else {
        result(FlutterError(code: "no_view", message: "sem tela para apresentar", details: nil))
        return
      }
      let sheet = UIActivityViewController(activityItems: items, applicationActivities: nil)
      if let popover = sheet.popoverPresentationController {
        popover.sourceView = presenter.view
        popover.sourceRect = CGRect(
          x: presenter.view.bounds.midX, y: presenter.view.bounds.midY, width: 0, height: 0)
        popover.permittedArrowDirections = []
      }
      presenter.present(sheet, animated: true)
      result(nil)
    }
  }

  private static func topViewController() -> UIViewController? {
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    let window = scenes.flatMap { $0.windows }.first { $0.isKeyWindow } ?? scenes.first?.windows.first
    var top = window?.rootViewController
    while let presented = top?.presentedViewController {
      top = presented
    }
    return top
  }
}
