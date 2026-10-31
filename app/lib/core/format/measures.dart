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

/// Numero com [casas] decimais e virgula como separador, o padrao pt-BR
/// ("5,23", "12,4"). Base de todos os formatadores com decimal (INI-04).
String formatDecimal(double v, int casas) =>
    v.toStringAsFixed(casas).replaceAll('.', ',');

// Abaixo disto o imperial mostra pes, como o metrico mostra metros abaixo
// de 1 km (EST-05).
const double _milhasMinimas = 0.1;

// Formata uma distancia em metros.
// Metrico: "### m" (abaixo de 1000 m) ou "#,## km".
// Imperial: "### ft" (abaixo de 0,1 mi) ou "#,## mi".
String formatDistance(double meters, {bool metric = true}) {
  if (!_valido(meters)) return metric ? '$_tracos m' : '$_tracos mi';
  final double m = meters < 0 ? 0 : meters;
  if (metric) {
    if (m < _metrosPorKm) {
      return '${m.round()} m';
    }
    final double km = m / _metrosPorKm;
    return '${formatDecimal(km, 2)} km';
  }
  final double mi = m / _metrosPorMilha;
  if (mi < _milhasMinimas) {
    return '${(m * _pesPorMetro).round()} ft';
  }
  return '${formatDecimal(mi, 2)} mi';
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

/// Duracao de um total (soma do periodo, maior semana), onde nao ha contexto
/// de cronometro e "0:06" seria ambiguo (EST-04). Sempre com unidade:
/// "6 s" abaixo de 1 min, "6 min" abaixo de 1 h (minutos inteiros) e
/// "1:05 h" dai para cima. Valores <= 0 => "0 min".
String formatTotalDuration(int milliseconds) {
  if (milliseconds <= 0) return '0 min';
  final int totalSegundos = milliseconds ~/ 1000;
  if (totalSegundos < 60) return '$totalSegundos s';
  final int horas = totalSegundos ~/ 3600;
  final int minutos = (totalSegundos % 3600) ~/ 60;
  if (horas == 0) return '$minutos min';
  return '$horas:${minutos.toString().padLeft(2, '0')} h';
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

// Formata uma velocidade (metros por segundo) como "#,# km/h" ou "#,# mph".
String formatSpeed(double metersPerSecond, {bool metric = true}) {
  final String unidade = metric ? 'km/h' : 'mph';
  if (!_valido(metersPerSecond)) return '$_tracos $unidade';
  final double v = metersPerSecond < 0 ? 0 : metersPerSecond;
  final double convertida = metric ? v * 3.6 : v / _metrosPorMilha * 3600.0;
  return '${formatDecimal(convertida, 1)} $unidade';
}

// Formata uma elevacao em metros como "### m" ou "### ft" (inteiro).
String formatElevation(double meters, {bool metric = true}) {
  final String unidade = metric ? 'm' : 'ft';
  if (!_valido(meters)) return '$_tracos $unidade';
  final double convertida = metric ? meters : meters * _pesPorMetro;
  return '${convertida.round()} $unidade';
}

/// Separa "12,50 km" em ("12,50", "km") no ultimo espaco. Sem espaco
/// (ex.: "1:02:03"), a unidade sai null.
(String, String?) splitMeasure(String formatted) {
  final i = formatted.lastIndexOf(' ');
  if (i <= 0) return (formatted, null);
  return (formatted.substring(0, i), formatted.substring(i + 1));
}

// Palavras para o leitor de tela, (singular, plural) por abreviacao.
const Map<String, (String, String)> _unidadesFaladas = {
  'm': ('metro', 'metros'),
  'km': ('quilometro', 'quilometros'),
  'mi': ('milha', 'milhas'),
  'ft': ('pe', 'pes'),
  'km/h': ('quilometro por hora', 'quilometros por hora'),
  'mph': ('milha por hora', 'milhas por hora'),
  '/km': ('por quilometro', 'por quilometro'),
  '/mi': ('por milha', 'por milha'),
  's': ('segundo', 'segundos'),
  'min': ('minuto', 'minutos'),
};

String _plural(int n, String um, String varios) =>
    n == 1 ? '$n $um' : '$n $varios';

/// Versao falada de um valor formatado, para Semantics: "12,4 km" vira
/// "12,4 quilometros" e "1:05 h" vira "1 hora e 5 minutos". Sem unidade
/// conhecida, devolve o texto como veio.
String spokenMeasure(String formatted) {
  final (valor, unidade) = splitMeasure(formatted);
  if (unidade == null) return formatted;
  if (unidade == 'h') {
    final partes = valor.split(':');
    final h = int.tryParse(partes.first);
    final min = partes.length > 1 ? int.tryParse(partes[1]) : 0;
    if (h == null || min == null) return formatted;
    final horas = _plural(h, 'hora', 'horas');
    return min == 0 ? horas : '$horas e ${_plural(min, 'minuto', 'minutos')}';
  }
  final palavras = _unidadesFaladas[unidade];
  if (palavras == null) return formatted;
  return '$valor ${valor == '1' ? palavras.$1 : palavras.$2}';
}
