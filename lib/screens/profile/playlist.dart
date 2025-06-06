import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:symphonia/models/playlist.dart';
import 'package:symphonia/services/playlist.dart';

import '../playlist/playlist_creation_screen.dart';

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
  }

  Future<void> _loadPlaylists() async {
    final loadedPlaylists = await PlayListOperations.getLocalPlaylists();
    setState(() {
      playlists = loadedPlaylists;
    });
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
            return _buildPlaylistTile(playlist);
          }),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildPlaylistHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            AppLocalizations.of(context)!.playlist,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
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
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PlaylistCreationScreen()),
        );
      },
    );
  }

  Widget _buildPlaylistTile(PlayList playlist) {
    return ListTile(
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: Colors.grey[300],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child:
              playlist.picture.isNotEmpty
                  ? Image.network(
                    playlist.picture,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(child: Icon(Icons.music_note));
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      );
                    },
                  )
                  : const Center(child: Icon(Icons.music_note)),
        ),
      ),
      title: Text(
        playlist.title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(playlist.creator),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, color: Colors.grey),
        onPressed: () async {
          final bool? confirm = await showDialog<bool>(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text(AppLocalizations.of(context)!.deletePlaylist),
                content: Text(
                  "${AppLocalizations.of(context)!.confirmDeletePlaylist} ${playlist.title}?",
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(AppLocalizations.of(context)!.cancel),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(
                      AppLocalizations.of(context)!.delete,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              );
            },
          );

          if (confirm == true) {
            await PlayListOperations.deletePlaylist(playlist.id);
            _loadPlaylists();
          }
        },
      ),
      onTap: () {
        widget.onTabSelected(6, playlist.id);
      },
    );
  }
}
