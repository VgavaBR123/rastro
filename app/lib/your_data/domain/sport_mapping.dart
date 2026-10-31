/// Tipo de atividade dos arquivos importados (F07). Dart puro.
///
/// O nome do esporte vem do activities.csv da exportacao de conta, do `type`
/// do GPX, do `Sport` do TCX ou do enum do FIT. Comparamos sem caixa, sem
/// acento, sem espacos e sem pontuacao. Corrida, pedal e caminhada (com
/// trilha) entram; os outros sao ignorados e contados pelo rotulo.
library;

import '../../recording/domain/recording_models.dart';

/// Resultado da leitura do esporte.
class SportMatch {
  /// Tipo nosso; null para outro esporte ou desconhecido.
  final ActivityType? type;

  /// Rotulo do esporte ignorado ("natacao"); null quando nao e "outro".
  final String? otherLabel;

  /// O nome esta nas nossas tabelas (dos 3 esportes ou dos "outros"
  /// conhecidos). False em [SportMatch.unlisted]: nome que nao conhecemos.
  final bool listed;

  const SportMatch.known(ActivityType this.type) : otherLabel = null, listed = true;
  const SportMatch.other(String this.otherLabel) : type = null, listed = true;

  /// Nome fora das tabelas. No CSV, quem decide e o esporte do arquivo.
  const SportMatch.unlisted(String this.otherLabel) : type = null, listed = false;
  const SportMatch.unknown() : type = null, otherLabel = null, listed = true;

  bool get isUnknown => type == null && otherLabel == null;

  @override
  bool operator ==(Object other) =>
      other is SportMatch &&
      other.type == type &&
      other.otherLabel == otherLabel &&
      other.listed == listed;

  @override
  int get hashCode => Object.hash(type, otherLabel, listed);

  @override
  String toString() => 'SportMatch(${type ?? otherLabel ?? 'desconhecido'})';
}

const Set<String> _run = {
  'run', 'running', 'trailrun', 'trailrunning', 'virtualrun', 'treadmill',
  'treadmillrunning', 'indoorrunning', 'streetrunning', 'trackrunning',
  'corrida', 'corridaderua', 'corridaemtrilha', 'esteira',
  // Exportacao de conta em portugues.
  'corridavirtual', 'corridanaesteira', 'corridaindoor',
};

const Set<String> _ride = {
  'ride', 'cycling', 'biking', 'bike', 'virtualride', 'ebikeride', 'ebiking',
  'mountainbikeride', 'emountainbikeride', 'gravelride', 'roadbiking',
  'roadcycling', 'mountainbiking', 'indoorcycling', 'velomobile', 'handcycle',
  'pedal', 'ciclismo', 'bicicleta',
  // Exportacao de conta em portugues.
  'pedalada', 'pedaladavirtual', 'pedaladaeletrica', 'pedaladademountainbike',
  'pedaladademountainbikeeletrica', 'pedaladaemcascalho', 'pedaladaindoor',
  'bicicletaeletrica', 'ebike', 'mountainbike', 'ciclismovirtual',
  'ciclismoindoor', 'handbike', 'velomovel',
};

const Set<String> _walk = {
  'walk', 'walking', 'hike', 'hiking', 'caminhada', 'trilha', 'trekking',
  'speedwalking',
  // Exportacao de conta em portugues.
  'caminhadavirtual', 'caminhadarapida', 'caminhadanaesteira',
};

const Set<String> _unknown = {'', 'other', 'generic', 'outro', 'outros', 'unknown'};

