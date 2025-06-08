import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:audio_service/audio_service.dart';
import 'package:symphonia/services/audio_handler.dart';
import 'package:symphonia/services/token_manager.dart';
import 'package:symphonia/services/user_info_manager.dart';
import 'screens/navigation_bar_screen.dart';
import 'screens/profile/login_screen.dart';
import 'package:symphonia/controller/download_controller.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:symphonia/services/preferences_service.dart';

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
      androidNotificationOngoing: false,
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
  Locale _currentLocale = const Locale('vi');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final languageCode = await PreferencesService.getLanguage();
      final theme = await PreferencesService.getTheme();

      setState(() {
        _currentLocale = Locale(languageCode);
        switch (theme) {
          case 'light':
            _themeMode = ThemeMode.light;
            break;
          case 'dark':
            _themeMode = ThemeMode.dark;
            break;
          default:
            _themeMode = ThemeMode.system;
        }
      });
    } catch (e) {
      print('Error loading preferences: $e');
      // Keep default values if preferences fail to load
    }
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
        break;
      case AppLifecycleState.resumed:
        // App được mở lại
        break;
      case AppLifecycleState.inactive:
        // App tạm thời inactive (như khi có cuộc gọi)
        break;
      case AppLifecycleState.hidden:
        // App bị ẩn
        break;
    }
  }

  Future<void> _stopAudioServiceWhenAppClosed() async {
    try {
      // Force stop và clear notification khi app terminate
      final handler = audioHandler as SymphoniaAudioHandler;
      await handler.forceStopAndClearNotification();
    } catch (e) {
      await audioHandler.stop();
    }
  }

  void setThemeMode(ThemeMode themeMode) {
    setState(() {
      _themeMode = themeMode;
    });
    // Save theme preference
    String themeString = 'system';
    switch (themeMode) {
      case ThemeMode.light:
        themeString = 'light';
        break;
      case ThemeMode.dark:
        themeString = 'dark';
        break;
      default:
        themeString = 'system';
    }
    PreferencesService.setTheme(themeString);
  }

  void setLocale(Locale locale) {
    setState(() {
      _currentLocale = locale;
    });
    // Save language preference
    PreferencesService.setLanguage(locale.languageCode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Symphonia',
      debugShowCheckedModeBanner: false,
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
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('vi')],
      locale: _currentLocale,
      home:
          widget.isAuthenticated
              ? NavigationBarScreen(selectedBottom: 0)
              : const LoginScreen(),
    );
  }
}
