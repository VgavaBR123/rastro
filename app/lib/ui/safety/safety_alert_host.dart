// Alerta de um contato de confianca (F08) por cima de QUALQUER tela,
// inclusive da propria gravacao de quem recebe: nome, motivo e "Ver
// localizacao". A fala critica e a vibracao saem quando o alerta chega
// (safety_providers.dart). Fica na raiz do app (builder do MaterialApp), acima
// do Navigator.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../safety/safety_alerts.dart';
import '../../safety/safety_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import 'inbox_screen.dart' show openAlertLocation;

class SafetyAlertHost extends ConsumerStatefulWidget {
  final Widget child;
  const SafetyAlertHost({super.key, required this.child});

  @override
  ConsumerState<SafetyAlertHost> createState() => _SafetyAlertHostState();
}

class _SafetyAlertHostState extends ConsumerState<SafetyAlertHost> {
  String? _error;

  @override
  Widget build(BuildContext context) {
    final queue = ref.watch(safetyAlertQueueProvider);
    final n = queue.isEmpty ? null : queue.first;
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (n != null)
          Positioned.fill(
            child: Builder(
              builder: (context) {
                final c = AppColors.of(context);
                void close() {
                  ref.read(inboxProvider.notifier).markRead(n.id);
                  ref.read(safetyAlertQueueProvider.notifier).dismiss(n.id);
                  setState(() => _error = null);
                }

                Future<void> location() async {
                  final err = await openAlertLocation(ref, n);
                  if (!mounted) return;
                  if (err == null) {
                    ref.read(safetyAlertQueueProvider.notifier).dismiss(n.id);
                  }
                  setState(() => _error = err);
                }

                return Material(
                  key: const Key('safety_alert_panel'),
                  color: c.bg.withValues(alpha: 0.95),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(AppShape.gutter),
                      child: Semantics(
                        container: true,
                        liveRegion: true,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Icon(Icons.warning_rounded, size: 64, color: c.danger),
                            const SizedBox(height: 16),
                            Text(
                              alertTitle(n),
                              key: const Key('safety_alert_title'),
                              textAlign: TextAlign.center,
                              style: AppText.screenTitle.copyWith(color: c.text),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              alertDetail(n),
                              textAlign: TextAlign.center,
                              style: AppText.body.copyWith(color: c.textMuted),
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 8),
                              Text(_error!, textAlign: TextAlign.center, style: AppText.body.copyWith(color: c.danger)),
                            ],
                            const SizedBox(height: 24),
                            if (ref.read(inboxProvider).shareUrlFor(n) != null)
                              FilledButton.icon(
                                key: const Key('safety_alert_location'),
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size(44, 64),
                                  backgroundColor: c.danger,
                                  foregroundColor: c.bg,
                                  textStyle: AppText.action,
                                ),
                                onPressed: location,
                                icon: const Icon(Icons.location_on_rounded),
                                label: const Text('Ver localizacao'),
                              ),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              key: const Key('safety_alert_close'),
                              style: OutlinedButton.styleFrom(minimumSize: const Size(44, 52), foregroundColor: c.text),
                              onPressed: close,
                              child: Text(queue.length > 1 ? 'Fechar (mais ${queue.length - 1})' : 'Fechar'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
