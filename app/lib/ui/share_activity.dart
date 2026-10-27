// Acao Compartilhar dos cartoes e do Detalhe: monta o resumo da atividade e
// abre a folha nativa. Falha da plataforma vira SnackBar.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../core/format/activity_labels.dart';
import '../core/format/activity_share_text.dart';
import '../persistence/database.dart';
import '../platform/activity_sharer.dart';

/// Texto compartilhado para [a] na unidade das configuracoes.
String shareTextFor(Activity a, {required bool metric}) => activityShareText(
  title: displayActivityTitle(
    a.title,
    a.activityType,
    DateTime.fromMillisecondsSinceEpoch(a.startTimestampMs),
  ),
  type: a.activityType,
  distanceMeters: a.distanceMeters,
  timerMs: a.timerTimeMs,
  metric: metric,
);

Future<void> shareActivity(
  BuildContext context,
  WidgetRef ref,
  Activity a,
) async {
  final metric = ref.read(settingsProvider).useMetric;
  final messenger = ScaffoldMessenger.of(context);
  try {
    await ref
        .read(activitySharerProvider)
        .shareText(shareTextFor(a, metric: metric));
  } on Exception {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Nao foi possivel compartilhar')),
      );
  }
}
