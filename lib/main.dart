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

  // await UserInfoManager.fetchUserInfo();

  print("Access token: ${TokenManager.accessToken}");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Symphonia',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: NavigationBarScreen(selectedBottom: 0),
    );
  }
}
