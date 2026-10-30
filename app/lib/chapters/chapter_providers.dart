// Capitulos (F05): providers que leem as atividades finalizadas do banco
// local e aplicam o dominio puro (chapters/domain). Tudo no aparelho, sem
// servidor. So os cabecalhos sao lidos (nada de pontos): o capitulo nao
// precisa de trajeto.
//
// "Agora" dos capitulos: Inicio e Estatisticas ficam vivos no shell, entao
// os providers nao podem ler o relogio so quando calculam. Eles dependem de
// [chapterTodayProvider] (o dia local atual), que vira na meia-noite por um
// Timer e e relido quando o app volta do segundo plano.
library;

import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import 'domain/chapter.dart';
import 'domain/chapter_activity.dart';
import 'domain/period.dart';
import 'domain/weekly_streak.dart';

/// Relogio dos capitulos (sobrescrito nos testes).
final chapterClockProvider = Provider<DateTime Function()>((_) => DateTime.now);

/// Cancela um timer agendado por [chapterDayTimerProvider].
typedef CancelTimer = void Function();

/// Agenda [onFire] depois de [delay]. Dentro de `flutter test` nao agenda
/// nada (nenhum Timer pendente nos testes de widget); os testes do relogio
/// injetam um falso.
final chapterDayTimerProvider =
    Provider<CancelTimer Function(Duration delay, void Function() onFire)>((_) {
      final underTest =
          !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
      if (underTest) return (_, _) => () {};
      return (delay, onFire) => Timer(delay, onFire).cancel;
    });

DateTime _dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

/// Dia local atual (00:00). Muda na meia-noite e ao voltar do segundo plano.
class ChapterToday extends Notifier<DateTime> {
  CancelTimer? _cancel;

  @override
  DateTime build() {
    final clock = ref.watch(chapterClockProvider);
    final lifecycle = AppLifecycleListener(onResume: refresh);
    ref.onDispose(() {
      _cancel?.call();
      _cancel = null;
      lifecycle.dispose();
    });
    final now = clock();
    _schedule(now);
    return _dayOf(now);
  }

  /// Rele o relogio; so notifica se o dia mudou. Reagenda a proxima virada.
  void refresh() {
    final now = ref.read(chapterClockProvider)();
    _schedule(now);
    final today = _dayOf(now);
    if (today != state) state = today;
  }

  void _schedule(DateTime now) {
    _cancel?.call();
    final next = DateTime(now.year, now.month, now.day + 1);
    _cancel = ref.read(chapterDayTimerProvider)(next.difference(now), refresh);
  }
}

final chapterTodayProvider = NotifierProvider<ChapterToday, DateTime>(
  ChapterToday.new,
);

/// "Agora" usado pelos capitulos: o ultimo instante do dia atual, para as
/// atividades de hoje sempre entrarem. Todos os providers abaixo usam este
/// mesmo valor.
final chapterNowProvider = Provider<DateTime>((ref) {
  final d = ref.watch(chapterTodayProvider);
  return DateTime(d.year, d.month, d.day + 1)
      .subtract(const Duration(milliseconds: 1));
});

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
    now: ref.watch(chapterNowProvider),
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
        now: ref.watch(chapterNowProvider),
      );
    });

final yearChapterProvider = FutureProvider.autoDispose
    .family<YearChapter, int>((ref, year) async {
      final acts = await ref.watch(chapterActivitiesProvider.future);
      return buildYearChapter(acts, year, now: ref.watch(chapterNowProvider));
    });

/// Lista "Capitulos" da aba Estatisticas: meses fechados com dados e anos.
final chapterIndexProvider =
    FutureProvider.autoDispose<({List<MonthKey> months, List<int> years})>((
      ref,
    ) async {
      final acts = await ref.watch(chapterActivitiesProvider.future);
      final now = ref.watch(chapterNowProvider);
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
  return weeklyStreak(acts, now: ref.watch(chapterNowProvider));
});

/// Tudo o que a secao da aba Estatisticas desenha, calculado com o mesmo
/// "agora": sequencia, coringa do mes de referencia e a lista de capitulos
/// ja com os rotulos ("2026 ate agora").
class ChaptersOverview {
  final WeeklyStreak streak;

  /// Mes do "agora" (o do coringa mostrado).
  final MonthKey referenceMonth;
  final bool jokerAvailable;
  final List<({int year, String label})> years;
  final List<({MonthKey month, String label})> months;

  const ChaptersOverview({
    required this.streak,
    required this.referenceMonth,
    required this.jokerAvailable,
    required this.years,
    required this.months,
  });

  /// "Coringa de novembro: disponivel" (ou "usado").
  String get jokerLabel =>
      'Coringa de ${monthName(referenceMonth.month).toLowerCase()}: '
      '${jokerAvailable ? 'disponivel' : 'usado'}';
}

final chaptersOverviewProvider = FutureProvider.autoDispose<ChaptersOverview>((
  ref,
) async {
  final acts = await ref.watch(chapterActivitiesProvider.future);
  final now = ref.watch(chapterNowProvider);
  final month = MonthKey.of(now);
  final streak = weeklyStreak(acts, now: now);
  return ChaptersOverview(
    streak: streak,
    referenceMonth: month,
    jokerAvailable: streak.jokerAvailable(month),
    years: [
      for (final y in chapterYears(acts, now: now))
        (year: y, label: y == now.year ? '$y ate agora' : '$y'),
    ],
    months: [
      for (final m in chapterMonths(acts, now: now))
        (month: m, label: '${monthName(m.month)} de ${m.year}'),
    ],
  );
});
