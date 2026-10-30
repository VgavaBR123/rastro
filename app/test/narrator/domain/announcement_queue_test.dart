// Fila de falas do Narrador (F03): prioridade, ordem de chegada, troca por
// chave e descarte de fala velha.
import 'package:flutter_test/flutter_test.dart';
import 'package:strava_estudo_app/narrator/domain/announcement.dart';
import 'package:strava_estudo_app/narrator/domain/announcement_queue.dart';

Announcement a(String text, {
  AnnouncementPriority p = AnnouncementPriority.normal,
  String? key,
  int? maxAgeMs,
}) => Announcement(text, priority: p, key: key, maxAgeMs: maxAgeMs);

void main() {
  late AnnouncementQueue q;
  setUp(() => q = AnnouncementQueue());

  test('vazia devolve null', () {
    expect(q.takeNext(0), isNull);
    expect(q.isEmpty, isTrue);
  });

  test('mesma prioridade sai na ordem de chegada', () {
    q.add(a('um'), 0);
    q.add(a('dois'), 0);
    expect(q.takeNext(0)!.text, 'um');
    expect(q.takeNext(0)!.text, 'dois');
    expect(q.takeNext(0), isNull);
  });

  test('prioridade maior passa na frente', () {
    q.add(a('baixa', p: AnnouncementPriority.low), 0);
    q.add(a('normal'), 0);
    q.add(a('alta', p: AnnouncementPriority.high), 0);
    q.add(a('critica', p: AnnouncementPriority.critical), 0);
    expect([for (var i = 0; i < 4; i++) q.takeNext(0)!.text], ['critica', 'alta', 'normal', 'baixa']);
  });

  test('mesma chave substitui a pendente, na posicao da nova', () {
    q.add(a('pausa', key: 'estado'), 0);
    q.add(a('split'), 0);
    q.add(a('retomada', key: 'estado'), 0);
    expect(q.length, 2);
    expect(q.takeNext(0)!.text, 'split');
    expect(q.takeNext(0)!.text, 'retomada');
  });

  test('fala velha e descartada', () {
    q.add(a('tempo', p: AnnouncementPriority.low, maxAgeMs: 30000), 1000);
    q.add(a('fica'), 1000);
    expect(q.takeNext(40000)!.text, 'fica');
    expect(q.takeNext(40000), isNull);
  });

  test('limite de tamanho descarta a de menor prioridade mais antiga', () {
    final small = AnnouncementQueue(maxLength: 2);
    small.add(a('baixa', p: AnnouncementPriority.low), 0);
    small.add(a('normal'), 0);
    small.add(a('alta', p: AnnouncementPriority.high), 0);
    expect(small.length, 2);
    expect(small.takeNext(0)!.text, 'alta');
    expect(small.takeNext(0)!.text, 'normal');
  });

  test('texto vazio e ignorado', () {
    q.add(a('   '), 0);
    expect(q.isEmpty, isTrue);
  });

  test('clear esvazia', () {
    q.add(a('x'), 0);
    q.clear();
    expect(q.isEmpty, isTrue);
  });
}
