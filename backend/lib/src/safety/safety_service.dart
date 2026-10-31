// Regras do Rastro Seguro (docs/CONTRATO-RASTRO-SEGURO.md): contatos de
// confianca, sessoes, o vigia (tick), notificacoes e a visao do link publico.
// Nao conhece HTTP: as rotas ficam em safety_api.dart e os erros sobem como
// SafetyError(status, mensagem).
//
// Concorrencia: o vigia e as rotas mexem na mesma sessao. Toda alteracao de
// sessao passa por uma trava por id (_comTrava), entao um `ok` nunca e
// atropelado por um tick que leu a sessao antes dele. A trava vive no
// processo: vale para uma instancia so do servidor (mesma premissa do
// RateLimiter).
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io' show stderr;
import 'dart:math';

import '../auth/rate_limiter.dart';
import '../user_store.dart';
import 'push_sender.dart';
import 'safety_store.dart';

class SafetyError implements Exception {
  const SafetyError(this.status, this.message);
  final int status;
  final String message;

  @override
  String toString() => 'SafetyError($status, $message)';
}

class SafetyConfig {
  const SafetyConfig({
    this.tickMs = 15000,
    this.silenceMs = 5 * 60 * 1000,
    this.stopMs = 10 * 60 * 1000,
    this.checkMs = 2 * 60 * 1000,
    this.publicBaseUrl = 'http://localhost:8081',
    this.etaMinMs = 5 * 60 * 1000,
    this.etaMaxMs = 12 * 60 * 60 * 1000,
    this.endGraceMs = 6 * 60 * 60 * 1000,
    this.purgeAfterMs = 24 * 60 * 60 * 1000,
    this.arrivedLinkMs = 15 * 60 * 1000,
    this.maxAcceptedContacts = 3,
    this.invitesPerHour = 20,
    this.pushMaxAttempts = 5,
    this.pushRetryBaseMs = 15000,
    this.maxClockAheadMs = 2 * 60 * 1000,
    this.maxPositionBeforeStartMs = 60 * 60 * 1000,
  });

  /// Le as variaveis do contrato; ausentes ou invalidas ficam no padrao.
  /// SAFETY_ETA_MIN_MS e extra (decisao do backend, para o E2E testar a
  /// regra do horario sem esperar 5 min).
  factory SafetyConfig.fromEnv(Map<String, String> env) {
    const SafetyConfig p = SafetyConfig();
    int ler(String k, int padrao) {
      final int? v = int.tryParse(env[k]?.trim() ?? '');
      return (v == null || v <= 0) ? padrao : v;
    }

    final String base = (env['PUBLIC_BASE_URL'] ?? '').trim();
    return SafetyConfig(
      tickMs: ler('SAFETY_TICK_MS', p.tickMs),
      silenceMs: ler('SAFETY_SILENCE_MS', p.silenceMs),
      stopMs: ler('SAFETY_STOP_MS', p.stopMs),
      checkMs: ler('SAFETY_CHECK_MS', p.checkMs),
      etaMinMs: ler('SAFETY_ETA_MIN_MS', p.etaMinMs),
      publicBaseUrl: base.isEmpty ? p.publicBaseUrl : base,
    );
  }

  final int tickMs;
  final int silenceMs;
  final int stopMs;
  final int checkMs;
  final String publicBaseUrl;
  final int etaMinMs;
  final int etaMaxMs;

  /// A sessao encerra sozinha em etaMs + isto.
  final int endGraceMs;

  /// Sessoes (posicao e link) somem isto depois do fim (LGPD).
  final int purgeAfterMs;

  /// Depois de `arrived`, o link ainda vale isto.
  final int arrivedLinkMs;
  final int maxAcceptedContacts;

  /// Convites (com sucesso ou nao) por conta por hora. Barra quem usaria o
  /// 404 "sem conta no Rastro" para descobrir quais emails tem conta.
  final int invitesPerHour;

  /// Tentativas de cada push da outbox antes de desistir (a caixa de entrada
  /// ja tem a notificacao).
  final int pushMaxAttempts;

  /// Espera antes da 2a tentativa; dobra a cada falha (base, 2x, 4x...).
  final int pushRetryBaseMs;

  /// recordedAtMs mais que isto depois do recebimento e cortado.
  final int maxClockAheadMs;

  /// recordedAtMs mais que isto antes do inicio da sessao vira batimento.
  final int maxPositionBeforeStartMs;
}

/// Formato do token do link: 32 bytes em base64url sem padding = 43 chars.
final RegExp formatoTokenLink = RegExp(r'^[A-Za-z0-9_-]{43}$');

final RegExp _emailValido = RegExp(r'^[^@\s]+@[^@\s.]+(\.[^@\s.]+)+$');

String _idAleatorio(String prefixo) {
  final Random r = Random.secure();
  final String hex = [
    for (var i = 0; i < 12; i++) r.nextInt(256).toRadixString(16).padLeft(2, '0')
  ].join();
  return '${prefixo}_$hex';
}

/// 32 bytes de Random.secure em base64url, sem padding.
String gerarTokenLink() {
  final Random r = Random.secure();
  return base64Url
      .encode([for (var i = 0; i < 32; i++) r.nextInt(256)])
      .replaceAll('=', '');
}

