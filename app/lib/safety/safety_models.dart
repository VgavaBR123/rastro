// Modelos do Rastro Seguro (F08): contatos de confianca, sessao da chegada
// combinada e notificacoes da caixa de entrada. Formato do contrato em
// backend/docs/CONTRATO-RASTRO-SEGURO.md (tempos em epoch ms).
library;

enum ContactStatus { pending, accepted }

/// Outra conta do Rastro ligada a esta por convite aceito (ou pendente).
class TrustedContact {
  final String id;
  final String otherUserId;
  final String displayName;
  final String email;
  final ContactStatus status;
  final int createdAt;

  const TrustedContact({
    required this.id,
    required this.otherUserId,
    required this.displayName,
    required this.email,
    required this.status,
    required this.createdAt,
  });

  bool get accepted => status == ContactStatus.accepted;

  factory TrustedContact.fromJson(Map<String, dynamic> j) => TrustedContact(
    id: j['id'].toString(),
    otherUserId: (j['otherUserId'] ?? '').toString(),
    displayName: (j['displayName'] as String?) ?? '',
    email: (j['email'] as String?) ?? '',
    status: j['status'] == 'accepted' ? ContactStatus.accepted : ContactStatus.pending,
    createdAt: (j['createdAt'] as num?)?.toInt() ?? 0,
  );

  /// Nome para a tela: o de exibicao ou, sem ele, o email.
  String get label => displayName.trim().isEmpty ? email : displayName;
}

/// `outgoing`: quem eu convidei; `incoming`: quem me convidou.
class ContactLists {
  final List<TrustedContact> outgoing;
  final List<TrustedContact> incoming;
  const ContactLists({this.outgoing = const [], this.incoming = const []});

  factory ContactLists.fromJson(Map<String, dynamic> j) =>
      ContactLists(outgoing: _list(j['outgoing']), incoming: _list(j['incoming']));

  static List<TrustedContact> _list(Object? v) =>
      v is List ? [for (final e in v) TrustedContact.fromJson(e as Map<String, dynamic>)] : const [];

  /// Contatos aceitos dos dois lados (quem pode ser avisado numa sessao).
  /// O contrato aceita `contactIds` de convites enviados ou recebidos.
  List<TrustedContact> get accepted => [
    for (final c in outgoing)
      if (c.accepted) c,
    for (final c in incoming)
      if (c.accepted) c,
  ];
}

enum SafetyStatus { active, checking, alerted, ended }

SafetyStatus _statusOf(Object? v) => switch (v) {
  'checking' => SafetyStatus.checking,
  'alerted' => SafetyStatus.alerted,
  'ended' => SafetyStatus.ended,
  _ => SafetyStatus.active,
};

enum CheckReason { silence, stopped, eta }

CheckReason? checkReasonOf(Object? v) => switch (v) {
  'silence' => CheckReason.silence,
  'stopped' => CheckReason.stopped,
  'eta' => CheckReason.eta,
  _ => null,
};

/// Pergunta "esta tudo bem?" em aberto.
class SafetyCheck {
  final CheckReason? reason;
  final int startedAt;
  final int deadlineMs;
  const SafetyCheck({this.reason, required this.startedAt, required this.deadlineMs});

  factory SafetyCheck.fromJson(Map<String, dynamic> j) => SafetyCheck(
    reason: checkReasonOf(j['reason']),
    startedAt: (j['startedAt'] as num?)?.toInt() ?? 0,
    deadlineMs: (j['deadlineMs'] as num?)?.toInt() ?? 0,
  );
}

class SafetyPosition {
  final double lat;
  final double lon;
  final double? accuracyM;
  final int recordedAtMs;
  const SafetyPosition({required this.lat, required this.lon, this.accuracyM, required this.recordedAtMs});

