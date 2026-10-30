// Frase a falar pelo Narrador (F03). E a moeda da API generica: o Narrador da
// gravacao, o plano 5 km (F06) e os sensores (F11) enfileiram Announcements.
library;

/// Prioridade da fala. A maior sai primeiro; [critical] ainda interrompe uma
/// fala menor que esteja tocando (ex.: alerta de frequencia cardiaca).
enum AnnouncementPriority { low, normal, high, critical }

class Announcement {
  final String text;
  final AnnouncementPriority priority;

  /// Falas com a mesma chave se substituem na fila (fica a mais nova). Ex.:
  /// "Pausa automatica" seguida de "Gravacao retomada" antes de tocar.
  final String? key;

  /// Idade maxima na fila (ms). Passou disso sem tocar, e descartada: uma
  /// marca de tempo atrasada so confunde.
  final int? maxAgeMs;

  const Announcement(
    this.text, {
    this.priority = AnnouncementPriority.normal,
    this.key,
    this.maxAgeMs,
  });

  @override
  String toString() => 'Announcement($priority, "$text")';
}
