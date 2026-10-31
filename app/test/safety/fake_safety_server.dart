// Servidor falso do Rastro Seguro: um HttpClientAdapter do Dio que segue o
// contrato (backend/docs/CONTRATO-RASTRO-SEGURO.md) com estado em memoria.
// Varias contas (token -> usuario), contatos com limite de 3, sessoes,
// notificacoes e os ganchos do vigia ([startCheck], [alert]) que o teste
// dispara na mao. Nenhuma rede e tocada.
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

class FakeUser {
  final String id;
  final String email;
  final String name;
  const FakeUser(this.id, this.email, this.name);
}

class FakeRequest {
  final String method;
  final String path;
  final Map<String, String> query;
  final Object? body;
  final String? token;
  const FakeRequest(this.method, this.path, this.query, this.body, this.token);

  @override
  String toString() => '$method $path ${body ?? ''}';
}

class FakeSafetyServer implements HttpClientAdapter {
  int Function() now;
  FakeSafetyServer({int Function()? now}) : now = now ?? (() => 1000000);

  final Map<String, FakeUser> tokens = {};
  final List<Map<String, dynamic>> contacts = [];
  final List<Map<String, dynamic>> sessions = [];
  final List<Map<String, dynamic>> notifications = [];
  final List<FakeRequest> requests = [];

  /// Sem rede: toda requisicao falha na conexao.
  bool offline = false;

  /// Forca uma resposta para "METHOD /caminho" (prefixo), antes das regras.
  final Map<String, (int, Object?)> overrides = {};

  int _seq = 0;
  String _id(String p) => '${p}_${++_seq}';

  FakeUser addUser(String token, String id, String email, String name) {
    final u = FakeUser(id, email, name);
    tokens[token] = u;
    return u;
  }

  FakeUser? _byEmail(String email) {
    for (final u in tokens.values) {
      if (u.email == email) return u;
    }
    return null;
  }

  FakeUser? _byId(String id) {
    for (final u in tokens.values) {
      if (u.id == id) return u;
    }
    return null;
  }

  List<FakeRequest> requestsTo(String method, String pathPart) => [
    for (final r in requests)
      if (r.method == method && r.path.contains(pathPart)) r,
  ];

  void notify(String userId, String type, {Map<String, dynamic> data = const {}, String? title}) {
    notifications.add({
      'id': _id('nt'),
      'userId': userId,
      'type': type,
      'title': title ?? type,
      'body': 'corpo $type',
      'data': data,
      'createdAt': now(),
      'readAt': null,
    });
  }

  /// Contato ja aceito entre [owner] (quem convidou) e [other].
  String linkAccepted(FakeUser owner, FakeUser other) {
    final c = {'id': _id('ct'), 'ownerId': owner.id, 'otherId': other.id, 'status': 'accepted', 'createdAt': now()};
    contacts.add(c);
    return c['id'] as String;
  }

  Map<String, dynamic>? sessionById(String id) {
    for (final s in sessions) {
      if (s['id'] == id) return s;
    }
    return null;
  }

  /// Vigia: abre a checagem "esta tudo bem?".
  void startCheck(String sessionId, {String reason = 'silence', int? deadlineMs}) {
    final s = sessionById(sessionId)!;
    s['status'] = 'checking';
    s['check'] = {'reason': reason, 'startedAt': now(), 'deadlineMs': deadlineMs ?? now() + 120000};
    notify(s['ownerId'] as String, 'safety_check', data: {'sessionId': sessionId, 'reason': reason});
  }

  /// Vigia: prazo da checagem passou; avisa os contatos.
  void alert(String sessionId) {
    final s = sessionById(sessionId)!;
    final reason = (s['check'] as Map?)?['reason'] ?? 'silence';
    s['status'] = 'alerted';
    s['alertedAt'] = now();
    final owner = _byId(s['ownerId'] as String)!;
    for (final cid in (s['contactIds'] as List)) {
      final other = _otherSide(cid as String, owner.id);
      if (other != null) {
        notify(
          other,
          'safety_alert',
          title: '${owner.name} pode precisar de ajuda',
          data: {'sessionId': sessionId, 'shareUrl': s['shareUrl'], 'reason': reason, 'ownerName': owner.name},
        );
      }
    }
  }

  String? _otherSide(String contactId, String userId) {
    for (final c in contacts) {
      if (c['id'] != contactId) continue;
      if (c['ownerId'] == userId) return c['otherId'] as String;
      if (c['otherId'] == userId) return c['ownerId'] as String;
    }
    return null;
  }

