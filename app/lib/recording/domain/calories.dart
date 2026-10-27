/// Estimativa de calorias de uma atividade (relatorio 05: o cabecalho guarda
/// calorias).
///
/// Metodo: equivalente metabolico (MET). kcal = MET x peso_kg x horas, com o
/// MET escolhido pela velocidade media no tempo de movimento (timerTime, que
/// ja exclui as pausas).
///
/// Fonte dos MET: Compendium of Physical Activities (Ainsworth BE et al.,
/// "2011 Compendium of Physical Activities: a second update of codes and MET
/// values", Med Sci Sports Exerc 43(8):1575-1581; tabelas publicas em
/// https://pacompendium.com). Grupos usados: running, walking e bicycling
/// (os rotulos de cada linha resumem a descricao da atividade). As tabelas sao em mph; aqui ficam em mph
/// tambem, para conferencia direta com a fonte.
///
/// Entre dois pontos da tabela o MET e interpolado linearmente na velocidade
/// (evita degraus bruscos: 0,1 km/h a mais nao muda a conta em 10%). Abaixo do
/// primeiro ponto e acima do ultimo, o valor e travado no extremo. Faixas do
/// Compendium (ex.: pedal "12-13.9 mph") viram um ponto no meio da faixa.
///
/// Limitacao conhecida: MET e media populacional; ignora relevo, vento, idade,
/// sexo e frequencia cardiaca. E uma estimativa de ordem de grandeza.
library;

import 'recording_models.dart';

/// Ponto da tabela: velocidade (mph) -> MET.
class _MetPoint {
  final double mph;
  final double met;
  const _MetPoint(this.mph, this.met);
}

/// Corrida (Compendium 2011, running).
const List<_MetPoint> _runTable = [
  _MetPoint(4.0, 6.0), // 4 mph (15 min/mi)
  _MetPoint(5.0, 8.3), // 5 mph (12 min/mi)
  _MetPoint(5.2, 9.0), // 5.2 mph (11.5 min/mi)
  _MetPoint(6.0, 9.8), // 6 mph (10 min/mi)
  _MetPoint(6.7, 10.5), // 6.7 mph (9 min/mi)
  _MetPoint(7.0, 11.0), // 7 mph (8.5 min/mi)
  _MetPoint(7.5, 11.5), // 7.5 mph (8 min/mi)
  _MetPoint(8.0, 11.8), // 8 mph (7.5 min/mi)
  _MetPoint(8.6, 12.3), // 8.6 mph (7 min/mi)
  _MetPoint(9.0, 12.8), // 9 mph (6.5 min/mi)
  _MetPoint(10.0, 14.5), // 10 mph (6 min/mi)
  _MetPoint(11.0, 16.0), // 11 mph (5.5 min/mi)
  _MetPoint(12.0, 19.0), // 12 mph (5 min/mi)
  _MetPoint(13.0, 19.8), // 13 mph (4.6 min/mi)
  _MetPoint(14.0, 23.0), // 14 mph (4.3 min/mi)
];

/// Caminhada (Compendium 2011, walking, chao plano e firme).
const List<_MetPoint> _walkTable = [
  _MetPoint(1.5, 2.0), // < 2.0 mph, muito devagar (ponto em 1.5)
  _MetPoint(2.0, 2.8), // 2.0 mph
  _MetPoint(2.5, 3.0), // 2.5 mph
  _MetPoint(3.0, 3.5), // 2.8-3.2 mph, moderado (ponto em 3.0)
  _MetPoint(3.5, 4.3), // 3.5 mph, rapido
  _MetPoint(4.0, 5.0), // 4.0 mph, muito rapido
  _MetPoint(4.5, 7.0), // 4.5 mph
  _MetPoint(5.0, 8.3), // 5.0 mph
];

/// Pedal (Compendium 2011, bicycling, estrada).
const List<_MetPoint> _rideTable = [
  _MetPoint(5.5, 3.5), // 5.5 mph, lazer
  _MetPoint(11.0, 6.8), // 10-11.9 mph, lazer/leve (meio da faixa)
  _MetPoint(13.0, 8.0), // 12-13.9 mph, moderado
  _MetPoint(15.0, 10.0), // 14-15.9 mph, vigoroso
  _MetPoint(17.5, 12.0), // 16-19 mph, muito rapido
  _MetPoint(20.0, 15.8), // > 20 mph, competicao (ponto em 20)
];

const double _metersPerMile = 1609.344;

List<_MetPoint> _tableFor(ActivityType type) {
  switch (type) {
    case ActivityType.run:
      return _runTable;
    case ActivityType.walk:
      return _walkTable;
    case ActivityType.ride:
      return _rideTable;
  }
}

/// MET para a velocidade [mph], interpolado na tabela e travado nos extremos.
double _metAt(List<_MetPoint> table, double mph) {
  if (mph <= table.first.mph) return table.first.met;
  if (mph >= table.last.mph) return table.last.met;
  for (int i = 1; i < table.length; i++) {
    final _MetPoint b = table[i];
    if (mph <= b.mph) {
      final _MetPoint a = table[i - 1];
      final double f = (mph - a.mph) / (b.mph - a.mph);
      return a.met + f * (b.met - a.met);
    }
  }
  return table.last.met; // inalcancavel
}

/// Kcal estimadas, ou null quando nao da para estimar (sem peso, sem tempo).
///
/// - null se [weightKg] for null ou fora de 20..400 kg, ou [timerTimeMs] <= 0;
/// - distancia <= 0 (ou invalida) com tempo > 0 usa o MET mais baixo do
///   esporte (esteira sem GPS, atividade parada).
double? estimateCaloriesKcal({
  required ActivityType type,
  required int timerTimeMs,
  required double distanceMeters,
  required double? weightKg,
}) {
  final double? kg = weightKg;
  if (kg == null || kg.isNaN || kg < 20 || kg > 400) return null;
  if (timerTimeMs <= 0) return null;

  final double hours = timerTimeMs / 3600000.0;
  final List<_MetPoint> table = _tableFor(type);
  final double met;
  if (!distanceMeters.isFinite || distanceMeters <= 0) {
    met = table.first.met;
  } else {
    final double mph = (distanceMeters / _metersPerMile) / hours;
    met = _metAt(table, mph);
  }
  return met * kg * hours;
}
