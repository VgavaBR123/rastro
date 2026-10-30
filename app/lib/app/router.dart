// Navegacao do app (relatorio 08: navegacao declarada num unico grafo, com os
// destinos tipados num so lugar). go_router; as telas nunca montam rota na mao,
// sempre usam [AppRoutes].
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../persistence/database.dart';
import '../persistence/recording_repository.dart';
import '../recording/domain/geo.dart';
import '../recording/domain/recording_models.dart';
import '../ui/activity_detail_screen.dart';
import '../ui/components/app_nav_bar.dart';
import '../ui/auth_screen.dart';
import '../ui/history_screen.dart';
import '../ui/home_screen.dart';
import '../ui/narrator_settings_screen.dart';
import '../ui/password_reset_screen.dart';
import '../ui/privacy/add_zone_screen.dart';
import '../ui/privacy/privacy_zones_screen.dart';
import '../ui/profile_screen.dart';
import '../ui/record_setup_screen.dart';
import '../ui/reliability_checklist_screen.dart';
import '../ui/recording_screen.dart';
import '../ui/settings_screen.dart';
import '../ui/stats_screen.dart';
import '../ui/theme/app_theme.dart';
import 'providers.dart';

/// Destinos do app. Caminhos so sao escritos aqui.
abstract final class AppRoutes {
  // Abas do shell (relatorio 11: Inicio, Historico, Estatisticas, Voce) e Gravar.
  static const String home = '/';
  static const String history = '/history';
  static const String stats = '/stats';
  static const String profile = '/profile';

  /// Tela Gravar: mapa, escolha do esporte e Iniciar.
  static const String recordSetup = '/record';

  static const String settings = '/settings';

  /// Checklist "Gravacao confiavel" (F01), pelas Configuracoes.
  static const String reliability = '/reliability';

  /// O mesmo checklist antes da primeira gravacao: com "Continuar para
  /// gravar", que devolve true no pop.
  static const String reliabilityBeforeRecording = '/reliability?first=1';

  /// Zonas de privacidade (F02), pelas Configuracoes.
  static const String privacy = '/privacy';

  /// Novo local protegido no mapa. O centro inicial (GeoPoint) vai em `extra`.
  static const String privacyAddZone = '/privacy/add';

  /// Narrador por voz (F03), pelas Configuracoes.
  static const String narrator = '/narrator';
  static const String auth = '/auth';

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

/// Indice do ramo Gravar no shell (depois das quatro abas).
const int kRecordBranch = 4;

GoRouter buildAppRouter({String initialLocation = AppRoutes.home}) {
  // Gravando, Detalhe, Configuracoes e conta abrem por cima do shell, sem a
  // navegacao (relatorio 11).
  final root = GlobalKey<NavigatorState>(debugLabel: 'root');
  return GoRouter(
    navigatorKey: root,
    initialLocation: initialLocation,
    observers: [_ClearSnackBarsObserver()],
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.home, builder: (_, _) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.history,
              builder: (_, _) => const HistoryScreen(),
              routes: [
                GoRoute(
                  path: ':guid',
                  parentNavigatorKey: root,
                  builder: (_, state) {
                    final extra = state.extra;
                    if (extra is Activity) return ActivityDetailScreen(activity: extra);
                    return _ActivityByGuid(state.pathParameters['guid']!);
                  },
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.stats, builder: (_, _) => const StatsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.profile, builder: (_, _) => const ProfileScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.recordSetup,
              builder: (_, _) => const RecordSetupScreen(),
              routes: [
                GoRoute(
                  path: ':type',
                  parentNavigatorKey: root,
                  builder: (_, state) => RecordingScreen(
                    activityType:
                        ActivityType.values.byName(state.pathParameters['type']!),
                    resumeFrom: state.extra as InterruptedActivity?,
                  ),
                ),
              ],
            ),
          ]),
        ],
      ),
      GoRoute(path: AppRoutes.settings, builder: (_, _) => const SettingsScreen()),
      reliabilityRoute(),
      ...privacyRoutes(),
      narratorRoute(),
      GoRoute(
        path: AppRoutes.auth,
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
  );
}

/// Rota do checklist "Gravacao confiavel" (por cima do shell).
GoRoute reliabilityRoute() => GoRoute(
  path: AppRoutes.reliability,
  builder: (_, state) => ReliabilityChecklistScreen(
    beforeFirstRecording: state.uri.queryParameters['first'] == '1',
  ),
);

/// Configuracoes do Narrador por voz (F03), por cima do shell.
GoRoute narratorRoute() => GoRoute(
  path: AppRoutes.narrator,
  builder: (_, _) => const NarratorSettingsScreen(),
);

/// Rotas da privacidade (F02), por cima do shell.
List<GoRoute> privacyRoutes() => [
  GoRoute(
    path: AppRoutes.privacy,
    builder: (_, _) => const PrivacyZonesScreen(),
    routes: [
      GoRoute(
        path: 'add',
        builder: (_, state) => AddZoneScreen(initialCenter: state.extra as GeoPoint?),
      ),
    ],
  ),
];

/// Moldura das abas: o conteudo do ramo com a AppNavBar flutuando por cima.
/// As telas deixam `AppNavBar.reservedHeight` livre no fim da rolagem.
class AppShell extends StatelessWidget {
  final StatefulNavigationShell shell;
  const AppShell({super.key, required this.shell});

  // NavBarModeScope: as telas (e a margem do aviso, abaixo) usam
  // AppNavBar.reservedHeight e reconstroem quando a barra nativa do iOS entra.
  @override
  Widget build(BuildContext context) => NavBarModeScope(child: Builder(builder: _build));

  Widget _build(BuildContext context) {
    final index = shell.currentIndex;
    final theme = Theme.of(context);
    // Com o teclado aberto a navegacao some (senao sobe junto e cobre o campo).
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    void go(int i) {
      // Aviso de uma aba nao segue para a outra.
      ScaffoldMessenger.maybeOf(context)?.clearSnackBars();
      shell.goBranch(i, initialLocation: i == index);
    }

    // O ScaffoldMessenger mostra o aviso no Scaffold mais externo (este), entao
    // a margem acima da navegacao precisa estar no tema acima dele.
    return Theme(
      data: theme.copyWith(
        snackBarTheme: theme.snackBarTheme.copyWith(
          insetPadding: EdgeInsets.fromLTRB(
            AppShape.gutter,
            5,
            AppShape.gutter,
            keyboardOpen ? 10 : AppNavBar.reservedHeight(context),
          ),
        ),
      ),
      child: Scaffold(
        // As telas das abas tratam o teclado no proprio Scaffold.
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            Positioned.fill(child: shell),
            if (!keyboardOpen)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: AppNavBar(
                  currentIndex: index == kRecordBranch ? null : index,
                  recordActive: index == kRecordBranch,
                  onTabSelected: go,
                  onRecord: () => go(kRecordBranch),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Fecha os avisos ao abrir ou fechar uma tela por cima do shell: um aviso
/// do Detalhe ("Em breve") nao deve aparecer na tela de conta, por exemplo.
class _ClearSnackBarsObserver extends NavigatorObserver {
  void _clear(Route<dynamic>? route) {
    // Dialogos e folhas nao contam: o aviso pode ser sobre eles.
    if (route is! PageRoute) return;
    final ctx = navigator?.context;
    if (ctx != null) ScaffoldMessenger.maybeOf(ctx)?.clearSnackBars();
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => _clear(route);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => _clear(route);
}

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
