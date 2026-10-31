// Controller de sincronizacao manual: dispara o processamento da fila de
// pendentes e expoe o resultado para a UI. A execucao fica no SyncService
// (ja testado); aqui so orquestramos estado e mensagem.
library;

// ignore_for_file: prefer_initializing_formals

import 'package:flutter_riverpod/legacy.dart';

import '../persistence/database.dart';
import 'upload/sync_service.dart';

const String kSignInToSyncMessage = 'Entre na sua conta para sincronizar';

class SyncUiState {
  final bool running;
  final String? message;

  /// Sobe a cada resultado novo, mesmo com o texto repetido: a tela mostra o
  /// aviso de novo a cada toque em Sincronizar (HIS-01).
  final int messageSeq;

  const SyncUiState({this.running = false, this.message, this.messageSeq = 0});
}

class SyncController extends StateNotifier<SyncUiState> {
  final SyncService _service;
  final RecordingDatabase _db;

  /// Conta logada, ou null. Sem conta nao ha para quem enviar (401).
  final Future<String?> Function() _currentUserId;

  SyncController(
    this._service,
    this._db, {
    required Future<String?> Function() currentUserId,
  }) : _currentUserId = currentUserId,
       super(const SyncUiState());

  Future<void> syncNow() async {
    if (state.running) return;
    final userId = await _currentUserId();
    if (userId == null) {
      _finish(kSignInToSyncMessage);
      return;
    }
    state = SyncUiState(running: true, messageSeq: state.messageSeq);
    await _service.prepareRound(userId);
    await _service.processRemoteDeletions(ownerUserId: userId);
    final before = (await _db.pendingActivities(ownerUserId: userId)).length;
    if (before == 0) {
      _finish('Nada para sincronizar');
      return;
    }
    try {
      final ok = await _service.processPending(ownerUserId: userId);
      final failed = before - ok;
      _finish(
        failed == 0
            ? '$ok sincronizada(s)'
            : '$ok sincronizada(s), $failed falhou(aram)',
      );
    } catch (e) {
      _finish('Falha na sincronizacao: $e');
    }
  }

  void _finish(String message) {
    state = SyncUiState(message: message, messageSeq: state.messageSeq + 1);
  }
}
