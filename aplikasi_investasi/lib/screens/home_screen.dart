import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import 'riwayat_screen.dart';

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
              TextField(controller: editDeskripsi, decoration: InputDecoration(labelText: 'Deskripsi (Misal: Makan)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
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
    if (_imageFile == null) return;
    setState(() { _isLoading = true; _hasilAnalisis = null; });

    try {
      List<int> imageBytes = await _imageFile!.readAsBytes();
      String fileName = _imageFile!.name; 
      
      var responseData = await ApiService.kirimStrukKeAI(imageBytes, fileName, _totalManual);
      setState(() { _hasilAnalisis = responseData; });
    } catch (e) {
      setState(() { _hasilAnalisis = {"status": "gagal", "pesan": "Error: $e"}; });
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  Widget _tampilkanGambar() {
    if (_imageFile == null) {
      return const Center(child: Text('Pilih gambar struk...', style: TextStyle(color: Colors.grey)));
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: kIsWeb 
        ? Image.network(_imageFile!.path, fit: BoxFit.contain) 
        : Image.file(File(_imageFile!.path), fit: BoxFit.contain),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('GIM - Gig Investasi', style: TextStyle(color: Colors.teal[700], fontWeight: FontWeight.bold, fontSize: 22)),
        actions: [
          IconButton(icon: Icon(Icons.history, color: Colors.teal[700], size: 28), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RiwayatScreen()))),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Catat Pengeluaran Harian/Mingguan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(flex: 3, child: TextField(controller: _deskripsiController, decoration: InputDecoration(hintText: 'Misal: Bensin', filled: true, fillColor: Colors.grey[50], border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)))),
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['deskripsi'], style: const TextStyle(fontSize: 15, color: Colors.black87)),
                          const SizedBox(height: 4),
                          Text('Rp ${_formatRupiah(item['nominal'])}', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(icon: const Icon(Icons.edit, color: Colors.blue, size: 20), onPressed: () => _editPengeluaran(index), constraints: const BoxConstraints(), padding: const EdgeInsets.symmetric(horizontal: 8)),
                          IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 20), onPressed: () => _hapusPengeluaran(index), constraints: const BoxConstraints(), padding: const EdgeInsets.symmetric(horizontal: 8)),
                        ],
                      ),
                    ],
                  ),
                );
              }),
              Divider(color: Colors.grey[300], thickness: 1),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Pengeluaran:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
                  Text('Rp ${_formatRupiah(_totalManual)}', style: TextStyle(color: Colors.orange[800], fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ],

            const SizedBox(height: 32),
            const Text('Struk Pendapatan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Container(
              height: 220,
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.teal.withOpacity(0.4), width: 1.5), borderRadius: BorderRadius.circular(16)),
              child: _tampilkanGambar(),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(child: ElevatedButton.icon(onPressed: () => _pilihGambar(ImageSource.camera), icon: Icon(Icons.camera_alt, color: Colors.teal[700]), label: Text('Kamera', style: TextStyle(color: Colors.teal[700])), style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.withOpacity(0.1), elevation: 0, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton.icon(onPressed: () => _pilihGambar(ImageSource.gallery), icon: Icon(Icons.photo_library, color: Colors.teal[700]), label: Text('Galeri', style: TextStyle(color: Colors.teal[700])), style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.withOpacity(0.1), elevation: 0, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _analisisStruk,
              icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.auto_awesome, color: Colors.white),
              label: Text(_isLoading ? 'Menganalisis...' : 'Mulai Analisis AI', style: const TextStyle(color: Colors.white, fontSize: 16)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal[600], elevation: 0, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),

            if (_hasilAnalisis != null) ...[
              const SizedBox(height: 28),
              Builder(
                builder: (context) {
                  // --- LOGIKA DINAMIS WARNA DAN TEKS ---
                  int surplus = _hasilAnalisis!['surplus'];
                  Color themeColor;
                  IconData statusIcon;
                  String judulHasil;

                  if (surplus > 0) {
                    themeColor = Colors.teal;
                    statusIcon = Icons.sentiment_very_satisfied;
                    judulHasil = 'Selamat kamu luar biasaa';
                  } else if (surplus == 0) {
                    themeColor = Colors.grey;
                    statusIcon = Icons.sentiment_neutral;
                    judulHasil = 'Lebih semangat kerjanya';
                  } else {
                    themeColor = Colors.red;
                    statusIcon = Icons.warning_amber_rounded;
                    judulHasil = 'Wajib nabung!';
                  }

                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white, 
                      border: Border.all(color: themeColor, width: 2), 
                      borderRadius: BorderRadius.circular(16)
                    ),
                    child: Column(children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center, 
                        children: [
                          Icon(statusIcon, color: themeColor), 
                          const SizedBox(width: 8), 
                          Text(judulHasil, style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: 18))
                        ]
                      ),
                      const Divider(height: 32),
                      _barisHasil('Pendapatan (AI)', 'Rp ${_formatRupiah(_hasilAnalisis!['pendapatan_terdeteksi'])}'),
                      _barisHasil('Total Pengeluaran AI', 'Rp ${_formatRupiah(_hasilAnalisis!['kebutuhan_harian'])}'),
                      const Divider(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                        children: [
                          const Text('Surplus/Sisa', style: TextStyle(color: Colors.grey)), 
                          Text('Rp ${_formatRupiah(surplus)}', style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: 18))
                        ]
                      ),
                      // Tampilkan Rekomendasi di bawah surplus
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: themeColor.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('💡 ', style: TextStyle(fontSize: 16)),
                            Expanded(child: Text(_hasilAnalisis!['rekomendasi_investasi'], style: TextStyle(color: themeColor, fontStyle: FontStyle.italic, fontSize: 13))),
                          ],
                        ),
                      )
                    ]),
                  );
                }
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _barisHasil(String label, String nilai) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(color: Colors.grey)), Text(nilai, style: const TextStyle(fontWeight: FontWeight.w600))]));
  }
}