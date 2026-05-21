import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart'; // Untuk format tanggal kalender
import 'login_screen.dart'; 
import 'goals_screen.dart';
import '../services/api_service.dart'; 
import '../services/pdf_service.dart'; 

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
              await prefs.clear();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Keluar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _tampilkanDialogFilterPdf() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int userId = prefs.getInt('userId') ?? 0;

    if (userId == 0) return;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mengambil data riwayat dari database...'), duration: Duration(seconds: 1)),
    );

    try {
      var riwayatData = await ApiService.ambilRiwayat(userId);

      if (riwayatData.isEmpty) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Data Kosong'),
              content: const Text('Belum ada riwayat transaksi yang tersimpan di akun Anda.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))
              ],
            ),
          );
        }
        return;
      }

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(Icons.filter_list, color: Colors.teal[700]),
                const SizedBox(width: 10),
                const Text('Periode Laporan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.today, color: Colors.teal),
                    title: const Text('Hari Ini'),
                    onTap: () {
                      Navigator.pop(context);
                      _prosesFilterDanCetak("Hari Ini", riwayatData, "hari");
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.date_range, color: Colors.teal),
                    title: const Text('Minggu Ini'),
                    onTap: () {
                      Navigator.pop(context);
                      _prosesFilterDanCetak("Minggu Ini", riwayatData, "minggu");
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.calendar_month, color: Colors.teal),
                    title: const Text('Bulan Ini'),
                    onTap: () {
                      Navigator.pop(context);
                      _prosesFilterDanCetak("Bulan Ini", riwayatData, "bulan");
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.event_note, color: Colors.teal),
                    title: const Text('Tahun Ini'),
                    onTap: () {
                      Navigator.pop(context);
                      _prosesFilterDanCetak("Tahun Ini", riwayatData, "tahun");
                    },
                  ),
                  const Divider(),
                  // FITUR BARU: PILIH TANGGAL MANUAL (KALENDER)
                  ListTile(
                    leading: const Icon(Icons.edit_calendar, color: Colors.blue),
                    title: const Text('Pilih Kalender Manual', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                    onTap: () async {
                      Navigator.pop(context);
                      DateTimeRange? pickedRange = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020), // Batas bawah tahun
                        lastDate: DateTime(2030),  // Batas atas tahun
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: Colors.teal, 
                                onPrimary: Colors.white, 
                                onSurface: Colors.black, 
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      
                      if (pickedRange != null) {
                        String tglMulai = DateFormat('dd MMM yyyy').format(pickedRange.start);
                        String tglAkhir = DateFormat('dd MMM yyyy').format(pickedRange.end);
                        _prosesFilterDanCetak(
                          "Kustom ($tglMulai - $tglAkhir)", 
                          riwayatData, 
                          "kustom", 
                          range: pickedRange
                        );
                      }
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: Icon(Icons.all_inclusive, color: Colors.orange[700]),
                    title: const Text('Semua Riwayat'),
                    onTap: () {
                      Navigator.pop(context);
                      _prosesFilterDanCetak("Semua Periode", riwayatData, "semua");
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memproses data: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _prosesFilterDanCetak(String namaPeriode, List<dynamic> riwayatRaw, String tipeFilter, {DateTimeRange? range}) async {
    DateTime sekarang = DateTime.now();
    List<Map<String, dynamic>> hasilFilter = [];

    for (var item in riwayatRaw) {
      DateTime tglTransaksi = sekarang;
      if (item['tanggal'] != null) {
        try {
          tglTransaksi = DateTime.parse(item['tanggal'].toString());
        } catch (_) {
          tglTransaksi = sekarang;
        }
      }

      bool lolosFilter = false;

      if (tipeFilter == "semua") {
        lolosFilter = true;
      } else if (tipeFilter == "kustom" && range != null) {
        // Logika kalender kustom: pastikan tanggal berada di dalam range yang dipilih
        if (tglTransaksi.isAfter(range.start.subtract(const Duration(days: 1))) && 
            tglTransaksi.isBefore(range.end.add(const Duration(days: 1)))) {
          lolosFilter = true;
        }
      } else if (tipeFilter == "hari") {
        if (tglTransaksi.year == sekarang.year &&
            tglTransaksi.month == sekarang.month &&
            tglTransaksi.day == sekarang.day) {
          lolosFilter = true;
        }
      } else if (tipeFilter == "minggu") {
        final selisihHari = sekarang.difference(tglTransaksi).inDays;
        if (selisihHari >= 0 && selisihHari <= 7) {
          lolosFilter = true;
        }
      } else if (tipeFilter == "bulan") {
        if (tglTransaksi.year == sekarang.year && tglTransaksi.month == sekarang.month) {
          lolosFilter = true;
        }
      } else if (tipeFilter == "tahun") {
        if (tglTransaksi.year == sekarang.year) {
          lolosFilter = true;
        }
      }

      if (lolosFilter) {
        int nominalSurplus = 0;
        if (item['surplus'] != null) {
          nominalSurplus = int.tryParse(item['surplus'].toString()) ?? 0;
        }
        
        // MAPPING FIELD LENGKAP: Mengambil juga field tanggal dan rekomendasi
        hasilFilter.add({
          'tanggal': item['tanggal']?.toString() ?? '-',
          'deskripsi': item['rincian']?.toString() ?? 'Transaksi',
          'nominal': nominalSurplus,
          'rekomendasi': item['rekomendasi']?.toString() ?? 'Tidak ada rekomendasi.'
        });
      }
    }

    if (hasilFilter.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tidak ada data transaksi pada periode yang dipilih.'), backgroundColor: Colors.orange),
        );
      }
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Menyusun Desain Laporan PDF...')),
      );
    }
    
    // Kirim data ke Service PDF
    await PdfService.cetakLaporan(namaPeriode, hasilFilter, _namaPengguna);
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

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Manajemen Target & Laporan', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 10),
                  
                  _buildMenuItem(
                    icon: Icons.track_changes, 
                    title: 'Target Finansial (Goals)', 
                    subtitle: 'Lacak tabungan impianmu', 
                    isComingSoon: false,
                    onTap: () {
                      Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (context) => const GoalsScreen())
                      );
                    }
                  ),
                  
                  _buildMenuItem(
                    icon: Icons.picture_as_pdf, 
                    title: 'Ekspor Laporan PDF', 
                    subtitle: 'Unduh rekap riwayat keuangan & AI', 
                    isComingSoon: false,
                    onTap: _tampilkanDialogFilterPdf, 
                  ),
                  
                  const SizedBox(height: 20),
                  const Text('Pengaturan', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 10),
                  _buildMenuItem(icon: Icons.notifications_active, title: 'Notifikasi', subtitle: 'Atur pengingat harian', isComingSoon: true),
                  _buildMenuItem(icon: Icons.security, title: 'Keamanan Akun', subtitle: 'Ubah password & privasi', isComingSoon: true),
                  _buildMenuItem(icon: Icons.info_outline, title: 'Tentang Aplikasi', subtitle: 'GIM Versi 2.0 (Stable)', isComingSoon: true),
                  
                  const SizedBox(height: 30),
                  
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

  Widget _buildMenuItem({
    required IconData icon, 
    required String title, 
    required String subtitle, 
    bool isComingSoon = false,
    VoidCallback? onTap
  }) {
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
            : const Icon(Icons.chevron_right, color: Colors.teal),
        onTap: onTap ?? () {
          if (isComingSoon) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fitur ini akan hadir di GIM V3!')));
          }
        },
      ),
    );
  }
}