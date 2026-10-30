/// Providers da privacidade automatica (F02).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../recording/domain/geo.dart';
import 'domain/privacy_zone.dart';
import 'domain/routine.dart';
import 'domain/zone_detection.dart';
import 'privacy_repository.dart';

final privacyRepositoryProvider = Provider<PrivacyRepository>(
  (ref) => PrivacyRepository(ref.watch(recordingDatabaseProvider)),
);

/// Zonas salvas, na ordem de criacao.
final privacyZonesProvider = FutureProvider.autoDispose<List<PrivacyZone>>(
  (ref) => ref.watch(privacyRepositoryProvider).zones(),
);

/// Sugestoes de casa/trabalho ainda nao aceitas nem ignoradas.
final zoneSuggestionsProvider =
    FutureProvider.autoDispose<List<ZoneSuggestion>>((ref) {
      // Recalcula quando as zonas mudam e quando uma atividade e salva ou
      // apagada (a gravacao e a exclusao invalidam as recentes).
      ref.watch(privacyZonesProvider);
      ref.watch(recentActivitiesProvider);
      return ref.watch(privacyRepositoryProvider).suggestions();
    });

/// Rota de uma atividade com o corte de privacidade.
final visibleRouteProvider = FutureProvider.autoDispose
    .family<PrivateRoute, String>((ref, guid) {
      ref.watch(privacyZonesProvider);
      return ref.watch(privacyRepositoryProvider).visibleRoute(guid);
    });

/// Aviso de rotina para uma atividade ja salva (tela Compartilhar): so avisa
/// se ela propria faz parte da rotina que se repete.
final routineWarningForActivityProvider = FutureProvider.autoDispose
    .family<bool, String>(
      (ref, guid) =>
          ref.watch(privacyRepositoryProvider).routineWarningFor(guid),
    );

/// Aviso de rotina incluindo uma atividade que ainda vai ser salva (inicio
/// em [start] as [startedAt]); as finalizadas completam a janela.
Future<bool> routineWarningWithNew(
  PrivacyRepository repo, {
  required GeoPoint? start,
  required DateTime startedAt,
  String? exceptGuid,
}) async {
  final previous = await repo.recentStarts(
    limit: start == null ? kRoutineWindow : kRoutineWindow - 1,
    exceptGuid: exceptGuid,
  );
  return isRoutinePredictable([
    if (start != null) ActivityStartSample.at(start, startedAt),
    ...previous,
  ]);
}
