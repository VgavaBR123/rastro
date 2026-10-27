// Abstracao de armazenamento das atividades recebidas. Permite testar os
// handlers com um store em memoria, sem precisar do Postgres.
library;

import 'fit_decoder.dart';

/// Tipos de atividade aceitos no header `x-activity-type`.
const Set<String> tiposDeAtividade = <String>{'run', 'ride', 'walk'};

/// Metadados de uma atividade que nao vem do FIT minimo: os opcionais
/// informados pelo app nos headers do upload e os derivados dos timestamps
/// dos records do FIT. Null = sem valor.
class ActivityMetadata {
  final String? activityType;
  final int? startTimeMs;
  final int? elapsedTimeMs;
  final int? timerTimeMs;
  final double? distanceMeters;

  const ActivityMetadata({
    this.activityType,
    this.startTimeMs,
    this.elapsedTimeMs,
    this.timerTimeMs,
    this.distanceMeters,
  });
}

class UploadRecord {
  final String id;

  /// Dono do upload. Nao sai no JSON; a API so devolve uploads do proprio
  /// usuario. Null apenas em uploads antigos (anteriores as contas).
  final String? userId;
  final String status; // received | processed | error
  final int receivedAtMs;
  final int sizeBytes;
  final String? activityGuid;

  /// Pontos com posicao valida lidos do FIT. Null quando a decodificacao
  /// falhou (o arquivo bruto continua guardado e pode ser reprocessado).
  final int? pointCount;

  /// Comprimento da rota em metros. Null quando nao ha rota.
  final double? lengthMeters;

  /// `run` | `ride` | `walk`, ou null quando o app nao informou.
  final String? activityType;

  /// Nome dado pelo usuario (PATCH); null = sem nome.
  final String? name;

  /// Inicio da atividade (header ou 1o record do FIT); null sem nenhum dos dois.
  final int? startTimeMs;

  /// Ultimo menos primeiro timestamp dos records do FIT.
  final int? elapsedTimeMs;

  /// Tempo em movimento informado pelo app.
  final int? timerTimeMs;

  /// Distancia informada pelo app (pode diferir do comprimento da rota).
  final double? distanceMeters;

  const UploadRecord({
    required this.id,
    this.userId,
    required this.status,
    required this.receivedAtMs,
    required this.sizeBytes,
    this.activityGuid,
    this.pointCount,
    this.lengthMeters,
    this.activityType,
    this.name,
    this.startTimeMs,
    this.elapsedTimeMs,
    this.timerTimeMs,
    this.distanceMeters,
  });

  /// Chave de ordenacao da listagem: startTime, senao receivedAt.
  int get sortKey => startTimeMs ?? receivedAtMs;

  /// Distancia que entra nas estatisticas: a do app, senao a da rota.
  double get distanciaEfetiva => distanceMeters ?? lengthMeters ?? 0;

  UploadRecord comNome(String? novoNome) => UploadRecord(
        id: id,
        userId: userId,
        status: status,
        receivedAtMs: receivedAtMs,
        sizeBytes: sizeBytes,
        activityGuid: activityGuid,
        pointCount: pointCount,
        lengthMeters: lengthMeters,
        activityType: activityType,
        name: novoNome,
        startTimeMs: startTimeMs,
        elapsedTimeMs: elapsedTimeMs,
        timerTimeMs: timerTimeMs,
        distanceMeters: distanceMeters,
      );

  /// Objeto `activity` do contrato. Todos os campos sempre presentes (podem
  /// vir null), para o cliente nao precisar distinguir "ausente" de "vazio".
  Map<String, dynamic> toJson() => {
        'id': id,
        'uploadId': id,
        'status': status,
        'receivedAt': receivedAtMs,
        'sizeBytes': sizeBytes,
        'activityGuid': activityGuid,
        'activityType': activityType,
        'name': name,
        'startTime': startTimeMs,
        'elapsedTimeMs': elapsedTimeMs,
        'timerTimeMs': timerTimeMs,
        'distanceMeters': distanceMeters,
        'pointCount': pointCount,
        'lengthMeters': lengthMeters,
      };
}

/// Posicao na listagem paginada: o ultimo item da pagina anterior. A proxima
/// pagina comeca no primeiro item estritamente "depois" dele na ordem
/// (sortKey desc, id desc).
class ActivityCursor {
  final int sortKey;
  final String id;
  const ActivityCursor(this.sortKey, this.id);
}

/// Rota de um upload pronta para virar GeoJSON.
class RouteData {
  /// Geometria GeoJSON: `{"type":"LineString","coordinates":[[lon,lat],...]}`.
  final Map<String, Object?> geometry;

  /// Quantidade de pontos da linha.
  final int pointCount;

  /// Comprimento da linha em metros.
  final double lengthMeters;

  const RouteData({
    required this.geometry,
    required this.pointCount,
    required this.lengthMeters,
  });

