// Implementacao Android do RecordingService sobre o plugin
// `flutter_foreground_task` (pub.dev).
//
// Como funciona:
//  - o plugin sobe um foreground service de tipo `location` (declarado no
//    AndroidManifest) com notificacao persistente, wake lock e os botoes
//    Pausar/Retomar, Volta e Encerrar;
//  - o plugin roda um TaskHandler num isolate proprio. Ele nao grava nada: so
//    recebe o toque nos botoes e repassa o id ao isolate principal pela porta
//    de comunicacao (sendDataToMain). Por isso `initCommunicationPort` precisa
//    ser chamado no main() antes do runApp;
//  - a gravacao (geolocator + RecordingController) continua no isolate
//    principal; o servico so mantem o processo em primeiro plano;
//  - tocar na notificacao abre o app (intent de launch do pacote), que volta
//    para a tela de gravacao no topo da pilha.
library;

import 'dart:async';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'recording_service.dart';

/// Id fixo da notificacao/servico da gravacao.
const int kRecordingServiceId = 4201;

// Ids dos botoes da notificacao (= nomes dos RecordingCommand).
const String _kBtnPause = 'pause';
const String _kBtnResume = 'resume';
const String _kBtnLap = 'lap';
const String _kBtnStop = 'stop';

/// Chave do mapa enviado do TaskHandler ao isolate principal.
const String _kCommandKey = 'recordingCommand';

/// Ponto de entrada do isolate do servico. Precisa ser funcao de topo com
/// `vm:entry-point` para sobreviver ao tree shaking em release.
@pragma('vm:entry-point')
void recordingServiceStartCallback() {
  FlutterForegroundTask.setTaskHandler(_RecordingTaskHandler());
}

/// Handler do isolate do servico: so repassa os botoes ao isolate principal.
class _RecordingTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}

  @override
  void onNotificationButtonPressed(String id) {
    FlutterForegroundTask.sendDataToMain({_kCommandKey: id});
  }

  @override
  void onNotificationPressed() {
    // O conteudo da notificacao ja abre o app; reforca para versoes do Android
    // em que o toque so chega aqui.
    FlutterForegroundTask.launchApp();
  }
}

/// Traduz o id de botao em comando (null se desconhecido).
RecordingCommand? recordingCommandFromButtonId(String id) {
  for (final c in RecordingCommand.values) {
    if (c.name == id) return c;
  }
  return null;
}

/// Botoes da notificacao conforme o estado (Pausar/Retomar alterna).
List<NotificationButton> recordingNotificationButtons({required bool paused}) =>
    [
      paused
          ? const NotificationButton(id: _kBtnResume, text: 'Retomar')
          : const NotificationButton(id: _kBtnPause, text: 'Pausar'),
      const NotificationButton(id: _kBtnLap, text: 'Volta'),
      const NotificationButton(id: _kBtnStop, text: 'Encerrar'),
    ];

class ForegroundTaskRecordingService implements RecordingService {
  final StreamController<RecordingCommand> _commands =
      StreamController<RecordingCommand>.broadcast();
  bool _initialized = false;
  bool _listening = false;
  bool? _lastPaused;

  @override
  Stream<RecordingCommand> get commands => _commands.stream;

  void _onTaskData(Object data) {
    if (data is! Map) return;
    final id = data[_kCommandKey];
    if (id is! String) return;
    final cmd = recordingCommandFromButtonId(id);
    if (cmd != null) _commands.add(cmd);
  }

  void _ensureInit() {
    if (_initialized) return;
    _initialized = true;
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'recording',
        channelName: 'Gravação de atividade',
        channelDescription: 'Mostra a atividade em andamento e seus controles',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        // Nada periodico no isolate do servico: quem atualiza a notificacao e
        // o controller, a partir das amostras de GPS.
        eventAction: ForegroundTaskEventAction.nothing(),
        allowWakeLock: true,
        // Se o sistema matar o app, o isolate principal (que grava) morre
        // junto; reiniciar so o servico deixaria uma notificacao orfa. A
        // retomada e a recuperacao pos-crash da Home.
        allowAutoRestart: false,
        // ATENCAO: false de proposito. No flutter_foreground_task 11.0.3 esta
        // opcao instala um TrackVisibilityUtils que para o servico assim que
        // todas as Activities ficam em PAUSE, ou seja, ao ir para segundo
        // plano (botao HOME, tela desligada) -- exatamente quando o servico e
        // necessario. Achado no emulador: a notificacao sumia no HOME e o GPS
        // parava. Encerrar ao tirar o app dos recentes ja e garantido pelo
        // `android:stopWithTask="true"` do AndroidManifest (onTaskRemoved).
        stopWithTask: false,
      ),
    );
  }

  @override
  Future<void> start(RecordingNotification n) async {
    try {
      _ensureInit();
      if (!_listening) {
        FlutterForegroundTask.addTaskDataCallback(_onTaskData);
        _listening = true;
      }
      // Android 13+: sem permissao de notificacao o servico roda, mas a
      // notificacao (e os botoes) nao aparecem na gaveta.
      final perm = await FlutterForegroundTask.checkNotificationPermission();
      if (perm != NotificationPermission.granted) {
        await FlutterForegroundTask.requestNotificationPermission();
      }
      _lastPaused = n.paused;
      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.updateService(
          notificationTitle: n.title,
          notificationText: n.text,
          notificationButtons: recordingNotificationButtons(paused: n.paused),
        );
        return;
      }
      await FlutterForegroundTask.startService(
        serviceId: kRecordingServiceId,
        serviceTypes: const [ForegroundServiceTypes.location],
        notificationTitle: n.title,
        notificationText: n.text,
        notificationButtons: recordingNotificationButtons(paused: n.paused),
        callback: recordingServiceStartCallback,
      );
    } catch (_) {
      // Sem servico a gravacao segue no isolate principal; so perde a
      // garantia de continuar com o app em segundo plano.
    }
  }

  @override
  Future<void> update(RecordingNotification n) async {
    try {
      // Botoes so sao reenviados quando o estado de pausa muda.
      final buttonsChanged = _lastPaused != n.paused;
      _lastPaused = n.paused;
      await FlutterForegroundTask.updateService(
        notificationTitle: n.title,
        notificationText: n.text,
        notificationButtons: buttonsChanged
            ? recordingNotificationButtons(paused: n.paused)
            : null,
      );
    } catch (_) {}
  }

  @override
  Future<void> stop() async {
    try {
      if (_listening) {
        FlutterForegroundTask.removeTaskDataCallback(_onTaskData);
        _listening = false;
      }
      _lastPaused = null;
      await FlutterForegroundTask.stopService();
    } catch (_) {}
  }
}
