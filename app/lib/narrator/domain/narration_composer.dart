// Compositor de frases do Narrador (F03): transforma um evento da gravacao
// numa fala natural em portugues, conforme as preferencias. Dart puro.
//
// As frases de contexto ("seu quilometro mais rapido ate agora") sao
// calculadas aqui, so com o que o aparelho ja tem: os splits e voltas da
// atividade em curso.
library;

import '../../recording/domain/recording_models.dart';
import 'announcement.dart';
import 'narration_event.dart';
import 'narrator_settings.dart';
import 'spoken_pt.dart';

const double _metersPerKm = 1000.0;
const double _metersPerMile = 1609.344;

/// Chaves de fila: falas da mesma chave se substituem antes de tocar.
abstract final class NarrationKeys {
  static const String state = 'narrator.state';

  /// Todos os splits dividem esta chave, de proposito: se o Narrador esta
  /// ocupado e dois splits fecham no mesmo update (buraco no GPS), so o mais
  /// recente e falado. Evita uma fila de numeros velhos; o total ja vem nele.
  static const String split = 'narrator.split';
  static const String lap = 'narrator.lap';
  static const String time = 'narrator.time';
  static const String finish = 'narrator.finish';

  /// "Ouvir exemplo" das Configuracoes.
  static const String sample = 'narrator.sample';
}

/// Diferenca minima (s) para falar "N segundos mais rapido que o anterior".
const int _kFasterThanPreviousMinMs = 5000;

class NarrationComposer {
  const NarrationComposer();

  /// Fala do evento, ou null quando as preferencias mandam ficar quieto.
  Announcement? compose(NarrationEvent e, NarratorSettings s) => switch (e) {
    RecordingStarted() => _started(e, s),
    SplitClosed() => _split(e, s),
    LapClosed() => _lap(e, s),
    TimeMark() => _time(e, s),
    AutoPaused() => _status('Pausa automática.', s),
    ManuallyPaused() => _status('Gravação pausada.', s),
    Resumed() => _status('Gravação retomada.', s),
    RecordingFinished() => _finished(e, s),
  };

  /// Exemplo para "Ouvir exemplo": o segundo split de uma corrida, com as
  /// preferencias atuais (inclusive o modo so o essencial).
  Announcement sample(NarratorSettings s, {required bool metric}) {
    final unit = metric ? _metersPerKm : _metersPerMile;
    final perUnitMs = metric ? 332000 : 534000;
    final secondMs = perUnitMs - 12000;
    final e = SplitClosed(
      number: 2,
      durationMs: secondMs,
      previousDurationsMs: [perUnitMs],
      totals: NarrationTotals(
        type: ActivityType.run,
        distanceMeters: 2 * unit,
        timerMs: perUnitMs + secondMs,
        metric: metric,
      ),
    );
    final a = _split(e, s.copyWith(distanceTrigger: true, distanceEvery: 1))!;
    return Announcement(a.text, priority: a.priority, key: NarrationKeys.sample);
  }

  // --- Eventos ---

  Announcement? _started(RecordingStarted e, NarratorSettings s) {
    if (!s.statusAnnouncements) return null;
    final text = e.resumed
        ? 'Gravação retomada.'
        : '${_label(e.totals.type)} ${_ended(e.totals.type, 'iniciad')}.';
    return Announcement(text, priority: AnnouncementPriority.normal, key: NarrationKeys.state);
  }

  Announcement? _status(String text, NarratorSettings s) {
    if (!s.statusAnnouncements) return null;
    return Announcement(text, priority: AnnouncementPriority.high, key: NarrationKeys.state);
  }

  Announcement? _split(SplitClosed e, NarratorSettings s) {
    if (!s.distanceTrigger || e.number % s.distanceEvery != 0) return null;
    final t = e.totals;
    final metric = t.metric;
    final unit = metric ? _metersPerKm : _metersPerMile;
    final speedSport = _isSpeedSport(t.type);
    final parts = <String>['${spokenSplitMark(e.number, metric: metric)}.'];

    final splitPace = e.durationMs > 0 ? (e.durationMs / 1000.0) / unit : null;
    if (s.essentialOnly) {
      final main = speedSport
          ? _speedText(splitPace, metric)
          : _paceText(splitPace, metric);
      if (main != null) parts.add(speedSport ? '${capitalize(main)}.' : 'Pace $main.');
      return _announce(parts, AnnouncementPriority.normal, NarrationKeys.split, 60000);
    }

    if (s.sayTime) parts.add('Tempo ${spokenDuration(t.timerMs)}.');
    // No primeiro split o medio e igual ao do split: nao repete.
    final avgIsRedundant = e.number == 1 && s.saySplitPace;
    if (s.sayAvgPace && !avgIsRedundant) {
      final avg = _avgPhrase(t);
      if (avg != null) parts.add(avg);
    }
    if (s.saySplitPace) {
      final unitName = metric ? 'do quilômetro' : 'da milha';
      if (speedSport) {
        final v = _speedText(splitPace, metric);
        if (v != null) parts.add('Velocidade ${metric ? 'no quilômetro' : 'na milha'} $v.');
      } else {
        final p = _paceText(splitPace, metric);
        if (p != null) parts.add('Pace $unitName $p.');
      }
    }
    if (s.contextPhrases) {
      final ctx = _splitContext(e);
      if (ctx != null) parts.add(ctx);
    }
    return _announce(parts, AnnouncementPriority.normal, NarrationKeys.split, 60000);
  }

