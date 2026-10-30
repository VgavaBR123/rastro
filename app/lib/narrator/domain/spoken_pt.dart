// Numeros e medidas por extenso em portugues do Brasil, para o Narrador (F03).
//
// Dart puro e deterministico. O texto e para ser FALADO pelo TTS, por isso usa
// acentos ("quilômetro", "vírgula"): sem eles a voz erra a pronuncia. As
// telas continuam sem acento, como o resto do app.
library;

const double _metersPerKm = 1000.0;
const double _metersPerMile = 1609.344;

const List<String> _units = [
  'zero', 'um', 'dois', 'três', 'quatro', 'cinco', 'seis', 'sete', 'oito',
  'nove', 'dez', 'onze', 'doze', 'treze', 'quatorze', 'quinze', 'dezesseis',
  'dezessete', 'dezoito', 'dezenove',
];

const List<String> _tens = [
  '', '', 'vinte', 'trinta', 'quarenta', 'cinquenta', 'sessenta', 'setenta',
  'oitenta', 'noventa',
];

const List<String> _hundreds = [
  '', 'cento', 'duzentos', 'trezentos', 'quatrocentos', 'quinhentos',
  'seiscentos', 'setecentos', 'oitocentos', 'novecentos',
];

/// Inteiro por extenso ("trinta e dois", "mil duzentos e trinta e quatro").
/// Com [feminine], "uma", "duas", "duzentas" (para horas e milhas).
/// Negativos viram "zero".
String numberWords(int n, {bool feminine = false}) {
  if (n <= 0) return 'zero';
  final words = n >= 1000000
      ? n.toString() // fora do uso do narrador; nao inventa extenso
      : _upToMillion(n, feminine);
  return words;
}

String _upToMillion(int n, bool feminine) {
  final thousands = n ~/ 1000;
  final rest = n % 1000;
  if (thousands == 0) return _upToThousand(rest, feminine);
  final head = thousands == 1 ? 'mil' : '${_upToThousand(thousands, feminine)} mil';
  if (rest == 0) return head;
  // "mil e um", "mil e cem", "mil e quinhentos", mas "mil duzentos e trinta".
  final joiner = (rest < 100 || rest % 100 == 0) ? ' e ' : ' ';
  return '$head$joiner${_upToThousand(rest, feminine)}';
}

String _upToThousand(int n, bool feminine) {
  if (n == 100) return 'cem';
  final h = n ~/ 100;
  final rest = n % 100;
  final parts = <String>[];
  if (h > 0) {
    var word = _hundreds[h];
    if (feminine && h > 1) word = word.replaceAll('entos', 'entas');
    parts.add(word);
  }
  if (rest > 0) parts.add(_upToHundred(rest, feminine));
  return parts.join(' e ');
}

String _upToHundred(int n, bool feminine) {
  if (n < 20) return _unit(n, feminine);
  final t = n ~/ 10;
  final u = n % 10;
  if (u == 0) return _tens[t];
  return '${_tens[t]} e ${_unit(u, feminine)}';
}

String _unit(int n, bool feminine) {
  if (feminine && n == 1) return 'uma';
  if (feminine && n == 2) return 'duas';
  return _units[n];
}

String _countOf(int n, String singular, String plural, {bool feminine = false}) =>
    '${numberWords(n, feminine: feminine)} ${n == 1 ? singular : plural}';

/// Duracao falada: "cinco minutos e trinta e dois segundos",
/// "uma hora, dois minutos e cinco segundos". Partes zeradas somem.
String spokenDuration(int milliseconds) {
  final total = milliseconds <= 0 ? 0 : milliseconds ~/ 1000;
  if (total == 0) return 'zero segundos';
  final h = total ~/ 3600;
  final m = (total % 3600) ~/ 60;
  final s = total % 60;
  final parts = [
    if (h > 0) _countOf(h, 'hora', 'horas', feminine: true),
    if (m > 0) _countOf(m, 'minuto', 'minutos'),
    if (s > 0) _countOf(s, 'segundo', 'segundos'),
  ];
  return _joinList(parts);
}

