import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart'; // TAMBAHAN
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  XFile? _imageFile; 
  final ImagePicker _picker = ImagePicker();
  
  final TextEditingController _deskripsiController = TextEditingController(); 
  final TextEditingController _kebutuhanController = TextEditingController(); 
  final TextEditingController _lamaWaktuController = TextEditingController(); 
  
  String _tipePendapatan = 'Harian'; 
  final List<String> _opsiTipe = ['Harian', 'Mingguan', 'Bulanan', 'Proyek / Freelance'];

  bool _isLoading = false;
  Map<String, dynamic>? _hasilAnalisis;
  List<Map<String, dynamic>> _daftarManual = [];

  int get _totalManual => _daftarManual.fold(0, (sum, item) => sum + (item['nominal'] as int));

  String _formatRupiah(int angka) {
    return angka.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), 
      (Match m) => '${m[1]}.'
    );
  }

  void _tambahPengeluaran() {
    String deskripsi = _deskripsiController.text;
    String rawNominal = _kebutuhanController.text.replaceAll('.', '');
    int nominal = int.tryParse(rawNominal) ?? 0;

    if (deskripsi.isEmpty || nominal <= 0) return;

    setState(() {
      _daftarManual.add({"deskripsi": deskripsi, "nominal": nominal});
      _deskripsiController.clear();
      _kebutuhanController.clear();
    });
  }

  void _hapusPengeluaran(int index) {
    setState(() => _daftarManual.removeAt(index));
  }

  void _editPengeluaran(int index) {
    TextEditingController editDeskripsi = TextEditingController(text: _daftarManual[index]['deskripsi']);
    TextEditingController editNominal = TextEditingController(text: _daftarManual[index]['nominal'].toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Edit Pengeluaran', style: TextStyle(color: Colors.teal[700], fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: editDeskripsi, decoration: InputDecoration(labelText: 'Deskripsi', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 16),
              TextField(controller: editNominal, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Nominal (Rp)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal[600], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              onPressed: () {
                setState(() {
                  _daftarManual[index]['deskripsi'] = editDeskripsi.text;
                  _daftarManual[index]['nominal'] = int.tryParse(editNominal.text.replaceAll('.', '')) ?? 0;
                });
                Navigator.pop(context);
              },
              child: const Text('Simpan', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pilihGambar(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source, imageQuality: 80);
    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile; 
        _hasilAnalisis = null; 
      });
    }
  }

  Future<void> _analisisStruk() async {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Silakan pilih gambar struk terlebih dahulu!')));
      return;
    }

    String lamaWaktuStr = "";
    if (_tipePendapatan == 'Proyek / Freelance') {
      lamaWaktuStr = _lamaWaktuController.text.trim().toLowerCase();
      if (lamaWaktuStr.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lama waktu proyek wajib diisi!'), backgroundColor: Colors.red));
        return;
      }
      if (!lamaWaktuStr.contains('hari') && !lamaWaktuStr.contains('minggu') && !lamaWaktuStr.contains('bulan') && !lamaWaktuStr.contains('tahun')) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kurang lengkap! Tambahkan satuan waktu (contoh: 42 hari).'), backgroundColor: Colors.red));
        return;
      }
    }

    setState(() { _isLoading = true; _hasilAnalisis = null; });

    try {
      // TAMBAHAN: Tarik userID dari memori sebelum memanggil API
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int userId = prefs.getInt('userId') ?? 0;

      if (userId == 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sesi tidak valid, silakan login ulang.'), backgroundColor: Colors.red));
        setState(() { _isLoading = false; });
        return;
      }

      List<int> imageBytes = await _imageFile!.readAsBytes();
      String fileName = _imageFile!.name; 
      String rincianTeks = "Tipe: $_tipePendapatan\n" + 
          (_daftarManual.isEmpty ? "Tanpa rincian pengeluaran." : _daftarManual.map((item) => "${item['deskripsi']}: Rp ${_formatRupiah(item['nominal'])}").join("\n"));
      
      // TAMBAHAN: Masukkan userId ke dalam fungsi API
      var responseData = await ApiService.kirimStrukKeAI(userId, imageBytes, fileName, _totalManual, rincianTeks, _tipePendapatan, lamaWaktuStr);
      setState(() { _hasilAnalisis = responseData; });
    } catch (e) {
      setState(() { _hasilAnalisis = {"status": "gagal", "pesan": "Error: $e"}; });
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  Widget _tampilkanGambar() {
    if (_imageFile == null) return const Center(child: Icon(Icons.receipt_long, size: 64, color: Colors.grey));
    return ClipRRect(borderRadius: BorderRadius.circular(14), child: kIsWeb ? Image.network(_imageFile!.path, fit: BoxFit.contain) : Image.file(File(_imageFile!.path), fit: BoxFit.contain));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, 
        elevation: 0,
        title: Text('GIM - Gig Investasi', style: TextStyle(color: Colors.teal[700], fontWeight: FontWeight.bold, fontSize: 22)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Manajemen Tipe Pendapatan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _tipePendapatan,
              decoration: InputDecoration(
                filled: true, fillColor: Colors.teal.withOpacity(0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                prefixIcon: const Icon(Icons.account_balance_wallet, color: Colors.teal),
              ),
              items: _opsiTipe.map((String value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(),
              onChanged: (newValue) => setState(() => _tipePendapatan = newValue!),
            ),
            
            if (_tipePendapatan == 'Proyek / Freelance') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _lamaWaktuController,
                decoration: InputDecoration(
                  hintText: 'Misal: 42 hari, atau 3 bulan',
                  prefixIcon: const Icon(Icons.timer, color: Colors.orange),
                  filled: true, fillColor: Colors.orange.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
                ),
              ),
            ],

            const SizedBox(height: 24),
            const Text('Catat Pengeluaran Manual', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(flex: 3, child: TextField(controller: _deskripsiController, decoration: InputDecoration(hintText: 'Barang', filled: true, fillColor: Colors.grey[50], border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)))),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: TextField(controller: _kebutuhanController, keyboardType: TextInputType.number, decoration: InputDecoration(hintText: 'Rp', filled: true, fillColor: Colors.grey[50], border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)))),
                const SizedBox(width: 12),
                InkWell(onTap: _tambahPengeluaran, child: CircleAvatar(backgroundColor: Colors.teal[600], radius: 26, child: const Icon(Icons.add, color: Colors.white))),
              ],
            ),

            if (_daftarManual.isNotEmpty) ...[
              const SizedBox(height: 24),
              ...List.generate(_daftarManual.length, (index) {
                var item = _daftarManual[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(item['deskripsi'], style: const TextStyle(fontSize: 15)),
                        Text('Rp ${_formatRupiah(item['nominal'])}', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                      ]),
                      Row(children: [
                        IconButton(icon: const Icon(Icons.edit, color: Colors.blue, size: 20), onPressed: () => _editPengeluaran(index)),
                        IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 20), onPressed: () => _hapusPengeluaran(index)),
                      ]),
                    ],
                  ),
                );
              }),
              Divider(color: Colors.grey[300], thickness: 1),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Total Pengeluaran:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Rp ${_formatRupiah(_totalManual)}', style: TextStyle(color: Colors.orange[800], fontWeight: FontWeight.bold, fontSize: 16)),
              ]),
            ],

            const SizedBox(height: 32),
            const Text('Scan Struk Pendapatan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Container(
              height: 220,
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.teal.withOpacity(0.4), width: 1.5), borderRadius: BorderRadius.circular(16)),
              child: _tampilkanGambar(),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: ElevatedButton.icon(onPressed: () => _pilihGambar(ImageSource.camera), icon: const Icon(Icons.camera_alt), label: const Text('Kamera'), style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.withOpacity(0.1), foregroundColor: Colors.teal[700], elevation: 0))),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton.icon(onPressed: () => _pilihGambar(ImageSource.gallery), icon: const Icon(Icons.photo_library), label: const Text('Galeri'), style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.withOpacity(0.1), foregroundColor: Colors.teal[700], elevation: 0))),
            ]),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _analisisStruk,
              icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.auto_awesome, color: Colors.white),
              label: Text(_isLoading ? 'Menganalisis...' : 'Minta Saran AI', style: const TextStyle(color: Colors.white, fontSize: 16)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal[600], padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),

            if (_hasilAnalisis != null) ...[
              const SizedBox(height: 28),
              _hasilKartuAnalisis(),
            ]
          ],
        ),
      ),
    );
  }

  Widget _hasilKartuAnalisis() {
    int surplus = _hasilAnalisis!['surplus'];
    Color themeColor = surplus > 0 ? Colors.teal : (surplus == 0 ? Colors.grey : Colors.red);
    String judul = surplus > 0 ? 'Selamat kamu luar biasaa' : (surplus == 0 ? 'Lebih semangat kerjanya' : 'Wajib nabung!');
    IconData iconStatus = surplus > 0 ? Icons.sentiment_very_satisfied : (surplus == 0 ? Icons.sentiment_neutral : Icons.warning_amber_rounded);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: themeColor, width: 2), borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(iconStatus, color: themeColor), const SizedBox(width: 8), Text(judul, style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: 18))]),
        const Divider(height: 32),
        _barisHasil('Total Pendapatan', 'Rp ${_formatRupiah(_hasilAnalisis!['pendapatan_terdeteksi'])}'),
        _barisHasil('Total Pengeluaran', 'Rp ${_formatRupiah(_hasilAnalisis!['kebutuhan_harian'])}'),
        const Divider(height: 32),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Surplus/Sisa Akhir', style: TextStyle(fontWeight: FontWeight.bold)), 
          Text('Rp ${_formatRupiah(surplus)}', style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: 18))
        ]),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: themeColor.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [Icon(Icons.smart_toy, color: themeColor, size: 20), const SizedBox(width: 8), Text('Saran Manajer AI', style: TextStyle(fontWeight: FontWeight.bold, color: themeColor))]),
              const SizedBox(height: 8),
              Text(_hasilAnalisis!['rekomendasi_investasi'] ?? '', style: const TextStyle(height: 1.5)),
            ],
          ),
        )
      ]),
    );
  }

  Widget _barisHasil(String l, String n) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(l, style: const TextStyle(color: Colors.grey)), Text(n, style: const TextStyle(fontWeight: FontWeight.bold))]));
  }
}