import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../app_info.dart';
import '../constants/role_visuals.dart';
import '../constants/skills.dart';

/// Laporan PDF perkembangan anak — sebelumnya nggak ada cara sama sekali
/// buat orang tua nyimpen/nge-print/ngirim rangkuman progres anaknya ke
/// luar app (misal buat ditunjukin ke guru/psikolog anak). Dipanggil dari
/// Progress page, isinya persis riwayat & filter yang lagi ditampilkan di
/// layar (jadi kalau filter "Minggu Ini" dipilih ini otomatis jadi
/// ringkasan mingguan).
class ProgressReportData {
  const ProgressReportData({
    required this.childName,
    required this.level,
    required this.totalXp,
    required this.currentStreak,
    required this.skillScores,
    required this.achievements,
    required this.missionHistory,
    required this.periodLabel,
  });

  final String childName;
  final int level;
  final int totalXp;
  final int currentStreak;

  /// {'cognitive': x, 'empathy': x, 'creativity': x, 'literacy': x, 'motoric': x}
  final Map<String, double> skillScores;

  /// {'title', 'unlockedAt' (DateTime?)}
  final List<Map<String, dynamic>> achievements;

  /// Each entry: `roleId`, `completedAt` (DateTime?), `xp`, `skills` (list of strings).
  final List<Map<String, dynamic>> missionHistory;

  final String periodLabel;
}

