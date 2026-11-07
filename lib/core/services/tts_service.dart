import 'package:docora/core/services/logger_service.dart';
import 'package:docora/core/services/widget_sync.dart';
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
  int get currentWordStart => _currentWordStart;
  int get currentWordEnd => _currentWordEnd;

  String _currentTitle = 'Document';

  Future<void> _initTts() async {
    _flutterTts.setStartHandler(() {
      _state = TtsState.playing;
      WidgetSync.syncTtsState(
        fileName: _currentTitle,
        isPlaying: true,
        progress: 0.1,
      );
      notifyListeners();
    });

    _flutterTts.setCompletionHandler(() {
      _state = TtsState.stopped;
      WidgetSync.resetTtsState();
      notifyListeners();
    });

    _flutterTts.setCancelHandler(() {
      _state = TtsState.stopped;
      WidgetSync.resetTtsState();
      notifyListeners();
    });

    _flutterTts.setPauseHandler(() {
      _state = TtsState.paused;
      WidgetSync.syncTtsState(
        fileName: _currentTitle,
        isPlaying: false,
        progress: 0.5,
      );
      notifyListeners();
    });

    _flutterTts.setContinueHandler(() {
      _state = TtsState.playing;
      WidgetSync.syncTtsState(
        fileName: _currentTitle,
        isPlaying: true,
        progress: 0.5,
      );
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

  Future<void> speak(String text, {String? documentTitle}) async {
    if (text.isEmpty) return;
    if (documentTitle != null && documentTitle.isNotEmpty) {
      _currentTitle = documentTitle;
    }
    _currentText = text;
    try {
      final result = await _flutterTts.speak(text);
      if (result == 1) {
        _state = TtsState.playing;
        WidgetSync.syncTtsState(
          fileName: _currentTitle,
          isPlaying: true,
          progress: 0.1,
        );
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
      WidgetSync.syncTtsState(
        fileName: _currentTitle,
        isPlaying: false,
        progress: 0.5,
      );
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
        WidgetSync.syncTtsState(
          fileName: _currentTitle,
          isPlaying: true,
          progress: 0.5,
        );
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
      WidgetSync.resetTtsState();
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
