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

class RekGameApp extends StatelessWidget {
  const RekGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cambodian Rek (ល្បែងរែក)',
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
