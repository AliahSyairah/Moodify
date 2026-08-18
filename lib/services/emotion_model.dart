import 'package:tflite_flutter/tflite_flutter.dart';

class EmotionModel {
  Interpreter? _interpreter;

  Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset(
      'assets/models/emotion_fp16.tflite',
    );
  }

  Interpreter? get interpreter => _interpreter;
}