  /// Feature GeoJSON completa, no formato que a API devolve.
  Map<String, Object?> toFeatureJson() => {
        'type': 'Feature',
        'geometry': geometry,
        'properties': {
          'pointCount': pointCount,
          'lengthMeters': lengthMeters,
        },
      };
}

/// Contagem e distancia de um tipo de atividade.
class TypeStats {
  final int count;
  final double distanceMeters;
  const TypeStats(this.count, this.distanceMeters);

  Map<String, dynamic> toJson() =>
      {'count': count, 'distanceMeters': distanceMeters};
}

/// Agregados de um usuario para GET /me.
class UserStats {
  final int activityCount;
  final double totalDistanceMeters;
  final int totalTimerTimeMs;

  /// So tipos com atividade; atividades sem tipo nao entram.
  final Map<String, TypeStats> byType;

  const UserStats(this.activityCount, this.totalDistanceMeters,
      {this.totalTimerTimeMs = 0, this.byType = const {}});

  Map<String, dynamic> toJson() => {
        'activityCount': activityCount,
        'totalDistanceMeters': totalDistanceMeters,
        'totalTimerTimeMs': totalTimerTimeMs,
        'byType': {
          for (final e in byType.entries) e.key: e.value.toJson(),
        },
      };
}

/// Todas as leituras sao escopadas por usuario: upload de outro usuario se
/// comporta exatamente como upload inexistente.
abstract class ActivityStore {
  /// Confere se o armazenamento responde. Lanca (ou devolve false) quando nao.
  Future<bool> ping();

  /// Guarda o arquivo FIT recebido e devolve o registro. Se ja existe upload
  /// do mesmo [userId] para o mesmo [activityGuid], nao grava nada e devolve
  /// o existente (com o id dele, diferente de [id]).
  Future<UploadRecord> saveUpload(List<int> fitBytes,
      {required String userId,
      String? activityGuid,
      ActivityMetadata metadata = const ActivityMetadata(),
      required int nowMs,
      required String id});
  Future<UploadRecord?> getUpload(String id, {required String userId});

  /// Upload ja recebido de [userId] para a atividade [activityGuid], se
  /// houver. Base da idempotencia: o app pode reenviar a mesma atividade
  /// (retry, sync manual e de fundo ao mesmo tempo) e o servidor guarda uma
  /// so. O mesmo guid vindo de outro usuario e outra atividade.
  Future<UploadRecord?> findByActivityGuid(String userId, String activityGuid);

  /// Todos os uploads de [userId], na ordem da listagem (mais recente
  /// primeiro por startTime/receivedAt, desempate por id desc).
  Future<List<UploadRecord>> listUploads(String userId);

  /// Ate [limit] uploads de [userId] na ordem da listagem, comecando logo
  /// depois de [after] (null = do inicio).
  Future<List<UploadRecord>> listPage(String userId,
      {required int limit, ActivityCursor? after});

  /// Troca o nome (null = remove). Devolve o registro atualizado ou null se
  /// o upload nao existe (ou e de outro usuario).
  Future<UploadRecord?> updateName(String id,
      {required String userId, String? name});

  /// Apaga o upload. false se nao existe (ou e de outro usuario).
  Future<bool> deleteUpload(String id, {required String userId});

  /// Bytes do FIT original, ou null se o upload nao existe.
  Future<List<int>?> getFit(String id, {required String userId});

  /// Apaga todos os uploads de [userId] (exclusao de conta).
  Future<void> deleteAllForUser(String userId);

  /// Rota do upload [id]. Devolve null quando o upload nao existe (ou e de
  /// outro usuario) OU quando existe mas nao tem rota utilizavel (menos de 2
  /// pontos / FIT ilegivel). Quem chama distingue os casos com [getUpload].
  Future<RouteData?> getRoute(String id, {required String userId});

  /// Agregados dos uploads de [userId].
  Future<UserStats> statsFor(String userId);
}

/// Ordem da listagem: sortKey desc, id desc. Negativo = [a] vem antes.
int compararListagem(UploadRecord a, UploadRecord b) {
  final int c = b.sortKey.compareTo(a.sortKey);
  return c != 0 ? c : b.id.compareTo(a.id);
}

/// Agrega [uploads] no formato de GET /me (mesma regra nos dois stores).
UserStats agregarStats(Iterable<UploadRecord> uploads) {
  var n = 0;
  var total = 0.0;
  var timer = 0;
  final Map<String, TypeStats> porTipo = {};
  for (final UploadRecord r in uploads) {
    n++;
    total += r.distanciaEfetiva;
    timer += r.timerTimeMs ?? 0;
    final String? tipo = r.activityType;
    if (tipo != null) {
      final TypeStats atual = porTipo[tipo] ?? const TypeStats(0, 0.0);
      porTipo[tipo] =
          TypeStats(atual.count + 1, atual.distanceMeters + r.distanciaEfetiva);
    }
  }
  return UserStats(n, total, totalTimerTimeMs: timer, byType: porTipo);
}

