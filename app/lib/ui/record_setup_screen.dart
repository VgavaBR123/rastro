// Tela Gravar: escolha do esporte e inicio da gravacao.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/router.dart';
import '../recording/domain/recording_models.dart';

class RecordSetupScreen extends StatelessWidget {
  const RecordSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final t in ActivityType.values)
              FilledButton(
                onPressed: () => context.push(AppRoutes.record(t)),
                child: Text(t.name),
              ),
          ],
        ),
      ),
    );
  }
}
