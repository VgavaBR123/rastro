// Push plugavel (F08). Hoje o app funciona inteiro pela caixa de entrada
// (busca a cada 30 s em primeiro plano); o push so acorda o app mais rapido.
//
// Onde o Firebase Messaging entra (quando o Gava criar o projeto Firebase):
// 1. Adicionar `firebase_core` e `firebase_messaging` ao pubspec (registrar
//    em DEPENDENCIAS-FEATURES.md), `google-services.json` em android/app e o
//    plugin `com.google.gms.google-services` no Gradle. iOS so com conta paga
//    da Apple (APNs).
// 2. Criar `FirebasePushRegistrar implements PushRegistrar`:
//    - [onSignedIn]: `Firebase.initializeApp()`, pedir permissao de
//      notificacao (Android 13+ / iOS), `FirebaseMessaging.instance.getToken()`
//      e `api.registerPushToken(token, 'android' | 'ios')`; escutar
//      `onTokenRefresh` e registrar de novo.
//    - `FirebaseMessaging.onMessage` e `onMessageOpenedApp`: chamar
//      [onMessage] (o provider liga isso ao refresh da caixa de entrada).
//    - [onSignedOut]: `api.deletePushToken(token)` e `deleteToken()`.
// 3. Trocar a implementacao em `pushRegistrarProvider`
//    (lib/safety/safety_providers.dart). Nada mais muda: a caixa de entrada
//    continua sendo a fonte das notificacoes.
library;

import 'safety_api.dart';

abstract interface class PushRegistrar {
  /// Conta logada: registra o aparelho no backend. [onMessage] e chamado
  /// quando chega um push (para buscar a caixa de entrada na hora).
  Future<void> onSignedIn(SafetyApi api, {required void Function() onMessage});

  /// Saiu da conta: tira o aparelho do backend.
  Future<void> onSignedOut(SafetyApi api);
}

/// Padrao: sem push. A caixa de entrada e buscada pelo [InboxPoller].
class NoopPushRegistrar implements PushRegistrar {
  const NoopPushRegistrar();

  @override
  Future<void> onSignedIn(SafetyApi api, {required void Function() onMessage}) async {}

  @override
  Future<void> onSignedOut(SafetyApi api) async {}
}
