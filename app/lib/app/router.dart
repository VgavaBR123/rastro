// Navegacao do app (relatorio 08: navegacao declarada num unico grafo, com os
// destinos tipados num so lugar). go_router; as telas nunca montam rota na mao,
// sempre usam [AppRoutes].
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../persistence/database.dart';
import '../persistence/recording_repository.dart';
import '../recording/domain/recording_models.dart';
import '../ui/activity_detail_screen.dart';
import '../ui/auth_screen.dart';
import '../ui/history_screen.dart';
import '../ui/home_screen.dart';
import '../ui/password_reset_screen.dart';
import '../ui/profile_screen.dart';
import '../ui/recording_screen.dart';
import '../ui/settings_screen.dart';
import 'providers.dart';

/// Destinos do app. Caminhos so sao escritos aqui.
abstract final class AppRoutes {
  static const String home = '/';
  static const String history = '/history';
  static const String settings = '/settings';
  static const String auth = '/auth';
  static const String profile = '/profile';

  /// Gravacao de [type]. Para retomar uma interrompida, passe-a em `extra`.
  static String record(ActivityType type) => '/record/${type.name}';

  /// Detalhe de uma atividade. O objeto pode ir em `extra` (evita reler o
  /// banco); sem ele, a tela carrega pelo guid (deep link).
  static String activity(String guid) => '/history/${Uri.encodeComponent(guid)}';

  /// Recuperacao de senha, com o e-mail ja preenchido.
  static String passwordReset({String email = ''}) =>
      Uri(path: '/auth/reset', queryParameters: email.isEmpty ? null : {'email': email})
          .toString();
}

GoRouter buildAppRouter({String initialLocation = AppRoutes.home}) => GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: AppRoutes.home,
          builder: (_, _) => const HomeScreen(),
          routes: [
            GoRoute(
              path: 'record/:type',
              builder: (_, state) => RecordingScreen(
                activityType:
                    ActivityType.values.byName(state.pathParameters['type']!),
                resumeFrom: state.extra as InterruptedActivity?,
              ),
            ),
            GoRoute(
              path: 'history',
              builder: (_, _) => const HistoryScreen(),
              routes: [
                GoRoute(
                  path: ':guid',
                  builder: (_, state) {
                    final extra = state.extra;
                    if (extra is Activity) return ActivityDetailScreen(activity: extra);
                    return _ActivityByGuid(state.pathParameters['guid']!);
                  },
                ),
              ],
            ),
            GoRoute(path: 'settings', builder: (_, _) => const SettingsScreen()),
            GoRoute(path: 'profile', builder: (_, _) => const ProfileScreen()),
            GoRoute(
              path: 'auth',
              builder: (_, _) => const AuthScreen(),
              routes: [
                GoRoute(
                  path: 'reset',
                  builder: (_, state) => PasswordResetScreen(
                    initialEmail: state.uri.queryParameters['email'] ?? '',
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );

/// Grafo do app. Um por ProviderScope (testes criam o deles).
final appRouterProvider = Provider<GoRouter>((ref) {
  final router = buildAppRouter();
  ref.onDispose(router.dispose);
  return router;
});

/// Detalhe aberto so com o guid: le o cabecalho e mostra a tela.
class _ActivityByGuid extends ConsumerWidget {
  final String guid;
  const _ActivityByGuid(this.guid);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<Activity?>(
      future: ref.read(recordingRepositoryProvider).activity(guid),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final a = snap.data;
        if (a == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Atividade nao encontrada')),
          );
        }
        return ActivityDetailScreen(activity: a);
      },
    );
  }
}
