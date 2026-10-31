// Navegacao principal (relatorio 11, AppNavBar): capsula flutuante com quatro
// abas e, ao lado, o botao Gravar com anel multicolorido.
//
// No iPhone com iOS 26 ou mais novo a barra e a nativa (Liquid Glass, pacote
// native_glass_navbar): as abas viram itens do UITabBar com SF Symbols e o
// Gravar vira o botao de acao circular. Em Android, iOS antigo e nos testes
// aparece a barra Flutter (_FlutterNavBar), que tambem e o `fallback` do pacote.
library;

import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:native_glass_navbar/native_glass_navbar.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import 'gradient_ring.dart';

class NavTab {
  final String label;
  final IconData icon;
  final RoleColors Function(AppColors) role;
  final Key key;

  /// SF Symbol da aba na barra nativa do iOS.
  final String symbol;

  /// SF Symbol com a aba selecionada (null = o mesmo de [symbol]).
  final String? selectedSymbol;

  const NavTab({
    required this.label,
    required this.icon,
    required this.role,
    required this.key,
    required this.symbol,
    this.selectedSymbol,
  });
}

/// Abas do shell, na ordem dos ramos do router.
final List<NavTab> kNavTabs = [
  NavTab(
    label: 'Inicio',
    icon: Icons.home_rounded,
    role: (c) => c.dist,
    key: const Key('nav_home'),
    symbol: 'house',
    selectedSymbol: 'house.fill',
  ),
  NavTab(
    label: 'Historico',
    icon: Icons.history_rounded,
    role: (c) => c.pace,
    key: const Key('nav_history'),
    symbol: 'clock.arrow.circlepath',
  ),
  NavTab(
    label: 'Estatisticas',
    icon: Icons.insights_rounded,
    role: (c) => c.subida,
    key: const Key('nav_stats'),
    symbol: 'chart.xyaxis.line',
  ),
  NavTab(
    label: 'Voce',
    icon: Icons.person_rounded,
    role: (c) => c.extra,
    key: const Key('nav_profile'),
    symbol: 'person',
    selectedSymbol: 'person.fill',
  ),
];

/// SF Symbol do botao de acao (Gravar) na barra nativa.
const String kNavRecordSymbol = 'record.circle';

/// Rotulo de acessibilidade do botao de gravar, igual nas duas barras (INI-02:
/// na nativa o VoiceOver anunciava "Buscar", o item de sistema por baixo).
const String kNavRecordLabel = 'Gravar atividade';

class AppNavBar extends StatefulWidget {
  /// Aba ativa (0 a 3), ou null quando a tela atual e Gravar.
  final int? currentIndex;
  final bool recordActive;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onRecord;

  const AppNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.onRecord,
    this.recordActive = false,
  });

  /// Altura da barra Flutter.
  static const double height = 64;
  static const double bottomGap = 20;

  /// Altura da barra nativa do iOS sem a area segura (padrao do UITabBar,
  /// a mesma que o pacote usa no SizedBox do UiKitView).
  static const double nativeHeight = 49;

  /// true quando a barra nativa (Liquid Glass) esta na tela. Comeca false e
  /// so muda no iOS, depois que o canal do pacote confirma iOS 26+.
  static final ValueNotifier<bool> nativeActive = ValueNotifier(false);

  static Future<void>? _probe;

  /// Faz uma unica vez a mesma checagem que o NativeGlassNavBar faz para
  /// decidir entre o nativo e o fallback, e publica em [nativeActive].
  static void _ensureProbed() {
    if (defaultTargetPlatform != TargetPlatform.iOS) return;
    _probe ??= LiquidGlassHelper.isLiquidGlassSupported().then((ok) {
      nativeActive.value = ok;
    });
  }

  /// Espaco que o conteudo rolavel precisa deixar livre embaixo para nao
  /// ficar escondido atras da navegacao. Reflete a barra que esta na tela
  /// (nativa ou Flutter); dentro de um [NavBarModeScope] quem chama e
  /// reconstruido quando o modo muda.
  static double reservedHeight(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<NavBarModeScope>();
    final native = (scope?.notifier ?? nativeActive).value;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return native
        ? nativeHeight + bottom + 12
        : height + bottomGap + bottom + 12;
  }

  @override
  State<AppNavBar> createState() => _AppNavBarState();
}

/// Publica [AppNavBar.nativeActive] para a subarvore: quem usa
/// [AppNavBar.reservedHeight] embaixo dele reconstroi quando a barra nativa
/// entra (ou sai) da tela.
class NavBarModeScope extends InheritedNotifier<ValueNotifier<bool>> {
  NavBarModeScope({super.key, required super.child})
    : super(notifier: AppNavBar.nativeActive);
}

