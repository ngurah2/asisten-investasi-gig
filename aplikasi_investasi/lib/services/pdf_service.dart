import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class PdfService {
  static Future<void> cetakLaporan(String periode, List<Map<String, dynamic>> data, String namaUser) async {
    final pdf = pw.Document();

    // Kalkulasi Total untuk Dasbor
    int totalSurplus = 0;
    for (var item in data) {
      totalSurplus += (item['nominal'] as int);
    }
    
    // Fungsi format rupiah
    String formatRupiah(int angka) {
      return angka.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
    }

    pdf.addPage(
      pw.MultiPage( // MultiPage agar jika riwayat banyak bisa otomatis lanjut ke halaman berikutnya
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // ================= HEADER DASBOR =================
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('DASBOR KPI KEUANGAN', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.teal800)),
                    pw.SizedBox(height: 4),
                    pw.Text('Asisten Investasi Gig (GIM)', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                  ],
                ),
                pw.Text(DateFormat('dd MMM yyyy').format(DateTime.now()), style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600)),
              ],
            ),
            pw.SizedBox(height: 20),

            // Informasi User & Periode
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8))),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Nama: $namaUser', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('Periode: $periode', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.teal700)),
                ]
              )
            ),
            pw.SizedBox(height: 20),

            // ================= KARTU SUMMARY DASBOR =================
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                // Kartu 1: Total Transaksi
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(16),
                    decoration: pw.BoxDecoration(color: PdfColors.teal700, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12))),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Total Transaksi', style: const pw.TextStyle(color: PdfColors.white, fontSize: 12)),
                        pw.SizedBox(height: 8),
                        pw.Text('${data.length} Data', style: pw.TextStyle(color: PdfColors.white, fontSize: 20, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 16),
                // Kartu 2: Total Surplus Terkumpul
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(16),
                    decoration: pw.BoxDecoration(color: PdfColors.teal500, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12))),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Total Surplus Periode Ini', style: const pw.TextStyle(color: PdfColors.white, fontSize: 12)),
                        pw.SizedBox(height: 8),
                        pw.Text('Rp ${formatRupiah(totalSurplus)}', style: pw.TextStyle(color: PdfColors.white, fontSize: 20, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 30),

            // ================= RINCIAN ANALISIS AI =================
            pw.Text('Detail Transaksi & Rekomendasi AI', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.teal800)),
            pw.Divider(color: PdfColors.teal200, thickness: 2),
            pw.SizedBox(height: 10),

            // Meloop setiap transaksi agar tampil seperti list yang rapi
            ...data.map((item) {
              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 16),
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Baris Tanggal & Surplus
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(item['tanggal'], style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
                        pw.Text('+ Rp ${formatRupiah(item['nominal'])}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.teal700, fontSize: 14)),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                    
                    // Baris Deskripsi Belanja
                    pw.Text('Deskripsi:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
                    pw.Text(item['deskripsi'], style: const pw.TextStyle(fontSize: 12)),
                    pw.SizedBox(height: 12),
                    
                    // Baris Rekomendasi AI
                    pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(color: PdfColors.orange50, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6))),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Saran Manajer AI & Investasi:', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.orange800)),
                          pw.SizedBox(height: 6),
                          pw.Text(
                            item['rekomendasi'].toString().replaceAll('**', ''), // Menghilangkan bintang markdown agar rapi di PDF
                            style: pw.TextStyle(fontSize: 11, color: PdfColors.grey800, lineSpacing: 1.5)
                          ),
                        ]
                      )
                    ),
                  ],
                ),
              );
            }).toList(),
          ];
        },
      ),
    );

    // Otomatisasi Nama File saat disave dengan tanggal cetak
    String namaFileDefault = 'Laporan_GIM_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: namaFileDefault,
    );
  }
}