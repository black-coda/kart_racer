import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';

import 'client.dart';
import 'game/rendering/models_view.dart';
import 'screens/greetings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeClient();
  // _logFps();
  runApp(const MyApp());
}

/// M0 step 8: prints average FPS once per second to the console.
void _logFps() {
  var frames = 0;
  var windowStart = DateTime.now();
  SchedulerBinding.instance.addTimingsCallback((_) {
    frames++;
    final now = DateTime.now();
    final elapsedMs = now.difference(windowStart).inMilliseconds;
    if (elapsedMs >= 1000) {
      final fps = frames * 1000 / elapsedMs;
      debugPrint('FPS: ${fps.toStringAsFixed(1)}');
      frames = 0;
      windowStart = now;
    }
  });
}

/// Builds a theme for the given [brightness].
ThemeData _buildTheme(Brightness brightness) {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: brightness,
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kart Racer M0',
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: ThemeMode.system,

      home: const ModelsView(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const GreetingsScreen(),
      // To test authentication in this example app, uncomment the line below
      // and comment out the line above. This wraps the GreetingsScreen with a
      // SignInScreen, which automatically shows a sign-in UI when the user is
      // not authenticated and displays the GreetingsScreen once they sign in.
      //
      // body: SignInScreen(
      //   child: GreetingsScreen(
      //     onSignOut: () async {
      //       await client.auth.signOutDevice();
      //     },
      //   ),
      // ),
    );
  }
}
