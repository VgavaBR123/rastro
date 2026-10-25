// CRC-16 do formato FIT (Flexible and Interoperable Data Transfer).
//
// O FIT usa um CRC-16 "nibble-based": para cada byte processado, o algoritmo
// faz dois passos (nibble baixo e nibble alto) consultando uma tabela de 16
// entradas. Este e o algoritmo publico documentado no FIT SDK; a tabela e os
// passos abaixo foram reimplementados a partir dessa descricao (clean room),
// sem copiar codigo de terceiros.
library;

import 'dart:typed_data';

/// Tabela de 16 entradas usada pelo CRC-16 do FIT (indexada por nibble).
const List<int> _fitCrcTable = <int>[
  0x0000, 0xCC01, 0xD801, 0x1400, //
  0xF001, 0x3C00, 0x2800, 0xE401, //
  0xA001, 0x6C00, 0x7800, 0xB401, //
  0x5000, 0x9C01, 0x8801, 0x4400, //
];

/// Calcula o CRC-16 do FIT sobre [bytes].
///
/// O parametro [crc] permite encadear o calculo em pedacos (passa-se o
/// resultado anterior como semente). Para uma lista vazia o resultado e
/// igual a semente (0 por padrao), conforme esperado pelo formato.
int fitCrc16(List<int> bytes, [int crc = 0]) {
  for (final int rawByte in bytes) {
    final int byte = rawByte & 0xFF;

    // Primeiro passo: nibble baixo do byte.
    int tmp = _fitCrcTable[crc & 0x0F];
    crc = (crc >> 4) & 0x0FFF;
    crc = crc ^ tmp ^ _fitCrcTable[byte & 0x0F];

    // Segundo passo: nibble alto do byte.
    tmp = _fitCrcTable[crc & 0x0F];
    crc = (crc >> 4) & 0x0FFF;
    crc = crc ^ tmp ^ _fitCrcTable[(byte >> 4) & 0x0F];
  }
  return crc & 0xFFFF;
}

/// Variante de conveniencia que opera diretamente sobre um [Uint8List].
int fitCrc16Bytes(Uint8List bytes, [int crc = 0]) => fitCrc16(bytes, crc);