const Map<String, String> _otherLabels = {
  'swim': 'natacao', 'swimming': 'natacao', 'openwaterswimming': 'natacao',
  'lapswimming': 'natacao', 'natacao': 'natacao',
  'yoga': 'ioga', 'weighttraining': 'musculacao', 'strengthtraining': 'musculacao',
  'workout': 'treino', 'training': 'treino', 'crossfit': 'crossfit',
  'rowing': 'remo', 'virtualrow': 'remo',
  'alpineski': 'esqui', 'backcountryski': 'esqui', 'nordicski': 'esqui',
  'alpineskiing': 'esqui', 'crosscountryskiing': 'esqui',
  'snowboard': 'snowboard', 'snowboarding': 'snowboard',
  'kayaking': 'canoagem', 'canoeing': 'canoagem', 'paddling': 'canoagem',
  'standuppaddling': 'stand up paddle', 'surfing': 'surfe', 'kitesurf': 'kitesurf',
  'elliptical': 'eliptico', 'stairstepper': 'escada', 'tennis': 'tenis',
  'soccer': 'futebol', 'iceskate': 'patinacao', 'inlineskate': 'patins',
  'rockclimbing': 'escalada', 'golf': 'golfe',
  // Exportacao de conta em portugues.
  'natacaoemaguasabertas': 'natacao', 'ioga': 'ioga', 'musculacao': 'musculacao',
  'treinocompesos': 'musculacao', 'treinamentodeforca': 'musculacao',
  'treino': 'treino', 'remo': 'remo', 'removirtual': 'remo',
  'esqui': 'esqui', 'esquialpino': 'esqui', 'esquinordico': 'esqui',
  'esquidefundo': 'esqui', 'esquicrosscountry': 'esqui', 'esquibackcountry': 'esqui',
  'canoagem': 'canoagem', 'caiaque': 'canoagem', 'standuppaddle': 'stand up paddle',
  'surfe': 'surfe', 'windsurf': 'windsurf', 'eliptico': 'eliptico', 'escada': 'escada',
  'tenis': 'tenis', 'futebol': 'futebol', 'patinacao': 'patinacao',
  'patinacaonogelo': 'patinacao', 'patins': 'patins', 'escalada': 'escalada',
  'golfe': 'golfe',
};

final RegExp _digitsOnly = RegExp(r'^\d+$');
final RegExp _sportCode = RegExp(r'^sport\d+$');
final RegExp _alnum = RegExp(r'[a-z0-9]');

/// Letras acentuadas do portugues e o equivalente sem acento.
const String _accented = 'áàâãäéèê'
    'ëíìîïóòôõöúù'
    'ûüç';
const String _plain = 'aaaaaeeeeiiiiooooouuuuc';

String _normalize(String s) {
  final b = StringBuffer();
  for (final ch in s.toLowerCase().split('')) {
    final i = _accented.indexOf(ch);
    final c = i >= 0 ? _plain[i] : ch;
    if (_alnum.hasMatch(c)) b.write(c);
  }
  return b.toString();
}

/// Le o esporte [raw] do arquivo ou do CSV.
SportMatch matchSport(String? raw) {
  if (raw == null) return const SportMatch.unknown();
  final key = _normalize(raw);
  if (_unknown.contains(key) || _digitsOnly.hasMatch(key)) {
    return const SportMatch.unknown();
  }
  if (_run.contains(key)) return const SportMatch.known(ActivityType.run);
  if (_ride.contains(key)) return const SportMatch.known(ActivityType.ride);
  if (_walk.contains(key)) return const SportMatch.known(ActivityType.walk);
  final label = _otherLabels[key];
  if (label != null) return SportMatch.other(label);
  if (_sportCode.hasMatch(key)) return const SportMatch.other('outros');
  return SportMatch.unlisted(raw.trim().toLowerCase());
}

/// Velocidade media em movimento (m/s) abaixo da qual a atividade sem tipo
/// vira caminhada (~6,8 km/h).
const double kWalkMaxSpeedMps = 1.9;

/// Acima desta (~16,2 km/h), pedal.
const double kRunMaxSpeedMps = 4.5;

/// Tipo de uma atividade cujo arquivo nao diz o esporte, pelo ritmo medio.
ActivityType inferSportFromSpeed(double movingSpeedMps) {
  if (movingSpeedMps < kWalkMaxSpeedMps) return ActivityType.walk;
  if (movingSpeedMps > kRunMaxSpeedMps) return ActivityType.ride;
  return ActivityType.run;
}
