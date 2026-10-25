// Ponto de entrada do app. Clean room — app proprio de atividades.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ui/home_screen.dart';

void main() {
  runApp(const ProviderScope(child: StravaEstudoApp()));
}

class StravaEstudoApp extends StatelessWidget {
  const StravaEstudoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Atividades',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
