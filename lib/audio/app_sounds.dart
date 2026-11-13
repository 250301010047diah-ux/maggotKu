import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

/// Efek pendek; kegagalan audio tidak boleh mengganggu aksi pengguna.
class AppSounds {
  AppSounds._();

  static final _player = AudioPlayer();

  static void _play(String file) {
    unawaited(
      _player.play(AssetSource('audio/$file')).catchError((Object _) {}),
    );
  }

  static void success() => _play('plup-ting.mp3');
  static void warning() => _play('warning.mp3');
  static void onboarding() => _play('onboarding.mp3');
  static void agenda() => _play('lonceng.mp3');
}
