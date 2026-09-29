import 'dart:io';

import 'package:record/record.dart';

class AudioRecordingService {
  final AudioRecorder _recorder = AudioRecorder();

  /// Checks whether microphone permission is available.
  Future<bool> hasPermission() async {
    return _recorder.hasPermission();
  }

  /// Starts recording audio.
  ///
  /// The recording is saved as an M4A file.
  Future<void> startRecording(String path) async {
    final hasPermission = await _recorder.hasPermission();

    if (!hasPermission) {
      throw Exception(
        'Microphone permission was not granted.',
      );
    }

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        sampleRate: 44100,
        numChannels: 1,
      ),
      path: path,
    );
  }

  /// Stops recording and returns the audio file.
  Future<File?> stopRecording() async {
    final path = await _recorder.stop();

    if (path == null || path.isEmpty) {
      return null;
    }

    return File(path);
  }

  /// Returns whether recording is currently active.
 Future<bool> get isRecording => _recorder.isRecording();

  /// Releases the recorder resources.
  Future<void> dispose() async {
    await _recorder.dispose();
  }
}