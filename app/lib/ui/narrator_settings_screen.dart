// Configuracoes > Narrador (F03): liga/desliga a voz, escolhe quando ela fala
// (distancia, tempo, volta, inicio/pausas/fim) e o que ela diz (tempo,
// distancia, pace/velocidade, frases de contexto, so o essencial), com o
// botao "Ouvir exemplo".
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../narrator/domain/narration_composer.dart';
import '../narrator/domain/narrator_settings.dart';
import '../narrator/narrator_providers.dart';
import 'components/big_action_button.dart';
import 'components/segmented_selector.dart';
import 'section_card.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'theme/app_typography.dart';

class NarratorSettingsScreen extends ConsumerWidget {
  const NarratorSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final metric = ref.watch(settingsProvider.select((s) => s.useMetric));
    final n = ref.watch(settingsProvider.select((s) => s.narrator));
    final ctrl = ref.read(settingsProvider.notifier);
    final unit = metric ? 'km' : 'mi';

    // Muda so o campo tocado, sobre as preferencias ja carregadas do banco.
    void save(NarratorSettings Function(NarratorSettings n) change) =>
        ctrl.updateNarrator(change);

    Widget hint(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(AppShape.gutter, 4, AppShape.gutter, 8),
      child: Text(text, style: AppText.label.copyWith(color: c.textMuted)),
    );

    // Conteudo vale so fora do modo "so o essencial".
    final contentEnabled = !n.essentialOnly;
    SwitchListTile content({
      required String key,
      required String title,
      String? subtitle,
      required bool value,
      required NarratorSettings Function(NarratorSettings n, bool v) apply,
    }) => SwitchListTile(
      key: Key(key),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle),
      value: value,
      onChanged: contentEnabled ? (v) => save((n) => apply(n, v)) : null,
    );

    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppShape.gutter, 0, AppShape.gutter, 24),
        children: [
          const ScreenTitle(
            'Narrador por voz',
            subtitle: 'Ouca o tempo e o pace sem olhar o celular',
          ),
          SectionCard(
            child: SwitchListTile(
              key: const Key('narrator_enabled'),
              title: const Text('Narrador por voz'),
              subtitle: const Text('Fala durante a gravacao e abaixa a musica'),
              value: n.enabled,
              onChanged: (v) => save((n) => n.copyWith(enabled: v)),
            ),
          ),
          SectionCard(
            title: 'Quando falar',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SwitchListTile(
                  key: const Key('narrator_distance'),
                  title: Text(metric ? 'A cada km' : 'A cada milha'),
                  value: n.distanceTrigger,
                  onChanged: (v) => save((n) => n.copyWith(distanceTrigger: v)),
                ),
                if (n.distanceTrigger)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: SegmentedSelector<int>(
                      key: const Key('narrator_distance_every'),
                      selected: n.distanceEvery,
                      onChanged: (v) => save((n) => n.copyWith(distanceEvery: v)),
                      options: [
                        for (final d in kNarratorDistanceEveryOptions)
                          SegmentOption(
                            value: d,
                            label: '$d $unit',
                            role: c.dist,
                            key: Key('narrator_distance_every_$d'),
                          ),
                      ],
                    ),
                  ),
                const SectionDivider(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppShape.gutter, 12, AppShape.gutter, 0),
                  child: Text('A cada tanto tempo', style: AppText.body.copyWith(color: c.text)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: SegmentedSelector<int>(
                    key: const Key('narrator_time'),
                    selected: n.timeEveryMinutes,
                    onChanged: (v) => save((n) => n.copyWith(timeEveryMinutes: v)),
                    options: [
                      for (final m in kNarratorTimeEveryOptions)
                        SegmentOption(
                          value: m,
                          label: m == 0 ? 'Nao' : '$m min',
                          role: c.tempo,
                          key: Key('narrator_time_$m'),
                        ),
                    ],
                  ),
                ),
                hint('Conta o tempo em movimento, sem as pausas'),
                const SectionDivider(),
                SwitchListTile(
                  key: const Key('narrator_lap'),
                  title: const Text('A cada volta'),
                  value: n.lapTrigger,
                  onChanged: (v) => save((n) => n.copyWith(lapTrigger: v)),
                ),
                const SectionDivider(),
                SwitchListTile(
                  key: const Key('narrator_status'),
                  title: const Text('Inicio, pausas e fim'),
                  subtitle: const Text('Avisa a pausa automatica e a retomada'),
                  value: n.statusAnnouncements,
                  onChanged: (v) => save((n) => n.copyWith(statusAnnouncements: v)),
                ),
              ],
            ),
          ),
          SectionCard(
            title: 'O que falar',
            child: Column(
              children: [
                SwitchListTile(
                  key: const Key('narrator_essential'),
                  title: const Text('So o essencial'),
                  subtitle: const Text('Frases curtas: a marca e o pace (ou a velocidade)'),
                  value: n.essentialOnly,
                  onChanged: (v) => save((n) => n.copyWith(essentialOnly: v)),
                ),
                const SectionDivider(),
                content(
                  key: 'narrator_say_time',
                  title: 'Tempo total',
                  value: n.sayTime,
                  apply: (n, v) => n.copyWith(sayTime: v),
                ),
                content(
                  key: 'narrator_say_distance',
                  title: 'Distancia',
                  value: n.sayDistance,
                  apply: (n, v) => n.copyWith(sayDistance: v),
                ),
                content(
                  key: 'narrator_say_avg',
                  title: 'Pace medio',
                  subtitle: 'No pedal, velocidade media',
                  value: n.sayAvgPace,
                  apply: (n, v) => n.copyWith(sayAvgPace: v),
                ),
                content(
                  key: 'narrator_say_split',
                  title: metric ? 'Pace do km e da volta' : 'Pace da milha e da volta',
                  subtitle: 'No pedal, a velocidade',
                  value: n.saySplitPace,
                  apply: (n, v) => n.copyWith(saySplitPace: v),
                ),
                content(
                  key: 'narrator_context',
                  title: 'Frases de contexto',
                  subtitle: metric
                      ? 'Ex.: seu quilometro mais rapido ate agora'
                      : 'Ex.: sua milha mais rapida ate agora',
                  value: n.contextPhrases,
                  apply: (n, v) => n.copyWith(contextPhrases: v),
                ),
              ],
            ),
          ),
          BigActionButton(
            key: const Key('narrator_sample'),
            label: 'Ouvir exemplo',
            icon: Icons.volume_up_rounded,
            onPressed: () {
              // Troca so o exemplo anterior: falas pendentes de uma gravacao
              // em curso continuam na fila.
              ref
                  .read(narratorProvider)
                  .replace(const NarrationComposer().sample(n, metric: metric));
            },
          ),
          hint('A voz e a do sistema do celular, em portugues'),
        ],
      ),
    );
  }
}