String primeiroNome(String nome) {
  final String t = nome.trim();
  if (t.isEmpty) return 'Alguem';
  return t.split(RegExp(r'\s+')).first;
}

const Map<String, String> _motivoCheck = {
  'silence': 'Nao recebemos sinal do seu aparelho ha alguns minutos.',
  'stopped': 'Voce esta sem se mover ha um tempo, sem pausa.',
  'eta': 'Passou do horario previsto de chegada.',
};

const Map<String, String> _motivoAlerta = {
  'silence': 'o aparelho ficou sem sinal',
  'stopped': 'ficou sem se mover por um tempo',
  'eta': 'passou do horario previsto de chegada',
};

class SafetyService {
  SafetyService({
    required SafetyStore store,
    required UserStore users,
    this.config = const SafetyConfig(),
    PushSender? push,
    int Function()? nowMs,
    String Function(String prefixo)? genId,
    String Function()? genShareToken,
  })  : _store = store,
        _users = users,
        _push = push ?? LogPushSender(),
        _now = nowMs ?? (() => DateTime.now().millisecondsSinceEpoch),
        _genId = genId ?? _idAleatorio,
        _genToken = genShareToken ?? gerarTokenLink {
    _carenciaDesdeMs = _now();
    _convites = RateLimiter(
        maxAttempts: config.invitesPerHour,
        window: const Duration(hours: 1),
        nowMs: _now);
  }

  final SafetyStore _store;
  final UserStore _users;
  final PushSender _push;
  final int Function() _now;
  final String Function(String) _genId;
  final String Function() _genToken;
  final SafetyConfig config;
  late final RateLimiter _convites;

  final Map<String, Future<void>> _travas = {};

  Future<T> _comTrava<T>(String chave, Future<T> Function() f) {
    final Future<void> anterior = _travas[chave] ?? Future<void>.value();
    final Completer<void> fim = Completer<void>();
    final Future<void> minha = fim.future;
    _travas[chave] = minha;
    return anterior.then((_) => f()).whenComplete(() {
      fim.complete();
      if (identical(_travas[chave], minha)) _travas.remove(chave);
    });
  }

  String shareUrlDe(SafetySessionRecord s) {
    final String base = config.publicBaseUrl.endsWith('/')
        ? config.publicBaseUrl.substring(0, config.publicBaseUrl.length - 1)
        : config.publicBaseUrl;
    return '$base/s/${s.shareToken}';
  }

  // ------------------------------------------------------------ notificacoes

  /// Grava a notificacao na caixa de entrada de [userId] e um envio pendente
  /// na outbox para cada aparelho dele, tudo dentro da transacao [tx]. A
  /// caixa de entrada e a fonte de verdade; o push sai depois do commit
  /// (_dispararPush / drenarPush).
  Future<void> _notificar(SafetyStore tx, String userId, String tipo,
      String titulo, String corpo, Map<String, dynamic> dados) async {
    final int agora = _now();
    final NotificationRecord n = NotificationRecord(
      id: _genId('nt'),
      userId: userId,
      type: tipo,
      title: titulo,
      body: corpo,
      data: dados,
      createdAtMs: agora,
    );
    await tx.addNotification(n);
    for (final PushTokenRecord t in await tx.pushTokensOf(userId)) {
      await tx.addPushOutbox(PushOutboxRecord(
        id: _genId('po'),
        notificationId: n.id,
        userId: userId,
        token: t.token,
        createdAtMs: agora,
        nextAttemptAtMs: agora,
      ));
    }
  }

  Future<void>? _drenagem;
  bool _drenarDeNovo = false;

  /// Depois de um commit com notificacao: envia sem a rota esperar.
  void _dispararPush() {
    unawaited(drenarPush().catchError((Object e) {
      stderr.writeln('outbox de push falhou: $e');
    }));
  }

  /// Termina quando a drenagem em curso (se houver) acabar. Para os testes.
  Future<void> aguardarPush() => _drenagem ?? Future<void>.value();

  /// Envia o que esta vencido na outbox. Uma drenagem por vez: quem chama
  /// durante uma em curso pede outra passada e espera a mesma.
  Future<void> drenarPush() {
    if (_drenagem != null) {
      _drenarDeNovo = true;
      return _drenagem!;
    }
    final Future<void> d = () async {
      do {
        _drenarDeNovo = false;
        await _drenarUmaVez();
      } while (_drenarDeNovo);
    }();
    _drenagem = d.whenComplete(() => _drenagem = null);
    return _drenagem!;
  }

