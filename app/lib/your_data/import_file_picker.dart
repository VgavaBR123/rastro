/// Seletor de arquivos da importacao (F07). Atras de uma interface para os
/// testes (e o E2E no emulador) trocarem o seletor do sistema por caminhos
/// fixos: `importFilePickerProvider.overrideWithValue(FixedImportFilePicker([...]))`.
library;

import 'package:file_picker/file_picker.dart';

import 'import_feed.dart';

abstract class ImportFilePicker {
  /// Caminhos locais escolhidos (vazio = cancelou).
  Future<List<String>> pick();

  /// Libera as copias temporarias que o seletor fez (depois da importacao).
  Future<void> cleanUp();
}

/// Seletor do sistema (pacote file_picker). Sem filtro de extensao no
/// seletor: .fit e .gz nao tem tipo MIME confiavel no Android, e o filtro
/// esconderia arquivos validos. O que nao e aceito vira erro no resumo.
class SystemImportFilePicker implements ImportFilePicker {
  const SystemImportFilePicker();

  @override
  Future<List<String>> pick() async {
    final files = await FilePicker.pickFiles(dialogTitle: 'Escolha os arquivos');
    return [for (final f in files) ?f.path];
  }

  @override
  Future<void> cleanUp() async {
    try {
      await FilePicker.clearTemporaryFiles();
    } on Object {
      // Limpeza e cortesia: o sistema apaga o cache sozinho depois.
    }
  }
}

/// Seletor que devolve sempre [paths] (testes e E2E com arquivos enviados
/// por adb). Nao apaga nada.
class FixedImportFilePicker implements ImportFilePicker {
  final List<String> paths;
  const FixedImportFilePicker(this.paths);

  @override
  Future<List<String>> pick() async => paths;

  @override
  Future<void> cleanUp() async {}
}

/// Para mostrar na tela: as extensoes aceitas.
String get acceptedExtensionsText => ['.zip', ...kImportExtensions].join(', ');
