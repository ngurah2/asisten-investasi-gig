import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // TAMBAHAN
import '../services/api_service.dart';

class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key});

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  late Future<List<dynamic>> _futureRiwayat;
  String _filterAktif = 'Semua';
  DateTime _bulanDipilih = DateTime.now(); 

  final List<String> _namaBulan = [
    '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  @override
  void initState() {
    super.initState();
    _futureRiwayat = _loadData(); // TAMBAHAN: Memanggil load data
  }

  // TAMBAHAN: Fungsi untuk mengambil user_id lalu fetch API
  Future<List<dynamic>> _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int userId = prefs.getInt('userId') ?? 0;
    return ApiService.ambilRiwayat(userId);
  }

  String formatRp(int angka) {
    return angka.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }

  List<dynamic> _filterData(List<dynamic> data) {
    DateTime sekarang = DateTime.now();
    return data.where((item) {
      if (item['tanggal'] == null) return false;
      DateTime tgl = DateTime.parse(item['tanggal']);
      if (_filterAktif == 'Harian') return tgl.day == sekarang.day && tgl.month == sekarang.month && tgl.year == sekarang.year;
      if (_filterAktif == 'Mingguan') return sekarang.difference(tgl).inDays <= 7;
      if (_filterAktif == 'Bulanan') return tgl.month == _bulanDipilih.month && tgl.year == _bulanDipilih.year;
      return true;
    }).toList();
  }

  void _ubahBulan(int nilai) {
    setState(() {
      _bulanDipilih = DateTime(_bulanDipilih.year, _bulanDipilih.month + nilai, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        title: const Text('Riwayat Keuangan', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _futureRiwayat,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('Belum ada riwayat.'));

          List<dynamic> dataTersaring = _filterData(snapshot.data!);
          int totalPendapatan = dataTersaring.fold(0, (sum, item) => sum + (item['pendapatan'] as int));
          int totalSurplus = dataTersaring.fold(0, (sum, item) => sum + (item['surplus'] as int));

          return Column(
            children: [
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.teal[700]!, Colors.teal[400]!]), borderRadius: BorderRadius.circular(16)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(children: [
                      const Text('Total Pendapatan', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      Text('Rp ${formatRp(totalPendapatan)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ]),
                    Container(width: 1, height: 40, color: Colors.white24),
                    Column(children: [
                      const Text('Total Surplus', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      Text('Rp ${formatRp(totalSurplus)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ]),
                  ],
                ),
              ),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: ['Semua', 'Harian', 'Mingguan', 'Bulanan'].map((f) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: ChoiceChip(label: Text(f), selected: _filterAktif == f, onSelected: (s) => setState(() => _filterAktif = f), selectedColor: Colors.teal, labelStyle: TextStyle(color: _filterAktif == f ? Colors.white : Colors.teal[700])),
                  )).toList(),
                ),
              ),

              if (_filterAktif == 'Bulanan')
                Container(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(icon: const Icon(Icons.chevron_left, color: Colors.teal), onPressed: () => _ubahBulan(-1)),
                      Text('${_namaBulan[_bulanDipilih.month]} ${_bulanDipilih.year}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      IconButton(icon: const Icon(Icons.chevron_right, color: Colors.teal), onPressed: () => _ubahBulan(1)),
                    ],
                  ),
                ),

              Expanded(
                child: dataTersaring.isEmpty 
                ? Center(child: Text('Tidak ada riwayat di ${_namaBulan[_bulanDipilih.month]} ${_bulanDipilih.year}.', style: const TextStyle(color: Colors.grey)))
                : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: dataTersaring.length,
                  itemBuilder: (context, index) {
                    var item = dataTersaring[index];
                    int surplus = item['surplus'];
                    String rincian = item['rincian'] ?? "Data lama: Tanpa rincian.";
                    
                    Color statusColor = surplus > 0 ? Colors.teal : (surplus == 0 ? Colors.grey : Colors.red);
                    String statusPesan = surplus > 0 ? "Surplus" : (surplus == 0 ? "Lebih semangat kerjanya" : "Fokus nabungggg!!!!");

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              title: Text('Detail Transaksi', style: TextStyle(fontWeight: FontWeight.bold, color: statusColor)),
                              content: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Rincian Belanja:', style: TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8), Text(rincian), const SizedBox(height: 16), const Divider(),
                                    const Text('Saran Manajer AI & Investasi:', style: TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8), Text(item['rekomendasi'] ?? '-', style: const TextStyle(height: 1.5)),
                                  ],
                                ),
                              ),
                              actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('Tutup', style: TextStyle(color: statusColor)))],
                            ),
                          );
                        },
                        leading: CircleAvatar(backgroundColor: statusColor.withOpacity(0.1), child: Icon(surplus >= 0 ? Icons.trending_up : Icons.trending_down, color: statusColor)),
                        title: Text('Rp ${formatRp(item['pendapatan'])}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(statusPesan, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
                        trailing: Text('Rp ${formatRp(surplus)}', style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}