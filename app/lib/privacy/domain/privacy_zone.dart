/// Zona de privacidade (F02): um circulo (centro + raio) guardado so no
/// aparelho. O que comeca ou termina dentro dele sai cortado da imagem
/// compartilhada, do upload e da exportacao. Dart puro.
library;

import '../../recording/domain/geo.dart';

class PrivacyZone {
  /// Id no banco; null antes de salvar.
  final int? id;
  final double latitude;
  final double longitude;
  final double radiusMeters;

  /// Nome dado pela pessoa ("Casa", "Trabalho"...).
  final String label;

  const PrivacyZone({
    this.id,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.label,
  });

  GeoPoint get center => GeoPoint(latitude: latitude, longitude: longitude);

  /// Se [p] esta dentro da zona, usando [radiusMeters] ou o raio informado.
  bool contains(GeoPoint p, {double? radiusMeters}) =>
      haversineMeters(center, p) <= (radiusMeters ?? this.radiusMeters);

  @override
  String toString() =>
      'PrivacyZone($label, $latitude, $longitude, $radiusMeters m)';
}
