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

  static Future<void> downloadSong(Song song) async {
    await loadPaths();

    // Download audio file
    final audioPath = '${_downloadAudioPath!}${song.id}.mp3';
    final audioResponse = await http.get(Uri.parse(song.audioUrl));
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
    };

    await metadataFile.writeAsString(jsonEncode(metadata));

    // Notify that download data has changed
    DataEventManager.instance.notifyDownloadChanged(songId: song.id);
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
}