/// "a", "a e b", "a, b e c".
String _joinList(List<String> parts) {
  if (parts.length == 1) return parts.first;
  return '${parts.sublist(0, parts.length - 1).join(', ')} e ${parts.last}';
}

/// Pace falado ("cinco e trinta e dois" = 5:32 por unidade). Null quando nao
/// ha pace que valha a pena falar (sem distancia, ou 60 min por unidade ou mais).
String? spokenPace(double? secondsPerMeter, {required bool metric}) {
  if (secondsPerMeter == null || !secondsPerMeter.isFinite || secondsPerMeter <= 0) {
    return null;
  }
  final total = (secondsPerMeter * (metric ? _metersPerKm : _metersPerMile)).round();
  final m = total ~/ 60;
  final s = total % 60;
  if (m >= 60) return null;
  if (m == 0) return _countOf(s, 'segundo', 'segundos');
  if (s == 0) return _countOf(m, 'minuto', 'minutos');
  return '${numberWords(m)} e ${numberWords(s)}';
}

/// Distancia falada. Metrico: metros abaixo de 1 km, depois quilometros com
/// ate duas casas ("três vírgula vinte e cinco quilômetros"). Imperial: milhas.
String spokenDistance(double meters, {required bool metric}) {
  final m = meters.isFinite && meters > 0 ? meters : 0.0;
  if (metric && m < _metersPerKm) {
    final r = m.round();
    return _countOf(r, 'metro', 'metros');
  }
  final value = m / (metric ? _metersPerKm : _metersPerMile);
  final feminine = !metric;
  final unitSingular = metric ? 'quilômetro' : 'milha';
  final unitPlural = metric ? 'quilômetros' : 'milhas';
  final fixed = value.toStringAsFixed(2);
  final dot = fixed.indexOf('.');
  final whole = int.parse(fixed.substring(0, dot));
  var decimals = fixed.substring(dot + 1);
  while (decimals.endsWith('0')) {
    decimals = decimals.substring(0, decimals.length - 1);
  }
  final wholeWords = numberWords(whole, feminine: feminine);
  if (decimals.isEmpty) {
    return '$wholeWords ${whole == 1 ? unitSingular : unitPlural}';
  }
  return '$wholeWords vírgula ${_decimalWords(decimals)} $unitPlural';
}

/// "25" -> "vinte e cinco"; "05" -> "zero cinco"; "5" -> "cinco".
String _decimalWords(String digits) {
  if (digits.startsWith('0')) {
    return 'zero ${numberWords(int.parse(digits.substring(1)))}';
  }
  return numberWords(int.parse(digits));
}

/// Marca do split, com maiuscula, para abrir a frase: "Um quilômetro",
/// "Duas milhas".
String spokenSplitMark(int number, {required bool metric}) {
  final text = metric
      ? _countOf(number, 'quilômetro', 'quilômetros')
      : _countOf(number, 'milha', 'milhas', feminine: true);
  return capitalize(text);
}

/// Velocidade falada com uma casa ("vinte e cinco vírgula três quilômetros por
/// hora"). Null sem velocidade.
String? spokenSpeed(double metersPerSecond, {required bool metric}) {
  if (!metersPerSecond.isFinite || metersPerSecond <= 0) return null;
  final value = metric ? metersPerSecond * 3.6 : metersPerSecond / _metersPerMile * 3600;
  final fixed = value.toStringAsFixed(1);
  final dot = fixed.indexOf('.');
  final whole = int.parse(fixed.substring(0, dot));
  final decimal = fixed.substring(dot + 1);
  final unit = metric ? 'quilômetros por hora' : 'milhas por hora';
  final wholeWords = numberWords(whole, feminine: !metric);
  if (decimal == '0') return '$wholeWords $unit';
  return '$wholeWords vírgula ${numberWords(int.parse(decimal))} $unit';
}

/// Primeira letra maiuscula.
String capitalize(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
