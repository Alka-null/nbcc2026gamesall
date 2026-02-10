import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _musicPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();

  bool _isMusicPlaying = false;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer.setVolume(0.3);
      await _sfxPlayer.setVolume(0.5);
      _isInitialized = true;
    } catch (e) {
      print('Audio initialization error: $e');
    }
  }

  Future<void> playBackgroundMusic() async {
    if (_isMusicPlaying) return;
    try {
      await _musicPlayer.play(AssetSource('audio/background_music.mp3'));
      _isMusicPlaying = true;
    } catch (e) {
      print('Background music error: $e');
    }
  }

  Future<void> pauseBackgroundMusic() async {
    if (!_isMusicPlaying) return;
    try {
      await _musicPlayer.pause();
      _isMusicPlaying = false;
    } catch (e) {
      print('Pause music error: $e');
    }
  }

  Future<void> playSound(String soundName) async {
    try {
      // Support both .mp3 and .wav files
      final extension = soundName == 'click' ? 'wav' : 'mp3';
      await _sfxPlayer.play(AssetSource('audio/$soundName.$extension'));
    } catch (e) {
      print('Sound effect error: $e');
    }
  }

  void dispose() {
    _musicPlayer.dispose();
    _sfxPlayer.dispose();
    _isInitialized = false;
    _isMusicPlaying = false;
  }
}
