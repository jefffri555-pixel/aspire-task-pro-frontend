import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:http/http.dart' as http;

class VoiceRecordingResult {
  final Uint8List bytes;
  final String fileName;
  final String mimeType;
  final int durationSeconds;

  VoiceRecordingResult({
    required this.bytes,
    required this.fileName,
    required this.mimeType,
    required this.durationSeconds,
  });
}

class VoiceRecordingService {
  final AudioRecorder _audioRecorder = AudioRecorder();
  DateTime? _startTime;

  Future<bool> hasPermission() async {
    return await _audioRecorder.hasPermission();
  }

  Future<void> startRecording() async {
    if (await hasPermission()) {
      _startTime = DateTime.now();
      // Use m4a for mobile/desktop, webm for web
      const encoder = kIsWeb ? AudioEncoder.opus : AudioEncoder.aacLc;

      await _audioRecorder.start(
        RecordConfig(
          encoder: encoder,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: kIsWeb ? '' : _generateTempPath(),
      );
    } else {
      throw Exception(
          'Microphone permission is required to record voice messages.');
    }
  }

  String _generateTempPath() {
    final dir = Directory.systemTemp;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${dir.path}/voice_message_$timestamp.m4a';
  }

  Future<VoiceRecordingResult?> stopRecording() async {
    if (!await _audioRecorder.isRecording()) {
      return null;
    }

    final path = await _audioRecorder.stop();
    if (path == null) return null;

    final durationSeconds = _startTime != null
        ? DateTime.now().difference(_startTime!).inSeconds
        : 0;

    Uint8List audioBytes;
    String fileName;
    String mimeType;

    if (kIsWeb) {
      // path is a blob URL on web
      final response = await http.get(Uri.parse(path));
      audioBytes = response.bodyBytes;
      fileName = 'voice-message-${DateTime.now().millisecondsSinceEpoch}.webm';
      mimeType = 'audio/webm';
    } else {
      final file = File(path);
      audioBytes = await file.readAsBytes();
      fileName = 'voice-message-${DateTime.now().millisecondsSinceEpoch}.m4a';
      mimeType = 'audio/m4a';
      // Clean up the temp file after reading
      try {
        await file.delete();
      } catch (_) {}
    }

    return VoiceRecordingResult(
      bytes: audioBytes,
      fileName: fileName,
      mimeType: mimeType,
      durationSeconds: durationSeconds,
    );
  }

  Future<void> cancelRecording() async {
    if (await _audioRecorder.isRecording()) {
      final path = await _audioRecorder.stop();
      if (path != null && !kIsWeb) {
        try {
          await File(path).delete();
        } catch (_) {}
      }
    }
    _startTime = null;
  }

  Future<void> dispose() async {
    await _audioRecorder.dispose();
  }
}
