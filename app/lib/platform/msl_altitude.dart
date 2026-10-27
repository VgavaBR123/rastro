/// Altitude acima do nivel medio do mar (MSL). O GPS do Android entrega a
/// altitude sobre o elipsoide WGS84; relatorio 03 decide usar o conversor de
/// altitude MSL da AndroidX, com fallback para a altitude crua. CONTRATO fixo;
/// a ponte nativa (MethodChannel) esta em andamento.
library;

abstract class MslAltitudeConverter {
  /// Altitude MSL em metros, ou null quando nao foi possivel converter (sem
  /// dados do modelo, plataforma sem suporte). Nunca lanca.
  Future<double?> toMsl({
    required double latitude,
    required double longitude,
    required double ellipsoidAltitudeMeters,
  });
}

/// Sem conversao (testes, plataformas sem suporte): sempre null.
class NoMslAltitudeConverter implements MslAltitudeConverter {
  const NoMslAltitudeConverter();

  @override
  Future<double?> toMsl({
    required double latitude,
    required double longitude,
    required double ellipsoidAltitudeMeters,
  }) async =>
      null;
}