/// Decodifica sem lancar: null quando o arquivo nao e um FIT legivel.
List<FitTrackPoint>? decodificarPontos(List<int> bytes) {
  try {
    return decodeFitRecords(bytes);
  } catch (_) {
    return null;
  }
}

/// Implementacao em memoria (testes e dev sem banco).
class InMemoryActivityStore implements ActivityStore {
  final Map<String, UploadRecord> _records = {};
  final Map<String, List<int>> _blobs = {};

  @override
  Future<bool> ping() async => true;

  @override
  Future<UploadRecord> saveUpload(List<int> fitBytes,
      {required String userId,
      String? activityGuid,
      ActivityMetadata metadata = const ActivityMetadata(),
      required int nowMs,
      required String id}) async {
    if (activityGuid != null) {
      final existing = await findByActivityGuid(userId, activityGuid);
      if (existing != null) return existing;
    }
    // Decodifica na entrada apenas para guardar os agregados; os bytes brutos
    // ficam em _blobs e a rota e remontada sob demanda em getRoute.
    final List<FitTrackPoint>? pontos = decodificarPontos(fitBytes);
    final rec = UploadRecord(
      id: id,
      userId: userId,
      status: 'received',
      receivedAtMs: nowMs,
      sizeBytes: fitBytes.length,
      activityGuid: activityGuid,
      pointCount: pontos?.length,
      lengthMeters: (pontos != null && pontos.length >= 2)
          ? comprimentoMetros(pontos)
          : null,
      activityType: metadata.activityType,
      startTimeMs: metadata.startTimeMs,
      elapsedTimeMs: metadata.elapsedTimeMs,
      timerTimeMs: metadata.timerTimeMs,
      distanceMeters: metadata.distanceMeters,
    );
    _records[id] = rec;
    _blobs[id] = List<int>.of(fitBytes);
    return rec;
  }

  @override
  Future<UploadRecord?> getUpload(String id, {required String userId}) async {
    final rec = _records[id];
    return (rec != null && rec.userId == userId) ? rec : null;
  }

  @override
  Future<UploadRecord?> findByActivityGuid(
      String userId, String activityGuid) async {
    for (final rec in _records.values) {
      if (rec.userId == userId && rec.activityGuid == activityGuid) return rec;
    }
    return null;
  }

  @override
  Future<List<UploadRecord>> listUploads(String userId) async =>
      _records.values.where((r) => r.userId == userId).toList()
        ..sort(compararListagem);

  @override
  Future<List<UploadRecord>> listPage(String userId,
      {required int limit, ActivityCursor? after}) async {
    final List<UploadRecord> todos = await listUploads(userId);
    final Iterable<UploadRecord> restantes = after == null
        ? todos
        : todos.where((r) =>
            r.sortKey < after.sortKey ||
            (r.sortKey == after.sortKey && r.id.compareTo(after.id) < 0));
    return restantes.take(limit).toList();
  }

  @override
  Future<UploadRecord?> updateName(String id,
      {required String userId, String? name}) async {
    final UploadRecord? rec = await getUpload(id, userId: userId);
    if (rec == null) return null;
    return _records[id] = rec.comNome(name);
  }

  @override
  Future<bool> deleteUpload(String id, {required String userId}) async {
    if (await getUpload(id, userId: userId) == null) return false;
    _records.remove(id);
    _blobs.remove(id);
    return true;
  }

  @override
  Future<List<int>?> getFit(String id, {required String userId}) async {
    if (await getUpload(id, userId: userId) == null) return null;
    return _blobs[id];
  }

  @override
  Future<void> deleteAllForUser(String userId) async {
    final ids = [
      for (final r in _records.values)
        if (r.userId == userId) r.id
    ];
    for (final String id in ids) {
      _records.remove(id);
      _blobs.remove(id);
    }
  }

  @override
  Future<UserStats> statsFor(String userId) async =>
      agregarStats(await listUploads(userId));

  @override
  Future<RouteData?> getRoute(String id, {required String userId}) async {
    if (await getUpload(id, userId: userId) == null) return null;
    final List<int>? bytes = _blobs[id];
    if (bytes == null) return null;
    final List<FitTrackPoint>? pontos = decodificarPontos(bytes);
    if (pontos == null || pontos.length < 2) return null;
    return RouteData(
      geometry: <String, Object?>{
        'type': 'LineString',
        'coordinates': <List<double>>[
          // GeoJSON usa a ordem [longitude, latitude].
          for (final FitTrackPoint p in pontos)
            <double>[p.longitude, p.latitude],
        ],
      },
      pointCount: pontos.length,
      lengthMeters: comprimentoMetros(pontos),
    );
  }
}
