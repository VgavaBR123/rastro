// Seus dados (F07): anuncio do progresso para o leitor de tela em degraus
// (a cada 10% ou 5 s), nunca a cada item.
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/your_data/import_service.dart';
import 'package:strava_estudo_app/your_data/progress_announcer.dart';

void main() {
  test('anuncia a cada 10% e nao a cada item', () {
    final a = ProgressAnnouncer('Importando');
    final t0 = DateTime(2026, 1, 1);
    final said = <String>[];
    for (var i = 1; i <= 100; i++) {
      final m = a.next(i, 100, t0.add(Duration(milliseconds: i * 10)));
      if (m != null) said.add(m);
    }
    expect(said, hasLength(10));
    expect(said.first, 'Importando: 10 de 100');
  });

  test('ou a cada 5 s quando anda devagar', () {
    final a = ProgressAnnouncer('Importando');
    final t0 = DateTime(2026, 1, 1);
    expect(a.next(1, 1000, t0), isNull);
    expect(a.next(2, 1000, t0.add(const Duration(seconds: 4))), isNull);
    expect(a.next(3, 1000, t0.add(const Duration(seconds: 6))), 'Importando: 3 de 1000');
  });

  test('sem total nao anuncia', () {
    expect(ProgressAnnouncer('Importando').next(0, 0, DateTime(2026)), isNull);
  });

  test('mensagem de fim da importacao', () {
    const s = ImportSummary(total: 3, imported: 2, duplicates: 0, ignored: {}, errors: [ImportFailure('a', 'b')], cancelled: false);
    expect(importEndAnnouncement(s), 'Importacao concluida: 2 importadas, 1 com erro');
    const c = ImportSummary(total: 3, imported: 1, duplicates: 0, ignored: {}, errors: [], cancelled: true);
    expect(importEndAnnouncement(c), 'Importacao cancelada: 1 importada, 0 com erro');
    const i = ImportSummary(total: 3, imported: 0, duplicates: 0, ignored: {}, errors: [], cancelled: false, interrupted: true);
    expect(importEndAnnouncement(i), startsWith('Importacao interrompida'));
  });
}
