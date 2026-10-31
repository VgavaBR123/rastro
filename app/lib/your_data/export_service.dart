/// Exportacao das atividades (F07).
///
/// - Tudo: um ZIP com um GPX 1.1 por atividade, `atividades.csv` com o resumo
///   (colunas nossas) e um `LEIA-ME.txt`.
/// - Uma so: um GPX.
///
/// Com "Aplicar zonas de privacidade" (padrao ligado), os pontos saem com o
/// mesmo corte do upload (F02: inicio e fim dentro das zonas e os metros
/// ocultos de cada atividade); distancia e tempos do CSV continuam os totais.
/// O arquivo fica em [outDir] (uma exportacao por vez: os anteriores sao
/// apagados) ate ir para o compartilhar do sistema.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show visibleForTesting;

import '../activity/elevation_profile.dart';
import '../core/format/activity_labels.dart';
import '../persistence/database.dart';
import '../privacy/privacy_repository.dart';
import '../recording/domain/waypoint.dart' as dom;
import 'domain/csv.dart';
import 'domain/gpx_writer.dart';
import 'domain/import_models.dart';
import 'domain/zip_writer.dart';

/// Cabecalho do atividades.csv.
const List<String> kExportCsvHeader = [
  'data',
  'tipo',
  'titulo',
  'distancia_km',
  'tempo_em_movimento',
  'tempo_total',
  'subida_m',
  'origem',
  'arquivo_gpx',
];

/// Ja ha uma exportacao em andamento (tudo ou uma atividade).
class ExportBusyException implements Exception {
  const ExportBusyException();
  @override
  String toString() => 'Ja ha uma exportacao em andamento';
}

/// Subpastas de exportacao com mais que isto sao apagadas na proxima.
const Duration kExportKeep = Duration(hours: 1);

class ExportResult {
  final String path;
  final int count;
  const ExportResult(this.path, this.count);
}

String _two(int v) => v.toString().padLeft(2, '0');

/// "2026-03-01T07:00:00-03:00" no fuso do aparelho.
String localIsoWithOffset(int ms) {
  final d = DateTime.fromMillisecondsSinceEpoch(ms);
  final off = d.timeZoneOffset;
  final sign = off.isNegative ? '-' : '+';
  final mins = off.inMinutes.abs();
  return '${d.year}-${_two(d.month)}-${_two(d.day)}T${_two(d.hour)}:${_two(d.minute)}:'
      '${_two(d.second)}$sign${_two(mins ~/ 60)}:${_two(mins % 60)}';
}

/// "1:02:03" (horas sem zero a esquerda).
String hms(int ms) {
  final s = ms ~/ 1000;
  return '${s ~/ 3600}:${_two((s ~/ 60) % 60)}:${_two(s % 60)}';
}

/// "gravada no app" ou "importada de GPX".
String originLabel(String? importSource) {
  final f = ImportFormat.fromDb(importSource);
  return f == null ? 'gravada no app' : 'importada de ${f.label}';
}

class ExportService {
  final RecordingDatabase db;
  final DateTime Function() _now;

  ExportService(this.db, {DateTime Function()? now}) : _now = now ?? DateTime.now;

  /// Uma exportacao por vez no app inteiro (todas as instancias).
  static bool _busy = false;

  Future<T> _exclusive<T>(Future<T> Function() body) => runExclusive(body);

  /// Roda [body] com a trava das exportacoes (tambem usado nos testes para
  /// segurar a trava). Lanca [ExportBusyException] se ja estiver presa.
  @visibleForTesting
  static Future<T> runExclusive<T>(Future<T> Function() body) async {
    if (_busy) throw const ExportBusyException();
    _busy = true;
    try {
      return await body();
    } finally {
      _busy = false;
    }
  }

  /// Exporta todas as atividades finalizadas. Devolve null se cancelado (e
  /// nao deixa arquivo pela metade).
  Future<ExportResult?> exportAll({
    required Directory outDir,
    required bool applyPrivacy,
    void Function(int done, int total)? onProgress,
    bool Function()? isCancelled,
  }) => _exclusive(() async {
    final now = _now();
    final folder = await _prepare(outDir, now);
    final stamp = '${now.year}${_two(now.month)}${_two(now.day)}-${_two(now.hour)}${_two(now.minute)}';
    final path = '${folder.path}/rastro-atividades-$stamp.zip';
    final activities = await db.finishedActivitiesAscending();
    final zip = ZipWriter.create(path, now: now);
    final privacy = PrivacyRepository(db);
    final csv = StringBuffer('${kExportCsvHeader.join(',')}\r\n');
    var done = 0;
    var closed = false;
    try {
      onProgress?.call(0, activities.length);
      for (final a in activities) {
        if (isCancelled?.call() ?? false) {
          zip.close();
          closed = true;
          await File(path).delete();
          return null;
        }
        final rows = await db.waypointsForActivity(a.guid);
        final title = _title(a);
        final gpx = _gpx(a, title, applyPrivacy ? await privacy.exportWaypoints(a) : _accepted(rows));
        final start = DateTime.fromMillisecondsSinceEpoch(a.startTimestampMs);
        final file = zip.add(
          'gpx/${start.year}-${_two(start.month)}-${_two(start.day)}_'
          '${_two(start.hour)}${_two(start.minute)} ${safeFileName(title)}.gpx',
          utf8.encode(gpx),
        );
        final gain = buildElevationProfile(rows)?.gainMeters ?? 0;
        final end = a.endTimestampMs ?? (a.startTimestampMs + a.timerTimeMs);
        csv.write([
          localIsoWithOffset(a.startTimestampMs),
          activityTypeLabel(a.activityType),
          csvField(title),
          (a.distanceMeters / 1000).toStringAsFixed(3),
          hms(a.timerTimeMs),
          hms(end - a.startTimestampMs),
          gain.round().toString(),
          originLabel(a.importSource),
          csvField(file),
        ].join(','));
        csv.write('\r\n');
        done++;
        onProgress?.call(done, activities.length);
        // Deixa a interface respirar entre uma atividade e outra.
        await Future<void>.delayed(Duration.zero);
      }
      zip.add('atividades.csv', utf8.encode(csv.toString()));
      zip.add('LEIA-ME.txt', utf8.encode(_readme(now, done, applyPrivacy)));
      zip.close();
      closed = true;
      return ExportResult(path, done);
    } on Object {
      if (!closed) {
        try {
          zip.close();
        } on Object {
          // Ja falhou; o importante e apagar o arquivo pela metade.
        }
      }
      final f = File(path);
      if (await f.exists()) await f.delete();
      rethrow;
    }
  });