  Map<String, dynamic> _contactJson(Map<String, dynamic> c, String viewerId) {
    final otherId = c['ownerId'] == viewerId ? c['otherId'] : c['ownerId'];
    final other = _byId(otherId as String)!;
    return {
      'id': c['id'],
      'otherUserId': other.id,
      'displayName': other.name,
      'email': other.email,
      'status': c['status'],
      'createdAt': c['createdAt'],
    };
  }

  Map<String, dynamic> _sessionJson(Map<String, dynamic> s) => {
    for (final e in s.entries)
      if (e.key != 'ownerId' && e.key != 'positions') e.key: e.value,
  };

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (offline) {
      throw DioException.connectionError(requestOptions: options, reason: 'offline');
    }
    final chunks = requestStream == null ? <Uint8List>[] : await requestStream.toList();
    final raw = utf8.decode([for (final c in chunks) ...c]);
    final body = raw.isEmpty ? options.data : jsonDecode(raw);
    final auth = options.headers['Authorization'] as String?;
    final token = auth?.startsWith('Bearer ') == true ? auth!.substring(7) : null;
    final path = options.uri.path;
    final req = FakeRequest(options.method, path, options.uri.queryParameters, body, token);
    requests.add(req);
    for (final e in overrides.entries) {
      if ('${options.method} $path'.startsWith(e.key)) return _json(e.value.$1, e.value.$2);
    }
    final user = token == null ? null : tokens[token];
    if (user == null) return _json(401, {'error': 'nao autenticado'});
    final (status, out) = _handle(options.method, path, req, user);
    return _json(status, out);
  }

  (int, Object?) _handle(String method, String path, FakeRequest r, FakeUser me) {
    final seg = path.split('/').where((s) => s.isNotEmpty).toList();
    final b = r.body is Map ? (r.body as Map).cast<String, dynamic>() : <String, dynamic>{};
    // Contatos
    if (path == '/safety/contacts' && method == 'POST') {
      final email = (b['email'] as String? ?? '').trim().toLowerCase();
      if (email == me.email) return (400, {'error': 'nao da para convidar o proprio email'});
      final other = _byEmail(email);
      if (other == null) return (404, {'error': 'sem conta no Rastro'});
      final dup = contacts.any(
        (c) =>
            (c['ownerId'] == me.id && c['otherId'] == other.id) || (c['ownerId'] == other.id && c['otherId'] == me.id),
      );
      if (dup) return (409, {'error': 'convite ja existe'});
      final accepted = contacts.where((c) => c['ownerId'] == me.id && c['status'] == 'accepted').length;
      if (accepted >= 3) return (409, {'error': 'limite de 3 contatos aceitos'});
      final c = {'id': _id('ct'), 'ownerId': me.id, 'otherId': other.id, 'status': 'pending', 'createdAt': now()};
      contacts.add(c);
      notify(other.id, 'contact_invite', data: {'contactId': c['id'], 'ownerName': me.name});
      return (201, _contactJson(c, me.id));
    }
    if (path == '/safety/contacts' && method == 'GET') {
      return (
        200,
        {
          'outgoing': [
            for (final c in contacts)
              if (c['ownerId'] == me.id) _contactJson(c, me.id),
          ],
          'incoming': [
            for (final c in contacts)
              if (c['otherId'] == me.id) _contactJson(c, me.id),
          ],
        },
      );
    }
    if (seg.length == 4 && seg[1] == 'contacts' && seg[3] == 'accept' && method == 'POST') {
      final c = contacts.where((c) => c['id'] == seg[2] && c['otherId'] == me.id).firstOrNull;
      if (c == null) return (404, {'error': 'nao encontrado'});
      c['status'] = 'accepted';
      notify(c['ownerId'] as String, 'contact_accepted', data: {'contactId': c['id']});
      return (200, _contactJson(c, me.id));
    }
    if (seg.length == 3 && seg[1] == 'contacts' && method == 'DELETE') {
      contacts.removeWhere((c) => c['id'] == seg[2] && (c['ownerId'] == me.id || c['otherId'] == me.id));
      return (204, null);
    }
    // Sessoes
    if (path == '/safety/sessions' && method == 'POST') {
      final eta = (b['etaMs'] as num?)?.toInt() ?? 0;
      final ids = [for (final e in (b['contactIds'] as List? ?? const [])) e.toString()];
      if (eta < now() + 5 * 60000 || eta > now() + 12 * 3600000) {
        return (400, {'error': 'etaMs fora do intervalo'});
      }
      final okIds =
          ids.isNotEmpty &&
          ids.every(
            (id) => contacts.any(
              (c) => c['id'] == id && c['status'] == 'accepted' && (c['ownerId'] == me.id || c['otherId'] == me.id),
            ),
          );
      if (!okIds) return (400, {'error': 'contato invalido'});
      if (sessions.any((s) => s['ownerId'] == me.id && s['status'] != 'ended')) {
        return (409, {'error': 'ja ha sessao ativa'});
      }
      final id = _id('ss');
      final s = <String, dynamic>{
        'id': id,
        'ownerId': me.id,
        'activityGuid': b['activityGuid'],
        'status': 'active',
        'etaMs': eta,
        'startedAt': now(),
        'endedAt': null,
        'lastSignalAt': now(),
        'lastPosition': null,
        'contactIds': ids,
        'check': null,
        'alertedAt': null,
        'shareUrl': 'http://localhost:8081/s/tok$id',
        'positions': <Object?>[],
      };
      sessions.add(s);
      return (201, _sessionJson(s));
    }
    if (path == '/safety/sessions/active' && method == 'GET') {
      final s = sessions.where((s) => s['ownerId'] == me.id && s['status'] != 'ended').firstOrNull;
      return s == null ? (404, {'error': 'sem sessao ativa'}) : (200, _sessionJson(s));
    }
    if (seg.length >= 3 && seg[1] == 'sessions') {
      final s = sessionById(seg[2]);
      if (s == null || s['ownerId'] != me.id) return (404, {'error': 'nao encontrada'});
      if (seg.length == 3 && method == 'GET') return (200, _sessionJson(s));
      final action = seg.length == 4 ? seg[3] : '';
      switch (action) {
        case 'positions':
          s['lastSignalAt'] = now();
          (s['positions'] as List).add(b);
          if (b['lat'] != null) {
            s['lastPosition'] = {
              'lat': b['lat'],
              'lon': b['lon'],
              'accuracyM': b['accuracyM'],
              'recordedAtMs': b['recordedAtMs'],
            };
          }
          return (200, _sessionJson(s));
        case 'ok':
          _clearCheck(s, me);
          return (200, _sessionJson(s));
        case 'extend':
          final m = (b['minutes'] as num?)?.toInt() ?? 0;
          if (m < 5 || m > 120) return (400, {'error': 'minutos fora do intervalo'});
          s['etaMs'] = (s['etaMs'] as int) + m * 60000;
          _clearCheck(s, me);
          return (200, _sessionJson(s));
        case 'arrived':
          s['status'] = 'ended';
          s['endedAt'] = now();
          s['check'] = null;
          return (200, _sessionJson(s));
        case 'sos':
          for (final cid in (s['contactIds'] as List)) {
            final other = _otherSide(cid as String, me.id);
            if (other != null) {
              notify(
                other,
                'safety_sos',
                title: '${me.name} pediu ajuda',
                data: {'sessionId': s['id'], 'shareUrl': s['shareUrl'], 'ownerName': me.name},
              );
            }
          }
          return (200, _sessionJson(s));
      }
    }
    // Notificacoes
    if (path == '/notifications' && method == 'GET') {
      final since = int.tryParse(r.query['since'] ?? '') ?? 0;
      final list = [
        for (final n in notifications)
          if (n['userId'] == me.id && (n['createdAt'] as int) > since)
            {
              for (final e in n.entries)
                if (e.key != 'userId') e.key: e.value,
            },
      ]..sort((a, b) => (b['createdAt'] as int).compareTo(a['createdAt'] as int));
      return (200, {'notifications': list.take(50).toList()});
    }
    if (seg.length == 3 && seg[0] == 'notifications' && seg[2] == 'read' && method == 'POST') {
      for (final n in notifications) {
        if (n['id'] == seg[1] && n['userId'] == me.id) n['readAt'] = now();
      }
      return (204, null);
    }
    if (path == '/push/tokens' && method == 'POST') return (204, null);
    if (seg.length == 3 && seg[0] == 'push' && method == 'DELETE') return (204, null);
    return (404, {'error': 'rota desconhecida'});
  }

  void _clearCheck(Map<String, dynamic> s, FakeUser me) {
    final wasAlerted = s['status'] == 'alerted';
    s['check'] = null;
    s['status'] = 'active';
    if (wasAlerted) {
      for (final cid in (s['contactIds'] as List)) {
        final other = _otherSide(cid as String, me.id);
        if (other != null) {
          notify(other, 'safety_all_clear', data: {'sessionId': s['id'], 'ownerName': me.name});
        }
      }
    }
  }

  static ResponseBody _json(int status, Object? body) => ResponseBody.fromString(
    body == null ? '' : jsonEncode(body),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  @override
  void close({bool force = false}) {}
}
