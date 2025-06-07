import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:symphonia/models/playlist.dart';
import 'package:symphonia/services/playlist.dart';
import 'package:symphonia/services/playlist_notifier.dart';
import 'package:symphonia/widgets/playlist_item.dart';
import 'package:symphonia/constants/screen_index.dart';

class PlayListComponent extends StatefulWidget {
  final void Function(int, String) onTabSelected;

  const PlayListComponent({super.key, required this.onTabSelected});

  @override
  State<PlayListComponent> createState() => _PlayListComponentState();
}

class _PlayListComponentState extends State<PlayListComponent> {
  late List<PlayList> playlists = [];

  @override
  void initState() {
    super.initState();
    _loadPlaylists();

    // Listen for playlist updates
    PlaylistUpdateNotifier().addListener(_refreshPlaylists);
  }

  @override
  void dispose() {
    // Remove listener when widget is disposed
    PlaylistUpdateNotifier().removeListener(_refreshPlaylists);
    super.dispose();
  }

  Future<void> _loadPlaylists() async {
    final loadedPlaylists = await PlayListOperations.getLocalPlaylists();
    setState(() {
      playlists = loadedPlaylists;
    });
  }

  void _refreshPlaylists() {
    _loadPlaylists();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPlaylistHeader(),

          const Divider(),
          _buildCreatePlaylistTile(),

          const Divider(),
          ...playlists.map((playlist) {
            return PlaylistItem(
              playlist: playlist,
              isHorizontal: true,
              showTrailingControls: true,
              isDeleteMode: true,
              onTap: () {
                widget.onTabSelected(ScreenIndex.playlist.value, playlist.id);
              },
              onPlaylistDeleted: () {
                _loadPlaylists();
              },
            );
          }),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildPlaylistHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
      child: Text(
        "Playlist của bạn",
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildCreatePlaylistTile() {
    return ListTile(
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(Icons.add, color: Colors.grey),
      ),
      title: Text(
        AppLocalizations.of(context)!.createPlaylist,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      onTap: () {
        widget.onTabSelected(ScreenIndex.playlistCreation.value, "");
      },
    );
  }
}
