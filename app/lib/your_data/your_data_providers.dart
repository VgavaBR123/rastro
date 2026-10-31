/// Providers do Seus dados (F07). Os testes e o E2E trocam o seletor
/// ([importFilePickerProvider]), a fila ([importFeedFactoryProvider]) e a
/// pasta da exportacao ([exportDirectoryProvider]).
library;

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:path_provider/path_provider.dart';

import '../app/providers.dart';
import '../platform/activity_sharer.dart';
import '../sync/background/background_sync_provider.dart';
import 'export_service.dart';
import 'import_feed.dart';
import 'import_file_picker.dart';
import 'your_data_controller.dart';

final importFilePickerProvider = Provider<ImportFilePicker>(
  (ref) => const SystemImportFilePicker(),
);

/// Fila da importacao: por padrao num isolate separado.
final importFeedFactoryProvider = Provider<ImportFeedFactory>(
  (ref) => IsolateImportFeed.open,
);

/// Onde o arquivo exportado fica ate ir para o compartilhar:
/// `<cache>/share/export/` (o FileProvider do Android expoe `cache/share/`).
final exportDirectoryProvider = Provider<Future<Directory> Function()>(
  (ref) =>
      () async => Directory('${(await getTemporaryDirectory()).path}/share/export'),
);

final exportServiceProvider = Provider<ExportService>(
  (ref) => ExportService(ref.watch(recordingDatabaseProvider)),
);

final yourDataControllerProvider =
    StateNotifierProvider<YourDataController, YourDataState>((ref) {
      return YourDataController(
        db: ref.watch(recordingDatabaseProvider),
        picker: ref.watch(importFilePickerProvider),
        openFeed: ref.watch(importFeedFactoryProvider),
        exportDir: ref.watch(exportDirectoryProvider),
        sharer: ref.watch(activitySharerProvider),
        onImported: (_) {
          ref.invalidate(recentActivitiesProvider);
          ref.invalidate(pendingCountProvider);
          // As importadas sobem pela fila normal, depois da importacao.
          ref.read(backgroundSyncSchedulerProvider).scheduleSoon();
        },
      );
    });
