// Armazenamento do Rastro Seguro (F08): contatos de confianca, sessoes,
// caixa de entrada de notificacoes e tokens de push. Mesmo padrao dos outros
// stores: interface + implementacao em memoria (testes e USE_INMEMORY=1); a
// versao Postgres fica em postgres_safety_store.dart.
//
// Posicoes: o vigia so precisa da ultima posicao e de saber desde quando as
// amostras vem paradas (sem pausa). Por isso a sessao guarda so isso
// (lastPosition e stillSinceMs) e nenhum historico de trajeto e mantido.
library;

/// Convite/relacao de contato de confianca. [ownerId] e a dona (quem
/// convidou); [contactUserId] e quem foi convidado e, depois de aceitar,
/// recebe os alertas dela.
class ContactRecord {
  ContactRecord({
    required this.id,
    required this.ownerId,
    required this.contactUserId,
    required this.status,
    required this.createdAtMs,
    this.acceptedAtMs,
  });

  final String id;
  final String ownerId;
  final String contactUserId;

  /// `pending` | `accepted`.
  String status;
  final int createdAtMs;
  int? acceptedAtMs;

  bool get accepted => status == 'accepted';

  ContactRecord copy() => ContactRecord(
        id: id,
        ownerId: ownerId,
        contactUserId: contactUserId,
        status: status,
        createdAtMs: createdAtMs,
        acceptedAtMs: acceptedAtMs,
      );
}

/// Ultima posicao conhecida da dona.
class SafetyPosition {
  const SafetyPosition({
    required this.lat,
    required this.lon,
    this.accuracyM,
    required this.recordedAtMs,
  });

  final double lat;
  final double lon;
  final double? accuracyM;
  final int recordedAtMs;

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lon': lon,
        'accuracyM': accuracyM,
        'recordedAtMs': recordedAtMs,
      };
}

/// Sessao do Rastro Seguro. Mutavel de proposito: o servico carrega, altera e
/// salva sob a trava da sessao (ver SafetyService). Os stores devolvem copias.
class SafetySessionRecord {
  SafetySessionRecord({
    required this.id,
    required this.ownerId,
    required this.activityGuid,
    required this.status,
    required this.etaMs,
    required this.startedAtMs,
    required this.lastSignalAtMs,
    required this.contactIds,
    required this.shareToken,
    this.endedAtMs,
    this.endReason,
    this.lastPosition,
    this.stillSinceMs,
    this.checkReason,
    this.checkStartedAtMs,
    this.checkDeadlineMs,
    this.alertedAtMs,
    this.etaRecheckAfterMs,
    this.shareExpiresAtMs,
  });

  final String id;
  final String ownerId;
  final String activityGuid;

  /// `active` | `checking` | `alerted` | `ended`.
  String status;
  int etaMs;
  final int startedAtMs;
  int? endedAtMs;

  /// `arrived` (a dona confirmou) | `expired` (fim automatico em eta + 6 h).
  String? endReason;
  int lastSignalAtMs;
  SafetyPosition? lastPosition;

  /// Instante (relogio do servidor) da primeira amostra de uma sequencia
  /// ininterrupta com moving=false e paused=false. Null = nao esta parada.
  int? stillSinceMs;
  List<String> contactIds;

  /// `silence` | `stopped` | `eta` enquanto houver checagem.
  String? checkReason;
  int? checkStartedAtMs;
  int? checkDeadlineMs;
  int? alertedAtMs;

  /// Depois de um `ok` com o horario ja vencido, a regra do horario so volta
  /// a perguntar a partir daqui (senao perguntaria de novo no tick seguinte).
  int? etaRecheckAfterMs;

  /// Token do link publico (32 bytes aleatorios em base64url).
  final String shareToken;

  /// Null = o link vale enquanto a sessao existir (some na limpeza de 24 h).
  int? shareExpiresAtMs;

  bool get ended => status == 'ended';

  void clearCheck() {
    checkReason = null;
    checkStartedAtMs = null;
    checkDeadlineMs = null;
  }

