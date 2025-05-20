import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:symphonia/services/token_manager.dart';
import 'package:symphonia/services/user_info_manager.dart';
import 'screens/navigation_bar_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure platform bindings are ready

  await dotenv.load(fileName: ".env");
  // await TokenManager.login(
  //   dotenv.env['USERNAME'] ?? '',
  //   dotenv.env['PASSWORD'] ?? '',
  // );

  await UserInfoManager.fetchUserInfo();

  print("Access token: ${TokenManager.accessToken}");

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static _MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()!;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
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
      home: NavigationBarScreen(selectedBottom: 0),
    );
  }
}
