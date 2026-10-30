// Fakes das bordas da gravacao (GPS, servico/notificacao, acelerometro,
// bateria, altitude MSL) compartilhados pelos testes.
import 'dart:async';

import 'package:strava_estudo_app/platform/msl_altitude.dart';
import 'package:strava_estudo_app/recording/domain/auto_pause.dart';
import 'package:strava_estudo_app/recording/domain/motion_auto_pause.dart';
import 'package:strava_estudo_app/recording/domain/location_sample.dart';
import 'package:strava_estudo_app/recording/service/recording_service.dart';
import 'package:strava_estudo_app/recording/source/accelerometer_source.dart';
import 'package:strava_estudo_app/recording/source/battery_level_source.dart';
import 'package:strava_estudo_app/recording/source/heartbeat_ticker.dart';
import 'package:strava_estudo_app/recording/source/location_source.dart';

class FakeLocationSource implements LocationSource {
  final _controller = StreamController<LocationSample>.broadcast();
  bool permission = true;

  void add(LocationSample s) => _controller.add(s);

  @override
  Future<bool> ensurePermission() async => permission;

  @override
  Stream<LocationSample> positions() => _controller.stream;

  @override
  Future<void> stop() async {}
}

/// Servico fake: registra o que a gravacao pediu e deixa o teste "tocar" nos
/// botoes da notificacao.
class FakeRecordingService implements RecordingService {
  final _commands = StreamController<RecordingCommand>.broadcast();
  final List<RecordingNotification> started = [];
  final List<RecordingNotification> updates = [];
  int stops = 0;
  bool get running => started.length > stops;

  void press(RecordingCommand c) => _commands.add(c);

  @override
  Stream<RecordingCommand> get commands => _commands.stream;

  @override
  Future<void> start(RecordingNotification n) async => started.add(n);

  @override
  Future<void> update(RecordingNotification n) async => updates.add(n);

  @override
  Future<void> stop() async => stops++;
}

class FakeAccelerometerSource implements AccelerometerSource {
  final _controller = StreamController<AccelSample>.broadcast();
  int listens = 0;
  bool get hasListener => _controller.hasListener;

  void add(AccelSample s) => _controller.add(s);

  @override
  Stream<AccelSample> samples() {
    listens++;
    return _controller.stream;
  }
}

class FakeBatteryLevelSource implements BatteryLevelSource {
  final List<int?> levels;
  int calls = 0;
  FakeBatteryLevelSource(this.levels);

  @override
  Future<int?> level() async => levels[calls++ % levels.length];
}

/// Detector de movimento espiao: guarda as amostras do acelerometro.
class SpyMotionDetector extends MotionAutoPauseDetector {
  final List<AccelSample> received = [];
  SpyMotionDetector() : super(fallback: SpeedAutoPauseDetector());

  @override
  void addAccel(AccelSample s) => received.add(s);
}

/// Conversor MSL fake: devolve a altitude crua menos [offset], ou null.
class FakeMslConverter implements MslAltitudeConverter {
  final double? offset;
  int calls = 0;
  FakeMslConverter(this.offset);

  @override
  Future<double?> toMsl({
    required double latitude,
    required double longitude,
    required double ellipsoidAltitudeMeters,
  }) async {
    calls++;
    final o = offset;
    return o == null ? null : ellipsoidAltitudeMeters - o;
  }
}

/// Relogio do heartbeat controlado pelo teste: cada [tick] e um batimento.
class FakeHeartbeatTicker implements HeartbeatTicker {
  final _controller = StreamController<void>.broadcast();
  final List<Duration> intervals = [];
  bool get hasListener => _controller.hasListener;

  void tick() => _controller.add(null);

  @override
  Stream<void> ticks(Duration interval) {
    intervals.add(interval);
    return _controller.stream;
  }
}
