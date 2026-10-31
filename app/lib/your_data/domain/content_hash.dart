/// Hash do conteudo de um arquivo importado (F07): base do guid
/// deterministico, para que reimportar o mesmo arquivo nao duplique. Dart puro
/// (o VM tem inteiros de 64 bits com estouro modular).
library;

/// FNV-1a de 64 bits sobre [bytes] mais o tamanho, em hexadecimal.
/// Mesmo conteudo, mesmo hash, em qualquer aparelho.
String contentHash(List<int> bytes) {
  var h = 0xcbf29ce484222325;
  const prime = 0x100000001b3;
  for (final b in bytes) {
    h ^= b & 0xFF;
    h *= prime;
  }
  final hex = h.toUnsigned(64).toRadixString(16).padLeft(16, '0');
  return '$hex${bytes.length.toRadixString(16)}';
}
