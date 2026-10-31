// Ponto de entrada do app. Clean room — app proprio de atividades.
library;

import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'app/providers.dart' show kSyncBaseUrl;
import 'sync/background/background_sync_provider.dart';
import 'sync/background/background_sync_scheduler.dart';
import 'app/router.dart';
import 'ui/safety/inbox_poller.dart';
import 'ui/theme/app_theme.dart';

/// DSN do Sentry (relatorio 07: observabilidade com Sentry, open source).
/// Vazio = desligado: o SDK nem e inicializado e nada sai do aparelho.
///   flutter run --dart-define=SENTRY_DSN=https://...@.../...
const String kSentryDsn = String.fromEnvironment('SENTRY_DSN');

Future<void> main() async {
  if (kSentryDsn.isEmpty) {
    await _start();
    return;
  }
  await SentryFlutter.init(
    (options) {
      options.dsn = kSentryDsn;
      // Sem dados pessoais (IP, usuario) e sem rastreio de desempenho: so
      // erros e crashes. Localizacao nunca vai em evento.
      options.sendDefaultPii = false;
      options.tracesSampleRate = 0;
    },
    appRunner: _start,
  );
}

Future<void> _start() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Porta pela qual o isolate do servico de gravacao (notificacao) entrega os
  // toques nos botoes Pausar/Retomar, Volta e Encerrar ao isolate principal.
  // Precisa existir antes do runApp (ver foreground_task_recording_service).
  FlutterForegroundTask.initCommunicationPort();

  // Sync automatico em segundo plano: registra o dispatcher e garante a
  // tarefa periodica. Best effort — o agendador engole os proprios erros e,
  // fora de Android/iOS ou sem backend configurado, nao faz nada.
  final BackgroundSyncScheduler scheduler =
      createPlatformBackgroundSyncScheduler(kSyncBaseUrl);
  await scheduler.initialize();
  await scheduler.schedulePeriodic();

  runApp(
    ProviderScope(
      overrides: [backgroundSyncSchedulerProvider.overrideWithValue(scheduler)],
      child: const StravaEstudoApp(),
    ),
  );
}

class StravaEstudoApp extends ConsumerWidget {
  const StravaEstudoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      routerConfig: ref.watch(appRouterProvider),
      title: 'Atividades',
      // Escuro por padrao (relatorio 11); o claro existe, mas e secundario.
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      // Caixa de entrada do Rastro Seguro (F08): busca em primeiro plano.
      builder: (_, child) => InboxPoller(child: child ?? const SizedBox.shrink()),
    );
  }
}
