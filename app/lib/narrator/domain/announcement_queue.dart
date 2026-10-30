// Fila de falas com prioridade (F03). Dart puro: o relogio vem de fora.
library;

import 'announcement.dart';

class _Entry {
  final Announcement announcement;
  final int addedMs;
  final int seq;
  const _Entry(this.announcement, this.addedMs, this.seq);
}

class AnnouncementQueue {
  /// Teto de falas pendentes; acima disso sai a de menor prioridade mais antiga.
  final int maxLength;

  AnnouncementQueue({this.maxLength = 8});

  final List<_Entry> _items = [];
  int _seq = 0;

  bool get isEmpty => _items.isEmpty;
  int get length => _items.length;

  void add(Announcement a, int nowMs) {
    if (a.text.trim().isEmpty) return;
    final key = a.key;
    if (key != null) _items.removeWhere((e) => e.announcement.key == key);
    _items.add(_Entry(a, nowMs, _seq++));
    while (_items.length > maxLength) {
      _items.remove(_lowest());
    }
  }

  /// Menor prioridade; empate sai a mais antiga.
  _Entry _lowest() => _items.reduce((x, y) {
    final px = x.announcement.priority.index;
    final py = y.announcement.priority.index;
    if (px != py) return px < py ? x : y;
    return x.seq < y.seq ? x : y;
  });

  /// Proxima fala: maior prioridade, e na mesma prioridade a mais antiga.
  /// Descarta as que passaram de [Announcement.maxAgeMs].
  Announcement? takeNext(int nowMs) {
    _items.removeWhere((e) {
      final max = e.announcement.maxAgeMs;
      return max != null && nowMs - e.addedMs > max;
    });
    if (_items.isEmpty) return null;
    final best = _items.reduce((x, y) {
      final px = x.announcement.priority.index;
      final py = y.announcement.priority.index;
      if (px != py) return px > py ? x : y;
      return x.seq < y.seq ? x : y;
    });
    _items.remove(best);
    return best.announcement;
  }

  /// Maior prioridade pendente, ou null.
  AnnouncementPriority? get highestPending => _items.isEmpty
      ? null
      : AnnouncementPriority.values[_items
            .map((e) => e.announcement.priority.index)
            .reduce((a, b) => a > b ? a : b)];

  void clear() => _items.clear();
}