  Future<void> _drenarUmaVez() async {
    for (final PushOutboxRecord o in await _store.duePushOutbox(_now())) {
      final NotificationRecord? n = await _store.findNotification(o.notificationId);
      final List<PushTokenRecord> tokens = await _store.pushTokensOf(o.userId);
      PushTokenRecord? t;
      for (final x in tokens) {
        if (x.token == o.token) t = x;
      }
      // Notificacao apagada ou token que saiu da conta: nada a enviar.
      if (n == null || t == null) {
        await _store.deletePushOutbox(o.id);
        continue;
      }
      PushResult r;
      try {
        r = await _push
            .send(PushMessage(
              token: t.token,
              platform: t.platform,
              notificationId: n.id,
              type: n.type,
              title: n.title,
              body: n.body,
              data: n.data,
            ))
            .timeout(const Duration(seconds: 10));
      } catch (e) {
        stderr.writeln('push ${n.id}: $e');
        r = PushResult.failed;
      }
      switch (r) {
        case PushResult.sent:
          await _store.deletePushOutbox(o.id);
        case PushResult.invalidToken:
          await _store.deletePushOutbox(o.id);
          await _store.deletePushTokenAnyOwner(t.token);
        case PushResult.failed:
          o.attempts++;
          if (o.attempts >= config.pushMaxAttempts) {
            stderr.writeln('push ${n.id}: desistiu depois de '
                '${o.attempts} tentativas (fica so na caixa de entrada)');
            await _store.deletePushOutbox(o.id);
          } else {
            o.nextAttemptAtMs =
                _now() + config.pushRetryBaseMs * (1 << (o.attempts - 1));
            await _store.savePushOutbox(o);
          }
      }
    }
  }

  Future<List<Map<String, dynamic>>> notifications(UserRecord u,
          {int? sinceMs}) async =>
      [
        for (final n
            in await _store.notificationsOf(u.id, sinceMs: sinceMs, limit: 50))
          n.toJson()
      ];

  Future<void> markRead(UserRecord u, String id) async {
    if (!await _store.markNotificationRead(id, userId: u.id, nowMs: _now())) {
      throw const SafetyError(404, 'nao encontrado');
    }
  }

  Future<void> registerPushToken(
      UserRecord u, String token, String platform) async {
    await _store.upsertPushToken(PushTokenRecord(
        token: token, userId: u.id, platform: platform, updatedAtMs: _now()));
  }

  Future<void> deletePushToken(UserRecord u, String token) =>
      _store.deletePushToken(token, userId: u.id);

  // ---------------------------------------------------------------- contatos

  Future<Map<String, dynamic>?> _contatoJson(
      ContactRecord c, String euId) async {
    final String outroId = c.ownerId == euId ? c.contactUserId : c.ownerId;
    final UserRecord? outro = await _users.findById(outroId);
    if (outro == null) return null;
    return {
      'id': c.id,
      'otherUserId': outro.id,
      'displayName': outro.displayName,
      'email': outro.email,
      'status': c.status,
      'createdAt': c.createdAtMs,
    };
  }

  Future<Map<String, dynamic>> inviteContact(
      UserRecord dona, String emailBruto) async {
    final Duration? espera = _convites.check(dona.id);
    if (espera != null) throw const SafetyError(429, 'muitas tentativas');
    _convites.recordFailure(dona.id);

    final String email = emailBruto.trim().toLowerCase();
    if (!_emailValido.hasMatch(email)) {
      throw const SafetyError(400, 'email invalido');
    }
    if (email == dona.email) {
      throw const SafetyError(400, 'nao da para convidar o proprio email');
    }
    final UserRecord? convidado = await _users.findByEmail(email);
    if (convidado == null) throw const SafetyError(404, 'sem conta no Rastro');
    if (await _store.countAcceptedContacts(dona.id) >=
        config.maxAcceptedContacts) {
      throw SafetyError(
          409, 'limite de ${config.maxAcceptedContacts} contatos aceitos');
    }
    final ContactRecord c = await _store.transaction((tx) async {
      final ContactRecord? c = await tx.createContact(ContactRecord(
        id: _genId('ct'),
        ownerId: dona.id,
        contactUserId: convidado.id,
        status: 'pending',
        createdAtMs: _now(),
      ));
      if (c == null) throw const SafetyError(409, 'convite ja existe');
      await _notificar(
        tx,
        convidado.id,
        'contact_invite',
        'Convite para o Rastro Seguro',
        '${dona.displayName} quer ter voce como contato de confianca.',
        {'contactId': c.id, 'ownerName': dona.displayName},
      );
      return c;
    });
    _dispararPush();
    return (await _contatoJson(c, dona.id))!;
  }

  Future<Map<String, dynamic>> listContacts(UserRecord u) async {
    final List<Map<String, dynamic>> saida = [];
    final List<Map<String, dynamic>> entrada = [];
    for (final ContactRecord c in await _store.contactsOfUser(u.id)) {
      final Map<String, dynamic>? j = await _contatoJson(c, u.id);
      if (j == null) continue;
      (c.ownerId == u.id ? saida : entrada).add(j);
    }
    return {'outgoing': saida, 'incoming': entrada};
  }

