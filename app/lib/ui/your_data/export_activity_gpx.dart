// Detalhe da atividade > menu > Exportar GPX (F07): dialogo com a opcao
// "Aplicar zonas de privacidade" (ligada por padrao), gera o GPX e abre o
// compartilhar do sistema.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../persistence/database.dart';
import '../../platform/activity_sharer.dart';
import '../../your_data/export_service.dart';
import '../../your_data/your_data_controller.dart' show kExportBusyMessage;
import '../../your_data/your_data_providers.dart';

/// Tipo MIME do GPX no compartilhar.
const String kGpxMimeType = 'application/gpx+xml';

Future<void> exportActivityGpx(BuildContext context, WidgetRef ref, Activity activity) async {
  final privacy = await showDialog<bool>(
    context: context,
    builder: (_) => const _ExportGpxDialog(),
  );
  if (privacy == null || !context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  try {
    final path = await ref.read(exportServiceProvider).exportOne(
      activity,
      outDir: await ref.read(exportDirectoryProvider)(),
      applyPrivacy: privacy,
    );
    await ref.read(activitySharerProvider).shareFile(path, mimeType: kGpxMimeType);
  } on ExportBusyException {
    messenger.showSnackBar(
      const SnackBar(key: Key('exportGpxBusy'), content: Text(kExportBusyMessage)),
    );
  } on Object {
    messenger.showSnackBar(
      const SnackBar(
        key: Key('exportGpxError'),
        content: Text('Nao foi possivel exportar o GPX'),
      ),
    );
  }
}

class _ExportGpxDialog extends StatefulWidget {
  const _ExportGpxDialog();

  @override
  State<_ExportGpxDialog> createState() => _ExportGpxDialogState();
}

class _ExportGpxDialogState extends State<_ExportGpxDialog> {
  bool _privacy = true;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Exportar GPX'),
      contentPadding: const EdgeInsets.fromLTRB(8, 16, 8, 0),
      content: SwitchListTile(
        key: const Key('exportGpxPrivacy'),
        title: const Text('Aplicar zonas de privacidade'),
        subtitle: const Text('Corta o inicio e o fim protegidos'),
        value: _privacy,
        onChanged: (v) => setState(() => _privacy = v),
      ),
      actions: [
        TextButton(
          key: const Key('exportGpxCancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('exportGpxConfirm'),
          onPressed: () => Navigator.of(context).pop(_privacy),
          child: const Text('Exportar'),
        ),
      ],
    );
  }
}
