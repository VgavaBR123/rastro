// Rotulos de apresentacao: nenhum estado interno vaza em ingles para a tela.
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/core/format/activity_labels.dart';
import 'package:strava_estudo_app/recording/domain/recording_models.dart';

void main() {
  test('todo estado de sincronizacao tem rotulo proprio em portugues', () {
    final labels = {for (final s in SyncState.values) s: syncStateLabel(s)};
    expect(labels[SyncState.pending], 'Aguardando envio');
    expect(labels[SyncState.synced], 'Sincronizada');
    for (final s in SyncState.values) {
      expect(labels[s], isNot(s.name), reason: '$s sem traducao');
    }
    expect(labels.values.toSet(), hasLength(SyncState.values.length));
  });
}
