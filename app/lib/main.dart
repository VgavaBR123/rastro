// Ponto de entrada do app. Clean room — app proprio de atividades.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/providers.dart' show kSyncBaseUrl;
import 'sync/background/background_sync_provider.dart';
import 'sync/background/background_sync_scheduler.dart';
import 'ui/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Sync automatico em segundo plano: registra o dispatcher e garante a
  // tarefa periodica. Best effort — o agendador engole os proprios erros e,
  // fora de Android/iOS ou sem backend configurado, nao faz nada.
  final BackgroundSyncScheduler scheduler =
      createPlatformBackgroundSyncScheduler(kSyncBaseUrl);
  await scheduler.initialize();
  await scheduler.schedulePeriodic();

  runApp(
    ProviderScope(
      overrides: [
        backgroundSyncSchedulerProvider.overrideWithValue(scheduler),
      ],
      child: const StravaEstudoApp(),
    ),
  );
}

class StravaEstudoApp extends StatelessWidget {
  const StravaEstudoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Atividades',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
