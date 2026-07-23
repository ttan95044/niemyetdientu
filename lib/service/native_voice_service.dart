import 'package:flutter/services.dart';

class NativeVoiceService {
  static const MethodChannel _channel = MethodChannel("voice_input");

  static Future<String> start() async {
    final result = await _channel.invokeMethod<String>("startVoice");

    print("VOICE RESULT = $result");

    return result ?? "";
  }
}
