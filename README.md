# Symphonia 🎵

Symphonia is a cross-platform music streaming application built with Flutter, offering a rich set of features for music lovers to discover, stream, and manage their favorite music.

## Features

🎵 **Music Streaming** - Stream high-quality music from the Symphonia backend  
👤 **User Authentication** - Secure login and signup functionality  
🔍 **Smart Search** - Search for songs, artists, and albums  
📚 **Personal Library** - Manage your music collection  
❤️ **Favorites & Playlists** - Create and organize your favorite tracks  
👥 **Social Features** - Connect with friends and send friend requests  
🌍 **Multilingual Support** - Available in English and Vietnamese  
📱 **Cross-Platform** - Works on Android, iOS, and desktop platforms  

<!-- ## Screenshots

*Add screenshots of your app here* -->

## Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- [Android Studio](https://developer.android.com/studio) or [VS Code](https://code.visualstudio.com/)
- [Git](https://git-scm.com/)
- An Android/iOS device or emulator

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/egnaro1007/symphonia.git
   cd symphonia
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure environment variables:**
   Create a `.env` file in the root directory:
   ```env
   SERVER_URL=your_backend_server_url
   ```
   
   **Important Notes:**
   - Replace `your_backend_server_url` with your actual backend URL
   - For Android emulator: use ip `10.0.2.2`
   - For iOS simulator: use ip `127.0.0.1`
   - For physical devices: use your computer's IP address

4. **Run the application:**
   ```bash
   flutter run
   ```

## Backend

This application requires the Symphonia backend server to function properly. 

**Backend Repository:** [symphonia-be](https://github.com/egnaro1007/symphonia-be.git)

Please follow the backend setup instructions in the backend repository before running this mobile application.

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── config/                   # Configuration files
├── models/                   # Data models
├── services/                 # API services and business logic
├── screens/                  # UI screens
├── widgets/                  # Reusable UI components
└── utils/                    # Utility functions
```

## Localization

Symphonia supports multiple languages:
- 🇺🇸 English
- 🇻🇳 Vietnamese

To add more languages, follow the [Flutter internationalization guide](https://flutter.dev/docs/development/accessibility-and-localization/internationalization).

## Troubleshooting

### Common Issues

**Connection Issues:**
- Ensure your backend server is running
- Check that `SERVER_URL` in `.env` is correct
- For android emulator, use `10.0.2.2` instead of `localhost`

**Build Issues:**
```bash
flutter clean
flutter pub get
flutter run
```

## Technologies Used

- **Framework:** Flutter
- **Language:** Dart

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
