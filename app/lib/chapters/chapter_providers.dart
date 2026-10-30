// Capitulos (F05): providers que leem as atividades finalizadas do banco
// local e aplicam o dominio puro (chapters/domain). Tudo no aparelho, sem
// servidor. So os cabecalhos sao lidos (nada de pontos): o capitulo nao
// precisa de trajeto.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import 'domain/chapter.dart';
import 'domain/chapter_activity.dart';
import 'domain/period.dart';
import 'domain/weekly_streak.dart';

/// Relogio dos capitulos (sobrescrito nos testes).
final chapterClockProvider = Provider<DateTime Function()>((_) => DateTime.now);

/// Historico inteiro como o capitulo enxerga (sem titulo, descricao nem
/// trajeto). Recalcula quando a lista de recentes e invalidada (salvar,
/// apagar, recuperar).
final chapterActivitiesProvider =
    FutureProvider.autoDispose<List<ChapterActivity>>((ref) async {
      await ref.watch(recentActivitiesProvider.future);
      final rows = await ref
          .watch(recordingDatabaseProvider)
          .finishedActivitiesAscending();
      return [
        for (final a in rows)
          ChapterActivity(
            type: a.activityType,
            start: DateTime.fromMillisecondsSinceEpoch(a.startTimestampMs),
            distanceMeters: a.distanceMeters,
            timerMs: a.timerTimeMs,
            finished: a.isFinished,
          ),
      ];
    });

/// `yyyymm` do ultimo capitulo aberto ou dispensado.
final chapterSeenProvider = FutureProvider.autoDispose<int?>(
  (ref) => ref.watch(recordingDatabaseProvider).chapterMonthSeen(),
);

/// Mes cujo capitulo o cartao do Inicio oferece; null = sem cartao.
final homeChapterProvider = FutureProvider.autoDispose<MonthKey?>((ref) async {
  final acts = await ref.watch(chapterActivitiesProvider.future);
  final seen = await ref.watch(chapterSeenProvider.future);
  return pendingHomeChapter(
    acts,
    now: ref.watch(chapterClockProvider)(),
    seenCode: seen,
  );
});

/// Marca capitulos como vistos (abriu ou dispensou): o cartao do Inicio some.
class ChapterSeenMarker {
  final Ref _ref;
  ChapterSeenMarker(this._ref);

  Future<void> markSeen(MonthKey month) async {
    await _ref.read(recordingDatabaseProvider).markChapterMonthSeen(month.code);
    _ref.invalidate(chapterSeenProvider);
  }
}

final chapterSeenMarkerProvider = Provider<ChapterSeenMarker>(ChapterSeenMarker.new);

final monthChapterProvider = FutureProvider.autoDispose
    .family<MonthChapter, MonthKey>((ref, month) async {
      final acts = await ref.watch(chapterActivitiesProvider.future);
      return buildMonthChapter(
        acts,
        month,
        now: ref.watch(chapterClockProvider)(),
      );
    });

final yearChapterProvider = FutureProvider.autoDispose
    .family<YearChapter, int>((ref, year) async {
      final acts = await ref.watch(chapterActivitiesProvider.future);
      return buildYearChapter(acts, year, now: ref.watch(chapterClockProvider)());
    });

/// Lista "Capitulos" da aba Estatisticas: meses fechados com dados e anos.
final chapterIndexProvider =
    FutureProvider.autoDispose<({List<MonthKey> months, List<int> years})>((
      ref,
    ) async {
      final acts = await ref.watch(chapterActivitiesProvider.future);
      final now = ref.watch(chapterClockProvider)();
      return (
        months: chapterMonths(acts, now: now),
        years: chapterYears(acts, now: now),
      );
    });

/// Sequencia semanal de agora (resumo da aba Estatisticas).
final currentStreakProvider = FutureProvider.autoDispose<WeeklyStreak>((
  ref,
) async {
  final acts = await ref.watch(chapterActivitiesProvider.future);
  return weeklyStreak(acts, now: ref.watch(chapterClockProvider)());
});
