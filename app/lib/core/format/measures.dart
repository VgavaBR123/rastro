// Formatadores de medidas para a UI (distancia, duracao, pace,
// velocidade e elevacao). Dart puro, logica propria e trivial.
// Todas as funcoes sao defensivas contra NaN/Infinity.
library;

// Fatores de conversao usados em todo o arquivo.
const double _metrosPorKm = 1000.0;
const double _metrosPorMilha = 1609.344;
const double _pesPorMetro = 3.280839895;

// Placeholder exibido quando o valor nao faz sentido numerico.
const String _tracos = '--';

bool _valido(num? v) => v != null && v.isFinite;

// Formata uma distancia em metros.
// Metrico: "### m" (abaixo de 1000 m) ou "#.## km".
// Imperial: "#.## mi".
String formatDistance(double meters, {bool metric = true}) {
  if (!_valido(meters)) return metric ? '$_tracos m' : '$_tracos mi';
  final double m = meters < 0 ? 0 : meters;
  if (metric) {
    if (m < _metrosPorKm) {
      return '${m.round()} m';
    }
    final double km = m / _metrosPorKm;
    return '${km.toStringAsFixed(2)} km';
  }
  final double mi = m / _metrosPorMilha;
  return '${mi.toStringAsFixed(2)} mi';
}

// Formata uma duracao em milissegundos.
// "H:MM:SS" quando ha horas, senao "M:SS". Valores <= 0 => "0:00".
String formatDuration(int milliseconds) {
  if (milliseconds <= 0) return '0:00';
  final int totalSegundos = milliseconds ~/ 1000;
  final int horas = totalSegundos ~/ 3600;
  final int minutos = (totalSegundos % 3600) ~/ 60;
  final int segundos = totalSegundos % 60;
  final String ss = segundos.toString().padLeft(2, '0');
  if (horas > 0) {
    final String mm = minutos.toString().padLeft(2, '0');
    return '$horas:$mm:$ss';
  }
  return '$minutos:$ss';
}

// Formata um pace (segundos por metro) como "M:SS /km" ou "M:SS /mi".
// null, <= 0 ou nao finito => "--:--" com o sufixo da unidade.
String formatPace(double? secondsPerMeter, {bool metric = true}) {
  final String sufixo = metric ? ' /km' : ' /mi';
  if (!_valido(secondsPerMeter) || secondsPerMeter! <= 0) {
    return '$_tracos:$_tracos$sufixo';
  }
  final double unidade = metric ? _metrosPorKm : _metrosPorMilha;
  final int totalSegundos = (secondsPerMeter * unidade).round();
  final int minutos = totalSegundos ~/ 60;
  final int segundos = totalSegundos % 60;
  final String ss = segundos.toString().padLeft(2, '0');
  return '$minutos:$ss$sufixo';
}

// Formata uma velocidade (metros por segundo) como "#.# km/h" ou "#.# mph".
String formatSpeed(double metersPerSecond, {bool metric = true}) {
  final String unidade = metric ? 'km/h' : 'mph';
  if (!_valido(metersPerSecond)) return '$_tracos $unidade';
  final double v = metersPerSecond < 0 ? 0 : metersPerSecond;
  final double convertida =
      metric ? v * 3.6 : v / _metrosPorMilha * 3600.0;
  return '${convertida.toStringAsFixed(1)} $unidade';
}

// Formata uma elevacao em metros como "### m" ou "### ft" (inteiro).
String formatElevation(double meters, {bool metric = true}) {
  final String unidade = metric ? 'm' : 'ft';
  if (!_valido(meters)) return '$_tracos $unidade';
  final double convertida = metric ? meters : meters * _pesPorMetro;
  return '${convertida.round()} $unidade';
}