  SafetySessionRecord copy() => SafetySessionRecord(
        id: id,
        ownerId: ownerId,
        activityGuid: activityGuid,
        status: status,
        etaMs: etaMs,
        startedAtMs: startedAtMs,
        lastSignalAtMs: lastSignalAtMs,
        contactIds: List<String>.of(contactIds),
        shareToken: shareToken,
        endedAtMs: endedAtMs,
        endReason: endReason,
        lastPosition: lastPosition,
        stillSinceMs: stillSinceMs,
        checkReason: checkReason,
        checkStartedAtMs: checkStartedAtMs,
        checkDeadlineMs: checkDeadlineMs,
        alertedAtMs: alertedAtMs,
        etaRecheckAfterMs: etaRecheckAfterMs,
        shareExpiresAtMs: shareExpiresAtMs,
      );
}

class NotificationRecord {
  NotificationRecord({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.createdAtMs,
    this.readAtMs,
  });

  final String id;
  final String userId;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final int createdAtMs;
  int? readAtMs;

  NotificationRecord copy() => NotificationRecord(
        id: id,
        userId: userId,
        type: type,
        title: title,
        body: body,
        data: Map<String, dynamic>.of(data),
        createdAtMs: createdAtMs,
        readAtMs: readAtMs,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'title': title,
        'body': body,
        'data': data,
        'createdAt': createdAtMs,
        'readAt': readAtMs,
      };
}

class PushTokenRecord {
  const PushTokenRecord({
    required this.token,
    required this.userId,
    required this.platform,
    required this.updatedAtMs,
  });

  final String token;
  final String userId;

  /// `android` | `ios`.
  final String platform;
  final int updatedAtMs;
}

abstract class SafetyStore {
  // Contatos.

  /// Null se ja existe convite de [ContactRecord.ownerId] para
  /// [ContactRecord.contactUserId] (o chamador responde 409).
  Future<ContactRecord?> createContact(ContactRecord c);
  Future<ContactRecord?> findContact(String id);

  /// Contatos em que [userId] e a dona ou a convidada.
  Future<List<ContactRecord>> contactsOfUser(String userId);
  Future<int> countAcceptedContacts(String ownerId);
  Future<void> saveContact(ContactRecord c);
  Future<void> deleteContact(String id);

  // Sessoes.

  /// Null se a dona ja tem sessao nao encerrada (o chamador responde 409).
  Future<SafetySessionRecord?> createSession(SafetySessionRecord s);
  Future<SafetySessionRecord?> findSession(String id);
  Future<SafetySessionRecord?> findOpenSessionOfOwner(String ownerId);
  Future<SafetySessionRecord?> findSessionByShareToken(String token);

  /// Sessoes com status diferente de `ended` (o vigia percorre estas).
  Future<List<SafetySessionRecord>> openSessions();
  Future<void> saveSession(SafetySessionRecord s);

  /// Apaga as sessoes encerradas antes de [ms] (LGPD); devolve quantas.
  Future<int> deleteSessionsEndedBefore(int ms);

  // Notificacoes.

  Future<void> addNotification(NotificationRecord n);

  /// Do usuario, criadas depois de [sinceMs], mais novas primeiro.
  Future<List<NotificationRecord>> notificationsOf(String userId,
      {int? sinceMs, required int limit});

  /// False se a notificacao nao existe ou nao e de [userId].
  Future<bool> markNotificationRead(String id,
      {required String userId, required int nowMs});

  // Tokens de push.

  /// Grava (ou reatribui a [PushTokenRecord.userId]) o token.
  Future<void> upsertPushToken(PushTokenRecord t);

  /// Remove o token so se ele for de [userId].
  Future<void> deletePushToken(String token, {required String userId});

  /// Remove o token de qualquer dono (o FCM disse que nao vale mais).
  Future<void> deletePushTokenAnyOwner(String token);
  Future<List<PushTokenRecord>> pushTokensOf(String userId);

  /// Exclusao de conta: tudo que pertence a [userId] (no Postgres a FK em
  /// cascata ja faz isso; aqui cobre o store em memoria).
  Future<void> deleteAllForUser(String userId);
}

class InMemorySafetyStore implements SafetyStore {
  final Map<String, ContactRecord> _contacts = {};
  final Map<String, SafetySessionRecord> _sessions = {};
  final Map<String, NotificationRecord> _notifications = {};
  final Map<String, PushTokenRecord> _tokens = {};

  /// Para os testes.
  int get sessionCount => _sessions.length;
  bool hasPushToken(String token) => _tokens.containsKey(token);

