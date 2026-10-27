/// Provider do conversor de altitude MSL: canal nativo no Android, sem
/// conversao nas demais plataformas e nos testes no host.
library;

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'method_channel_msl_altitude.dart';
import 'msl_altitude.dart';

/// Escolhe a implementacao pela plataforma. Testes podem sobrescrever com
/// `mslAltitudeConverterProvider.overrideWithValue(...)`.
MslAltitudeConverter defaultMslAltitudeConverter({bool? isAndroid}) {
  final android = isAndroid ?? (!kIsWeb && Platform.isAndroid);
  return android
      ? const MethodChannelMslAltitudeConverter()
      : const NoMslAltitudeConverter();
}

final mslAltitudeConverterProvider = Provider<MslAltitudeConverter>(
  (ref) => defaultMslAltitudeConverter(),
);