  /// Exporta [a] como GPX e devolve o caminho.
  Future<String> exportOne(
    Activity a, {
    required Directory outDir,
    required bool applyPrivacy,
  }) => _exclusive(() async {
    final folder = await _prepare(outDir, _now());
    final title = _title(a);
    final points = applyPrivacy
        ? await PrivacyRepository(db).exportWaypoints(a)
        : _accepted(await db.waypointsForActivity(a.guid));
    final start = DateTime.fromMillisecondsSinceEpoch(a.startTimestampMs);
    final file = File('${folder.path}/${start.year}-${_two(start.month)}-${_two(start.day)} '
        '${safeFileName(title)}.gpx');
    await file.writeAsString(_gpx(a, title, points), flush: true);
    return file.path;
  });

  static String _title(Activity a) => displayActivityTitle(
    a.title,
    a.activityType,
    DateTime.fromMillisecondsSinceEpoch(a.startTimestampMs),
  );

  static List<Waypoint> _accepted(List<Waypoint> rows) => [
    for (final w in rows)
      if (w.classification == dom.WaypointClassification.accept.index) w,
  ];

  static String _gpx(Activity a, String title, List<Waypoint> points) => buildGpx(
    name: title,
    type: a.activityType,
    startMs: a.startTimestampMs,
    points: [
      for (final w in points)
        GpxPoint(
          latitude: w.latitude,
          longitude: w.longitude,
          altitudeMeters: w.altitudeMeters,
          timeMs: a.startTimestampMs + w.elapsedTimeMs,
        ),
    ],
  );

  /// Cria a subpasta desta exportacao (`<outDir>/<epoch ms>`) e apaga as
  /// antigas (mais de [kExportKeep]) e arquivos soltos do formato anterior.
  /// A atual e as recentes ficam: o app de destino pode estar lendo.
  static Future<Directory> _prepare(Directory outDir, DateTime now) async {
    final nowMs = now.millisecondsSinceEpoch;
    if (await outDir.exists()) {
      await for (final e in outDir.list()) {
        final name = e.uri.pathSegments.where((s) => s.isNotEmpty).last;
        if (e is File) {
          await e.delete();
        } else if (e is Directory) {
          final ms = int.tryParse(name.split('-').first);
          if (ms == null || nowMs - ms > kExportKeep.inMilliseconds) {
            await e.delete(recursive: true);
          }
        }
      }
    }
    var dir = Directory('${outDir.path}/$nowMs');
    for (var n = 2; await dir.exists(); n++) {
      dir = Directory('${outDir.path}/$nowMs-$n');
    }
    await dir.create(recursive: true);
    return dir;
  }

  static String _readme(DateTime now, int count, bool privacy) {
    final when = '${_two(now.day)}/${_two(now.month)}/${now.year} ${_two(now.hour)}:${_two(now.minute)}';
    final privacyText = privacy
        ? 'Os GPX sairam com o corte das zonas de privacidade e do inicio e do fim\n'
              'ocultos de cada atividade, como no envio ao servidor. A distancia e os\n'
              'tempos do CSV continuam sendo os totais da atividade.'
        : 'Os GPX sairam inteiros, sem o corte das zonas de privacidade. Cuidado ao\n'
              'compartilhar: o inicio e o fim podem mostrar onde voce mora ou trabalha.';
    return 'Rastro - suas atividades\r\n'
            '\r\n'
            'Gerado em $when, com $count ${count == 1 ? 'atividade' : 'atividades'}.\r\n'
            '\r\n'
            'atividades.csv: uma linha por atividade (data, tipo, titulo, distancia\n'
            'em km, tempo em movimento, tempo total, subida em metros, origem e o\n'
            'arquivo GPX). Separado por virgula, em UTF-8.\n'
            '\n'
            'gpx/: um arquivo GPX 1.1 por atividade, com horario (UTC) e elevacao de\n'
            'cada ponto. Atividades sem GPS (esteira) vem sem pontos.\n'
            '\n'
            'Privacidade: $privacyText\n'
            '\n'
            'Os arquivos GPX abrem na maioria dos apps e sites de atividade.\n'
        .replaceAll('\r\n', '\n')
        .replaceAll('\n', '\r\n');
  }
}
