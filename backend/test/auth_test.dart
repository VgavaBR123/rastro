// Testes unitarios das partes puras de autenticacao (hash de senha e tokens).
import 'dart:convert';

import 'package:strava_estudo_backend/src/auth/password.dart';
import 'package:strava_estudo_backend/src/auth/tokens.dart';
import 'package:test/test.dart';

String _hex(List<int> b) =>
    b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();

void main() {
  group('pbkdf2HmacSha256', () {
    // Vetores publicados na RFC 7914, secao 11 (PBKDF2-HMAC-SHA256).
    test('vetor RFC 7914: passwd/salt, c=1, 64 bytes', () {
      final dk =
          pbkdf2HmacSha256(utf8.encode('passwd'), utf8.encode('salt'), 1, 64);
      expect(
          _hex(dk),
          '55ac046e56e3089fec1691c22544b605f94185216dde0465e68b9d57c20dacbc'
          '49ca9cccf179b645991664b39d77ef317c71b845b1e30bd509112041d3a19783');
    });

    test('vetor RFC 7914: Password/NaCl, c=80000, 64 bytes', () {
      final dk = pbkdf2HmacSha256(
          utf8.encode('Password'), utf8.encode('NaCl'), 80000, 64);
      expect(
          _hex(dk),
          '4ddcd8f60b98be21830cee5ef22701f9641a4418d04c0414aeff08876b34ab56'
          'a1d425a1225833549adb841b51c9b3176a272bdebba1d078478f62b397f33c8d');
    });
  });

  group('hash de senha', () {
    test('formato pbkdf2_sha256\$iter\$salt\$hash', () {
      final h = hashPassword('minha-senha', iterations: 10);
      final partes = h.split(r'$');
      expect(partes, hasLength(4));
      expect(partes[0], 'pbkdf2_sha256');
      expect(partes[1], '10');
      expect(base64.decode(partes[2]), hasLength(16));
      expect(base64.decode(partes[3]), hasLength(32));
    });

    test('iteracoes padrao sao 120000', () {
      expect(defaultPbkdf2Iterations, 120000);
    });

    test('verifica a senha certa e rejeita a errada', () {
      final h = hashPassword('minha-senha', iterations: 10);
      expect(verifyPassword('minha-senha', h), isTrue);
      expect(verifyPassword('minha-senhA', h), isFalse);
      expect(verifyPassword('', h), isFalse);
    });

    test('salts diferentes geram hashes diferentes para a mesma senha', () {
      final a = hashPassword('igual', iterations: 10);
      final b = hashPassword('igual', iterations: 10);
      expect(a, isNot(b));
      expect(a.split(r'$')[2], isNot(b.split(r'$')[2]));
      expect(verifyPassword('igual', a), isTrue);
      expect(verifyPassword('igual', b), isTrue);
    });

    test('hash malformado nunca valida (e nao lanca)', () {
      for (final s in [
        '',
        'texto',
        r'md5$1$a$b',
        r'pbkdf2_sha256$x$AAAA$AAAA',
        r'pbkdf2_sha256$0$AAAA$AAAA',
        r'pbkdf2_sha256$10$@@@$AAAA',
        r'pbkdf2_sha256$10$AAAA$',
      ]) {
        expect(verifyPassword('qualquer', s), isFalse, reason: s);
      }
    });

    test('constantTimeEquals', () {
      expect(constantTimeEquals([1, 2, 3], [1, 2, 3]), isTrue);
      expect(constantTimeEquals([1, 2, 3], [1, 2, 4]), isFalse);
      expect(constantTimeEquals([1, 2], [1, 2, 3]), isFalse);
    });
  });

  group('tokens', () {
    test('32 bytes em base64url sem padding, todos diferentes', () {
      final vistos = <String>{};
      for (var i = 0; i < 50; i++) {
        final t = generateToken();
        expect(t, matches(RegExp(r'^[A-Za-z0-9_-]{43}$')));
        expect(base64Url.decode('$t='), hasLength(32));
        vistos.add(t);
      }
      expect(vistos, hasLength(50));
    });

    test('hashToken e o sha256 em hex e e deterministico', () {
      expect(hashToken('abc'),
          'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad');
      expect(hashToken('abc'), hashToken('abc'));
    });

    test('bearerToken extrai so do esquema Bearer', () {
      expect(bearerToken('Bearer abc'), 'abc');
      expect(bearerToken('bearer  abc '), 'abc');
      expect(bearerToken('Basic abc'), isNull);
      expect(bearerToken('Bearer '), isNull);
      expect(bearerToken(null), isNull);
    });
  });
}