class _AppNavBarState extends State<AppNavBar> {
  /// Ultima aba ativa: a barra nativa nao tem "nenhuma selecionada", entao na
  /// tela Gravar ela continua marcando a aba de onde se veio.
  int _lastIndex = 0;

  @override
  void initState() {
    super.initState();
    _lastIndex = widget.currentIndex ?? 0;
  }

  @override
  void didUpdateWidget(AppNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final i = widget.currentIndex;
    if (i != null) _lastIndex = i;
  }

  @override
  Widget build(BuildContext context) {
    final flutterBar = _FlutterNavBar(
      currentIndex: widget.currentIndex,
      recordActive: widget.recordActive,
      onTabSelected: widget.onTabSelected,
      onRecord: widget.onRecord,
    );
    if (defaultTargetPlatform != TargetPlatform.iOS) return flutterBar;

    AppNavBar._ensureProbed();
    final c = AppColors.of(context);
    return ValueListenableBuilder<bool>(
      valueListenable: AppNavBar.nativeActive,
      builder: (context, native, _) => NativeGlassNavBar(
        currentIndex: _lastIndex,
        onTap: widget.onTabSelected,
        tintColor: c.primary,
        actionButton: TabBarActionButton(
          symbol: kNavRecordSymbol,
          label: kNavRecordLabel,
          onTap: widget.onRecord,
        ),
        tabs: [
          for (final t in kNavTabs)
            NativeGlassNavBarItem(
              label: t.label,
              symbol: t.symbol,
              selectedSymbol: t.selectedSymbol,
            ),
        ],
        // O pacote mostra o fallback enquanto confirma o suporte (a cada vez
        // que o widget e recriado, ex.: ao fechar o teclado). Se ja sabemos
        // que o nativo vai aparecer, reserva so o espaco dele em vez de piscar
        // a barra Flutter.
        fallback: native
            ? SizedBox(
                height:
                    AppNavBar.nativeHeight +
                    MediaQuery.paddingOf(context).bottom,
              )
            : flutterBar,
      ),
    );
  }
}

/// A barra desenhada em Flutter (Android, iOS antes do 26 e testes).
class _FlutterNavBar extends StatelessWidget {
  final int? currentIndex;
  final bool recordActive;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onRecord;

  const _FlutterNavBar({
    required this.currentIndex,
    required this.recordActive,
    required this.onTabSelected,
    required this.onRecord,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppShape.gutter,
        0,
        AppShape.gutter,
        AppNavBar.bottomGap + MediaQuery.paddingOf(context).bottom,
      ),
      child: SizedBox(
        height: AppNavBar.height,
        child: Row(
          children: [
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppShape.nav),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x80000000),
                      blurRadius: 40,
                      offset: Offset(0, 16),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppShape.nav),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: c.navBg,
                        borderRadius: BorderRadius.circular(AppShape.nav),
                        border: Border.all(color: c.navLine),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.center,
                          colors: [c.text.withValues(alpha: 0.05), c.navBg],
                        ),
                      ),
                      child: Row(
                        children: [
                          for (var i = 0; i < kNavTabs.length; i++)
                            Expanded(
                              child: _TabItem(
                                tab: kNavTabs[i],
                                active: i == currentIndex,
                                onTap: () => onTabSelected(i),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            _RecordButton(active: recordActive, onTap: onRecord),
          ],
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final NavTab tab;
  final bool active;
  final VoidCallback onTap;
  const _TabItem({
    required this.tab,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final role = tab.role(c);
    return Semantics(
      selected: active,
      button: true,
      label: tab.label,
      excludeSemantics: true,
      child: InkWell(
        key: tab.key,
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppShape.navActive),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: active ? role.tint : Colors.transparent,
            borderRadius: BorderRadius.circular(AppShape.navActive),
            border: Border.all(
              color: active
                  ? role.fill.withValues(alpha: 0.35)
                  : Colors.transparent,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(tab.icon, size: 22, color: role.fg),
              const SizedBox(height: 2),
              Text(
                tab.label,
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
                style: (active ? AppText.navLabelActive : AppText.navLabel)
                    .copyWith(color: active ? role.fg : c.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecordButton extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;
  const _RecordButton({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Semantics(
      button: true,
      selected: active,
      label: kNavRecordLabel,
      excludeSemantics: true,
      child: SizedBox(
        width: 84,
        height: AppNavBar.height,
        child: GradientRing(
          borderRadius: BorderRadius.circular(32),
          child: Material(
            color: c.surface,
            borderRadius: BorderRadius.circular(30),
            child: InkWell(
              key: const Key('nav_record'),
              onTap: onTap,
              borderRadius: BorderRadius.circular(30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: c.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: c.primary.withValues(alpha: 0.6),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: c.onPrimary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Gravar',
                    style: AppText.recordLabel.copyWith(
                      color: active ? c.primaryText : c.text,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
