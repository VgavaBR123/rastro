// Busca da caixa de entrada (F08) com o app em primeiro plano: a cada
// [inboxIntervalProvider] (30 s) e ao voltar do segundo plano. Logado: liga
// o push (Noop por padrao) e confere a sessao do Rastro Seguro no backend
// (recuperacao apos crash e "arrived" que nao saiu). Deslogado: esquece a
// caixa. Fica na raiz do app (builder do MaterialApp).
library;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../safety/safety_providers.dart';

class InboxPoller extends ConsumerStatefulWidget {
  final Widget child;
  const InboxPoller({super.key, required this.child});

  @override
  ConsumerState<InboxPoller> createState() => _InboxPollerState();
}

class _InboxPollerState extends ConsumerState<InboxPoller> {
  AppLifecycleListener? _life;
  StreamSubscription<void>? _tick;
  bool _foreground = true;
  bool? _signedIn;

  @override
  void initState() {
    super.initState();
    _life = AppLifecycleListener(
      onResume: () {
        _foreground = true;
        if (_signedIn == true) {
          _poll();
          _reconcile();
        }
      },
      onHide: () => _foreground = false,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _onAuth(ref.read(authControllerProvider).isSignedIn);
    });
  }

  void _onAuth(bool signedIn) {
    if (_signedIn == signedIn) return;
    final was = _signedIn;
    _signedIn = signedIn;
    final api = ref.read(safetyApiProvider);
    if (signedIn) {
      _tick?.cancel();
      _tick = ref.read(inboxTickerProvider).ticks(ref.read(inboxIntervalProvider)).listen((_) {
        if (_foreground) _poll();
      });
      _poll();
      _reconcile();
      unawaited(
        ref.read(pushRegistrarProvider).onSignedIn(api, onMessage: _poll).catchError((Object e) {
          debugPrint('Push nao registrou: $e');
        }),
      );
    } else {
      _tick?.cancel();
      _tick = null;
      ref.read(inboxProvider.notifier).reset();
      if (was == true) {
        unawaited(ref.read(pushRegistrarProvider).onSignedOut(api).catchError((Object _) {}));
      }
    }
  }

  void _poll() => unawaited(ref.read(inboxProvider.notifier).refresh());

  void _reconcile() {
    final repo = ref.read(recordingRepositoryProvider);
    unawaited(
      ref
          .read(safetySessionProvider.notifier)
          .reconcile(interrupted: (guid) async => (await repo.interrupted()).any((i) => i.activity.guid == guid)),
    );
  }

  @override
  void dispose() {
    _life?.dispose();
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(authControllerProvider.select((s) => s.isSignedIn), (_, v) => _onAuth(v));
    return widget.child;
  }
}
