# Reusable Widgets for Symphonia

## SongItem Widget

The `SongItem` widget provides a consistent UI for displaying songs throughout the application.

### Features

- Common song UI for displaying songs in both search results and recommendations
- Supports both horizontal and vertical layouts
- Includes play and more options controls
- Handles song playback and options menu

### Usage

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

### Screenshots

(Add screenshots here)

## Examples

### Home Screen (Horizontal Layout)

```dart
@override
Widget _buildSongItem(Song suggestedSong) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: SongItem(song: suggestedSong),
  );
}
```

### Search Results (Horizontal Layout)

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

### Featured Songs Grid (Vertical Layout)

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