Future<void> exportProgressReportPdf({
  required ProgressReportData data,
  required String lang,
}) async {
  final doc = pw.Document();
  final bool id = lang == 'id';

  // Nggak pakai locale eksplisit ('id_ID' dst) di sini karena
  // `initializeDateFormatting()` nggak pernah dipanggil di app ini —
  // DateFormat dengan locale eksplisit yang belum di-load bakal crash.
  final dateFmt = DateFormat('dd MMM yyyy');
  String fmtDate(DateTime? d) => d == null ? '-' : dateFmt.format(d);

  // Label skill-nya dari core/constants/skills.dart -- dulu file ini punya
  // salinan sendiri, jadi nambah/ganti skill harus diinget diubah di sini
  // juga (gampang kelewat: skill baru muncul di app tapi hilang di PDF).
  final Map<String, String> skillLabels = {
    for (final s in kSkills) s.key: s.name(id ? 'id' : 'en'),
  };

  final double maxSkill = data.skillScores.values.isEmpty
      ? 1
      : data.skillScores.values.reduce((a, b) => a > b ? a : b).clamp(1, double.infinity);

  final navy = PdfColor.fromInt(0xFF0A264F);
  final coral = PdfColor.fromInt(0xFFE57B65);
  final muted = PdfColor.fromInt(0xFF64748B);
  final border = PdfColor.fromInt(0xFFE2E8F0);

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      header: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            kAppName,
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: coral),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            id ? 'Laporan Perkembangan Anak' : 'Child Development Report',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: navy),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '${data.childName} • ${data.periodLabel} • ${fmtDate(DateTime.now())}',
            style: pw.TextStyle(fontSize: 10, color: muted),
          ),
          pw.SizedBox(height: 12),
          pw.Divider(color: border),
        ],
      ),
      footer: (context) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          '${context.pageNumber}/${context.pagesCount}',
          style: pw.TextStyle(fontSize: 9, color: muted),
        ),
      ),
      build: (context) => [
        // Ringkasan level/XP/streak
        pw.Row(
          children: [
            _statBox(id ? 'Level' : 'Level', '${data.level}', navy, border),
            pw.SizedBox(width: 10),
            _statBox('XP', '${data.totalXp}', navy, border),
            pw.SizedBox(width: 10),
            _statBox(
              id ? 'Streak' : 'Streak',
              '${data.currentStreak} ${id ? 'hari' : 'days'}',
              navy,
              border,
            ),
          ],
        ),
        pw.SizedBox(height: 20),

        pw.Text(
          id ? 'Skor Keahlian' : 'Skill Scores',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: navy),
        ),
        pw.SizedBox(height: 8),
        ...skillLabels.entries.map((e) {
          final score = data.skillScores[e.key] ?? 0;
          final fraction = maxSkill == 0 ? 0.0 : (score / maxSkill).clamp(0.0, 1.0);
          final filledFlex = (fraction * 100).round().clamp(1, 100);
          final remainingFlex = 100 - filledFlex;
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 6),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.SizedBox(
                  width: 80,
                  child: pw.Text(e.value, style: const pw.TextStyle(fontSize: 10)),
                ),
                pw.Expanded(
                  // pw (pdf widgets) nggak punya FractionallySizedBox, jadi
                  // bar proporsional disimulasikan pakai 2 Expanded ber-flex
                  // (bagian terisi vs sisa) dalam 1 Row, bukan overlay Stack.
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        flex: filledFlex,
                        child: pw.Container(
                          height: 10,
                          decoration: pw.BoxDecoration(
                            color: coral,
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      if (remainingFlex > 0)
                        pw.Expanded(
                          flex: remainingFlex,
                          child: pw.Container(
                            height: 10,
                            decoration: pw.BoxDecoration(
                              color: PdfColor.fromInt(0xFFF5F8FB),
                              borderRadius: pw.BorderRadius.circular(4),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.SizedBox(
                  width: 30,
                  child: pw.Text(
                    score.toStringAsFixed(0),
                    style: const pw.TextStyle(fontSize: 10),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
              ],
            ),
          );
        }),
        pw.SizedBox(height: 20),

        pw.Text(
          id ? 'Pencapaian Diraih (${data.achievements.length})' : 'Achievements Earned (${data.achievements.length})',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: navy),
        ),
        pw.SizedBox(height: 8),
        if (data.achievements.isEmpty)
          pw.Text(
            id ? 'Belum ada pencapaian di periode ini.' : 'No achievements in this period yet.',
            style: pw.TextStyle(fontSize: 10, color: muted),
          )
        else
          pw.Table(
            border: pw.TableBorder.all(color: border, width: 0.5),
            columnWidths: const {0: pw.FlexColumnWidth(3), 1: pw.FlexColumnWidth(1.4)},
            children: [
              _tableHeaderRow(id ? ['Lencana', 'Tanggal'] : ['Badge', 'Date'], navy),
              ...data.achievements.map(
                (a) => _tableRow([
                  a['title']?.toString() ?? '-',
                  fmtDate(a['unlockedAt'] as DateTime?),
                ]),
              ),
            ],
          ),
        pw.SizedBox(height: 20),

        pw.Text(
          id ? 'Riwayat Misi (${data.missionHistory.length})' : 'Mission History (${data.missionHistory.length})',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: navy),
        ),
        pw.SizedBox(height: 8),
        if (data.missionHistory.isEmpty)
          pw.Text(
            id ? 'Belum ada misi selesai di periode ini.' : 'No completed missions in this period yet.',
            style: pw.TextStyle(fontSize: 10, color: muted),
          )
        else
          pw.Table(
            border: pw.TableBorder.all(color: border, width: 0.5),
            columnWidths: const {
              0: pw.FlexColumnWidth(1.6),
              1: pw.FlexColumnWidth(1.6),
              2: pw.FlexColumnWidth(2.2),
              3: pw.FlexColumnWidth(0.8),
            },
            children: [
              _tableHeaderRow(
                id ? ['Peran', 'Tanggal', 'Skill', 'XP'] : ['Role', 'Date', 'Skills', 'XP'],
                navy,
              ),
              ...data.missionHistory.map((m) {
                final role = roleVisualById(m['roleId']?.toString()) ?? kUnknownRoleVisual;
                final skills = (m['skills'] as List?)?.join(', ') ?? '-';
                return _tableRow([
                  role.name(lang),
                  fmtDate(m['completedAt'] as DateTime?),
                  skills.isEmpty ? '-' : skills,
                  '+${m['xp'] ?? 0}',
                ]);
              }),
            ],
          ),
      ],
    ),
  );

  await Printing.layoutPdf(onLayout: (format) => doc.save());
}

pw.Widget _statBox(String label, String value, PdfColor navy, PdfColor border) {
  return pw.Expanded(
    child: pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: border),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        children: [
          pw.Text(value, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: navy)),
          pw.SizedBox(height: 2),
          pw.Text(label, style: const pw.TextStyle(fontSize: 9)),
        ],
      ),
    ),
  );
}

pw.TableRow _tableHeaderRow(List<String> labels, PdfColor navy) {
  return pw.TableRow(
    decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFFEBF4FA)),
    children: labels
        .map(
          (l) => pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            child: pw.Text(
              l,
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: navy),
            ),
          ),
        )
        .toList(),
  );
}

pw.TableRow _tableRow(List<String> cells) {
  return pw.TableRow(
    children: cells
        .map(
          (c) => pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            child: pw.Text(c, style: const pw.TextStyle(fontSize: 9)),
          ),
        )
        .toList(),
  );
}
