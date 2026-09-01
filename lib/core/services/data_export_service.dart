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
    final certifications = await forChildren('child_certifications');
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
    final file = File(
      '${dir.path}/miro_data_export_${DateTime.now().millisecondsSinceEpoch}.json',
    );
    await file.writeAsString(jsonStr);

    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: 'Ekspor data MiRO kamu'),
    );
  }
}