  Future<Map<String, dynamic>> acceptContact(UserRecord u, String id) async {
    final ContactRecord? c = await _store.findContact(id);
    if (c == null || c.contactUserId != u.id) {
      throw const SafetyError(404, 'nao encontrado');
    }
    if (!c.accepted) {
      if (await _store.countAcceptedContacts(c.ownerId) >=
          config.maxAcceptedContacts) {
        throw SafetyError(409,
            'a pessoa ja tem ${config.maxAcceptedContacts} contatos aceitos');
      }
      c
        ..status = 'accepted'
        ..acceptedAtMs = _now();
      await _store.transaction((tx) async {
        await tx.saveContact(c);
        await _notificar(
          tx,
          c.ownerId,
          'contact_accepted',
          'Contato de confianca aceito',
          '${u.displayName} aceitou ser seu contato de confianca.',
          {'contactId': c.id, 'contactName': u.displayName},
        );
      });
      _dispararPush();
    }
    final Map<String, dynamic>? j = await _contatoJson(c, u.id);
    if (j == null) throw const SafetyError(404, 'nao encontrado');
    return j;
  }

  Future<void> deleteContact(UserRecord u, String id) async {
    final ContactRecord? c = await _store.findContact(id);
    if (c == null || (c.ownerId != u.id && c.contactUserId != u.id)) {
      throw const SafetyError(404, 'nao encontrado');
    }
    await _removerContato(c);
  }

  /// Apaga o contato e, se ele estava na sessao aberta da dona, tira ele de
  /// la, troca o token do link (o ex-contato perde o acesso) e avisa a dona.
  /// Se a sessao ja tinha alertado, quem ficou recebe o link novo.
  Future<void> _removerContato(ContactRecord c) async {
    final SafetySessionRecord? aberta =
        await _store.findOpenSessionOfOwner(c.ownerId);
    if (aberta == null) {
      await _store.deleteContact(c.id);
      return;
    }
    final UserRecord? contato = await _users.findById(c.contactUserId);
    final UserRecord? dona = await _users.findById(c.ownerId);
    final String nomeContato = contato?.displayName ?? 'Um contato';
    await _comTrava(aberta.id, () {
      return _store.transaction((tx) async {
        await tx.deleteContact(c.id);
        final SafetySessionRecord? s = await tx.findSession(aberta.id);
        if (s == null || s.ended || !s.contactIds.contains(c.id)) return;
        s
          ..contactIds = ([...s.contactIds]..remove(c.id))
          ..shareToken = _genToken();
        await tx.saveSession(s);
        final Map<String, dynamic> dados = {
          'sessionId': s.id,
          'contactId': c.id,
          'contactName': nomeContato,
          'shareUrl': shareUrlDe(s),
        };
        if (s.contactIds.isEmpty) {
          await _notificar(
            tx,
            s.ownerId,
            'safety_no_contacts',
            'Sem contatos nesta atividade',
            'Ninguem vai ser avisado se voce nao responder',
            dados,
          );
        } else {
          await _notificar(
            tx,
            s.ownerId,
            'safety_contact_removed',
            'Contato removido da atividade',
            '$nomeContato nao e mais seu contato de confianca nesta atividade.',
            dados,
          );
        }
        if (s.status == 'alerted') {
          final String nome = dona?.displayName ?? 'Sua contato';
          await _avisarContatos(
            tx,
            s,
            'safety_link_updated',
            '${primeiroNome(nome)}: link novo',
            'O link da ultima posicao de $nome mudou. Use este.',
            {'sessionId': s.id, 'shareUrl': shareUrlDe(s), 'ownerName': nome},
          );
        }
      });
    });
    _dispararPush();
  }

  /// Exclusao de conta: tira a pessoa das sessoes de quem a tinha como
  /// contato e apaga tudo dela (as sessoes dela vao junto).
  Future<void> deleteAllForUser(String userId) async {
    for (final ContactRecord c in await _store.contactsOfUser(userId)) {
      if (c.contactUserId == userId) await _removerContato(c);
    }
    await _store.deleteAllForUser(userId);
  }


  // ----------------------------------------------------------------- sessoes

  Map<String, dynamic> sessionJson(SafetySessionRecord s) => {
        'id': s.id,
        'activityGuid': s.activityGuid,
        'status': s.status,
        'etaMs': s.etaMs,
        'startedAt': s.startedAtMs,
        'endedAt': s.endedAtMs,
        'lastSignalAt': s.lastSignalAtMs,
        'lastPosition': s.lastPosition?.toJson(),
        'contactIds': s.contactIds,
        'check': s.checkReason == null
            ? null
            : {
                'reason': s.checkReason,
                'startedAt': s.checkStartedAtMs,
                'deadlineMs': s.checkDeadlineMs,
              },
        'alertedAt': s.alertedAtMs,
        'shareUrl': shareUrlDe(s),
      };

