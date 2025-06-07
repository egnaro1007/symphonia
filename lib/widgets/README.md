# Reusable Widgets for Symphonia

## SongItem Widget

The `SongItem` widget provides a consistent UI for displaying songs throughout the application.

## PlaylistItem Widget

The `PlaylistItem` widget provides a consistent UI for displaying playlists throughout the application, similar to the `SongItem` widget.

### Features (PlaylistItem)

- Common playlist UI for displaying playlists in lists and grids
- Supports both horizontal and vertical layouts
- Includes play and more options controls
- Handles playlist playback and options menu
- Shows essential playlist information (title, creator)
- Supports delete mode for playlist management

### Features (SongItem)

- Common song UI for displaying songs in both search results and recommendations
- Supports both horizontal and vertical layouts
- Includes play and more options controls
- Handles song playback and options menu

### Usage (PlaylistItem)

```dart
// Horizontal layout (default)
PlaylistItem(
  playlist: playlist,
  showTrailingControls: true, // Set to false to hide controls
)

// Vertical layout
PlaylistItem(
  playlist: playlist,
  isHorizontal: false,
)

// With custom tap handler
PlaylistItem(
  playlist: playlist,
  onTap: () {
    // Custom tap handling - navigate to playlist detail screen
  },
)

// In delete mode
PlaylistItem(
  playlist: playlist,
  isDeleteMode: true,
  onPlaylistDeleted: () {
    // Handle playlist deletion
  },
)
```

### Usage (SongItem)

```dart
// Horizontal layout (default)
SongItem(
  song: song,
  showTrailingControls: true, // Set to false to hide controls
)

// Vertical layout
SongItem(
  song: song,
  isHorizontal: false,
)

// With custom tap handler
SongItem(
  song: song,
  onTap: () {
    // Custom tap handling
  },
)
```

### Integration Status

✅ **Successfully integrated in:**
- `user_screen.dart` - Replaced custom GridView with horizontal scrollable PlaylistItem (vertical layout)
- `profile/playlist.dart` - Replaced custom ListTile with PlaylistItem (horizontal layout with delete mode)

### Screenshots

(Add screenshots here)

## Examples

### Playlist Examples

#### Playlist List (Horizontal Layout)

```dart
ListView.builder(
  itemCount: playlists.length,
  itemBuilder: (context, index) {
    return PlaylistItem(
      playlist: playlists[index],
      onTap: () {
        // Navigate to playlist detail screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlaylistDetailScreen(
              playlist: playlists[index],
            ),
          ),
        );
      },
    );
  },
);
```

#### Featured Playlists Horizontal Scrollable (Vertical Layout)

```dart
SingleChildScrollView(
  scrollDirection: Axis.horizontal,
  physics: const BouncingScrollPhysics(),
  child: Row(
    children: playlists.map((playlist) {
      return PlaylistItem(
        playlist: playlist,
        isHorizontal: false,
        showTrailingControls: false,
        onTap: () {
          // Navigate to playlist detail
        },
      );
    }).toList(),
  ),
);
```

#### Playlist Management with Delete Mode (Horizontal Layout)

```dart
PlaylistItem(
  playlist: playlist,
  isHorizontal: true,
  showTrailingControls: true,
  isDeleteMode: true,
  onTap: () {
    // Navigate to playlist detail
  },
  onPlaylistDeleted: () {
    // Reload playlist list
    _loadPlaylists();
  },
);
```

### Song Examples

#### Home Screen (Horizontal Layout)

```dart
@override
Widget _buildSongItem(Song suggestedSong) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: SongItem(song: suggestedSong),
  );
}
```

#### Search Results (Horizontal Layout)

```dart
Widget _buildSongResult(SongSearchResult result) {
  Song song = Song(
    id: result.id,
    title: result.name,
    artist: result.artist,
    imagePath: result.image,
    audioUrl: result.audio_url,
  );
  
  return SongItem(song: song);
}
```

#### Featured Songs Grid (Vertical Layout)

```dart
GridView.builder(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    childAspectRatio: 0.8,
    crossAxisSpacing: 10,
    mainAxisSpacing: 10,
  ),
  itemCount: featuredSongs.length,
  itemBuilder: (context, index) {
    return SongItem(
      song: featuredSongs[index],
      isHorizontal: false,
    );
  },
)
``` 