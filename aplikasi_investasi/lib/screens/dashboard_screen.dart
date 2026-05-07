import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart'; // TAMBAHAN
import '../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
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
        title: const Text('Dashboard Analisis', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _futureRiwayat,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('Belum ada data.'));

          List<dynamic> dataTersaring = _filterData(snapshot.data!);
          
          int totalPendapatan = dataTersaring.fold(0, (sum, item) => sum + (item['pendapatan'] as int));
          int totalKebutuhan = dataTersaring.fold(0, (sum, item) => sum + (item['kebutuhan'] as int));
          int totalSurplus = dataTersaring.fold(0, (sum, item) => sum + (item['surplus'] as int));
          List<dynamic> recentData = dataTersaring.take(7).toList().reversed.toList();

          return Column(
            children: [
              _buildFilterChips(),
              
              if (_filterAktif == 'Bulanan')
                Container(
                  color: Colors.white,
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
                ? Center(child: Text('Tidak ada transaksi di ${_namaBulan[_bulanDipilih.month]} ${_bulanDipilih.year}.', style: const TextStyle(color: Colors.grey)))
                : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.teal[800]!, Colors.teal[400]!]), borderRadius: BorderRadius.circular(16)),
                        child: Column(children: [
                          const Text('Total Kas Terkumpul (Surplus)', style: TextStyle(color: Colors.white70, fontSize: 14)),
                          const SizedBox(height: 8),
                          Text('Rp ${formatRp(totalSurplus)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 28)),
                        ]),
                      ),
                      const SizedBox(height: 24),
                      const Text('Proporsi Keuangan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[200]!)),
                        child: Column(children: [
                          SizedBox(
                            height: 200,
                            child: totalPendapatan == 0 ? const Center(child: Text("Belum ada pergerakan dana")) : PieChart(
                              PieChartData(sectionsSpace: 2, centerSpaceRadius: 50, sections: [
                                PieChartSectionData(color: Colors.orange, value: totalKebutuhan.toDouble(), title: '${((totalKebutuhan / (totalPendapatan == 0 ? 1 : totalPendapatan)) * 100).toStringAsFixed(1)}%', radius: 40, titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                                PieChartSectionData(color: Colors.teal, value: totalSurplus > 0 ? totalSurplus.toDouble() : 0, title: '${((totalSurplus / (totalPendapatan == 0 ? 1 : totalPendapatan)) * 100).toStringAsFixed(1)}%', radius: 50, titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                              ]),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(mainAxisAlignment: MainAxisAlignment.center, children: [_buildLegend(color: Colors.teal, text: 'Surplus'), const SizedBox(width: 16), _buildLegend(color: Colors.orange, text: 'Pengeluaran')]),
                        ]),
                      ),
                      const SizedBox(height: 24),
                      const Text('Tren 7 Transaksi Terakhir', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 16),
                      Container(
                        height: 250,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[200]!)),
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: recentData.isEmpty ? 100 : recentData.map((e) => e['pendapatan'] as int).reduce((a, b) => a > b ? a : b).toDouble() * 1.2,
                            barTouchData: BarTouchData(enabled: false),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (double value, TitleMeta meta) {
                                if (value.toInt() >= recentData.length) return const Text('');
                                String tgl = recentData[value.toInt()]['tanggal'].toString();
                                return Padding(padding: const EdgeInsets.only(top: 8.0), child: Text('${tgl.substring(8, 10)}/${tgl.substring(5, 7)}', style: const TextStyle(fontSize: 10, color: Colors.grey)));
                              })),
                              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            gridData: FlGridData(show: false), borderData: FlBorderData(show: false),
                            barGroups: recentData.asMap().entries.map((entry) {
                              int index = entry.key; int pendapatan = entry.value['pendapatan']; int surplus = entry.value['surplus'];
                              return BarChartGroupData(x: index, barRods: [
                                BarChartRodData(toY: pendapatan.toDouble(), color: Colors.teal[200], width: 12, borderRadius: BorderRadius.circular(4)),
                                BarChartRodData(toY: surplus > 0 ? surplus.toDouble() : 0, color: Colors.teal[700], width: 12, borderRadius: BorderRadius.circular(4)),
                              ]);
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [_buildLegend(color: Colors.teal[200]!, text: 'Pendapatan'), const SizedBox(width: 16), _buildLegend(color: Colors.teal[700]!, text: 'Surplus')]),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      color: Colors.white, padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: ['Semua', 'Harian', 'Mingguan', 'Bulanan'].map((f) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: ChoiceChip(label: Text(f), selected: _filterAktif == f, onSelected: (s) => setState(() => _filterAktif = f), selectedColor: Colors.teal[600], labelStyle: TextStyle(color: _filterAktif == f ? Colors.white : Colors.teal[700])),
        )).toList()),
      ),
    );
  }

  Widget _buildLegend({required Color color, required String text}) {
    return Row(children: [Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)), const SizedBox(width: 4), Text(text, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold))]);
  }
}