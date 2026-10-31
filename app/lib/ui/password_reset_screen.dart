// Recuperar a senha em 2 passos: (1) informar o e-mail e pedir o codigo;
// (2) digitar o codigo de 6 digitos e a nova senha. Ao final ja entra logado.
// Fecha com `true` quando a senha foi trocada (a tela de login fecha junto).
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import 'section_card.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'theme/app_typography.dart';

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

  /// O erro do servidor vale para a tentativa que falhou: some ao editar e
  /// ao tentar de novo (VOC-04).
  void _clearError() => ref.read(authControllerProvider.notifier).clearError();

  Future<void> _sendCode() async {
    _clearError();
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
          .showSnackBar(const SnackBar(content: Text('Código reenviado')));
    }
  }

  Future<void> _reset() async {
    _clearError();
    if (!_resetForm.currentState!.validate()) return;
    final ok = await ref
        .read(authControllerProvider.notifier)
        .resetPassword(_email.text, _code.text, _password.text);
    if (ok && mounted) Navigator.of(context).pop(true);
  }

  void _useOtherEmail() {
    _clearError();
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
      appBar: AppBar(),
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(
          AppShape.gutter,
          0,
          AppShape.gutter,
          24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ScreenTitle(
              'Recuperar senha',
              subtitle: _codeSent
                  ? 'Passo 2 de 2: código e nova senha'
                  : 'Passo 1 de 2: seu e-mail',
            ),
            _codeSent ? _resetStep(auth.busy) : _emailStep(auth.busy),
          ],
        ),
      ),
    );
  }

  Widget _error() {
    final error = ref.watch(authControllerProvider).error;
    if (error == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(
        error,
        key: const Key('reset_error'),
        style: AppText.body.copyWith(color: AppColors.of(context).danger),
      ),
    );
  }

  static final ButtonStyle _mainButton = FilledButton.styleFrom(
    minimumSize: const Size.fromHeight(56),
  );

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
          SectionCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Informe o e-mail da sua conta. Vamos enviar um código para '
                  'criar uma nova senha.',
                  style: AppText.body.copyWith(
                    color: AppColors.of(context).textMuted,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('reset_email'),
                  controller: _email,
                  decoration: const InputDecoration(labelText: 'E-mail'),
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  onChanged: (_) => _clearError(),
                  onFieldSubmitted: (_) => _sendCode(),
                  validator: (v) => (v == null || !v.contains('@'))
                      ? 'E-mail inválido'
                      : null,
                ),
                _error(),
              ],
            ),
          ),
          FilledButton(
            key: const Key('reset_send'),
            style: _mainButton,
            onPressed: busy ? null : _sendCode,
            child: _busyLabel(busy, 'Enviar código'),
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
          SectionCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Enviamos um código de 6 dígitos se o e-mail tiver conta. '
                  'Ele vale por 15 minutos.',
                  key: const Key('reset_info'),
                  style: AppText.body.copyWith(
                    color: AppColors.of(context).text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _email.text.trim(),
                  style: AppText.bodyStrong.copyWith(
                    color: AppColors.of(context).ciano.fg,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('reset_code'),
                  controller: _code,
                  decoration: const InputDecoration(labelText: 'Código'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => _clearError(),
                  validator: (v) =>
                      (v == null || !RegExp(r'^\d{6}$').hasMatch(v.trim()))
                      ? 'O código tem 6 dígitos'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('reset_new_password'),
                  controller: _password,
                  decoration: const InputDecoration(labelText: 'Nova senha'),
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => _clearError(),
                  validator: (v) => (v == null || v.length < 8)
                      ? 'Mínimo de 8 caracteres'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('reset_confirm_password'),
                  controller: _confirm,
                  decoration: const InputDecoration(
                    labelText: 'Confirmar nova senha',
                  ),
                  obscureText: true,
                  onChanged: (_) => _clearError(),
                  onFieldSubmitted: (_) => _reset(),
                  validator: (v) =>
                      v != _password.text ? 'As senhas não conferem' : null,
                ),
                _error(),
              ],
            ),
          ),
          FilledButton(
            key: const Key('reset_submit'),
            style: _mainButton,
            onPressed: busy ? null : _reset,
            child: _busyLabel(busy, 'Trocar senha e entrar'),
          ),
          const SizedBox(height: 8),
          TextButton(
            key: const Key('reset_resend'),
            onPressed: busy ? null : _sendCode,
            child: const Text('Reenviar código'),
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
