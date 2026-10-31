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

class InboxState {
  /// Mais novas primeiro.
  final List<AppNotification> items;
  final bool loading;
  final String? error;
  const InboxState({this.items = const [], this.loading = false, this.error});

  int get unread => items.where((n) => n.unread).length;
}

class InboxController extends StateNotifier<InboxState> {
  final SafetyApi _api;
  final int Function() _now;

  /// Notificacao nova (nao vista antes nesta execucao) chegou.
  final void Function(AppNotification n)? onNew;

  int _since = 0;
  bool _fetching = false;

  InboxController(this._api, {required int Function() now, this.onNew}) : _now = now, super(const InboxState());

  Future<void> refresh() async {
    if (_fetching) return;
    _fetching = true;
    if (state.items.isEmpty) state = InboxState(items: state.items, loading: true);
    try {
      final list = await _api.notifications(since: _since);
      if (!mounted) return;
      final known = {for (final n in state.items) n.id};
      final fresh = [
        for (final n in list)
          if (!known.contains(n.id)) n,
      ];
      final merged = [...fresh, ...state.items]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      for (final n in list) {
        if (n.createdAt > _since) _since = n.createdAt;
      }
      state = InboxState(items: merged);
      for (final n in fresh.reversed) {
        onNew?.call(n);
      }
    } on SafetyException catch (e) {
      if (mounted) state = InboxState(items: state.items, error: e.message);
    } finally {
      _fetching = false;
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

  /// Saiu da conta: esquece tudo.
  void reset() {
    _since = 0;
    state = const InboxState();
  }
}
