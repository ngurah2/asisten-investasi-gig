import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'dashboard_screen.dart';
import 'riwayat_screen.dart';
import 'profile_screen.dart'; // MENGIMPOR HALAMAN PROFIL BARU

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const DashboardScreen(),
    const RiwayatScreen(),
    const ProfileScreen(), // HALAMAN PROFIL DI URUTAN KE-4
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex], 
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))
          ]
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: Colors.white,
          selectedItemColor: Colors.teal[700],
          unselectedItemColor: Colors.grey[400],
          type: BottomNavigationBarType.fixed, // Pastikan fixed agar semua ikon muncul
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Beranda'),
            BottomNavigationBarItem(icon: Icon(Icons.pie_chart), label: 'Dashboard'),
            BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Riwayat'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'), // TOMBOL BARU
          ],
        ),
      ),
    );
  }
}