// Fechamento gentil (F04): monta as frases do fim do treino a partir do que
// esta salvo no aparelho. So le o banco local; as regras ficam no dominio
// puro (self_comparison.dart).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../persistence/database.dart';
import '../persistence/recording_repository.dart';
import '../recording/domain/splits_from_waypoints.dart';
import '../recording/domain/waypoint.dart' as dom;
import 'domain/self_comparison.dart';

/// Atividades lidas para achar a ultima antes da atual ("voltou") e as das
/// 4 semanas.
const int kClosingHistoryLimit = 300;

class ClosingService {
  final RecordingRepository _repo;
  ClosingService(this._repo);

  /// 2 ou 3 frases para a atividade [guid]; vazio se ela nao existe.
  Future<List<String>> phrasesFor(
    String guid, {
    required bool gentle,
    required bool metric,
  }) async {
    final current = await _repo.activity(guid);
    if (current == null) return const [];
    final recent = await _repo.recent(limit: kClosingHistoryLimit);
    final windowStart =
        current.startTimestampMs - kSelfComparisonDays * 24 * 60 * 60 * 1000;

    final history = <SelfEntry>[];
    for (final a in recent) {
      if (a.guid == current.guid) continue;
      // Splits so onde a constancia e comparada: mesmo esporte, na janela.
      final compare = a.activityType == current.activityType &&
          a.startTimestampMs >= windowStart &&
          a.startTimestampMs < current.startTimestampMs;
      history.add(await _entry(a, metric: metric, withSplits: compare));
    }
    return selfComparisonPhrases(
      current: await _entry(current, metric: metric, withSplits: true),
      history: history,
      gentle: gentle,
    );
  }

  Future<SelfEntry> _entry(
    Activity a, {
    required bool metric,
    required bool withSplits,
  }) async {
    var splits = const <int>[];
    if (withSplits) {
      final rows = await _repo.waypoints(a.guid);
      splits = [
        for (final s in splitsFromPoints(
          [
            for (final w in rows)
              if (w.classification == dom.WaypointClassification.accept.index)
                SplitSourcePoint(
                  cumulativeDistanceMeters: w.cumulativeDistanceMeters,
                  timerTimeMs: w.timerTimeMs,
                ),
          ],
          metric: metric,
          finalTimerMs: a.timerTimeMs,
        ))
          if (s.complete) s.durationMs,
      ];
    }
    return SelfEntry(
      guid: a.guid,
      type: a.activityType,
      startMs: a.startTimestampMs,
      distanceMeters: a.distanceMeters,
      timerMs: a.timerTimeMs,
      splitDurationsMs: splits,
    );
  }
}

final closingServiceProvider = Provider<ClosingService>(
  (ref) => ClosingService(ref.watch(recordingRepositoryProvider)),
);