  Future<Map<String, dynamic>> createSession(
      UserRecord dona, Map<String, dynamic> body) async {
    final Object? guid = body['activityGuid'];
    if (guid is! String || guid.trim().isEmpty || guid.length > 200) {
      throw const SafetyError(400, 'activityGuid obrigatorio');
    }
    final int agora = _now();
    final Object? eta = body['etaMs'];
    if (eta is! num || eta != eta.roundToDouble()) {
      throw const SafetyError(400, 'etaMs precisa ser um inteiro (epoch ms)');
    }
    final int etaMs = eta.toInt();
    if (etaMs < agora + config.etaMinMs || etaMs > agora + config.etaMaxMs) {
      throw SafetyError(
          400,
          'etaMs precisa estar entre agora + '
          '${(config.etaMinMs / 60000).ceil()} min e agora + '
          '${config.etaMaxMs ~/ 3600000} h');
    }
    final Object? ids = body['contactIds'];
    if (ids is! List || ids.isEmpty || ids.any((x) => x is! String)) {
      throw const SafetyError(400, 'contactIds precisa ter ao menos um contato');
    }
    final List<String> contatos = <String>{...ids.cast<String>()}.toList();
    for (final String id in contatos) {
      final ContactRecord? c = await _store.findContact(id);
      if (c == null || c.ownerId != dona.id || !c.accepted) {
        throw SafetyError(400, 'contato $id nao e um contato aceito');
      }
    }
    final SafetySessionRecord? s = await _store.createSession(
        SafetySessionRecord(
      id: _genId('ss'),
      ownerId: dona.id,
      activityGuid: guid.trim(),
      status: 'active',
      etaMs: etaMs,
      startedAtMs: agora,
      lastSignalAtMs: agora,
      contactIds: contatos,
      shareToken: _genToken(),
    ));
    if (s == null) throw const SafetyError(409, 'ja existe sessao ativa');
    return sessionJson(s);
  }

  Future<Map<String, dynamic>> activeSession(UserRecord u) async {
    final SafetySessionRecord? s = await _store.findOpenSessionOfOwner(u.id);
    if (s == null) throw const SafetyError(404, 'nenhuma sessao ativa');
    return sessionJson(s);
  }

  Future<Map<String, dynamic>> getSession(UserRecord u, String id) async {
    final SafetySessionRecord? s = await _store.findSession(id);
    if (s == null || s.ownerId != u.id) {
      throw const SafetyError(404, 'nao encontrado');
    }
    return sessionJson(s);
  }

  /// Carrega a sessao da dona sob trava e, numa transacao, aplica [f] e
  /// salva: a mudanca da sessao e as notificacoes que [f] gravar ficam juntas
  /// ou nao ficam. O push sai depois do commit, sem a rota esperar.
  Future<Map<String, dynamic>> _alterar(UserRecord u, String id,
      Future<void> Function(SafetySessionRecord s, SafetyStore tx) f) async {
    // Checa a dona antes de pegar a trava (id alheio nao enfileira nada).
    final SafetySessionRecord? previa = await _store.findSession(id);
    if (previa == null || previa.ownerId != u.id) {
      throw const SafetyError(404, 'nao encontrado');
    }
    final Map<String, dynamic> r = await _comTrava(id, () {
      return _store.transaction((tx) async {
        final SafetySessionRecord? s = await tx.findSession(id);
        if (s == null || s.ownerId != u.id) {
          throw const SafetyError(404, 'nao encontrado');
        }
        await f(s, tx);
        await tx.saveSession(s);
        return sessionJson(s);
      });
    });
    _dispararPush();
    return r;
  }

  void _exigirAberta(SafetySessionRecord s) {
    if (s.ended) throw const SafetyError(409, 'sessao encerrada');
  }

  Future<Map<String, dynamic>> position(
      UserRecord u, String id, Map<String, dynamic> body) {
    // Validacao antes de qualquer efeito.
    final Object? lat = body['lat'];
    final Object? lon = body['lon'];
    final bool semPosicao = lat == null && lon == null;
    if (!semPosicao) {
      if (lat is! num || lon is! num || !lat.isFinite || !lon.isFinite) {
        throw const SafetyError(400, 'lat e lon precisam ser numeros ou null');
      }
      if (lat < -90 || lat > 90 || lon < -180 || lon > 180) {
        throw const SafetyError(400, 'lat ou lon fora da faixa');
      }
    }
    final Object? acc = body['accuracyM'];
    if (acc != null && (acc is! num || !acc.isFinite || acc < 0)) {
      throw const SafetyError(400, 'accuracyM invalido');
    }
    final Object? rec = body['recordedAtMs'];
    if (rec != null && (rec is! num || rec < 0 || rec != rec.roundToDouble())) {
      throw const SafetyError(400, 'recordedAtMs invalido');
    }
    final Object? moving = body['moving'];
    final Object? paused = body['paused'];
    if ((moving != null && moving is! bool) ||
        (paused != null && paused is! bool)) {
      throw const SafetyError(400, 'moving e paused precisam ser booleanos');
    }
    return _alterar(u, id, (s, tx) async {
      _exigirAberta(s);
      final int agora = _now();
      s.lastSignalAtMs = agora;
      int registro = (rec as num?)?.toInt() ?? agora;
      // Relogio do aparelho adiantado: mais de 2 min no futuro vira o
      // instante do recebimento.
      if (registro > agora + config.maxClockAheadMs) registro = agora;
      // Muito antes do inicio da sessao (ex.: 0, relogio zerado): nao e uma
      // posicao desta atividade; conta so como sinal de vida.
      final bool antigaDemais =
          registro < s.startedAtMs - config.maxPositionBeforeStartMs;
      if (!semPosicao && !antigaDemais) {
        final SafetyPosition nova = SafetyPosition(
          lat: (lat as num).toDouble(),
          lon: (lon as num).toDouble(),
          accuracyM: (acc as num?)?.toDouble(),
          recordedAtMs: registro,
          receivedAtMs: agora,
        );
        // Envio atrasado (fila offline) nao troca a posicao mais recente.
        if (s.lastPosition == null ||
            nova.recordedAtMs >= s.lastPosition!.recordedAtMs) {
          s.lastPosition = nova;
        }
      }
      if (moving == true || paused == true) {
        s.stillSinceMs = null;
      } else if (moving == false && paused == false) {
        s.stillSinceMs ??= agora;
      }
    });
  }

