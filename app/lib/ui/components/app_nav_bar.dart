// Navegacao principal (relatorio 11, AppNavBar): capsula flutuante com quatro
// abas e, ao lado, o botao Gravar com anel multicolorido.
library;

import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import 'gradient_ring.dart';

class NavTab {
  final String label;
  final IconData icon;
  final RoleColors Function(AppColors) role;
  final Key key;
  const NavTab({required this.label, required this.icon, required this.role, required this.key});
}

/// Abas do shell, na ordem dos ramos do router.
final List<NavTab> kNavTabs = [
  NavTab(label: 'Inicio', icon: Icons.home_rounded, role: (c) => c.dist, key: const Key('nav_home')),
  NavTab(label: 'Historico', icon: Icons.history_rounded, role: (c) => c.pace, key: const Key('nav_history')),
  NavTab(label: 'Estatisticas', icon: Icons.insights_rounded, role: (c) => c.subida, key: const Key('nav_stats')),
  NavTab(label: 'Voce', icon: Icons.person_rounded, role: (c) => c.extra, key: const Key('nav_profile')),
];

class AppNavBar extends StatelessWidget {
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

  static const double height = 64;
  static const double bottomGap = 20;

  /// Espaco que o conteudo rolavel precisa deixar livre embaixo para nao
  /// ficar escondido atras da navegacao.
  static double reservedHeight(BuildContext context) =>
      height + bottomGap + MediaQuery.paddingOf(context).bottom + 12;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppShape.gutter,
        0,
        AppShape.gutter,
        bottomGap + MediaQuery.paddingOf(context).bottom,
      ),
      child: SizedBox(
        height: height,
        child: Row(
          children: [
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppShape.nav),
                  boxShadow: const [
                    BoxShadow(color: Color(0x80000000), blurRadius: 40, offset: Offset(0, 16)),
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
  const _TabItem({required this.tab, required this.active, required this.onTap});

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
              color: active ? role.fill.withValues(alpha: 0.35) : Colors.transparent,
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
      label: 'Gravar',
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
                      boxShadow: [BoxShadow(color: c.primary.withValues(alpha: 0.6), blurRadius: 12)],
                    ),
                    alignment: Alignment.center,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(color: c.onPrimary, shape: BoxShape.circle),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Gravar',
                    style: AppText.navLabelActive.copyWith(
                      fontSize: 11,
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
