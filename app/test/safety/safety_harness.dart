// Pecas comuns dos testes de widget do Rastro Seguro: servidor falso do
// contrato com duas contas (Ana e Bia), sessao logada em memoria e os
// overrides de rede, relogio, ticks, vibracao e abridor de link.
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:strava_estudo_app/app/providers.dart';
import 'package:strava_estudo_app/auth/auth_models.dart';
import 'package:strava_estudo_app/auth/session_store.dart';
import 'package:strava_estudo_app/persistence/database.dart';
import 'package:strava_estudo_app/safety/safety_providers.dart';
import 'package:strava_estudo_app/safety/safety_session_controller.dart';
import 'package:strava_estudo_app/safety/url_opener.dart';

import '../recording/fakes.dart';
import 'fake_safety_server.dart';

class FakeUrlOpener implements UrlOpener {
  final List<String> opened = [];
  bool result = true;
  @override
  Future<UrlOpenResult> open(String url) async {
    opened.add(url);
    return result ? const UrlOpenResult.opened() : const UrlOpenResult.failed('Nao deu para abrir o link.');
  }
}

class CountingSafetyHaptics implements SafetyHaptics {
  int alerts = 0;
  @override
  Future<void> alert() async => alerts++;
}

class SafetyHarness {
  int nowMs;
  late final FakeSafetyServer server = FakeSafetyServer(now: () => nowMs);
  late final FakeUser ana = server.addUser('tok-ana', 'u_ana', 'ana@x.com', 'Ana');
  late final FakeUser bia = server.addUser('tok-bia', 'u_bia', 'bia@x.com', 'Bia');
  final FakeHeartbeatTicker positionTicker = FakeHeartbeatTicker();
  final FakeHeartbeatTicker inboxTicker = FakeHeartbeatTicker();
  final FakeHeartbeatTicker countdownTicker = FakeHeartbeatTicker();
  final FakeUrlOpener opener = FakeUrlOpener();
  final CountingSafetyHaptics haptics = CountingSafetyHaptics();

  SafetyHarness({int? nowMs}) : nowMs = nowMs ?? DateTime.now().millisecondsSinceEpoch {
    ana;
    bia;
  }

  AuthSession session(FakeUser u, String token) => AuthSession(
    token: token,
    user: AppUser(id: u.id, email: u.email, displayName: u.name, createdAtMs: 0),
  );

  /// Overrides; [signedInAs] null = deslogado.
  /// Banco em memoria quando o teste nao traz o dele ([withDatabase] false).
  RecordingDatabase? db;

  List<Override> overrides({FakeUser? signedInAs, bool withDatabase = true}) {
    final token = signedInAs == null ? null : server.tokens.entries.firstWhere((e) => e.value == signedInAs).key;
    if (withDatabase) db ??= RecordingDatabase(NativeDatabase.memory());
    return [
      if (withDatabase) recordingDatabaseProvider.overrideWithValue(db!),
      dioProvider.overrideWithValue(Dio()..httpClientAdapter = server),
      sessionStoreProvider.overrideWithValue(
        InMemorySessionStore(signedInAs == null ? null : session(signedInAs, token!)),
      ),
      safetyClockProvider.overrideWithValue(() => nowMs),
      safetyTickerProvider.overrideWithValue(positionTicker),
      inboxTickerProvider.overrideWithValue(inboxTicker),
      safetyCountdownTickerProvider.overrideWithValue(countdownTicker),
      safetyHapticsProvider.overrideWithValue(haptics),
      urlOpenerProvider.overrideWithValue(opener),
    ];
  }
}
