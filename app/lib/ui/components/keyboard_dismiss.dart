// Fecha o teclado ao tocar fora de um campo (VOC-01 e GRA-07 do teste no
// iPhone): no iOS e no Android o Flutter nao faz isso sozinho, e sem tecla de
// fechar o teclado so saia enviando o formulario.
library;

import 'package:flutter/material.dart';

/// Envolve o app inteiro. Um toque que nenhum filho reivindica (fundo, titulo,
/// texto) tira o foco do campo; toques em botoes e campos seguem para eles,
/// porque o reconhecedor mais interno ganha a disputa do toque.
class KeyboardDismissOnTap extends StatelessWidget {
  final Widget child;
  const KeyboardDismissOnTap({super.key, required this.child});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
    child: child,
  );
}
