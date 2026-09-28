import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/audio_service.dart';
import 'services/user_service.dart';
import 'services/language_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  
  // Initialize user profile, audio systems, and language preferences
  await UserService.instance.init();
  await AudioService.instance.init();
  await LanguageService.instance.init();

  runApp(const RekGameApp());
}

class RekGameApp extends StatefulWidget {
  const RekGameApp({super.key});

  @override
  State<RekGameApp> createState() => _RekGameAppState();
}

class _RekGameAppState extends State<RekGameApp> with WidgetsBindingObserver {
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
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      AudioService.instance.handleAppPaused();
    } else if (state == AppLifecycleState.resumed) {
      AudioService.instance.handleAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Game Rek (ល្បែងរែក)',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: const Color(0xFF1E272C),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00897B),
          secondary: Color(0xFF7CB342),
          surface: Color(0xFF263238),
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
