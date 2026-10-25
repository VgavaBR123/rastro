// Gera um arquivo FIT de exemplo com o nosso codificador, para smoke test
// manual do backend (POST /uploads) sem precisar rodar o app no emulador.
//
// Uso (com o Dart do Flutter no PATH), dentro de app/:
//   dart run tool/gen_sample_fit.dart ../.tmp/exemplo.fit
library;

import 'dart:io';
import 'dart:math' as math;

import 'package:strava_estudo_app/sync/fit/fit_writer.dart';

void main(List<String> args) {
  final String path = args.isNotEmpty ? args.first : 'exemplo.fit';

  // Rota sintetica: 60 pontos subindo para nordeste a ~1 ponto/segundo,
  // partindo de um ponto qualquer em Belo Horizonte.
  const double lat0 = -19.9245;
  const double lon0 = -43.9352;
  const int startMs = 1760000000000; // timestamp fixo: saida reproduzivel.

  final List<FitRecord> records = <FitRecord>[];
  double distancia = 0;
  for (int i = 0; i < 60; i++) {
    final double lat = lat0 + i * 0.00009; // ~10 m por ponto
    final double lon = lon0 + i * 0.00009;
    distancia += 14.0; // metros acumulados aproximados
    records.add(FitRecord(
      timestampUnixMs: startMs + i * 1000,
      latitude: lat,
      longitude: lon,
      altitudeMeters: 850 + 5 * math.sin(i / 6),
      cumulativeDistanceMeters: distancia,
      speedMetersPerSecond: 3.0,
    ));
  }

  final bytes = encodeActivityFit(startTimeUnixMs: startMs, records: records);
  final File out = File(path);
  out.parent.createSync(recursive: true);
  out.writeAsBytesSync(bytes);
  stdout.writeln('${bytes.length} bytes em ${out.absolute.path} '
      '(${records.length} pontos)');
}
