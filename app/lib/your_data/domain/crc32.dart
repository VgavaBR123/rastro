/// CRC-32 (polinomio 0xEDB88320, o do ZIP e do gzip), em Dart puro.
library;

final List<int> _table = List<int>.generate(256, (n) {
  var c = n;
  for (var k = 0; k < 8; k++) {
    c = (c & 1) != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
  }
  return c;
}, growable: false);

/// CRC-32 incremental: [add] por partes e leia [value].
class Crc32 {
  int _crc = 0xFFFFFFFF;

  void add(List<int> bytes) {
    var c = _crc;
    for (final b in bytes) {
      c = _table[(c ^ b) & 0xFF] ^ (c >> 8);
    }
    _crc = c;
  }

  int get value => (_crc ^ 0xFFFFFFFF) & 0xFFFFFFFF;
}

int crc32(List<int> bytes) => (Crc32()..add(bytes)).value;
