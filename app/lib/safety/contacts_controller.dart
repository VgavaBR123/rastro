// Contatos de confianca do Rastro Seguro (F08): convidar por email, listar
// enviados e recebidos, aceitar e remover. Exige login (o backend valida).
library;

import 'package:flutter_riverpod/legacy.dart';

import 'safety_api.dart';
import 'safety_models.dart';

/// Maximo de contatos aceitos por pessoa (contrato).
const int kMaxTrustedContacts = 3;

class ContactsState {
  final ContactLists? lists;
  final bool loading;

  /// Acao (convite, aceitar, remover) em andamento.
  final bool busy;

  /// Erro de carregar a lista (sem rede, por exemplo).
  final String? error;

  /// Ultimo erro de carregar foi de login.
  final bool signedOut;

  const ContactsState({this.lists, this.loading = false, this.busy = false, this.error, this.signedOut = false});

  List<TrustedContact> get accepted => lists?.accepted ?? const [];
}

class ContactsController extends StateNotifier<ContactsState> {
  final SafetyApi _api;
  ContactsController(this._api) : super(const ContactsState());

  Future<void> load() async {
    state = ContactsState(lists: state.lists, loading: true, busy: state.busy);
    try {
      final lists = await _api.contacts();
      if (mounted) state = ContactsState(lists: lists, busy: state.busy);
    } on SafetyException catch (e) {
      if (!mounted) return;
      state = ContactsState(
        lists: state.lists,
        busy: state.busy,
        error: e.message,
        signedOut: e.kind == SafetyErrorKind.unauthorized,
      );
    }
  }

  /// Convida [email]. Devolve null se deu certo, ou a mensagem do erro.
  Future<String?> invite(String email) {
    final e = email.trim();
    if (e.isEmpty || !e.contains('@') || !e.contains('.')) {
      return Future.value('Informe um email valido.');
    }
    return _act(() => _api.invite(e));
  }

  Future<String?> accept(String id) => _act(() => _api.accept(id));

  Future<String?> remove(String id) => _act(() => _api.remove(id));

  Future<String?> _act(Future<Object?> Function() call) async {
    if (state.busy) return null;
    state = ContactsState(lists: state.lists, busy: true, error: state.error);
    try {
      await call();
      if (mounted) state = ContactsState(lists: state.lists);
      await load();
      return null;
    } on SafetyException catch (e) {
      if (mounted) state = ContactsState(lists: state.lists, error: state.error);
      return e.message;
    }
  }
}