  /// A dona respondeu (ok/extend): volta a `active`, zera a checagem e o
  /// sinal de vida; se ja tinha alertado, avisa os contatos que esta bem.
  Future<void> _respondeu(
      SafetySessionRecord s, UserRecord dona, SafetyStore tx) async {
    final bool tinhaAlertado = s.status == 'alerted';
    final int agora = _now();
    s
      ..status = 'active'
      ..alertedAtMs = null
      ..lastSignalAtMs = agora
      ..stillSinceMs = null
      ..clearCheck();
    if (tinhaAlertado) {
      await _avisarContatos(
        tx,
        s,
        'safety_all_clear',
        '${primeiroNome(dona.displayName)} esta bem',
        '${dona.displayName} respondeu que esta bem.',
        {'sessionId': s.id, 'ownerName': dona.displayName},
      );
    }
  }

  Future<Map<String, dynamic>> ok(UserRecord u, String id) =>
      _alterar(u, id, (s, tx) async {
        _exigirAberta(s);
        await _respondeu(s, u, tx);
        // Com o horario ja vencido, nao pergunta de novo no tick seguinte:
        // so depois de um intervalo de silencio (ou ela usa extend).
        final int agora = _now();
        s.etaRecheckAfterMs = agora > s.etaMs ? agora + config.silenceMs : null;
      });

  Future<Map<String, dynamic>> extend(
      UserRecord u, String id, Map<String, dynamic> body) {
    final Object? m = body['minutes'];
    if (m is! num || m != m.roundToDouble() || m < 5 || m > 120) {
      throw const SafetyError(400, 'minutes precisa ser inteiro de 5 a 120');
    }
    return _alterar(u, id, (s, tx) async {
      _exigirAberta(s);
      await _respondeu(s, u, tx);
      // Com o eta ja vencido, os minutos contam de agora (senao "mais 15
      // min" uma hora depois do eta continuaria no passado).
      s
        ..etaMs = max(s.etaMs, _now()) + m.toInt() * 60 * 1000
        ..etaRecheckAfterMs = null;

    });
  }

  Future<Map<String, dynamic>> arrived(UserRecord u, String id) =>
      _alterar(u, id, (s, tx) async {
        if (s.ended) return; // idempotente: reenvio do app nao muda nada
        final bool tinhaAlertado = s.status == 'alerted';
        final int agora = _now();
        s
          ..status = 'ended'
          ..endReason = 'arrived'
          ..endedAtMs = agora
          ..lastSignalAtMs = agora
          ..shareExpiresAtMs = agora + config.arrivedLinkMs
          ..clearCheck();
        if (tinhaAlertado) {
          await _avisarContatos(
            tx,
            s,
            'safety_all_clear',
            '${primeiroNome(u.displayName)} chegou',
            '${u.displayName} confirmou que chegou bem.',
            {'sessionId': s.id, 'ownerName': u.displayName},
          );
        }
      });

  Future<Map<String, dynamic>> sos(UserRecord u, String id) =>
      _alterar(u, id, (s, tx) async {
        _exigirAberta(s);
        s.lastSignalAtMs = _now();
        final SafetyPosition? p = s.lastPosition;
        await _avisarContatos(
          tx,
          s,
          'safety_sos',
          '${primeiroNome(u.displayName)} pediu ajuda',
          '${u.displayName} acionou o SOS. Veja a ultima posicao no link.',
          {
            'sessionId': s.id,
            'shareUrl': shareUrlDe(s),
            'reason': 'sos',
            'ownerName': u.displayName,
            if (p != null) 'lat': p.lat,
            if (p != null) 'lon': p.lon,
          },
        );
      });

  /// Notifica (na transacao [tx]) os contatos da sessao que ainda existem e
  /// estao aceitos.
  Future<void> _avisarContatos(SafetyStore tx, SafetySessionRecord s,
      String tipo, String titulo, String corpo, Map<String, dynamic> dados) async {
    for (final String id in s.contactIds) {
      final ContactRecord? c = await tx.findContact(id);
      if (c == null || c.ownerId != s.ownerId || !c.accepted) continue;
      await _notificar(tx, c.contactUserId, tipo, titulo, corpo, dados);
    }
  }

  // ------------------------------------------------------------------ vigia

  Timer? _timer;
  bool _rodando = false;

  /// Inicio da carencia de silencio: o instante em que o processo subiu, ou
  /// o tick que voltou depois de um intervalo grande (servidor travado ou
  /// suspenso). Ninguem e cobrado por um silencio que pode ter sido do
  /// servidor: a regra do silencio conta de max(lastSignalAt, isto).
  late int _carenciaDesdeMs;

