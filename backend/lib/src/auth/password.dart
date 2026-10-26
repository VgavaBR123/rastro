// Hash de senha com PBKDF2-HMAC-SHA256, montado sobre o pacote oficial
// `crypto` (dart-lang). Formato guardado no banco:
//   pbkdf2_sha256$<iteracoes>$<salt_base64>$<hash_base64>
// O formato carrega as iteracoes, entao da para subir o custo no futuro sem
// invalidar as senhas antigas (cada hash e verificado com o custo dele).
library;

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Iteracoes padrao em producao. Os testes injetam um valor baixo.
const int defaultPbkdf2Iterations = 120000;

const String _prefixo = 'pbkdf2_sha256';
const int _saltBytes = 16;
const int _hashBytes = 32;

/// Gera o hash de [password] com salt aleatorio de 16 bytes.
String hashPassword(
  String password, {
  int iterations = defaultPbkdf2Iterations,
  Random? random,
}) {
  if (iterations < 1) throw ArgumentError.value(iterations, 'iterations');
  final Random rnd = random ?? Random.secure();
  final Uint8List salt = Uint8List.fromList(
      List<int>.generate(_saltBytes, (_) => rnd.nextInt(256)));
  final Uint8List dk =
      pbkdf2HmacSha256(utf8.encode(password), salt, iterations, _hashBytes);
  return '$_prefixo\$$iterations\$${base64.encode(salt)}\$${base64.encode(dk)}';
}

/// Confere [password] contra um hash no formato acima. Formato invalido ou
/// desconhecido = false (nunca lanca). Comparacao em tempo constante.
bool verifyPassword(String password, String stored) {
  final List<String> partes = stored.split(r'$');
  if (partes.length != 4 || partes[0] != _prefixo) return false;
  final int? iteracoes = int.tryParse(partes[1]);
  if (iteracoes == null || iteracoes < 1) return false;
  final Uint8List salt;
  final Uint8List esperado;
  try {
    salt = base64.decode(partes[2]);
    esperado = base64.decode(partes[3]);
  } on FormatException {
    return false;
  }
  if (esperado.isEmpty) return false;
  final Uint8List obtido =
      pbkdf2HmacSha256(utf8.encode(password), salt, iteracoes, esperado.length);
  return constantTimeEquals(obtido, esperado);
}

/// PBKDF2 (RFC 8018) com HMAC-SHA256 como PRF.
Uint8List pbkdf2HmacSha256(
    List<int> password, List<int> salt, int iterations, int length) {
  final Hmac hmac = Hmac(sha256, password);
  const int hLen = 32;
  final int blocos = (length + hLen - 1) ~/ hLen;
  final BytesBuilder saida = BytesBuilder(copy: false);
  for (int i = 1; i <= blocos; i++) {
    // U1 = PRF(P, S || INT_32_BE(i))
    final Uint8List entrada = Uint8List(salt.length + 4)
      ..setRange(0, salt.length, salt)
      ..[salt.length] = (i >> 24) & 0xff
      ..[salt.length + 1] = (i >> 16) & 0xff
      ..[salt.length + 2] = (i >> 8) & 0xff
      ..[salt.length + 3] = i & 0xff;
    List<int> u = hmac.convert(entrada).bytes;
    final Uint8List t = Uint8List.fromList(u);
    // T = U1 xor U2 xor ... xor Uc
    for (int c = 1; c < iterations; c++) {
      u = hmac.convert(u).bytes;
      for (int k = 0; k < hLen; k++) {
        t[k] ^= u[k];
      }
    }
    saida.add(t);
  }
  return Uint8List.sublistView(saida.takeBytes(), 0, length);
}

/// Compara sem sair cedo no primeiro byte diferente (evita vazar, pelo tempo
/// de resposta, quantos bytes iniciais batem).
bool constantTimeEquals(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  int diff = 0;
  for (int i = 0; i < a.length; i++) {
    diff |= a[i] ^ b[i];
  }
  return diff == 0;
}
