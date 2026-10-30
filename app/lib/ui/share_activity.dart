// Acao Compartilhar dos cartoes e do Detalhe: abre a tela Compartilhar
// (previa da imagem, estilo, envio como imagem ou so texto).
library;

import 'package:flutter/material.dart';

import '../core/format/activity_labels.dart';
import '../core/format/activity_share_text.dart';
import '../persistence/database.dart';
import 'share/share_activity_screen.dart';

/// Texto compartilhado para [a] na unidade das configuracoes.
String shareTextFor(
  Activity a, {
  required bool metric,
  bool gentle = false,
}) => activityShareText(
  title: displayActivityTitle(
    a.title,
    a.activityType,
    DateTime.fromMillisecondsSinceEpoch(a.startTimestampMs),
  ),
  type: a.activityType,
  distanceMeters: a.distanceMeters,
  timerMs: a.timerTimeMs,
  metric: metric,
  gentle: gentle,
);

/// Abre a tela Compartilhar no Navigator raiz (por cima das abas).
Future<void> shareActivity(BuildContext context, Activity a) {
  return Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<void>(builder: (_) => ShareActivityScreen(activity: a)),
  );
}