  /// Fim do ultimo tick concluido.
  int? _ultimoTickMs;

  /// Liga o timer do vigia (a cada [SafetyConfig.tickMs]).
  void start() {
    _timer ??= Timer.periodic(Duration(milliseconds: config.tickMs), (_) async {
      if (_rodando) return; // tick anterior ainda nao acabou
      _rodando = true;
      try {
        await tick();
      } catch (e) {
        stderr.writeln('vigia do Rastro Seguro falhou: $e');
      } finally {
        _rodando = false;
      }
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Uma passada do vigia sobre as sessoes abertas, mais a limpeza LGPD.
  Future<void> tick() async {
    final int inicio = _now();
    final int? anterior = _ultimoTickMs;
    if (anterior != null && inicio - anterior > config.silenceMs ~/ 2) {
      stderr.writeln('vigia: ${inicio - anterior} ms desde o ultimo tick '
          '(servidor travado ou suspenso?); carencia de silencio a partir de '
          'agora');
      _carenciaDesdeMs = inicio;
    }
    for (final SafetySessionRecord previa in await _store.openSessions()) {
      try {
        // Cada sessao numa transacao: a mudanca de status e as notificacoes
        // ficam juntas ou nao ficam (o proximo tick tenta de novo).
        await _comTrava(
            previa.id, () => _store.transaction((tx) => _vigiar(previa.id, tx)));
      } catch (e) {
        stderr.writeln('vigia: sessao ${previa.id}: $e');
      }
    }
    await _limparLgpd();
    await drenarPush();
    _ultimoTickMs = _now();
  }

  /// 24 h depois do fim: a sessao (posicao e link) some e as notificacoes
  /// dela perdem lat, lon e shareUrl, numa transacao so.
  Future<void> _limparLgpd() async {
    final int limite = _now() - config.purgeAfterMs;
    final List<String> ids = await _store.sessionIdsEndedBefore(limite);
    if (ids.isEmpty) return;
    await _store.transaction((tx) async {
      for (final String id in ids) {
        await tx.scrubSessionNotifications(id);
      }
      await tx.deleteSessionsEndedBefore(limite);
    });
  }

  Future<void> _vigiar(String id, SafetyStore tx) async {
    final SafetySessionRecord? s = await tx.findSession(id);
    if (s == null || s.ended) return;
    final int agora = _now();

    if (agora >= s.etaMs + config.endGraceMs) {
      await _encerrarSozinha(s, tx, agora);
      return;
    }

    if (s.status == 'active') {
      final String? motivo = _motivo(s, agora);
      if (motivo == null) return;
      s
        ..status = 'checking'
        ..checkReason = motivo
        ..checkStartedAtMs = agora
        ..checkDeadlineMs = agora + config.checkMs;
      await tx.saveSession(s);
      final int minutos = (config.checkMs / 60000).ceil();
      await _notificar(
        tx,
        s.ownerId,
        'safety_check',
        'Esta tudo bem?',
        '${_motivoCheck[motivo]} Responda em ate $minutos min ou seus '
            'contatos serao avisados.',
        {
          'sessionId': s.id,
          'reason': motivo,
          'deadlineMs': s.checkDeadlineMs,
        },
      );
      return;
    }

    if (s.status == 'checking' && agora >= s.checkDeadlineMs!) {
      s
        ..status = 'alerted'
        ..alertedAtMs = agora;
      await tx.saveSession(s);
      final UserRecord? dona = await _users.findById(s.ownerId);
      final String nome = dona?.displayName ?? 'Sua contato';
      await _avisarContatos(
        tx,
        s,

        'safety_alert',
        '${primeiroNome(nome)} nao respondeu',
        '$nome nao respondeu ao Rastro Seguro: '
            '${_motivoAlerta[s.checkReason]}. Veja a ultima posicao no link.',
        {
          'sessionId': s.id,
          'shareUrl': shareUrlDe(s),
          'reason': s.checkReason,
          'ownerName': nome,
        },
      );
    }
    // alerted: nada (um alerta por checagem).
  }

  /// Fim automatico em eta + 6 h. Nao engole uma checagem em curso: se ela
  /// estava sendo perguntada, ou se esta em silencio de verdade (ex.: o
  /// servidor ficou fora do ar e voltou depois do fim), os contatos recebem o
  /// alerta antes de encerrar. A dona sempre recebe `safety_ended`; se houve
  /// alerta sem resposta, os contatos recebem `safety_ended_unconfirmed`.
  Future<void> _encerrarSozinha(
      SafetySessionRecord s, SafetyStore tx, int agora) async {
    final UserRecord? dona = await _users.findById(s.ownerId);
    final String nome = dona?.displayName ?? 'Sua contato';
    final bool emSilencio = agora - s.lastSignalAtMs > config.silenceMs;
    if (s.status == 'checking' || (s.status == 'active' && emSilencio)) {
      final String motivo = s.checkReason ?? 'eta';
      s
        ..status = 'alerted'
        ..checkReason = motivo
        ..checkStartedAtMs ??= agora
        ..alertedAtMs = agora;
      await _avisarContatos(
        tx,
        s,
        'safety_alert',
        '${primeiroNome(nome)} nao respondeu',
        '$nome nao respondeu ao Rastro Seguro: '
            '${_motivoAlerta[motivo]}. Veja a ultima posicao no link.',
        {
          'sessionId': s.id,
          'shareUrl': shareUrlDe(s),
          'reason': motivo,
          'ownerName': nome,
        },
      );
    }
    final bool semResposta = s.status == 'alerted';
    s
      ..status = 'ended'
      ..endReason = 'expired'
      ..endedAtMs = agora;
    // Link segue valendo ate a limpeza (24 h): se ela nao respondeu, os
    // contatos ainda precisam dele.
    await tx.saveSession(s);
    await _notificar(
      tx,
      s.ownerId,
      'safety_ended',
      'O acompanhamento terminou',
      'O Rastro Seguro encerrou sozinho 6 h depois do horario previsto.',
      {'sessionId': s.id},
    );
    if (semResposta) {
      await _avisarContatos(
        tx,
        s,
        'safety_ended_unconfirmed',
        '${primeiroNome(nome)}: acompanhamento encerrado',
        'O acompanhamento de $nome terminou sem confirmacao de chegada. '
            'O link da ultima posicao vale por mais 24 h.',
        {'sessionId': s.id, 'shareUrl': shareUrlDe(s), 'ownerName': nome},
      );
    }
  }

  /// Primeira regra que dispara, na ordem do contrato.

  String? _motivo(SafetySessionRecord s, int agora) {
    if (agora - max(s.lastSignalAtMs, _carenciaDesdeMs) > config.silenceMs) {
      return 'silence';
    }

    final int? parada = s.stillSinceMs;
    if (parada != null && agora - parada >= config.stopMs) return 'stopped';
    final int limite = max(s.etaMs, s.etaRecheckAfterMs ?? 0);
    if (agora > limite) return 'eta';
    return null;
  }

  // ----------------------------------------------------------- link publico

  /// Dados do link publico, ou null se o link nao existe ou expirou.
  Future<PublicSessionView?> publicView(String token) async {
    if (!formatoTokenLink.hasMatch(token)) return null;
    final SafetySessionRecord? s = await _store.findSessionByShareToken(token);
    final int agora = _now();
    if (s == null) return null;
    if (s.shareExpiresAtMs != null && agora >= s.shareExpiresAtMs!) return null;
    if (s.ended &&
        s.endedAtMs != null &&
        agora > s.endedAtMs! + config.purgeAfterMs) {
      return null;
    }
    final UserRecord? dona = await _users.findById(s.ownerId);
    final String estado;
    int? desde;
    if (s.ended && s.endReason == 'arrived') {
      estado = 'arrived';
      desde = s.endedAtMs;
    } else if (s.status == 'alerted' || (s.ended && s.alertedAtMs != null)) {
      estado = 'no_response';
      desde = s.checkStartedAtMs ?? s.alertedAtMs;
    } else if (s.ended) {
      estado = 'ended';
      desde = s.endedAtMs;
    } else {
      estado = 'active';
    }
    return PublicSessionView(
      firstName: primeiroNome(dona?.displayName ?? ''),
      state: estado,
      sinceMs: desde,
      etaMs: s.etaMs,
      lastPosition: s.lastPosition,
      lastSignalAtMs: s.lastSignalAtMs,
      nowMs: agora,
    );
  }
}

/// O que o link publico mostra. Sem email, trajeto nem historico.
class PublicSessionView {
  const PublicSessionView({
    required this.firstName,
    required this.state,
    required this.sinceMs,
    required this.etaMs,
    required this.lastPosition,
    required this.lastSignalAtMs,
    required this.nowMs,
  });

  final String firstName;

  /// `active` | `no_response` | `arrived` | `ended`.
  final String state;
  final int? sinceMs;
  final int etaMs;
  final SafetyPosition? lastPosition;
  final int lastSignalAtMs;
  final int nowMs;

  int? get lastPositionAgeMs => lastPosition == null
      ? null
      : max(0, nowMs - lastPosition!.ageReferenceMs);


  String? get mapUrl {
    final SafetyPosition? p = lastPosition;
    if (p == null) return null;
    final String la = p.lat.toStringAsFixed(6);
    final String lo = p.lon.toStringAsFixed(6);
    return 'https://www.openstreetmap.org/?mlat=$la&mlon=$lo#map=17/$la/$lo';
  }

  Map<String, dynamic> toJson() => {
        'firstName': firstName,
        'state': state,
        'sinceMs': sinceMs,
        'etaMs': etaMs,
        'lastPosition': lastPosition == null
            ? null
            : {
                'lat': lastPosition!.lat,
                'lon': lastPosition!.lon,
                'accuracyM': lastPosition!.accuracyM,
                'recordedAtMs': lastPosition!.recordedAtMs,
              },
        'lastPositionAgeMs': lastPositionAgeMs,
        'lastSignalAt': lastSignalAtMs,
        'mapUrl': mapUrl,
        'generatedAt': nowMs,
      };
}
