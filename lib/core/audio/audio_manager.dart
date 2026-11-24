import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  late AudioPlayer _sfxPlayer;
  late AudioPlayer _bgmPlayer;

  bool _isMusicEnabled = false;
  bool _isSoundEnabled = true;
  bool _isVibrationEnabled = true;
  double _musicVolume = 0.5;
  double _sfxVolume = 0.8;

  bool get isMusicEnabled => _isMusicEnabled;
  bool get isSoundEnabled => _isSoundEnabled;
  bool get isVibrationEnabled => _isVibrationEnabled;
  double get musicVolume => _musicVolume;
  double get sfxVolume => _sfxVolume;

  Future<void> init() async {
    _sfxPlayer = AudioPlayer();
    _bgmPlayer = AudioPlayer();

    final prefs = await SharedPreferences.getInstance();
    _isMusicEnabled = prefs.getBool('music_enabled') ?? false;
    _isSoundEnabled = prefs.getBool('sound_enabled') ?? true;
    _isVibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
    _musicVolume = prefs.getDouble('music_volume') ?? 0.5;
    _sfxVolume = prefs.getDouble('sfx_volume') ?? 0.8;

    await _sfxPlayer.setVolume(_isSoundEnabled ? _sfxVolume : 0.0);
    await _bgmPlayer.setVolume(_isMusicEnabled ? _musicVolume : 0.0);
  }

  // Smooth, atmospheric background music tracks
  Future<void> startBgm() async {
    await playHomeBgm();
  }

  Future<void> playHomeBgm() async {
    if (!_isMusicEnabled) return;
    try {
      await _bgmPlayer.stop();
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer.setVolume(_musicVolume);
      await _bgmPlayer.play(AssetSource('audio/home_bgm.wav'));
    } catch (_) {}
  }

  Future<void> playQuizBgm() async {
    if (!_isMusicEnabled) return;
    try {
      await _bgmPlayer.stop();
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer.setVolume(_musicVolume);
      await _bgmPlayer.play(AssetSource('audio/gameplay_bgm.wav'));
    } catch (_) {}
  }

  Future<void> pauseBgm() async {
    try {
      await _bgmPlayer.pause();
    } catch (_) {}
  }

  Future<void> resumeBgm() async {
    if (!_isMusicEnabled) return;
    try {
      await _bgmPlayer.resume();
    } catch (_) {}
  }

  Future<void> stopBgm() async {
    try {
      await _bgmPlayer.stop();
    } catch (_) {}
  }

  Future<void> duckForAd() async {
    try {
      await _bgmPlayer.setVolume(0.05);
    } catch (_) {}
  }

  Future<void> restoreAfterAd() async {
    try {
      if (_isMusicEnabled) {
        await _bgmPlayer.setVolume(_musicVolume);
      }
    } catch (_) {}
  }

  // Short, pleasant, premium interaction sounds only
  Future<void> playClick() async {
    if (!_isSoundEnabled) return;
    _playSfx('audio/click.wav');
    vibrateLight();
  }

  Future<void> playCategorySelect() async {
    if (!_isSoundEnabled) return;
    _playSfx('audio/click.wav');
    vibrateLight();
  }

  Future<void> playTick() async {
    if (!_isSoundEnabled) return;
    _playSfx('audio/tick.wav');
  }

  Future<void> playCorrect() async {
    if (!_isSoundEnabled) return;
    _playSfx('audio/correct.wav');
    vibrateSuccess();
  }

  Future<void> playWrong() async {
    if (!_isSoundEnabled) return;
    _playSfx('audio/wrong.wav');
    vibrateError();
  }

  Future<void> playCoin() async {
    if (!_isSoundEnabled) return;
    _playSfx('audio/coin.wav');
    vibrateLight();
  }

  Future<void> playPointsEarned() async {
    if (!_isSoundEnabled) return;
    _playSfx('audio/coin.wav');
    vibrateLight();
  }

  Future<void> playVictory() async {
    if (!_isSoundEnabled) return;
    _playSfx('audio/victory.wav');
    vibrateSuccess();
  }

  Future<void> _playSfx(String assetPath) async {
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.setVolume(_sfxVolume);
      await _sfxPlayer.play(AssetSource(assetPath));
    } catch (_) {}
  }

  // Haptic Feedbacks
  void vibrateLight() {
    if (_isVibrationEnabled) {
      HapticFeedback.lightImpact();
    }
  }

  void vibrateMedium() {
    if (_isVibrationEnabled) {
      HapticFeedback.mediumImpact();
    }
  }

  void vibrateSuccess() {
    if (_isVibrationEnabled) {
      HapticFeedback.mediumImpact();
    }
  }

  void vibrateError() {
    if (_isVibrationEnabled) {
      HapticFeedback.heavyImpact();
    }
  }

  // Toggles & Volume
  Future<void> setMusicEnabled(bool enabled) async {
    _isMusicEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('music_enabled', enabled);
    if (!enabled) {
      await _bgmPlayer.stop();
    } else {
      await playHomeBgm();
    }
  }

  Future<void> setSoundEnabled(bool enabled) async {
    _isSoundEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_enabled', enabled);
    await _sfxPlayer.setVolume(enabled ? _sfxVolume : 0.0);
  }

  Future<void> setVibrationEnabled(bool enabled) async {
    _isVibrationEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vibration_enabled', enabled);
  }

  Future<void> setMusicVolume(double volume) async {
    _musicVolume = volume;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('music_volume', volume);
    if (_isMusicEnabled) {
      await _bgmPlayer.setVolume(volume);
    }
  }

  Future<void> setSfxVolume(double volume) async {
    _sfxVolume = volume;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('sfx_volume', volume);
    if (_isSoundEnabled) {
      await _sfxPlayer.setVolume(volume);
    }
  }
}
