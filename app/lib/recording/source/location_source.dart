// Interface da borda de localizacao que alimenta o pipeline de gravacao.
//
// Clean room a partir de relatorios/03-gravacao-gps.md e 99-proposta-app.md:
// a captura de localizacao e especifica de plataforma (FGS no Android, Core
// Location no iOS), mas e exposta ao nucleo Dart por uma interface fina. O
// nucleo consome apenas um Stream de LocationSample; toda a matematica (filtro,
// metricas) acontece em Dart sobre esse fluxo.
library;

import 'package:strava_estudo_app/recording/domain/location_sample.dart';

/// Fonte de amostras de localizacao para a gravacao.
///
/// Implementacoes embrulham o provedor nativo (ver
/// [GeolocatorLocationSource]) e entregam amostras ja normalizadas para o
/// modelo de dominio, sem vazar tipos do plugin para o nucleo.
abstract class LocationSource {
  /// Solicita/verifica a permissao de localizacao.
  ///
  /// Retorna true somente quando ha permissao suficiente para gravar
  /// (whileInUse ou always) e o servico de localizacao esta habilitado.
  Future<bool> ensurePermission();

  /// Stream continuo de amostras de localizacao.
  ///
  /// Configurado para alta precisao, intervalo alvo de 1 s e deslocamento
  /// minimo 0 (filtrar e decisao do nosso pipeline, nao do provedor).
  Stream<LocationSample> positions();

  /// Encerra a captura e libera recursos (cancela a subscription interna).
  Future<void> stop();
}
