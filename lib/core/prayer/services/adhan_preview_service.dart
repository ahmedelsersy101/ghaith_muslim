import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'dart:async';

/// Service for previewing adhan sounds
/// Handles playing and stopping adhan sound previews from raw resources
class AdhanPreviewService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentlyPlaying;
  final _playingController = StreamController<String?>.broadcast();

  Stream<String?> get currentlyPlayingStream => _playingController.stream;

  /// Play an adhan sound preview from raw resources
  /// Returns true if playback started successfully
  Future<bool> playAdhanPreview(String fileName) async {
    try {
      // Stop any currently playing sound
      await stopPreview();

      // Get display name from file name
      final displayName = _getDisplayName(fileName);

      // Load audio from assets folder with MediaItem tag
      await _audioPlayer.setAudioSource(
        AudioSource.uri(
          Uri.parse('asset:///assets/audio/adhan/$fileName'),
          tag: MediaItem(
            id: fileName,
            title: displayName,
            artist: 'Adhan',
          ),
        ),
      );

      _currentlyPlaying = fileName;
      _playingController.add(_currentlyPlaying);

      // Play the audio
      await _audioPlayer.play();

      // Auto-stop when playback completes
      _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          _currentlyPlaying = null;
          _playingController.add(null);
        }
      });

      return true;
    } catch (e) {
      print('Error playing adhan preview: $e');
      _currentlyPlaying = null;
      _playingController.add(null);
      return false;
    }
  }

  /// Stop currently playing preview
  Future<void> stopPreview() async {
    try {
      await _audioPlayer.stop();
      _currentlyPlaying = null;
      _playingController.add(null);
    } catch (e) {
      print('Error stopping preview: $e');
    }
  }

  /// Dispose the audio player
  void dispose() {
    _audioPlayer.dispose();
    _playingController.close();
  }

  /// Get display name from file name
  String _getDisplayName(String fileName) {
    final nameMap = {
      'aqsa_athan.ogg': 'Al-Aqsa',
      'baset_athan.ogg': 'Abdul Basit',
      'qatami_athan.ogg': 'Al-Qatami',
      'salah_athan.ogg': 'Salah',
      'saqqaf_athan.ogg': 'Al-Saqqaf',
      'sarihi_athan.ogg': 'Al-Sarihi',
      'silence.ogg': 'Silent',
    };
    return nameMap[fileName] ?? 'Adhan';
  }

  /// Check if a specific sound is currently playing
  bool isPlaying(String fileName) {
    return _currentlyPlaying == fileName;
  }

  /// Check if any sound is currently playing
  bool get isAnyPlaying => _currentlyPlaying != null;

  /// Get currently playing sound file name
  String? get currentlyPlaying => _currentlyPlaying;
}
