/// Grava no banco o que a fila da importacao entrega (F07).
///
/// - Uma transacao por atividade: cabecalho + pontos entram juntos ou nada.
/// - Duplicata: o guid deterministico ja existe (mesmo arquivo de novo), ou
///   ja ha atividade finalizada do mesmo tipo com inicio a menos de 60 s
///   (inclusive gravada no app).
/// - A importada nasce finalizada, "so eu" e pendente de sync: sobe pela fila
///   normal depois (com o corte de privacidade do upload). Nada sobe aqui.
/// - Cancelar: para antes do proximo item; o que ja entrou fica.
library;

import 'package:drift/drift.dart';

import '../persistence/database.dart';
import '../persistence/recording_repository.dart';
import '../recording/domain/recording_models.dart';
import 'domain/activity_builder.dart';
import 'import_feed.dart';

/// Janela de duplicata por horario de inicio (mesmo tipo).
const int kDuplicateWindowMs = 60000;

class ImportFailure {
  final String source;
  final String reason;
  const ImportFailure(this.source, this.reason);
}

class ImportProgress {
  final int done;
  final int total;
  final int imported;
  const ImportProgress({required this.done, required this.total, required this.imported});
}

class ImportSummary {
  final int total;
  final int imported;
  final int duplicates;

  /// Ignoradas por rotulo do esporte ("natacao": 12).
  final Map<String, int> ignored;
  final List<ImportFailure> errors;
  final bool cancelled;

  const ImportSummary({
    required this.total,
    required this.imported,
    required this.duplicates,
    required this.ignored,
    required this.errors,
    required this.cancelled,
  });

  /// "12 de natacao ignoradas", na ordem de quantidade.
  List<String> get ignoredLines {
    final entries = ignored.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return [
      for (final e in entries) '${e.value} de ${e.key} ${e.value == 1 ? 'ignorada' : 'ignoradas'}',
    ];
  }
}

class ImportService {
  final RecordingDatabase db;

  /// Gancho de teste: roda dentro da transacao, antes do commit.
  final void Function(ImportedActivity a)? beforeCommit;

  ImportService(this.db, {this.beforeCommit});

  Future<ImportSummary> run(
    ImportFeed feed, {
    void Function(ImportProgress)? onProgress,
    bool Function()? isCancelled,
  }) async {
    final total = feed.total;
    var done = 0;
    var imported = 0;
    var duplicates = 0;
    final ignored = <String, int>{};
    final errors = <ImportFailure>[];
    var cancelled = false;
    void progress() =>
        onProgress?.call(ImportProgress(done: done, total: total, imported: imported));

    progress();
    try {
      while (true) {
        if (isCancelled?.call() ?? false) {
          cancelled = true;
          break;
        }
        final step = await feed.next();
        if (step == null) break;
        switch (step) {
          case ImportStepActivity(:final source, :final activity):
            try {
              if (await _write(activity)) {
                imported++;
              } else {
                duplicates++;
              }
            } on Object {
              errors.add(ImportFailure(source, 'nao foi possivel gravar'));
            }
          case ImportStepSkipped(:final label):
            ignored[label] = (ignored[label] ?? 0) + 1;
          case ImportStepError(:final source, :final reason):
            errors.add(ImportFailure(source, reason));
        }
        done++;
        progress();
      }
    } finally {
      await feed.close();
    }
    return ImportSummary(
      total: total,
      imported: imported,
      duplicates: duplicates,
      ignored: ignored,
      errors: errors,
      cancelled: cancelled,
    );
  }

  /// Grava [a] numa transacao. False quando e duplicata.
  Future<bool> _write(ImportedActivity a) => db.transaction(() async {
    final sameGuid = await (db.select(db.activities)
          ..where((t) => t.guid.equals(a.guid)))
        .getSingleOrNull();
    if (sameGuid != null) return false;
    final near = await (db.selectOnly(db.activities)
          ..addColumns([db.activities.guid])
          ..where(db.activities.isFinished.equals(true) &
              db.activities.activityType.equalsValue(a.type) &
              db.activities.startTimestampMs.isBiggerThanValue(a.startMs - kDuplicateWindowMs) &
              db.activities.startTimestampMs.isSmallerThanValue(a.startMs + kDuplicateWindowMs))
          ..limit(1))
        .get();
    if (near.isNotEmpty) return false;

    await db.into(db.activities).insert(ActivitiesCompanion.insert(
      guid: a.guid,
      activityType: a.type,
      startTimestampMs: a.startMs,
      endTimestampMs: Value(a.endMs),
      timerTimeMs: Value(a.timerMs),
      distanceMeters: Value(a.distanceMeters),
      isIndoor: Value(a.isIndoor),
      isFinished: const Value(true),
      syncState: SyncState.pending,
      title: Value(a.title),
      visibility: Value(ActivityVisibility.onlyMe.dbValue),
      importSource: Value(a.format.dbValue),
    ));
    if (a.points.isNotEmpty) {
      await db.appendWaypoints([
        for (var i = 0; i < a.points.length; i++) waypointToCompanion(a.guid, i, a.points[i]),
      ]);
    }
    beforeCommit?.call(a);
    return true;
  });
}
