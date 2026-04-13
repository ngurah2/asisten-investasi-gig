import 'package:flutter/material.dart';
// Memanggil layar ruang tamu yang baru dibuat
import 'screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aplikasi GIM',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      // Langsung arahkan aplikasi buka halaman HomeScreen
      home: const HomeScreen(),
    );
  }
}