import 'dart:io';
import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart'; // Menambahkan intl untuk format tanggal PDF
import '../services/api_service.dart';
import '../services/pdf_service.dart';
import 'goals_screen.dart';

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

  final PageController _pageController = PageController(viewportFraction: 0.93, initialPage: 1000);
  int _currentCardIndex = 1000;
  Timer? _carouselTimer;

  // Variabel penampung data IHSG Real-time
  String _ihsgNilai = "Memuat...";
  String _ihsgPerubahan = "Memuat data...";
  Map<String, dynamic>? _targetTerdekat;

  int get _totalManual => _daftarManual.fold(0, (sum, item) => sum + (item['nominal'] as int));

  String _formatRupiah(int angka) {
    return angka.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), 
      (Match m) => '${m[1]}.'
    );
  }

  @override
  void initState() {
    super.initState();
    _mulaiPutaranOtomatis();
    _loadIHSG();
    _loadTargetTerdekat();
  }

  Future<void> _loadIHSG() async {
    final response = await ApiService.fetchIHSG();
    if (mounted) {
      setState(() {
        if (response['status'] == 'sukses') {
          _ihsgNilai = response['nilai'];
          _ihsgPerubahan = '${response['perubahan']} Hari ini (Real-Time)';
        } else {
          _ihsgNilai = "Gagal memuat";
          _ihsgPerubahan = "Cek koneksi server";
        }
      });
    }
  }

  Future<void> _loadTargetTerdekat() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int userId = prefs.getInt('userId') ?? 0;
    var data = await ApiService.fetchTargetTerdekat(userId);
    if (mounted) setState(() => _targetTerdekat = data);
  }

  void _mulaiPutaranOtomatis() {
    _carouselTimer?.cancel(); 
    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      if (_pageController.hasClients) {
        _pageController.nextPage(duration: const Duration(milliseconds: 600), curve: Curves.easeOutCirc);
      }
    });
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    _deskripsiController.dispose();
    _kebutuhanController.dispose();
    _lamaWaktuController.dispose();
    super.dispose();
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

  void _tampilkanDetailKartu(int index) {
    if (index == 0) {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (context) => Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.trending_up, color: Colors.teal[800], size: 32),
                  const SizedBox(width: 12),
                  Text('Detail IHSG', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal[800])),
                ],
              ),
              const SizedBox(height: 16),
              Text('Indeks Harga Saham Gabungan (IHSG) hari ini berada di angka $_ihsgNilai, bergerak sebesar ${_ihsgPerubahan.split(' ')[0]}.', style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 12),
              const Text('Data ini ditarik secara real-time dari API pasar modal melalui backend FastAPI Anda.', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: Colors.teal), child: const Text('Tutup', style: TextStyle(color: Colors.white)))),
            ],
          ),
        ),
      );
    } else if (index == 1) {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (context) => Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: Colors.orange[800], size: 32),
                  const SizedBox(width: 12),
                  Text('Tips Alokasi Gig Worker', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange[800])),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Gunakan metode 50/30/20 untuk mengelola penghasilan tidak tetapmu:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('• 50% untuk Kebutuhan Pokok (makan, kos, bensin).\n• 30% untuk Keinginan (hiburan, nongkrong).\n• 20% untuk Tabungan & Investasi (darurat, masa depan).', style: TextStyle(fontSize: 15, height: 1.5)),
              const SizedBox(height: 24),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[800]), child: const Text('Mengerti', style: TextStyle(color: Colors.white)))),
            ],
          ),
        ),
      );
    } else if (index == 2) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(children: [Icon(Icons.document_scanner, color: Colors.teal[600]), const SizedBox(width: 8), const Text('Fitur Scan OCR')]),
          content: const Text('Scroll ke bagian bawah halaman ini untuk menemukan fitur "Scan Struk Pendapatan". \n\nFoto struk atau catatan belanjamu, dan AI akan menganalisis sisa uangmu secara otomatis!'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Siap!', style: TextStyle(color: Colors.teal[700]))),
          ],
        ),
      );
    } else if (index == 3) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const GoalsScreen()))
          .then((_) => _loadTargetTerdekat());
    }
  }

  Widget _buildCarousel() {
    final List<Map<String, dynamic>> carouselData = [
      {
        "title": "IHSG Real-Time",
        "content": _ihsgNilai, 
        "subtitle": _ihsgPerubahan, 
        "color": Colors.teal[800],
        "icon": Icons.trending_up,
      },
      {
        "title": "Tips Gig Worker",
        "content": "Alokasikan Dana",
        "subtitle": "Metode 50/30/20 untuk pekerja lepas. (Klik untuk baca)",
        "color": Colors.orange[800],
        "icon": Icons.lightbulb_outline,
      },
      {
        "title": "Fitur AI GIM",
        "content": "Scan OCR Pintar",
        "subtitle": "Kamera pintar untuk kelola keuangan. (Klik petunjuk)",
        "color": Colors.teal[600],
        "icon": Icons.document_scanner,
      },
      {
        "title": "Target Keuangan",
        "content": _targetTerdekat != null ? "Rp ${_formatRupiah(_targetTerdekat!['terkumpul'] ?? 0)}" : "Belum ada target",
        "subtitle": _targetTerdekat != null ? "${_targetTerdekat!['nama_target']} (Deadline: ${_targetTerdekat!['deadline']})" : "Klik untuk mulai buat impianmu!",
        "color": Colors.blueGrey[700],
        "icon": Icons.track_changes,
      }
    ];

    return Column(
      children: [
        SizedBox(
          height: 160,
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
            ),
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentCardIndex = index);
                _mulaiPutaranOtomatis();
              },
              itemBuilder: (context, index) {
                final realIndex = index % carouselData.length;
                final data = carouselData[realIndex];
                
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6.0),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _tampilkanDetailKartu(realIndex),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: data['color'],
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: (data['color'] as Color).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(data['title'], style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12)),
                                  const SizedBox(height: 8),
                                  Text(data['content'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                                  const SizedBox(height: 8),
                                  Text(data['subtitle'], style: const TextStyle(color: Colors.white, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                            Icon(data['icon'], size: 64, color: Colors.white.withOpacity(0.3)),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            carouselData.length,
            (index) {
              int currentPageMod = _currentCardIndex % carouselData.length;
              bool isActive = currentPageMod == index;
              
              return GestureDetector(
                onTap: () {
                  int offset = index - currentPageMod;
                  int targetPage = _currentCardIndex + offset;
                  _pageController.animateToPage(
                    targetPage, 
                    duration: const Duration(milliseconds: 500), 
                    curve: Curves.easeInOut
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 12, 
                  width: isActive ? 24 : 12,
                  decoration: BoxDecoration(
                    color: isActive ? Colors.teal : Colors.grey[300],
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              );
            },
          ),
        ),
      ],
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildCarousel(),
            const SizedBox(height: 32),

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
              
              // --- EKSPOR PDF ---
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  SharedPreferences prefs = await SharedPreferences.getInstance();
                  String namaUser = prefs.getString('userName') ?? 'Pengguna GIM';
                  
                  // Mengubah data manual menjadi format yang diterima PdfService Dasbor baru
                  List<Map<String, dynamic>> dataPdf = _daftarManual.map((item) {
                    return {
                      'tanggal': DateFormat('dd MMM yyyy').format(DateTime.now()),
                      'deskripsi': item['deskripsi'],
                      'nominal': item['nominal'],
                      'rekomendasi': 'Catatan Manual: Item ini diinput secara manual dan belum dianalisis oleh AI.'
                    };
                  }).toList();

                  await PdfService.cetakLaporan("Pengeluaran Manual GIM", dataPdf, namaUser);
                },
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Ekspor Laporan PDF'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
              ),
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
              if (_hasilAnalisis!['status'] == 'sukses')
                _hasilKartuAnalisis()
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red)),
                  child: Text(_hasilAnalisis!['pesan'] ?? 'Terjadi kesalahan saat memproses data.', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                )
            ]
          ],
        ),
      ),
    );
  }

  Widget _hasilKartuAnalisis() {
    int surplus = int.tryParse(_hasilAnalisis!['surplus']?.toString() ?? '0') ?? 0;
    Color themeColor = surplus > 0 ? Colors.teal : (surplus == 0 ? Colors.grey : Colors.red);
    String judul = surplus > 0 ? 'Selamat kamu luar biasaa' : (surplus == 0 ? 'Lebih semangat kerjanya' : 'Wajib nabung!');
    IconData iconStatus = surplus > 0 ? Icons.sentiment_very_satisfied : (surplus == 0 ? Icons.sentiment_neutral : Icons.warning_amber_rounded);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: themeColor, width: 2), borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(iconStatus, color: themeColor), const SizedBox(width: 8), Text(judul, style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: 18))]),
        const Divider(height: 32),
        _barisHasil('Total Pendapatan', 'Rp ${_formatRupiah(int.tryParse(_hasilAnalisis!['pendapatan_terdeteksi']?.toString() ?? '0') ?? 0)}'),
        _barisHasil('Total Pengeluaran', 'Rp ${_formatRupiah(int.tryParse(_hasilAnalisis!['kebutuhan_harian']?.toString() ?? '0') ?? 0)}'),
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