  static SafetyPosition? fromJson(Object? v) {
    if (v is! Map) return null;
    final lat = v['lat'];
    final lon = v['lon'];
    if (lat is! num || lon is! num) return null;
    return SafetyPosition(
      lat: lat.toDouble(),
      lon: lon.toDouble(),
      accuracyM: (v['accuracyM'] as num?)?.toDouble(),
      recordedAtMs: (v['recordedAtMs'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Sessao do Rastro Seguro (uma por atividade).
class SafetySession {
  final String id;
  final String activityGuid;
  final SafetyStatus status;
  final int etaMs;
  final int startedAt;
  final int? endedAt;
  final int? lastSignalAt;
  final SafetyPosition? lastPosition;
  final List<String> contactIds;
  final SafetyCheck? check;
  final int? alertedAt;
  final String? shareUrl;

  const SafetySession({
    required this.id,
    required this.activityGuid,
    required this.status,
    required this.etaMs,
    this.startedAt = 0,
    this.endedAt,
    this.lastSignalAt,
    this.lastPosition,
    this.contactIds = const [],
    this.check,
    this.alertedAt,
    this.shareUrl,
  });

  bool get ended => status == SafetyStatus.ended;

  factory SafetySession.fromJson(Map<String, dynamic> j) => SafetySession(
    id: j['id'].toString(),
    activityGuid: (j['activityGuid'] ?? '').toString(),
    status: _statusOf(j['status']),
    etaMs: (j['etaMs'] as num?)?.toInt() ?? 0,
    startedAt: (j['startedAt'] as num?)?.toInt() ?? 0,
    endedAt: (j['endedAt'] as num?)?.toInt(),
    lastSignalAt: (j['lastSignalAt'] as num?)?.toInt(),
    lastPosition: SafetyPosition.fromJson(j['lastPosition']),
    contactIds: [
      if (j['contactIds'] case final List l)
        for (final e in l) e.toString(),
    ],
    check: j['check'] is Map<String, dynamic> ? SafetyCheck.fromJson(j['check'] as Map<String, dynamic>) : null,
    alertedAt: (j['alertedAt'] as num?)?.toInt(),
    shareUrl: j['shareUrl'] as String?,
  );
}

/// Tipos de notificacao do contrato. [unknown] cobre tipos novos do backend.
enum NotificationKind { contactInvite, contactAccepted, safetyCheck, safetyAlert, safetySos, safetyAllClear, unknown }

NotificationKind notificationKindOf(Object? v) => switch (v) {
  'contact_invite' => NotificationKind.contactInvite,
  'contact_accepted' => NotificationKind.contactAccepted,
  'safety_check' => NotificationKind.safetyCheck,
  'safety_alert' => NotificationKind.safetyAlert,
  'safety_sos' => NotificationKind.safetySos,
  'safety_all_clear' => NotificationKind.safetyAllClear,
  _ => NotificationKind.unknown,
};

class AppNotification {
  final String id;
  final NotificationKind kind;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final int createdAt;
  final int? readAt;

  const AppNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    this.data = const {},
    required this.createdAt,
    this.readAt,
  });

  bool get unread => readAt == null;

  /// Alerta de alguem que pode precisar de ajuda (destaque na caixa).
  bool get isAlert => kind == NotificationKind.safetyAlert || kind == NotificationKind.safetySos;

  String? get sessionId => data['sessionId'] as String?;
  String? get shareUrl => data['shareUrl'] as String?;
  String? get ownerName => data['ownerName'] as String?;
  CheckReason? get reason => checkReasonOf(data['reason']);

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
    id: j['id'].toString(),
    kind: notificationKindOf(j['type']),
    title: (j['title'] as String?) ?? '',
    body: (j['body'] as String?) ?? '',
    data: j['data'] is Map<String, dynamic> ? j['data'] as Map<String, dynamic> : const {},
    createdAt: (j['createdAt'] as num?)?.toInt() ?? 0,
    readAt: (j['readAt'] as num?)?.toInt(),
  );

  AppNotification markRead(int atMs) => AppNotification(
    id: id,
    kind: kind,
    title: title,
    body: body,
    data: data,
    createdAt: createdAt,
    readAt: readAt ?? atMs,
  );
}

/// Motivo da checagem em portugues, para a tela e a caixa de entrada.
String checkReasonLabel(CheckReason? r) => switch (r) {
  CheckReason.silence => 'o app ficou sem sinal',
  CheckReason.stopped => 'parou por muito tempo sem pausar',
  CheckReason.eta => 'passou do horario previsto de chegada',
  null => 'sem resposta',
};
