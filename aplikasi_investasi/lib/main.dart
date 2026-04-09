import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const AplikasiInvestasiGig());
}

class AplikasiInvestasiGig extends StatelessWidget {
  const AplikasiInvestasiGig({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Investasi Gig',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const HalamanUtama(),
    );
  }
}

class HalamanUtama extends StatefulWidget {
  const HalamanUtama({super.key});

  @override
  State<HalamanUtama> createState() => _HalamanUtamaState();
}

class _HalamanUtamaState extends State<HalamanUtama> {
  XFile? _gambarTerpilih;
  bool _sedangMemuat = false;
  Map<String, dynamic>? _hasilAnalisis;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pilihGambar() async {
    final XFile? gambar = await _picker.pickImage(source: ImageSource.gallery);
    if (gambar != null) {
      setState(() {
        _gambarTerpilih = gambar;
        _hasilAnalisis = null;
      });
    }
  }

  Future<void> _analisisGambar() async {
    if (_gambarTerpilih == null) return;

    setState(() {
      _sedangMemuat = true;
    });

    try {
      // Menggunakan 127.0.0.1 karena kita akan mengetesnya di Chrome
      var uri = Uri.parse('http://127.0.0.1:8000/analisis-pendapatan/');
      
      var request = http.MultipartRequest('POST', uri);
      
      // Menggunakan Bytes agar file terbaca sempurna di Web/Chrome
      var bytes = await _gambarTerpilih!.readAsBytes();
      var multipartFile = http.MultipartFile.fromBytes(
        'file', 
        bytes, 
        filename: _gambarTerpilih!.name
      );
      request.files.add(multipartFile);

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        setState(() {
          _hasilAnalisis = jsonDecode(response.body);
        });
      } else {
        _tampilkanPesanError("Gagal terhubung. Kode Error: ${response.statusCode}");
      }
    } catch (e) {
      _tampilkanPesanError("Terjadi kesalahan: $e");
    } finally {
      setState(() {
        _sedangMemuat = false;
      });
    }
  }

  void _tampilkanPesanError(String pesan) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pesan)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Asisten Investasi Gig')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                color: Colors.grey[200],
              ),
              child: _gambarTerpilih != null
                  ? FutureBuilder(
                      future: _gambarTerpilih!.readAsBytes(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
                          return Image.memory(snapshot.data!, fit: BoxFit.contain);
                        }
                        return const Center(child: CircularProgressIndicator());
                      },
                    )
                  : const Center(child: Text('Belum ada foto yang dipilih')),
            ),
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _pilihGambar,
                  icon: const Icon(Icons.photo),
                  label: const Text('Pilih Foto'),
                ),
                ElevatedButton.icon(
                  onPressed: _sedangMemuat ? null : _analisisGambar,
                  icon: _sedangMemuat 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2,)) 
                    : const Icon(Icons.analytics),
                  label: const Text('Analisis AI'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 24),

            if (_hasilAnalisis != null && _hasilAnalisis!['status'] == 'sukses') ...[
              const Text('Hasil Analisis:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pendapatan: Rp ${_hasilAnalisis!['pendapatan_terdeteksi']}'),
                      Text('Kebutuhan Harian: Rp ${_hasilAnalisis!['kebutuhan_harian']}'),
                      const Divider(),
                      Text('Surplus: Rp ${_hasilAnalisis!['surplus']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                      const SizedBox(height: 16),
                      const Text('Rekomendasi Investasi:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        '${_hasilAnalisis!['rekomendasi_investasi']}', 
                        style: const TextStyle(fontSize: 16, color: Colors.blueAccent, fontWeight: FontWeight.bold)
                      ),
                    ],
                  ),
                ),
              )
            ]
          ],
        ),
      ),
    );
  }
}