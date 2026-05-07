import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/main_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  // Pastikan plugin Flutter terinisialisasi sebelum menjalankan app
  WidgetsFlutterBinding.ensureInitialized();
  
  // Ambil status login dari memori internal HP
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GIM - Gig Investasi Management',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
        fontFamily: 'sans-serif',
      ),
      // Jika sudah login, langsung ke MainScreen (Beranda dengan Bottom Nav)
      // Jika belum, arahkan ke LoginScreen
      initialRoute: '/',
      routes: {
        '/': (context) => isLoggedIn ? const MainScreen() : const LoginScreen(),
      },
    );
  }
}