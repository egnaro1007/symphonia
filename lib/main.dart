import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:symphonia/services/token_manager.dart';
import 'package:symphonia/services/user_info_manager.dart';
import 'screens/navigation_bar_screen.dart';
import 'screens/profile/login_screen.dart';
import 'package:symphonia/controller/download_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure platform bindings are ready

  await dotenv.load(fileName: ".env");

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

class MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

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
