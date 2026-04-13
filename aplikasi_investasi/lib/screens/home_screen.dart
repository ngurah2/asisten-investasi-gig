import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
// Ini yang paling penting: Memanggil kurir yang baru kita buat!
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // === VARIABEL STATE ===
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _kebutuhanController = TextEditingController();

  bool _isLoading = false;
  Map<String, dynamic>? _hasilAnalisis;

  // === FUNGSI AMBIL GAMBAR ===
  Future<void> _pilihGambar() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _hasilAnalisis = null; // Reset hasil lama
      });
    }
  }

  // === FUNGSI ANALISIS (MEMANGGIL KURIR API) ===
  Future<void> _analisisStruk() async {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih gambar struk dulu, Mas!')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _hasilAnalisis = null;
    });

    try {
      // Mengubah gambar menjadi urutan byte
      List<int> imageBytes = await _imageFile!.readAsBytes();
      String fileName = _imageFile!.path.split('/').last;
      
      // Mengambil nominal draf pengeluaran
      int kebutuhan = 0;
      if (_kebutuhanController.text.isNotEmpty) {
        kebutuhan = int.parse(_kebutuhanController.text);
      }

      // --- DISINILAH KITA MENYURUH KURIR BEKERJA ---
      var responseData = await ApiService.kirimStrukKeAI(imageBytes, fileName, kebutuhan);

      // --- KURIR PULANG MEMBAWA HASIL ---
      setState(() {
        _hasilAnalisis = responseData;
      });

    } catch (e) {
      setState(() {
        _hasilAnalisis = {
          "status": "gagal",
          "pesan": "Waduh, gagal ngirim nih. Error: $e"
        };
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // === TAMPILAN ANTARMUKA (UI) ===
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GIM - AI Vision'),
        backgroundColor: Colors.green[700],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Kolom Input Draf Pengeluaran
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Draf Pengeluaran (Opsional)', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _kebutuhanController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Misal: 50000',
                        prefixText: 'Rp ',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 2. Kotak Gambar Struk
            GestureDetector(
              onTap: _pilihGambar,
              child: Container(
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _imageFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_imageFile!, fit: BoxFit.cover),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('Ketuk untuk pilih struk Gojek', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),

            // 3. Tombol Analisis AI
            ElevatedButton(
              onPressed: _isLoading ? null : _analisisStruk,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue[800],
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Analisis AI Sekarang 🚀', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 24),

            // 4. Kartu Hasil Analisis AI
            if (_hasilAnalisis != null)
              Card(
                color: _hasilAnalisis!['status'] == 'sukses' ? Colors.green[50] : Colors.red[50],
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _hasilAnalisis!['status'] == 'sukses' ? '✅ Hasil Analisis AI' : '❌ Terjadi Kesalahan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _hasilAnalisis!['status'] == 'sukses' ? Colors.green[800] : Colors.red[800],
                        ),
                      ),
                      const Divider(),
                      if (_hasilAnalisis!['status'] == 'sukses') ...[
                        Text('Pendapatan: Rp ${_hasilAnalisis!['pendapatan_terdeteksi']}'),
                        Text('Dipotong Draf: Rp ${_hasilAnalisis!['kebutuhan_harian']}'),
                        const SizedBox(height: 8),
                        Text(
                          'Sisa (Surplus): Rp ${_hasilAnalisis!['surplus']}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _hasilAnalisis!['surplus'] > 0 ? Colors.green[700] : Colors.red[700],
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text('🤖 Rekomendasi AI:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(_hasilAnalisis!['rekomendasi_investasi']),
                      ] else ...[
                        Text(_hasilAnalisis!['pesan'], style: const TextStyle(color: Colors.red)),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}