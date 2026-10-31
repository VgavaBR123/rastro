/// Estado e acoes da tela Seus dados (F07): importar (escolher arquivos,
/// progresso, cancelar, resumo) e exportar tudo (opcao de privacidade,
/// progresso, compartilhar).
///
/// Vive fora da tela (provider sem autoDispose): sair da tela no meio nao
/// para a importacao; voltar mostra o progresso ou o resumo.
library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../persistence/database.dart';
import '../platform/activity_sharer.dart';
import 'export_service.dart';
import 'import_feed.dart';
import 'import_file_picker.dart';
import 'import_service.dart';

enum YourDataPhase { idle, importing, imported, exporting }

@immutable
class YourDataState {
  final YourDataPhase phase;

  /// Progresso da importacao ou da exportacao.
  final int done;
  final int total;

  /// Cancelamento pedido (a fila para antes do proximo item).
  final bool cancelling;
  final ImportSummary? summary;

  /// "Aplicar zonas de privacidade" na exportacao (padrao ligado).
  final bool exportPrivacy;

  /// Mensagem curta de falha (seletor, exportacao, compartilhar).
  final String? message;

  const YourDataState({
    this.phase = YourDataPhase.idle,
    this.done = 0,
    this.total = 0,
    this.cancelling = false,
    this.summary,
    this.exportPrivacy = true,
    this.message,
  });

  bool get busy => phase == YourDataPhase.importing || phase == YourDataPhase.exporting;

  /// Fracao para a barra (null = indeterminada, antes de saber o total).
  double? get fraction => total <= 0 ? null : (done / total).clamp(0.0, 1.0);

  YourDataState copyWith({
    YourDataPhase? phase,
    int? done,
    int? total,
    bool? cancelling,
    ImportSummary? summary,
    bool clearSummary = false,
    bool? exportPrivacy,
    String? message,
    bool clearMessage = false,
  }) => YourDataState(
    phase: phase ?? this.phase,
    done: done ?? this.done,
    total: total ?? this.total,
    cancelling: cancelling ?? this.cancelling,
    summary: clearSummary ? null : (summary ?? this.summary),
    exportPrivacy: exportPrivacy ?? this.exportPrivacy,
    message: clearMessage ? null : (message ?? this.message),
  );
}

/// Falha ao abrir os arquivos escolhidos (a copia do seletor costuma falhar
/// por falta de espaco).
const String kPickFailedMessage =
    'Nao foi possivel abrir os arquivos. Confira se ha espaco livre no aparelho.';

/// Outra exportacao (tudo ou uma atividade) ainda esta rodando.
const String kExportBusyMessage = 'Ja ha uma exportacao em andamento';

typedef ImportFeedFactory = Future<ImportFeed> Function(List<String> paths);

class YourDataController extends StateNotifier<YourDataState> {
  final RecordingDatabase db;
  final ImportFilePicker picker;
  final ImportFeedFactory openFeed;
  final Future<Directory> Function() exportDir;
  final ActivitySharer sharer;

  /// Depois de uma importacao com atividades novas (atualizar listas e
  /// agendar o sync normal).
  final void Function(ImportSummary summary)? onImported;

  YourDataController({
    required this.db,
    required this.picker,
    required this.openFeed,
    required this.exportDir,
    required this.sharer,
    this.onImported,
  }) : super(const YourDataState());

  bool _cancel = false;

  /// Abre o seletor e importa o que for escolhido. Nada escolhido: volta ao
  /// estado anterior.
  Future<void> pickAndImport() async {
    if (state.busy) return;
    final p = picker;
    List<String> paths;
    try {
      paths = p is ProgressImportFilePicker
          ? await p.pickWithProgress(() {
              // O sistema esta copiando os arquivos: barra indeterminada.
              if (mounted && !state.busy) {
                state = state.copyWith(
                  phase: YourDataPhase.importing,
                  done: 0,
                  total: 0,
                  cancelling: false,
                  clearSummary: true,
                  clearMessage: true,
                );
              }
            })
          : await p.pick();
    } on Object {
      if (mounted) {
        state = state.copyWith(
          phase: YourDataPhase.idle,
          message: kPickFailedMessage,
        );
      }
      return;
    }
    if (!mounted) return;
    if (paths.isEmpty) {
      if (state.phase == YourDataPhase.importing) {
        state = state.copyWith(phase: YourDataPhase.idle);
      }
      return;
    }
    // A fase "preparando" ja estava ligada: libera para a importacao.
    if (state.phase == YourDataPhase.importing) state = state.copyWith(phase: YourDataPhase.idle);
    await importPaths(paths);
  }

  /// Importa [paths] (ZIP e arquivos soltos), fora da thread da interface.
  Future<void> importPaths(List<String> paths) async {
    if (state.busy) return;
    _cancel = false;
    state = state.copyWith(
      phase: YourDataPhase.importing,
      done: 0,
      total: 0,
      cancelling: false,
      clearSummary: true,
      clearMessage: true,
    );
    ImportSummary summary;
    try {
      final feed = await openFeed(paths);
      summary = await ImportService(db).run(
        feed,
        isCancelled: () => _cancel,
        onProgress: (p) {
          if (mounted) state = state.copyWith(done: p.done, total: p.total);
        },
      );
    } on Object {
      summary = const ImportSummary(
        total: 0,
        imported: 0,
        duplicates: 0,
        ignored: {},
        errors: [ImportFailure('importacao', 'falha inesperada')],
        cancelled: false,
        interrupted: true,
      );
    } finally {
      await picker.cleanUp();
    }
    if (!mounted) return;
    state = state.copyWith(phase: YourDataPhase.imported, summary: summary, cancelling: false);
    if (summary.imported > 0) onImported?.call(summary);
  }

  /// Pede para parar: o que ja foi importado (ou exportado) fica.
  void cancel() {
    if (!state.busy) return;
    _cancel = true;
    state = state.copyWith(cancelling: true);
  }

  /// Fecha o resumo e volta ao inicio.
  void dismissSummary() {
    if (state.busy) return;
    state = state.copyWith(phase: YourDataPhase.idle, clearSummary: true, clearMessage: true);
  }

  void setExportPrivacy(bool value) => state = state.copyWith(exportPrivacy: value);

  void clearMessage() => state = state.copyWith(clearMessage: true);

  /// Gera o ZIP de tudo e abre o compartilhar do sistema.
  Future<void> exportAll() async {
    if (state.busy) return;
    _cancel = false;
    state = state.copyWith(
      phase: YourDataPhase.exporting,
      done: 0,
      total: 0,
      cancelling: false,
      clearMessage: true,
    );
    String? message;
    try {
      final result = await ExportService(db).exportAll(
        outDir: await exportDir(),
        applyPrivacy: state.exportPrivacy,
        isCancelled: () => _cancel,
        onProgress: (d, t) {
          if (mounted) state = state.copyWith(done: d, total: t);
        },
      );
      if (result != null) {
        if (result.count == 0) {
          message = 'Nenhuma atividade para exportar';
        } else {
          try {
            await sharer.shareFile(result.path, mimeType: 'application/zip');
          } on Object {
            message = 'Nao foi possivel abrir o compartilhamento';
          }
        }
      }
    } on ExportBusyException {
      message = kExportBusyMessage;
    } on Object {
      message = 'Nao foi possivel exportar';
    }
    if (!mounted) return;
    state = state.copyWith(phase: YourDataPhase.idle, cancelling: false, message: message);
  }
}
