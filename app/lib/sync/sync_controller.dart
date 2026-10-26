// Controller de sincronizacao manual: dispara o processamento da fila de
// pendentes e expoe o resultado para a UI. A execucao fica no SyncService
// (ja testado); aqui so orquestramos estado e mensagem.
library;

import 'package:flutter_riverpod/legacy.dart';

import '../persistence/database.dart';
import 'upload/sync_service.dart';

const String kSignInToSyncMessage = 'Entre na sua conta para sincronizar';

class SyncUiState {
  final bool running;
  final String? message;
  const SyncUiState({this.running = false, this.message});
}

class SyncController extends StateNotifier<SyncUiState> {
  final SyncService _service;
  final RecordingDatabase _db;

  /// Sem conta nao ha para quem enviar: o upload seria recusado (401).
  final Future<bool> Function() _isSignedIn;

  SyncController(this._service, this._db, {Future<bool> Function()? isSignedIn})
      : _isSignedIn = isSignedIn ?? (() async => true),
        super(const SyncUiState());

  Future<void> syncNow() async {
    if (state.running) return;
    if (!await _isSignedIn()) {
      state = const SyncUiState(message: kSignInToSyncMessage);
      return;
    }
    state = const SyncUiState(running: true);
    await _service.requeueStalled();
    final before = (await _db.pendingActivities()).length;
    if (before == 0) {
      state = const SyncUiState(message: 'Nada para sincronizar');
      return;
    }
    try {
      final ok = await _service.processPending();
      final failed = before - ok;
      state = SyncUiState(
        message: failed == 0
            ? '$ok sincronizada(s)'
            : '$ok sincronizada(s), $failed falhou(aram)',
      );
    } catch (e) {
      state = SyncUiState(message: 'Falha na sincronizacao: $e');
    }
  }
}
