// Entrar ou criar conta no nosso backend. A conta so e exigida para
// sincronizar; gravar funciona sem ela.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';

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

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final ctrl = ref.read(authControllerProvider.notifier);
    final ok = _register
        ? await ctrl.register(_email.text, _password.text, _name.text)
        : await ctrl.login(_email.text, _password.text);
    if (ok && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    return Scaffold(
      appBar: AppBar(title: Text(_register ? 'Criar conta' : 'Entrar')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'A conta serve para guardar suas atividades no servidor. '
                'Gravar funciona sem ela.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              if (_register)
                TextFormField(
                  key: const Key('auth_name'),
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Nome'),
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Informe seu nome' : null,
                ),
              TextFormField(
                key: const Key('auth_email'),
                controller: _email,
                decoration: const InputDecoration(labelText: 'E-mail'),
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    (v == null || !v.contains('@')) ? 'E-mail invalido' : null,
              ),
              TextFormField(
                key: const Key('auth_password'),
                controller: _password,
                decoration: const InputDecoration(labelText: 'Senha'),
                obscureText: true,
                onFieldSubmitted: (_) => _submit(),
                validator: (v) => (_register && (v == null || v.length < 8))
                    ? 'Minimo de 8 caracteres'
                    : (v == null || v.isEmpty)
                        ? 'Informe a senha'
                        : null,
              ),
              const SizedBox(height: 16),
              if (auth.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    auth.error!,
                    key: const Key('auth_error'),
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              FilledButton(
                key: const Key('auth_submit'),
                onPressed: auth.busy ? null : _submit,
                child: auth.busy
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_register ? 'Criar conta' : 'Entrar'),
              ),
              TextButton(
                key: const Key('auth_toggle'),
                onPressed: auth.busy
                    ? null
                    : () => setState(() => _register = !_register),
                child: Text(_register
                    ? 'Ja tenho conta'
                    : 'Nao tem conta? Criar uma'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
