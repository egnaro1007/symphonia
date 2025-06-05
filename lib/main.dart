import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:audio_service/audio_service.dart';
import 'package:symphonia/services/audio_handler.dart';
import 'package:symphonia/services/token_manager.dart';
import 'package:symphonia/services/user_info_manager.dart';
import 'screens/navigation_bar_screen.dart';
import 'screens/profile/login_screen.dart';
import 'package:symphonia/controller/download_controller.dart';

// Global audio handler instance
late AudioHandler audioHandler;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure platform bindings are ready

  await dotenv.load(fileName: ".env");

  // Initialize audio service
  audioHandler = await AudioService.init(
    builder: () => SymphoniaAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.symphonia.audio',
      androidNotificationChannelName: 'Music playback',
      androidNotificationChannelDescription: 'Symphonia music player controls',
      androidNotificationOngoing:
          false, // Thay đổi thành false để có thể dismiss
      androidShowNotificationBadge: true,
      androidNotificationClickStartsActivity: true,
      androidResumeOnClick: true,
      androidStopForegroundOnPause: true, // Stop foreground khi pause
      preloadArtwork: true,
      artDownscaleWidth: 150,
      artDownscaleHeight: 150,
      fastForwardInterval: Duration(seconds: 10),
      rewindInterval: Duration(seconds: 10),
    ),
  );

  await DownloadController.loadPaths();
  bool isAuthenticated = await TokenManager.verifyToken();

  // Load user info from file first, then fetch from server if needed
  await UserInfoManager.loadUserInfo();
  if (isAuthenticated) {
    await UserInfoManager.fetchUserInfo();
  }

  print("Access token: ${TokenManager.accessToken}");
  print("Is authenticated: $isAuthenticated");

  runApp(MyApp(isAuthenticated: isAuthenticated));
}

class MyApp extends StatefulWidget {
  final bool isAuthenticated;

  const MyApp({super.key, required this.isAuthenticated});

  static MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<MyAppState>()!;

  @override
  State<MyApp> createState() => MyAppState();
}

class MyAppState extends State<MyApp> with WidgetsBindingObserver {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Xử lý các trạng thái app lifecycle
    switch (state) {
      case AppLifecycleState.detached:
        // App thực sự bị terminate
        _stopAudioServiceWhenAppClosed();
        break;
      case AppLifecycleState.paused:
        // App chuyển sang background - không làm gì để nhạc tiếp tục chạy
        print("App paused - music continues in background");
        break;
      case AppLifecycleState.resumed:
        // App được mở lại
        print("App resumed");
        break;
      case AppLifecycleState.inactive:
        // App tạm thời inactive (như khi có cuộc gọi)
        print("App inactive");
        break;
      case AppLifecycleState.hidden:
        // App bị ẩn
        print("App hidden");
        break;
    }
  }

  Future<void> _stopAudioServiceWhenAppClosed() async {
    try {
      // Force stop và clear notification khi app terminate
      final handler = audioHandler as SymphoniaAudioHandler;
      await handler.forceStopAndClearNotification();
      print("Audio service force stopped - app terminated");
    } catch (e) {
      print("Error stopping audio service: $e");
      // Fallback
      try {
        await audioHandler.stop();
      } catch (e2) {
        print("Fallback stop error: $e2");
      }
    }
  }

  void setThemeMode(ThemeMode themeMode) {
    setState(() {
      _themeMode = themeMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Symphonia',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
          surface: Colors.grey.shade900,
        ),
      ),
      themeMode: _themeMode,
      home:
          widget.isAuthenticated
              ? NavigationBarScreen(selectedBottom: 0)
              : const LoginScreen(),
    );
  }
}
