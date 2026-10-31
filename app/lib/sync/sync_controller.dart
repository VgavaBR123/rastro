// Controller de sincronizacao manual: dispara o processamento da fila de
// pendentes e expoe o resultado para a UI. A execucao fica no SyncService
// (ja testado); aqui so orquestramos estado e mensagem.
library;

// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';

import '../persistence/database.dart';
import 'upload/activity_uploader.dart';
import 'upload/sync_service.dart';

const String kSignInToSyncMessage = 'Entre na sua conta para sincronizar';
const String kSessionExpiredMessage =
    'Sua sessão expirou. Entre de novo para sincronizar';
const String kSyncOfflineMessage =
    'Sem conexão com o servidor. Tente de novo mais tarde';
const String kSyncGenericErrorMessage =
    'Não foi possível sincronizar. Tente de novo';

/// Mensagem amigavel para uma falha da rodada (HIS-03): nunca o texto cru da
/// excecao, que nao diz nada ao usuario.
String syncErrorMessage(Object error) => switch (error) {
  UnauthorizedUploadException() => kSessionExpiredMessage,
  NetworkUploadException() || TimeoutException() => kSyncOfflineMessage,
  _ => kSyncGenericErrorMessage,
};

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
    // Tudo depois de `running: true` fica no try: uma excecao em qualquer
    // passo precisa devolver o botao (HIS-03).
    try {
      await _service.prepareRound(userId);
      await _service.processRemoteDeletions(ownerUserId: userId);
      final before = (await _db.pendingActivities(ownerUserId: userId)).length;
      if (before == 0) {
        _finish('Nada para sincronizar');
        return;
      }
      final ok = await _service.processPending(ownerUserId: userId);
      final failed = before - ok;
      _finish(
        failed == 0
            ? '$ok sincronizada(s)'
            : '$ok sincronizada(s), $failed falhou(aram)',
      );
    } on Object catch (e) {
      _finish(syncErrorMessage(e));
    }
  }

  void _finish(String message) {
    state = SyncUiState(message: message, messageSeq: state.messageSeq + 1);
  }
}
