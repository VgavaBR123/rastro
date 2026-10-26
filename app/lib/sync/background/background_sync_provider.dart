// Provider Riverpod do agendador de sync em segundo plano.
//
// O main.dart cria e inicializa o agendador antes do runApp e sobrescreve este
// provider com a mesma instancia (overrideWithValue). Sem override (ex.:
// testes de widget), cai no agendador da plataforma, que fora de
// Android/iOS e um no-op.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:strava_estudo_app/app/providers.dart' show kSyncBaseUrl;
import 'package:strava_estudo_app/sync/background/background_sync_scheduler.dart';

final backgroundSyncSchedulerProvider = Provider<BackgroundSyncScheduler>((ref) {
  return createPlatformBackgroundSyncScheduler(kSyncBaseUrl);
});
