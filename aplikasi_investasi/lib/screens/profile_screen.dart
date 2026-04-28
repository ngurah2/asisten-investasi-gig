import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _namaPengguna = "Memuat...";

  @override
  void initState() {
    super.initState();
    _muatDataProfil();
  }

  Future<void> _muatDataProfil() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _namaPengguna = prefs.getString('userName') ?? "Pengguna GIM";
    });
  }

  void _prosesLogout() async {
    // Konfirmasi sebelum keluar
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Konfirmasi Keluar', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Apakah kamu yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text('Batal', style: TextStyle(color: Colors.grey))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.clear(); // Hapus sesi login
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
              }
            },
            child: const Text('Keluar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.teal[700],
        elevation: 0,
        title: const Text('Profil Saya', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // KARTU HEADER PROFIL
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 30, top: 20),
              decoration: BoxDecoration(
                color: Colors.teal[700],
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 60, color: Colors.teal),
                  ),
                  const SizedBox(height: 16),
                  Text(_namaPengguna, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: Colors.orange[400], borderRadius: BorderRadius.circular(12)),
                    child: const Text('Investor Aktif', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            ),
            
            const SizedBox(height: 20),

            // MENU PROFIL
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Fitur Mendatang (V3)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 10),
                  _buildMenuItem(icon: Icons.track_changes, title: 'Target Finansial (Goals)', subtitle: 'Lacak tabungan impianmu', isComingSoon: true),
                  _buildMenuItem(icon: Icons.picture_as_pdf, title: 'Ekspor Laporan PDF', subtitle: 'Unduh rekap bulanan', isComingSoon: true),
                  
                  const SizedBox(height: 20),
                  const Text('Pengaturan', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 10),
                  _buildMenuItem(icon: Icons.notifications_active, title: 'Notifikasi', subtitle: 'Atur pengingat harian'),
                  _buildMenuItem(icon: Icons.security, title: 'Keamanan Akun', subtitle: 'Ubah password & privasi'),
                  _buildMenuItem(icon: Icons.info_outline, title: 'Tentang Aplikasi', subtitle: 'GIM Versi 2.0 (Stable)'),
                  
                  const SizedBox(height: 30),
                  
                  // TOMBOL LOGOUT
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _prosesLogout,
                      icon: const Icon(Icons.logout, color: Colors.white),
                      label: const Text('KELUAR APLIKASI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[400],
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({required IconData icon, required String title, required String subtitle, bool isComingSoon = false}) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey[200]!)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.teal.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: Colors.teal[700]),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: isComingSoon 
            ? const Icon(Icons.lock_clock, color: Colors.orange) 
            : const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () {
          if (isComingSoon) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fitur ini akan hadir di GIM V3!')));
          }
        },
      ),
    );
  }
}