  @override
  Future<ContactRecord?> createContact(ContactRecord c) async {
    final bool existe = _contacts.values.any(
        (x) => x.ownerId == c.ownerId && x.contactUserId == c.contactUserId);
    if (existe) return null;
    _contacts[c.id] = c.copy();
    return c.copy();
  }

  @override
  Future<ContactRecord?> findContact(String id) async => _contacts[id]?.copy();

  @override
  Future<List<ContactRecord>> contactsOfUser(String userId) async => [
        for (final c in _contacts.values)
          if (c.ownerId == userId || c.contactUserId == userId) c.copy()
      ]..sort((a, b) => a.createdAtMs.compareTo(b.createdAtMs));

  @override
  Future<int> countAcceptedContacts(String ownerId) async => _contacts.values
      .where((c) => c.ownerId == ownerId && c.accepted)
      .length;

  @override
  Future<void> saveContact(ContactRecord c) async {
    if (_contacts.containsKey(c.id)) _contacts[c.id] = c.copy();
  }

  @override
  Future<void> deleteContact(String id) async {
    _contacts.remove(id);
  }

  @override
  Future<SafetySessionRecord?> createSession(SafetySessionRecord s) async {
    if (_sessions.values.any((x) => x.ownerId == s.ownerId && !x.ended)) {
      return null;
    }
    _sessions[s.id] = s.copy();
    return s.copy();
  }

  @override
  Future<SafetySessionRecord?> findSession(String id) async =>
      _sessions[id]?.copy();

  @override
  Future<SafetySessionRecord?> findOpenSessionOfOwner(String ownerId) async {
    for (final s in _sessions.values) {
      if (s.ownerId == ownerId && !s.ended) return s.copy();
    }
    return null;
  }

  @override
  Future<SafetySessionRecord?> findSessionByShareToken(String token) async {
    for (final s in _sessions.values) {
      if (s.shareToken == token) return s.copy();
    }
    return null;
  }

  @override
  Future<List<SafetySessionRecord>> openSessions() async =>
      [for (final s in _sessions.values) if (!s.ended) s.copy()];

  @override
  Future<void> saveSession(SafetySessionRecord s) async {
    if (_sessions.containsKey(s.id)) _sessions[s.id] = s.copy();
  }

  @override
  Future<int> deleteSessionsEndedBefore(int ms) async {
    final List<String> ids = [
      for (final s in _sessions.values)
        if (s.ended && s.endedAtMs != null && s.endedAtMs! < ms) s.id
    ];
    ids.forEach(_sessions.remove);
    return ids.length;
  }

  @override
  Future<void> addNotification(NotificationRecord n) async {
    _notifications[n.id] = n.copy();
  }

  @override
  Future<List<NotificationRecord>> notificationsOf(String userId,
      {int? sinceMs, required int limit}) async {
    final List<NotificationRecord> lista = [
      for (final n in _notifications.values)
        if (n.userId == userId && (sinceMs == null || n.createdAtMs > sinceMs))
          n.copy()
    ];
    // Mais novas primeiro; desempate pelo id para a ordem ser estavel.
    lista.sort((a, b) {
      final int c = b.createdAtMs.compareTo(a.createdAtMs);
      return c != 0 ? c : b.id.compareTo(a.id);
    });
    return lista.take(limit).toList();
  }

  @override
  Future<bool> markNotificationRead(String id,
      {required String userId, required int nowMs}) async {
    final NotificationRecord? n = _notifications[id];
    if (n == null || n.userId != userId) return false;
    n.readAtMs ??= nowMs;
    return true;
  }

  @override
  Future<void> upsertPushToken(PushTokenRecord t) async {
    _tokens[t.token] = t;
  }

  @override
  Future<void> deletePushToken(String token, {required String userId}) async {
    if (_tokens[token]?.userId == userId) _tokens.remove(token);
  }

  @override
  Future<void> deletePushTokenAnyOwner(String token) async {
    _tokens.remove(token);
  }

  @override
  Future<List<PushTokenRecord>> pushTokensOf(String userId) async =>
      [for (final t in _tokens.values) if (t.userId == userId) t];

  @override
  Future<void> deleteAllForUser(String userId) async {
    _contacts.removeWhere(
        (_, c) => c.ownerId == userId || c.contactUserId == userId);
    _sessions.removeWhere((_, s) => s.ownerId == userId);
    _notifications.removeWhere((_, n) => n.userId == userId);
    _tokens.removeWhere((_, t) => t.userId == userId);
  }
}
