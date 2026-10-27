/// Implementacao real de [MslAltitudeConverter] no Android: chama o conversor
/// de altitude da AndroidX pelo canal nativo (ver `MslAltitudeChannel.kt`).
library;

import 'package:flutter/services.dart';

import 'msl_altitude.dart';

class MethodChannelMslAltitudeConverter implements MslAltitudeConverter {
  const MethodChannelMslAltitudeConverter({this.channel = defaultChannel});

  static const String channelName = 'com.stravaestudo/msl_altitude';
  static const MethodChannel defaultChannel = MethodChannel(channelName);

  final MethodChannel channel;

  @override
  Future<double?> toMsl({
    required double latitude,
    required double longitude,
    required double ellipsoidAltitudeMeters,
  }) async {
    if (!latitude.isFinite ||
        !longitude.isFinite ||
        !ellipsoidAltitudeMeters.isFinite) {
      return null;
    }
    try {
      final value = await channel.invokeMethod<Object?>('toMsl', {
        'latitude': latitude,
        'longitude': longitude,
        'ellipsoidAltitudeMeters': ellipsoidAltitudeMeters,
      });
      if (value is num && value.isFinite) return value.toDouble();
      return null;
    } catch (_) {
      // PlatformException, MissingPluginException etc.: cai na altitude crua.
      return null;
    }
  }
}
