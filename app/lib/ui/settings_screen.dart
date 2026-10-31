// Tela de configuracoes: unidades (metrico ou imperial), pausa automatica e
// peso (para calorias), em secoes de cartao.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import 'components/segmented_selector.dart';
import 'section_card.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'theme/app_typography.dart';

/// Libras por quilograma.
const double kLbPerKg = 2.20462262185;

/// Limites aceitos pelo SettingsController (kg).
const double _minKg = 20;
const double _maxKg = 400;

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final s = ref.watch(settingsProvider);
    final ctrl = ref.read(settingsProvider.notifier);
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(
          AppShape.gutter,
          0,
          AppShape.gutter,
          24,
        ),
        children: [
          const ScreenTitle('Configuracoes'),
          SectionCard(
            title: 'Unidades',
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SegmentedSelector<bool>(
                  key: const Key('metric'),
                  selected: s.useMetric,
                  onChanged: ctrl.setUseMetric,
                  options: [
                    SegmentOption(
                      value: true,
                      label: 'Metrico',
                      role: c.ciano,
                      key: const Key('metric_on'),
                    ),
                    SegmentOption(
                      value: false,
                      label: 'Imperial',
                      role: c.ciano,
                      key: const Key('metric_off'),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 10, 4, 0),
                  child: Text(
                    s.useMetric ? 'km, m, min/km' : 'mi, ft, min/mi',
                    style: AppText.label.copyWith(color: c.textMuted),
                  ),
                ),
              ],
            ),
          ),
          SectionCard(
            title: 'Gravacao',
            child: Column(
              children: [
                SwitchListTile(
                  key: const Key('autopause'),
                  title: const Text('Pausa automatica'),
                  subtitle: const Text('Pausa sozinho quando voce para'),
                  value: s.autoPauseEnabled,
                  onChanged: ctrl.setAutoPauseEnabled,
                ),
                const SectionDivider(),
                // MergeSemantics: a linha e um botao proprio (rotulo + valor),
                // sem se fundir com o resto da secao.
                MergeSemantics(
                  child: ListTile(
                    key: const Key('weight'),
                    title: const Text('Peso (para calorias)'),
                    subtitle: Text(
                      formatWeight(s.weightKg, metric: s.useMetric),
                      key: const Key('weightValue'),
                    ),
                    trailing: Icon(Icons.edit_rounded, color: c.extra.fg),
                    onTap: () => showDialog<void>(
                      context: context,
                      builder: (_) => WeightDialog(
                        initialKg: s.weightKg,
                        metric: s.useMetric,
                        onSave: ctrl.setWeightKg,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "72.5 kg", "160 lb" ou "Nao informado".
String formatWeight(double? kg, {required bool metric}) {
  if (kg == null) return 'Nao informado';
  final value = metric ? kg : kg * kLbPerKg;
  return '${_trim(value)} ${metric ? 'kg' : 'lb'}';
}

/// Uma casa decimal, sem o ".0" quando inteiro.
String _trim(double v) {
  final s = v.toStringAsFixed(1);
  return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
}

/// Dialogo de edicao do peso. Mostra e recebe o valor na unidade das
/// configuracoes; [onSave] recebe sempre kg (null apaga) e devolve se aceitou.
class WeightDialog extends StatefulWidget {
  final double? initialKg;
  final bool metric;
  final Future<bool> Function(double? kg) onSave;

  const WeightDialog({
    super.key,
    required this.initialKg,
    required this.metric,
    required this.onSave,
  });

  @override
  State<WeightDialog> createState() => _WeightDialogState();
}

class _WeightDialogState extends State<WeightDialog> {
  late final TextEditingController _text;
  String? _error;

  String get _unit => widget.metric ? 'kg' : 'lb';

  @override
  void initState() {
    super.initState();
    final kg = widget.initialKg;
    _text = TextEditingController(
      text: kg == null ? '' : _trim(widget.metric ? kg : kg * kLbPerKg),
    );
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final raw = _text.text.trim().replaceAll(',', '.');
    double? kg;
    if (raw.isNotEmpty) {
      final value = double.tryParse(raw);
      if (value == null || !value.isFinite) {
        setState(() => _error = 'Informe um numero');
        return;
      }
      kg = widget.metric ? value : value / kLbPerKg;
      if (kg < _minKg || kg > _maxKg) {
        setState(() => _error = _rangeMessage());
        return;
      }
    }
    final ok = await widget.onSave(kg);
    if (!mounted) return;
    if (!ok) {
      setState(() => _error = _rangeMessage());
      return;
    }
    Navigator.of(context).pop();
  }

  String _rangeMessage() => widget.metric
      ? 'Use um valor entre ${_minKg.round()} e ${_maxKg.round()} kg'
      : 'Use um valor entre ${(_minKg * kLbPerKg).ceil()} e '
            '${(_maxKg * kLbPerKg).floor()} lb';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Peso'),
      content: TextField(
        key: const Key('weightField'),
        controller: _text,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: 'Peso',
          suffixText: _unit,
          helperText: 'Deixe vazio para apagar',
          errorText: _error,
        ),
        onSubmitted: (_) => _save(),
      ),
      actions: [
        TextButton(
          key: const Key('weightCancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('weightSave'),
          onPressed: _save,
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
