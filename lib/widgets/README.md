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

# Widgets

This directory contains reusable Flutter widgets for the Symphonia music app.

## Available Widgets

### 1. PlaylistItem Widget
A versatile widget for displaying playlist information with support for both horizontal and vertical layouts.

**Key Features:**
- Horizontal (list) and vertical (grid) layout options
- Play and option controls
- Delete functionality for playlist owners
- Image loading with fallbacks (network, asset, file)
- Indexed display option

**Usage:**
```dart
PlaylistItem(
  playlist: myPlaylist,
  isHorizontal: true,
  showTrailingControls: true,
  onTap: () {
    // Handle playlist tap
  },
)
```

### 2. AlbumItem Widget
A widget similar to PlaylistItem but specifically designed for displaying album information.

**Key Features:**
- Horizontal (list) and vertical (grid) layout options
- Play button control
- Album information display (artist, release year, track count)
- Image loading with fallbacks (network, asset, file)
- Indexed display option
- Clean, simplified interface focused on playback

**Usage:**
```dart
AlbumItem(
  album: myAlbum,
  isHorizontal: true,
  showTrailingControls: true,
  onTap: () {
    // Handle album tap (play album)
  },
  onAlbumUpdate: () {
    // Handle album updates
  },
)
```

**Vertical layout usage:**
```dart
AlbumItem(
  album: myAlbum,
  isHorizontal: false,
  showTrailingControls: true,
  onTap: () {
    // Play album
  },
)
```

### 3. SongItem Widget
A widget for displaying individual song information in playlists and album views.

### 4. UserAvatar Widget  
A widget for displaying user profile pictures with fallback handling.

## Widget Properties

### AlbumItem Properties
- `album` (required): Album object containing album data
- `showTrailingControls`: Show/hide play and menu buttons (default: true)
- `onTap`: Callback when album is tapped
- `isHorizontal`: Layout orientation (default: true)
- `index`: Display index number (optional)
- `showIndex`: Show/hide index number (default: false)
- `onAlbumUpdate`: Callback for album updates

### Layout Support
All major widgets support both horizontal (list-style) and vertical (card-style) layouts:
- **Horizontal**: Suitable for list views with detailed information
- **Vertical**: Suitable for grid views with compact card design

## Related Models and Services

### Album Model (`symphonia/lib/models/album.dart`)
Contains album data structure with properties:
- `id`, `title`, `artist`, `picture`
- `description`, `releaseDate`, `trackCount`
- `songIds` (list of song IDs in the album)

### Album Service (`symphonia/lib/services/album.dart`)
Provides API operations for albums:
- `getAlbum(id)`: Get album by ID
- `getAlbums()`: Get all albums
- `getAlbumSongs(albumId)`: Get songs in album
- `searchAlbums(query)`: Search albums
- `getFeaturedAlbums()`: Get featured albums
- `getLatestAlbums()`: Get latest albums

## Search Integration

The AlbumItem widget is now integrated into the search functionality:

### Search Screen Integration
```dart
// In search_screen.dart
Widget _buildAlbumResult(AlbumSearchResult result) {
  Album album = AlbumOperations.createSimpleAlbum(
    id: result.id,
    title: result.name,
    artist: result.artist,
    coverArt: result.image,
  );

  return AlbumItem(
    album: album,
    isHorizontal: true,
    showTrailingControls: true,
    onTap: () {
      // Handle album playback
    },
  );
}
```

This replaces the previous simple ListTile with a streamlined album widget that provides:
- Consistent styling with other album displays
- Functional play integration with audio handler
- Enhanced image loading with debug information
- Proper serverUrl prefix for album cover art
- Loading states and comprehensive error handling
- Focused user experience without menu clutter

## Implementation Notes

- All widgets handle loading states and error conditions gracefully
- Image loading supports network URLs, asset paths, and local files
- Consistent Material Design styling across all widgets
- Responsive design for different screen sizes
- Vietnamese localization support
- Seamless integration with search results and other app features 