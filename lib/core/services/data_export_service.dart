import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Ekspor semua data milik akun yang login jadi 1 file JSON — Privacy
/// Policy app ini udah janji "Kamu bisa minta salinan data anakmu ...
/// kapan saja", tapi sebelumnya itu cuma bisa lewat email manual ke CS.
/// Sekarang self-service. Semua query di sini lewat client biasa (bukan
/// service role) — cukup, karena RLS tiap tabel udah discope ke
/// `auth.uid()`, jadi otomatis cuma balikin data milik akun ini sendiri.
class DataExportService {
  static Future<Map<String, dynamic>> collectAllData() async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Belum login');

    final parent = await supabase
        .from('parents')
        .select()
        .eq('id', userId)
        .maybeSingle();
    final children = await supabase
        .from('children')
        .select()
        .eq('parent_id', userId);
    final childIds = children.map((c) => c['id'] as String).toList();

    Future<List<Map<String, dynamic>>> forChildren(String table) async {
      if (childIds.isEmpty) return [];
      final rows = await supabase.from(table).select().inFilter('child_id', childIds);
      return List<Map<String, dynamic>>.from(rows);
    }

    final questionnaires = await forChildren('questionnaires');
    final childStats = await forChildren('child_stats');
    final missionLogs = await forChildren('mission_logs');
    final achievements = await forChildren('child_achievements');

    // Sertifikat BUKAN baris tersendiri per anak di database -- nggak ada
    // apa pun di app ini yang pernah nulis ke `child_certifications` (tabel
    // itu selalu kosong). "Sertifikat terbuka" itu dihitung, sama kayak di
    // UI (lihat certificateProgressProvider): semua achievement_id yang
    // disyaratkan sebuah sertifikat udah ada di child_achievements anak
    // itu. Dulu field ini query langsung ke child_certifications, jadi
    // laporan ekspor selalu bilang anaknya nol sertifikat walau di app-nya
    // udah dapet beberapa.
    final certificationsMaster = await supabase
        .from('certifications_master')
        .select();
    final Map<String, Set<String>> earnedByChild = {};
    for (final a in achievements) {
      final cid = a['child_id'] as String?;
      final aid = a['achievement_id'] as String?;
      if (cid == null || aid == null) continue;
      earnedByChild.putIfAbsent(cid, () => {}).add(aid);
    }
    final certifications = <Map<String, dynamic>>[];
    for (final childId in childIds) {
      final earned = earnedByChild[childId] ?? {};
      for (final cert in certificationsMaster) {
        final required = List<String>.from(
          cert['required_achievement_ids'] ?? [],
        );
        if (required.isNotEmpty && required.every(earned.contains)) {
          certifications.add({
            'child_id': childId,
            'certification_id': cert['id'],
            'title_en': cert['title_en'],
            'title_id': cert['title_id'],
          });
        }
      }
    }

    // journals (foto jurnal) & reflections (perasaan + catatan) nggak
    // punya child_id LANGSUNG (cuma mission_log_id), jadi nggak bisa lewat
    // forChildren() di atas -- dulu keduanya kelewat sama sekali dari
    // ekspor, padahal ini termasuk data paling personal di app ini (foto
    // anak beraktivitas, perasaan Bunda/Ayah & anak per misi).
    final missionLogIds = missionLogs.map((m) => m['id'] as String).toList();
    final journals = missionLogIds.isEmpty
        ? <Map<String, dynamic>>[]
        : List<Map<String, dynamic>>.from(
            await supabase
                .from('journals')
                .select()
                .inFilter('mission_log_id', missionLogIds),
          );
    final reflections = missionLogIds.isEmpty
        ? <Map<String, dynamic>>[]
        : List<Map<String, dynamic>>.from(
            await supabase
                .from('reflections')
                .select()
                .inFilter('mission_log_id', missionLogIds),
          );

    final aiChats = await supabase.from('ai_chats').select().eq('parent_id', userId);
    final notifications = await supabase.from('notifications').select().eq('parent_id', userId);
    final feedback = await supabase.from('feedback').select().eq('parent_id', userId);

    return {
      'exported_at': DateTime.now().toIso8601String(),
      'account': parent,
      'children': children,
      'questionnaires': questionnaires,
      'child_stats': childStats,
      'mission_history': missionLogs,
      'mission_journal_photos': journals,
      'mission_reflections': reflections,
      'achievements': achievements,
      'certifications': certifications,
      'ai_chat_history': aiChats,
      'notifications': notifications,
      'feedback_submitted': feedback,
    };
  }

  /// Kumpulkan lalu buka dialog share OS (simpan/kirim) buat file JSON-nya.
  static Future<void> exportAndShare() async {
    final data = await collectAllData();
    final jsonStr = const JsonEncoder.withIndent('  ').convert(data);

    final dir = await getTemporaryDirectory();

    // Bersihin sisa file ekspor dari percobaan sebelumnya -- dulu file JSON
    // berisi seluruh data pribadi anak ini numpuk di penyimpanan device
    // selama-lamanya, nggak pernah dihapus abis dibagi/disimpan.
    await _cleanupOldExports(dir);

    final file = File(
      '${dir.path}/miro_data_export_${DateTime.now().millisecondsSinceEpoch}.json',
    );
    await file.writeAsString(jsonStr);

    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: 'Ekspor data MiRO kamu'),
    );

    // Kasih jeda dulu sebelum hapus file ini sendiri -- di banyak platform
    // share() return begitu dialog OS-nya kebuka, bukan begitu app tujuan
    // (mis. email, penyimpanan cloud) beneran selesai baca filenya.
    Future.delayed(const Duration(seconds: 30), () {
      try {
        if (file.existsSync()) file.deleteSync();
      } catch (_) {
        // Nggak fatal -- kalau gagal hapus sekarang, kepakai _cleanupOldExports
        // di kesempatan ekspor berikutnya.
      }
    });
  }

  static Future<void> _cleanupOldExports(Directory dir) async {
    try {
      await for (final entity in dir.list()) {
        if (entity is File && entity.path.contains('miro_data_export_')) {
          await entity.delete();
        }
      }
    } catch (_) {
      // Nggak fatal -- kalau gagal bersihin, file lama paling numpuk lagi.
    }
  }
}
