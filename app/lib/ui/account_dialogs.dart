// Dialogos de conta do perfil: trocar senha, sair de todos os aparelhos e
// excluir conta. Cada um chama o AuthController e mostra o erro no proprio
// dialogo (ex.: senha atual errada), fechando com `true` so no sucesso.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';

/// Trocar senha (atual, nova, confirmar). Continua logado no sucesso.
Future<bool> showChangePasswordDialog(BuildContext context) async =>
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _ChangePasswordDialog(),
    ) ??
    false;

/// Sair de todos os aparelhos (inclusive este), com confirmacao.
Future<bool> showLogoutAllDialog(BuildContext context) async =>
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _LogoutAllDialog(),
    ) ??
    false;

/// Excluir a conta, exigindo a senha. Fecha com `true` se a conta foi apagada.
Future<bool> showDeleteAccountDialog(BuildContext context) async =>
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _DeleteAccountDialog(),
    ) ??
    false;

Widget _errorText(String? error, Key key) => error == null
    ? const SizedBox.shrink()
    : Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Text(
          error,
          key: key,
          style: const TextStyle(color: Colors.red),
        ),
      );

Widget _busyLabel(bool busy, String label) => busy
    ? const SizedBox.square(
        dimension: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      )
    : Text(label);

class _ChangePasswordDialog extends ConsumerStatefulWidget {
  const _ChangePasswordDialog();

  @override
  ConsumerState<_ChangePasswordDialog> createState() =>
      _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends ConsumerState<_ChangePasswordDialog> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _error = null);
    final ctrl = ref.read(authControllerProvider.notifier);
    final ok = await ctrl.changePassword(_current.text, _new.text);
    if (!mounted) return;
    final auth = ref.read(authControllerProvider);
    if (ok || !auth.isSignedIn) {
      // Sucesso, ou 401 (sessao caiu): nao ha o que fazer no dialogo.
      Navigator.of(context).pop(ok);
      return;
    }
    setState(() => _error = auth.error ?? 'Nao foi possivel trocar a senha');
    ctrl.clearError();
  }

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(authControllerProvider.select((s) => s.busy));
    return AlertDialog(
      title: const Text('Trocar senha'),
      content: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: const Key('change_current'),
                controller: _current,
                decoration: const InputDecoration(labelText: 'Senha atual'),
                obscureText: true,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Informe a senha atual' : null,
              ),
              TextFormField(
                key: const Key('change_new'),
                controller: _new,
                decoration: const InputDecoration(labelText: 'Nova senha'),
                obscureText: true,
                validator: (v) => (v == null || v.length < 8)
                    ? 'Minimo de 8 caracteres'
                    : null,
              ),
              TextFormField(
                key: const Key('change_confirm'),
                controller: _confirm,
                decoration: const InputDecoration(
                  labelText: 'Confirmar nova senha',
                ),
                obscureText: true,
                validator: (v) =>
                    v != _new.text ? 'As senhas nao conferem' : null,
              ),
              const SizedBox(height: 8),
              const Text(
                'Os outros aparelhos conectados vao precisar entrar de novo.',
                style: TextStyle(color: Colors.grey),
              ),
              _errorText(_error, const Key('change_error')),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          key: const Key('change_cancel'),
          onPressed: busy ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('change_submit'),
          onPressed: busy ? null : _submit,
          child: _busyLabel(busy, 'Trocar'),
        ),
      ],
    );
  }
}

class _LogoutAllDialog extends ConsumerStatefulWidget {
  const _LogoutAllDialog();

  @override
  ConsumerState<_LogoutAllDialog> createState() => _LogoutAllDialogState();
}

class _LogoutAllDialogState extends ConsumerState<_LogoutAllDialog> {
  String? _error;

  Future<void> _confirm() async {
    setState(() => _error = null);
    final ctrl = ref.read(authControllerProvider.notifier);
    final ok = await ctrl.logoutAll();
    if (!mounted) return;
    final auth = ref.read(authControllerProvider);
    if (ok || !auth.isSignedIn) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() => _error = auth.error ?? 'Nao foi possivel sair');
    ctrl.clearError();
  }

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(authControllerProvider.select((s) => s.busy));
    return AlertDialog(
      title: const Text('Sair de todos os aparelhos?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Todas as sessoes da sua conta serao encerradas, inclusive esta. '
            'Suas atividades continuam neste aparelho.',
          ),
          _errorText(_error, const Key('logout_all_error')),
        ],
      ),
      actions: [
        TextButton(
          key: const Key('logout_all_cancel'),
          onPressed: busy ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('logout_all_confirm'),
          onPressed: busy ? null : _confirm,
          child: _busyLabel(busy, 'Sair de todos'),
        ),
      ],
    );
  }
}

class _DeleteAccountDialog extends ConsumerStatefulWidget {
  const _DeleteAccountDialog();

  @override
  ConsumerState<_DeleteAccountDialog> createState() =>
      _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends ConsumerState<_DeleteAccountDialog> {
  final _form = GlobalKey<FormState>();
  final _password = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _error = null);
    final ctrl = ref.read(authControllerProvider.notifier);
    final ok = await ctrl.deleteAccount(_password.text);
    if (!mounted) return;
    final auth = ref.read(authControllerProvider);
    if (ok || !auth.isSignedIn) {
      Navigator.of(context).pop(ok);
      return;
    }
    setState(() => _error = auth.error ?? 'Nao foi possivel excluir a conta');
    ctrl.clearError();
  }

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(authControllerProvider.select((s) => s.busy));
    return AlertDialog(
      title: const Text('Excluir conta?'),
      content: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Isto apaga sua conta e TODAS as suas atividades no servidor. '
                'Nao da para desfazer.',
                key: Key('delete_warning'),
              ),
              const SizedBox(height: 8),
              const Text(
                'As atividades gravadas neste aparelho continuam nele.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 8),
              TextFormField(
                key: const Key('delete_password'),
                controller: _password,
                decoration: const InputDecoration(
                  labelText: 'Digite sua senha para confirmar',
                ),
                obscureText: true,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Informe a senha' : null,
              ),
              _errorText(_error, const Key('delete_error')),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          key: const Key('delete_cancel'),
          onPressed: busy ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('delete_confirm'),
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: busy ? null : _confirm,
          child: _busyLabel(busy, 'Excluir conta'),
        ),
      ],
    );
  }
}
