// Entrar ou criar conta no nosso backend. A conta so e exigida para
// sincronizar; gravar funciona sem ela.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/providers.dart';
import '../app/router.dart';
import 'section_card.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'theme/app_typography.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  bool _register = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  /// O erro do servidor vale para a tentativa que falhou: some ao editar,
  /// trocar de modo ou tentar de novo (VOC-04).
  void _clearError() => ref.read(authControllerProvider.notifier).clearError();

  Future<void> _submit() async {
    _clearError();
    if (!_form.currentState!.validate()) return;
    final ctrl = ref.read(authControllerProvider.notifier);
    final ok = _register
        ? await ctrl.register(_email.text, _password.text, _name.text)
        : await ctrl.login(_email.text, _password.text);
    if (ok && mounted) Navigator.of(context).pop();
  }

  Future<void> _forgot() async {
    final done = await context.push<bool>(
      AppRoutes.passwordReset(email: _email.text.trim()),
    );
    if (!mounted) return;
    if (done == true) {
      // Senha trocada: ja esta logado, fecha a tela de login tambem.
      Navigator.of(context).pop();
    } else {
      ref.read(authControllerProvider.notifier).clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final auth = ref.watch(authControllerProvider);
    const gap = SizedBox(height: 12);
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
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ScreenTitle(
                _register ? 'Criar conta' : 'Entrar',
                subtitle:
                    'A conta serve para guardar suas atividades no servidor. '
                    'Gravar funciona sem ela.',
              ),
              SectionCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_register) ...[
                      TextFormField(
                        key: const Key('auth_name'),
                        controller: _name,
                        decoration: const InputDecoration(labelText: 'Nome'),
                        textInputAction: TextInputAction.next,
                        onChanged: (_) => _clearError(),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Informe seu nome'
                            : null,
                      ),
                      gap,
                    ],
                    TextFormField(
                      key: const Key('auth_email'),
                      controller: _email,
                      decoration: const InputDecoration(labelText: 'E-mail'),
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      textInputAction: TextInputAction.next,
                      onChanged: (_) => _clearError(),
                      validator: (v) => (v == null || !v.contains('@'))
                          ? 'E-mail inválido'
                          : null,
                    ),
                    gap,
                    TextFormField(
                      key: const Key('auth_password'),
                      controller: _password,
                      decoration: const InputDecoration(labelText: 'Senha'),
                      obscureText: true,
                      onChanged: (_) => _clearError(),
                      onFieldSubmitted: (_) => _submit(),
                      validator: (v) =>
                          (_register && (v == null || v.length < 8))
                          ? 'Mínimo de 8 caracteres'
                          : (v == null || v.isEmpty)
                          ? 'Informe a senha'
                          : null,
                    ),
                    if (auth.error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          auth.error!,
                          key: const Key('auth_error'),
                          style: AppText.body.copyWith(color: c.danger),
                        ),
                      ),
                  ],
                ),
              ),
              FilledButton(
                key: const Key('auth_submit'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
                onPressed: auth.busy ? null : _submit,
                child: auth.busy
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_register ? 'Criar conta' : 'Entrar'),
              ),
              const SizedBox(height: 8),
              TextButton(
                key: const Key('auth_toggle'),
                onPressed: auth.busy
                    ? null
                    : () {
                        _clearError();
                        setState(() => _register = !_register);
                      },
                child: Text(
                  _register ? 'Já tenho conta' : 'Não tem conta? Criar uma',
                ),
              ),
              if (!_register)
                TextButton(
                  key: const Key('auth_forgot'),
                  onPressed: auth.busy ? null : _forgot,
                  child: const Text('Esqueci minha senha'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
