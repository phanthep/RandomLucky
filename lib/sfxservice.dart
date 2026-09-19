import 'package:audioplayers/audioplayers.dart';

class SfxService {
  static final AudioPlayer _gachaplayer = AudioPlayer();
  static final AudioPlayer _loopPlayer = AudioPlayer();

  static Future<void> _play(String file) async {
    try {
      await _gachaplayer.stop();
      await _gachaplayer.play(AssetSource('sounds/$file'));
    } catch (_) {}
  }

  static Future<void> click() => _play('click.mp3');
  static Future<void> shake() => _play('shake.mp3');
  static Future<void> tick() => _play('tick.mp3');
  static Future<void> drop() => _play('drop.mp3');
  static Future<void> reveal() => _play('reveal.mp3');
  static Future<void> win() => _play('reveal.mp3');

  /// เริ่มเล่นเสียงหวือแบบวนลูป ตอนวงล้อ/ตู้กำลังหมุน
  static Future<void> startSpinLoop() async {
    try {
      await _loopPlayer.setReleaseMode(ReleaseMode.loop);
      await _loopPlayer.play(AssetSource('sounds/tick.mp3'));
    } catch (_) {}
  }

  /// หยุดเสียงลูปตอนวงล้อหยุดหมุน
  static Future<void> stopSpinLoop() async {
    try {
      await _loopPlayer.stop();
    } catch (_) {}
  }
}