// Recuperar a senha em 2 passos: (1) informar o e-mail e pedir o codigo;
// (2) digitar o codigo de 6 digitos e a nova senha. Ao final ja entra logado.
// Fecha com `true` quando a senha foi trocada (a tela de login fecha junto).
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';

class PasswordResetScreen extends ConsumerStatefulWidget {
  final String initialEmail;
  const PasswordResetScreen({super.key, this.initialEmail = ''});

  @override
  ConsumerState<PasswordResetScreen> createState() =>
      _PasswordResetScreenState();
}

class _PasswordResetScreenState extends ConsumerState<PasswordResetScreen> {
  final _emailForm = GlobalKey<FormState>();
  final _resetForm = GlobalKey<FormState>();
  late final TextEditingController _email = TextEditingController(
    text: widget.initialEmail.trim(),
  );
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _codeSent = false;

  @override
  void initState() {
    super.initState();
    // Erro da tela de login nao deve aparecer aqui.
    Future.microtask(() {
      if (mounted) ref.read(authControllerProvider.notifier).clearError();
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    // No passo 2 (reenviar) o formulario do e-mail nao esta na arvore.
    final form = _emailForm.currentState;
    if (form != null && !form.validate()) return;
    final resend = _codeSent;
    final ok = await ref
        .read(authControllerProvider.notifier)
        .forgotPassword(_email.text);
    if (!ok || !mounted) return;
    setState(() => _codeSent = true);
    if (resend) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Codigo reenviado')));
    }
  }

  Future<void> _reset() async {
    if (!_resetForm.currentState!.validate()) return;
    final ok = await ref
        .read(authControllerProvider.notifier)
        .resetPassword(_email.text, _code.text, _password.text);
    if (ok && mounted) Navigator.of(context).pop(true);
  }

  void _useOtherEmail() {
    ref.read(authControllerProvider.notifier).clearError();
    setState(() {
      _codeSent = false;
      _code.clear();
      _password.clear();
      _confirm.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar senha')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: _codeSent ? _resetStep(auth.busy) : _emailStep(auth.busy),
      ),
    );
  }

  Widget _error() {
    final error = ref.watch(authControllerProvider).error;
    if (error == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        error,
        key: const Key('reset_error'),
        style: const TextStyle(color: Colors.red),
      ),
    );
  }

  Widget _busyLabel(bool busy, String label) => busy
      ? const SizedBox.square(
          dimension: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
      : Text(label);

  Widget _emailStep(bool busy) {
    return Form(
      key: _emailForm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Informe o e-mail da sua conta. Vamos enviar um codigo para '
            'criar uma nova senha.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('reset_email'),
            controller: _email,
            decoration: const InputDecoration(labelText: 'E-mail'),
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            onFieldSubmitted: (_) => _sendCode(),
            validator: (v) =>
                (v == null || !v.contains('@')) ? 'E-mail invalido' : null,
          ),
          const SizedBox(height: 16),
          _error(),
          FilledButton(
            key: const Key('reset_send'),
            onPressed: busy ? null : _sendCode,
            child: _busyLabel(busy, 'Enviar codigo'),
          ),
        ],
      ),
    );
  }

  Widget _resetStep(bool busy) {
    return Form(
      key: _resetForm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Enviamos um codigo de 6 digitos se o e-mail tiver conta. '
            'Ele vale por 15 minutos.',
            key: const Key('reset_info'),
          ),
          const SizedBox(height: 4),
          Text(_email.text.trim(), style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('reset_code'),
            controller: _code,
            decoration: const InputDecoration(labelText: 'Codigo'),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            textInputAction: TextInputAction.next,
            validator: (v) =>
                (v == null || !RegExp(r'^\d{6}$').hasMatch(v.trim()))
                ? 'O codigo tem 6 digitos'
                : null,
          ),
          TextFormField(
            key: const Key('reset_new_password'),
            controller: _password,
            decoration: const InputDecoration(labelText: 'Nova senha'),
            obscureText: true,
            textInputAction: TextInputAction.next,
            validator: (v) =>
                (v == null || v.length < 8) ? 'Minimo de 8 caracteres' : null,
          ),
          TextFormField(
            key: const Key('reset_confirm_password'),
            controller: _confirm,
            decoration: const InputDecoration(
              labelText: 'Confirmar nova senha',
            ),
            obscureText: true,
            onFieldSubmitted: (_) => _reset(),
            validator: (v) =>
                v != _password.text ? 'As senhas nao conferem' : null,
          ),
          const SizedBox(height: 16),
          _error(),
          FilledButton(
            key: const Key('reset_submit'),
            onPressed: busy ? null : _reset,
            child: _busyLabel(busy, 'Trocar senha e entrar'),
          ),
          TextButton(
            key: const Key('reset_resend'),
            onPressed: busy ? null : _sendCode,
            child: const Text('Reenviar codigo'),
          ),
          TextButton(
            key: const Key('reset_other_email'),
            onPressed: busy ? null : _useOtherEmail,
            child: const Text('Usar outro e-mail'),
          ),
        ],
      ),
    );
  }
}
