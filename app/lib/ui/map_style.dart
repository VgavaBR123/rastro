// Estilos do mapa (tiles vetoriais do OpenFreeMap, dados OSM, sem chave) e a
// escolha do usuario. A escolha vive so em memoria: sem ela, o mapa segue o
// brilho do tema (Escuro no tema escuro, Claro no tema claro).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';

const String _openFreeMap = 'https://tiles.openfreemap.org/styles';

enum MapStyle {
  escuro('Escuro', Icons.dark_mode_rounded, '$_openFreeMap/dark'),
  noturno('Noturno', Icons.nights_stay_rounded, '$_openFreeMap/fiord'),
  claro('Claro', Icons.light_mode_rounded, '$_openFreeMap/positron'),
  ruas('Ruas', Icons.map_rounded, '$_openFreeMap/liberty');

  final String label;
  final IconData icon;
  final String url;
  const MapStyle(this.label, this.icon, this.url);

  /// Padrao de cada tema.
  static MapStyle forBrightness(Brightness b) =>
      b == Brightness.dark ? MapStyle.escuro : MapStyle.claro;
}

/// Escolha feita em Camadas; null = segue o tema.
final mapStyleChoiceProvider = StateProvider<MapStyle?>((ref) => null);

/// Estilo efetivo: a escolha, ou o padrao do tema. Funcao pura.
MapStyle effectiveMapStyle(MapStyle? choice, Brightness brightness) =>
    choice ?? MapStyle.forBrightness(brightness);
