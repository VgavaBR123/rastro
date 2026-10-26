// Tokens de sessao opacos. O cliente recebe o token em claro uma unica vez;
// o banco guarda so o sha256 dele, entao um vazamento da tabela sessions nao
// entrega sessoes validas.
library;

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Validade de uma sessao: 180 dias.
const Duration sessionLifetime = Duration(days: 180);

/// 32 bytes de Random.secure() em base64url sem padding (43 caracteres).
String generateToken({Random? random}) {
  final Random rnd = random ?? Random.secure();
  final Uint8List bytes =
      Uint8List.fromList(List<int>.generate(32, (_) => rnd.nextInt(256)));
  return base64Url.encode(bytes).replaceAll('=', '');
}

/// sha256 do token em hexadecimal; e isto que vai para sessions.token_hash.
String hashToken(String token) => sha256.convert(utf8.encode(token)).toString();

/// Extrai o token de `Authorization: Bearer <token>`. Null se ausente ou
/// em outro formato.
String? bearerToken(String? authorization) {
  if (authorization == null) return null;
  final String valor = authorization.trim();
  if (valor.length < 7 || valor.substring(0, 7).toLowerCase() != 'bearer ') {
    return null;
  }
  final String token = valor.substring(7).trim();
  return token.isEmpty ? null : token;
}
