// Caixa de entrada (F08): notificacoes do backend buscadas com
// `GET /notifications?since=` (a cada 30 s em primeiro plano e ao voltar do
// segundo plano; o [InboxPoller] cuida disso). Funciona sem push. Guardada
// so em memoria: o backend e a fonte.
library;

// ignore_for_file: prefer_initializing_formals

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'safety_api.dart';
import 'safety_models.dart';

/// Tamanho maximo de uma pagina de `GET /notifications` (contrato).
const int kInboxPageSize = 50;

/// Paginas seguidas numa busca (pagina cheia busca de novo).
const int kInboxMaxPages = 5;

class InboxState {
  /// Mais novas primeiro.
  final List<AppNotification> items;
  final bool loading;
  final String? error;
  const InboxState({this.items = const [], this.loading = false, this.error});

  int get unread => items.where((n) => n.unread).length;

  /// Link mais novo da sessao de [n]: o backend troca o token quando um
  /// contato sai (safety_link_updated, safety_contact_removed) e o antigo para
  /// de funcionar.
  String? shareUrlFor(AppNotification n) {
    final id = n.sessionId;
    if (id == null) return n.shareUrl;
    for (final m in items) {
      if (m.sessionId == id && m.shareUrl != null) return m.shareUrl;
    }
    return n.shareUrl;
  }
}

class InboxController extends StateNotifier<InboxState> {
  final SafetyApi _api;
  final int Function() _now;

  /// Notificacao nova (nao vista antes nesta execucao) chegou.
  final void Function(AppNotification n)? onNew;

  /// Maior createdAt visto. A busca usa `since = max - 1` (com dedup por id)
  /// para nao perder outra notificacao gravada no mesmo milissegundo.
  int _maxSeen = 0;
  bool _fetching = false;

  /// Sobe a cada reset: a busca em voo de antes do reset e descartada.
  int _generation = 0;

  InboxController(this._api, {required int Function() now, this.onNew}) : _now = now, super(const InboxState());

  Future<void> refresh() async {
    if (_fetching) return;
    _fetching = true;
    final gen = _generation;
    if (state.items.isEmpty) state = InboxState(items: state.items, loading: true);
    try {
      final fresh = <AppNotification>[];
      final known = {for (final n in state.items) n.id};
      // Pagina cheia: pode haver mais novas; busca de novo a partir do maior
      // visto. (Com so `since` no contrato, o que ficar ANTES das 50 mais
      // novas de uma rajada nao e alcancado.)
      for (var page = 0; page < kInboxMaxPages; page++) {
        final list = await _api.notifications(since: _maxSeen == 0 ? 0 : _maxSeen - 1);
        if (!mounted || gen != _generation) return;
        var added = 0;
        for (final n in list) {
          if (n.createdAt > _maxSeen) _maxSeen = n.createdAt;
          if (known.add(n.id)) {
            fresh.add(n);
            added++;
          }
        }
        if (list.length < kInboxPageSize || added == 0) break;
      }
      final merged = [...fresh, ...state.items]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = InboxState(items: merged);
      fresh.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      for (final n in fresh) {
        onNew?.call(n);
      }
    } on SafetyException catch (e) {
      if (mounted && gen == _generation) state = InboxState(items: state.items, error: e.message);
    } finally {
      if (gen == _generation) _fetching = false;
    }
  }

  /// Marca [id] como lida (na hora aqui; no backend quando houver rede).
  Future<void> markRead(String id) async {
    final i = state.items.indexWhere((n) => n.id == id);
    if (i < 0 || !state.items[i].unread) return;
    final items = [...state.items];
    items[i] = items[i].markRead(_now());
    state = InboxState(items: items, error: state.error);
    try {
      await _api.markRead(id);
    } on SafetyException catch (e) {
      debugPrint('Caixa de entrada: nao marcou $id como lida no servidor: $e');
    }
  }

  /// Saiu da conta: esquece tudo (inclusive a busca em voo).
  void reset() {
    _generation++;
    _maxSeen = 0;
    _fetching = false;
    state = const InboxState();
  }
}
