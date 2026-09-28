import 'package:docora/core/services/logger_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

enum TtsState { stopped, playing, paused }

final ttsServiceProvider = ChangeNotifierProvider<TtsService>((ref) => TtsService());

class TtsService extends ChangeNotifier {
  TtsService() {
    _initTts();
  }

  final FlutterTts _flutterTts = FlutterTts();
  TtsState _state = TtsState.stopped;
  double _rate = 0.5; // Default speech rate
  double _pitch = 1.0;
  String _currentText = '';
  int _currentWordStart = 0;
  int _currentWordEnd = 0;

  TtsState get state => _state;
  bool get isPlaying => _state == TtsState.playing;
  bool get isPaused => _state == TtsState.paused;
  double get rate => _rate;

  Future<void> _initTts() async {
    _flutterTts.setStartHandler(() {
      _state = TtsState.playing;
      notifyListeners();
    });

    _flutterTts.setCompletionHandler(() {
      _state = TtsState.stopped;
      notifyListeners();
    });

    _flutterTts.setCancelHandler(() {
      _state = TtsState.stopped;
      notifyListeners();
    });

    _flutterTts.setPauseHandler(() {
      _state = TtsState.paused;
      notifyListeners();
    });

    _flutterTts.setContinueHandler(() {
      _state = TtsState.playing;
      notifyListeners();
    });

    _flutterTts.setProgressHandler((text, start, end, word) {
      _currentWordStart = start;
      _currentWordEnd = end;
      notifyListeners();
    });

    await _flutterTts.setSpeechRate(_rate);
    await _flutterTts.setPitch(_pitch);
  }

  Future<void> speak(String text) async {
    if (text.isEmpty) return;
    _currentText = text;
    try {
      final result = await _flutterTts.speak(text);
      if (result == 1) {
        _state = TtsState.playing;
        notifyListeners();
      }
    } catch (e) {
      LoggerService.error('TTS speak error: $e');
    }
  }

  Future<void> pause() async {
    try {
      await _flutterTts.pause();
      _state = TtsState.paused;
      notifyListeners();
    } catch (e) {
      LoggerService.error('TTS pause error: $e');
    }
  }

  Future<void> resume() async {
    if (_state == TtsState.paused) {
      try {
        await _flutterTts.speak(_currentText);
        _state = TtsState.playing;
        notifyListeners();
      } catch (e) {
        LoggerService.error('TTS resume error: $e');
      }
    }
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      _state = TtsState.stopped;
      notifyListeners();
    } catch (e) {
      LoggerService.error('TTS stop error: $e');
    }
  }

  Future<void> setRate(double rate) async {
    _rate = rate.clamp(0.2, 1.0);
    await _flutterTts.setSpeechRate(_rate);
    notifyListeners();
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }
}
