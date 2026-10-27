/// Compartilhamento pela folha nativa do sistema (canal `stravaestudo/share`):
/// Intent ACTION_SEND no Android (ShareChannel.kt) e UIActivityViewController
/// no iOS (AppDelegate.swift). Os testes trocam a implementacao pelo
/// [activitySharerProvider].
library;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class ActivitySharer {
  /// Abre a folha de compartilhamento com [text]. Lanca (PlatformException,
  /// MissingPluginException) se a plataforma nao conseguir.
  Future<void> shareText(String text);

  /// Abre a folha com o PNG em [path] e, se houver, [text] junto. No Android
  /// o arquivo precisa estar em `cache/share/` (FileProvider). Lanca como
  /// [shareText].
  Future<void> shareImage(String path, {String? text});
}

class MethodChannelActivitySharer implements ActivitySharer {
  const MethodChannelActivitySharer({this.channel = defaultChannel});

  static const String channelName = 'stravaestudo/share';
  static const MethodChannel defaultChannel = MethodChannel(channelName);

  final MethodChannel channel;

  @override
  Future<void> shareText(String text) =>
      channel.invokeMethod<void>('shareText', {'text': text});

  @override
  Future<void> shareImage(String path, {String? text}) => channel
      .invokeMethod<void>('shareImage', {'path': path, 'text': ?text});
}

final activitySharerProvider = Provider<ActivitySharer>(
  (ref) => const MethodChannelActivitySharer(),
);
