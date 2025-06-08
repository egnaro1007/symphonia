import 'package:flutter/material.dart';
import 'package:symphonia/screens/player/online_player_screen.dart';
import 'package:symphonia/screens/player/downloaded_player_screen.dart';
import '/controller/player_controller.dart';
import '/controller/download_controller.dart';

class AdaptivePlayerScreen extends StatefulWidget {
  final VoidCallback closePlayer;
  final Function(int, String)? onTabSelected;

  const AdaptivePlayerScreen({
    super.key,
    required this.closePlayer,
    this.onTabSelected,
  });

  @override
  State<AdaptivePlayerScreen> createState() => _AdaptivePlayerScreenState();
}

class _AdaptivePlayerScreenState extends State<AdaptivePlayerScreen> {
  final PlayerController _playerController = PlayerController.getInstance();
  bool _isDownloaded = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkDownloadStatus();

    // Listen to song changes to update download status
    _playerController.onSongChange.listen((song) {
      _checkDownloadStatus();
    });
  }

  Future<void> _checkDownloadStatus() async {
    try {
      bool downloaded = await DownloadController.isDownloaded(
        _playerController.playingSong.id,
      );
      if (mounted) {
        setState(() {
          _isDownloaded = downloaded;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error checking download status: $e');
      if (mounted) {
        setState(() {
          _isDownloaded = false;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          color: Theme.of(context).colorScheme.surface,
          child: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
      );
    }

    // Choose the appropriate player based on download status
    if (_isDownloaded) {
      return DownloadedPlayerScreen(
        closePlayer: widget.closePlayer,
        onTabSelected: widget.onTabSelected,
      );
    } else {
      return OnlinePlayerScreen(
        closePlayer: widget.closePlayer,
        onTabSelected: widget.onTabSelected,
      );
    }
  }
}
