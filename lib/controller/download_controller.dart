import 'package:symphonia/models/song.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:symphonia/services/data_event_manager.dart';

class DownloadController {
  static String? _downloadMetadataFile;
  static String? _downloadAudioPath;
  static String? _downloadImagePath;

  static Future<void> loadPaths() async {
    if (_downloadMetadataFile != null &&
        _downloadAudioPath != null &&
        _downloadImagePath != null) {
      return;
    }
    final documentDirectory = await getApplicationDocumentsDirectory();
    _downloadMetadataFile = '${documentDirectory.path}/download/meta.json';
    _downloadAudioPath = '${documentDirectory.path}/download/audio/';
    _downloadImagePath = '${documentDirectory.path}/download/images/';

    await Directory(_downloadAudioPath!).create(recursive: true);
    await Directory(_downloadImagePath!).create(recursive: true);

    final metadataFile = File(_downloadMetadataFile!);
    if (!await metadataFile.exists()) {
      await metadataFile.create(recursive: true);
      await metadataFile.writeAsString('{}');
    }
  }

  // Check if song is already downloaded and get its quality
  static Future<String?> getDownloadedQuality(int songId) async {
    await loadPaths();

    final metadataFile = File(_downloadMetadataFile!);
    if (!await metadataFile.exists()) {
      return null;
    }

    final content = await metadataFile.readAsString();
    final Map<String, dynamic> metadata = jsonDecode(content);

    if (metadata.containsKey(songId.toString())) {
      return metadata[songId.toString()]['quality'] ??
          '320kbps'; // Default to 320kbps for legacy downloads
    }

    return null;
  }

  // Check if song is downloaded
  static Future<bool> isDownloaded(int songId) async {
    String? quality = await getDownloadedQuality(songId);
    return quality != null;
  }

  // Main download method with quality support
  static Future<void> downloadSong(
    Song song, [
    String quality = '320kbps',
  ]) async {
    await loadPaths();

    // Check if already downloaded with same quality
    String? existingQuality = await getDownloadedQuality(song.id);
    if (existingQuality == quality) {
      return; // Already downloaded with same quality, do nothing
    }

    // If already downloaded with different quality, delete old version
    if (existingQuality != null) {
      await deleteSong(song.id);
    }

    // Get audio URL for the requested quality
    String audioUrl = song.getAudioUrl(quality);
    if (audioUrl.isEmpty) {
      throw Exception('Audio URL not available for quality: $quality');
    }

    // Download audio file with quality suffix
    final audioExtension = _getAudioExtension(quality);
    final audioPath =
        '${_downloadAudioPath!}${song.id}_$quality$audioExtension';
    final audioResponse = await http.get(Uri.parse(audioUrl));
    if (audioResponse.statusCode == 200) {
      final audioFile = File(audioPath);
      await audioFile.writeAsBytes(audioResponse.bodyBytes);
    } else {
      throw Exception('Failed to download audio file');
    }

    // Download image file
    String imagePath = "";
    if (song.imagePath.isNotEmpty) {
      final imageResponse = await http.get(Uri.parse(song.imagePath));
      if (imageResponse.statusCode == 200) {
        imagePath = '${_downloadImagePath!}${song.id}.jpg';
        final imageFile = File(imagePath);
        await imageFile.writeAsBytes(imageResponse.bodyBytes);
      }
    }

    // Update metadata
    final metadataFile = File(_downloadMetadataFile!);
    Map<String, dynamic> metadata = {};

    if (await metadataFile.exists()) {
      final content = await metadataFile.readAsString();
      metadata = jsonDecode(content);
    }

    metadata[song.id.toString()] = {
      'title': song.title,
      'artist': song.artist,
      'audioPath': audioPath,
      'imagePath': imagePath,
      'quality': quality,
      'fileSize': song.getFileSize(quality),
      'downloadTime': DateTime.now().toIso8601String(),
    };

    await metadataFile.writeAsString(jsonEncode(metadata));

    // Notify that download data has changed
    DataEventManager.instance.notifyDownloadChanged(songId: song.id);
  }

  // Get appropriate file extension based on quality
  static String _getAudioExtension(String quality) {
    switch (quality) {
      case 'lossless':
        return '.flac';
      case '320kbps':
      case '128kbps':
      default:
        return '.mp3';
    }
  }

  static Future<void> deleteSong(int songId) async {
    await loadPaths();

    final metadataFile = File(_downloadMetadataFile!);
    if (!await metadataFile.exists()) {
      return;
    }

    final content = await metadataFile.readAsString();
    final Map<String, dynamic> metadata = jsonDecode(content);

    if (metadata.containsKey(songId.toString())) {
      final songData = metadata[songId.toString()];
      final audioPath = songData['audioPath'];
      final imagePath = songData['imagePath'];

      // Delete audio file
      final audioFile = File(audioPath);
      if (await audioFile.exists()) {
        await audioFile.delete();
      }

      // Delete image file
      if (imagePath != null && imagePath.isNotEmpty) {
        final imageFile = File(imagePath);
        if (await imageFile.exists()) {
          await imageFile.delete();
        }
      }

      // Remove from metadata
      metadata.remove(songId.toString());
      await metadataFile.writeAsString(jsonEncode(metadata));

      // Notify that download data has changed
      DataEventManager.instance.notifyDownloadChanged(songId: songId);
    }
  }

  static Future<void> deleteAll() async {
    String downloadPath =
        '${(await getApplicationDocumentsDirectory()).path}/download';
    await Directory(downloadPath).delete(recursive: true);

    await Directory(_downloadAudioPath!).create(recursive: true);
    await Directory(_downloadImagePath!).create(recursive: true);

    await loadPaths();

    // Notify that all downloads have been cleared
    DataEventManager.instance.notifyDownloadChanged();
  }

  static Future<List<Song>> getDownloadedSongs() async {
    await loadPaths();

    final metadataFile = File(_downloadMetadataFile!);
    if (!await metadataFile.exists()) {
      return [];
    }

    final content = await metadataFile.readAsString();
    final Map<String, dynamic> metadata = jsonDecode(content);

    return metadata.entries.map((entry) {
      final data = entry.value;
      return Song(
        id: int.parse(entry.key),
        title: data['title'],
        artist: data['artist'],
        imagePath: data['imagePath'] ?? '',
        audioUrl: data['audioPath'],
      );
    }).toList();
  }

  // Get download info for a song
  static Future<Map<String, dynamic>?> getDownloadInfo(int songId) async {
    await loadPaths();

    final metadataFile = File(_downloadMetadataFile!);
    if (!await metadataFile.exists()) {
      return null;
    }

    final content = await metadataFile.readAsString();
    final Map<String, dynamic> metadata = jsonDecode(content);

    if (metadata.containsKey(songId.toString())) {
      return Map<String, dynamic>.from(metadata[songId.toString()]);
    }

    return null;
  }

  // Format file size for display
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