  String? _splitContext(SplitClosed e) {
    final prev = e.previousDurationsMs;
    if (prev.isEmpty || e.durationMs <= 0) return null;
    final metric = e.totals.metric;
    final best = prev.reduce((a, b) => a < b ? a : b);
    if (e.durationMs < best) {
      return metric
          ? 'Seu quilômetro mais rápido até agora.'
          : 'Sua milha mais rápida até agora.';
    }
    final diff = prev.last - e.durationMs;
    if (diff >= _kFasterThanPreviousMinMs) {
      final secs = (diff / 1000).round();
      return '${capitalize(numberWords(secs))} segundos mais rápido que o anterior.';
    }
    return null;
  }

  Announcement? _lap(LapClosed e, NarratorSettings s) {
    if (!s.lapTrigger) return null;
    final lap = e.lap;
    final metric = e.totals.metric;
    final speedSport = _isSpeedSport(e.totals.type);
    final parts = <String>['Volta ${numberWords(lap.number)}.'];
    if (s.essentialOnly) {
      parts.add('${capitalize(spokenDuration(lap.durationMs))}.');
      return _announce(parts, AnnouncementPriority.normal, NarrationKeys.lap, 60000);
    }
    if (s.sayTime) parts.add('Tempo da volta ${spokenDuration(lap.durationMs)}.');
    if (s.sayDistance && lap.distanceMeters > 0) {
      parts.add('Distância da volta ${spokenDistance(lap.distanceMeters, metric: metric)}.');
    }
    final pace = _lapPace(lap);
    if (s.saySplitPace) {
      final text = speedSport ? _speedText(pace, metric) : _paceText(pace, metric);
      if (text != null) {
        parts.add('${speedSport ? 'Velocidade' : 'Pace'} da volta $text.');
      }
    }
    if (s.contextPhrases && pace != null) {
      final others = [
        for (final l in e.previous)
          if (_lapPace(l) != null) _lapPace(l)!,
      ];
      if (others.isNotEmpty && pace < others.reduce((a, b) => a < b ? a : b)) {
        parts.add('Sua volta mais rápida até agora.');
      }
    }
    return _announce(parts, AnnouncementPriority.normal, NarrationKeys.lap, 60000);
  }

  Announcement? _time(TimeMark e, NarratorSettings s) {
    final t = e.totals;
    final parts = <String>['${capitalize(spokenDuration(e.markMs))}.'];
    if (s.essentialOnly) {
      parts.add('${capitalize(spokenDistance(t.distanceMeters, metric: t.metric))}.');
    } else {
      if (s.sayDistance) {
        parts.add('Distância ${spokenDistance(t.distanceMeters, metric: t.metric)}.');
      }
      if (s.sayAvgPace) {
        final avg = _avgPhrase(t);
        if (avg != null) parts.add(avg);
      }
    }
    return _announce(parts, AnnouncementPriority.low, NarrationKeys.time, 30000);
  }

  Announcement? _finished(RecordingFinished e, NarratorSettings s) {
    if (!s.statusAnnouncements) return null;
    final t = e.totals;
    final head = '${_label(t.type)} ${_ended(t.type, 'encerrad')}.';
    final parts = <String>[head];
    if (s.essentialOnly) {
      parts.add(
        '${capitalize(spokenDistance(t.distanceMeters, metric: t.metric))} '
        'em ${spokenDuration(t.timerMs)}.',
      );
    } else {
      if (s.sayDistance) {
        parts.add('Distância ${spokenDistance(t.distanceMeters, metric: t.metric)}.');
      }
      if (s.sayTime) parts.add('Tempo ${spokenDuration(t.timerMs)}.');
      if (s.sayAvgPace) {
        final avg = _avgPhrase(t);
        if (avg != null) parts.add(avg);
      }
    }
    return _announce(parts, AnnouncementPriority.high, NarrationKeys.finish, null);
  }

  // --- Pecas ---

  Announcement _announce(
    List<String> parts,
    AnnouncementPriority p,
    String key,
    int? maxAgeMs,
  ) => Announcement(parts.join(' '), priority: p, key: key, maxAgeMs: maxAgeMs);

  /// "Pace médio X." ou "Velocidade média V."; null sem distancia.
  String? _avgPhrase(NarrationTotals t) {
    if (t.distanceMeters <= 0 || t.timerMs <= 0) return null;
    final spm = (t.timerMs / 1000.0) / t.distanceMeters;
    if (_isSpeedSport(t.type)) {
      final v = _speedText(spm, t.metric);
      return v == null ? null : 'Velocidade média $v.';
    }
    final p = _paceText(spm, t.metric);
    return p == null ? null : 'Pace médio $p.';
  }

  String? _paceText(double? secondsPerMeter, bool metric) =>
      spokenPace(secondsPerMeter, metric: metric);

  String? _speedText(double? secondsPerMeter, bool metric) {
    if (secondsPerMeter == null || secondsPerMeter <= 0) return null;
    return spokenSpeed(1 / secondsPerMeter, metric: metric);
  }

  double? _lapPace(LapMark l) => l.distanceMeters > 0 && l.durationMs > 0
      ? (l.durationMs / 1000.0) / l.distanceMeters
      : null;

  static bool _isSpeedSport(ActivityType t) => t == ActivityType.ride;

  static String _label(ActivityType t) => switch (t) {
    ActivityType.run => 'Corrida',
    ActivityType.ride => 'Pedal',
    ActivityType.walk => 'Caminhada',
  };

  /// "iniciada"/"iniciado" pelo genero do esporte.
  static String _ended(ActivityType t, String stem) =>
      '$stem${t == ActivityType.ride ? 'o' : 'a'}';
}
