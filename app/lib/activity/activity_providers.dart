// Providers do detalhe da atividade: voltas e perfil de elevacao.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import 'elevation_profile.dart';
import 'lap_summary.dart';

/// Voltas gravadas de uma atividade, em ordem.
final activityLapsProvider = FutureProvider.autoDispose
    .family<List<LapSummary>, String>((ref, guid) async {
      final laps = await ref.watch(recordingRepositoryProvider).laps(guid);
      final sorted = [...laps]..sort((a, b) => a.number.compareTo(b.number));
      return [for (final l in sorted) LapSummary.fromLap(l)];
    });

/// Perfil de elevacao (so pontos aceitos com altitude); null sem dados.
final activityElevationProfileProvider = FutureProvider.autoDispose
    .family<ElevationProfile?, String>((ref, guid) async {
      final rows = await ref.watch(recordingRepositoryProvider).waypoints(guid);
      return buildElevationProfile(rows);
    });
