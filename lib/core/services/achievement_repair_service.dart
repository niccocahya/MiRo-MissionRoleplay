import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Menambal lencana yang seharusnya udah didapat tapi nggak tercatat.
///
/// Lencana cuma pernah diberikan SEKALI, tepat di detik misinya
/// diselesaikan (lihat `_syncToDatabase` di mission_journal_screen.dart).
/// Nggak ada transaksi yang ngiket XP + lencana jadi satu: kalau baris
/// `child_achievements`-nya gagal ditulis (koneksi putus pas itu juga,
/// atau bug versi lama), misinya tetap tercatat selesai tapi lencananya
/// HILANG PERMANEN -- nggak ada satu pun jalur di app yang bisa ngasih
/// lagi. Sertifikat pun ikut kena, karena sertifikat dihitung dari lencana
/// yang terkumpul.
///
/// Di database ini ada buktinya: satu anak (yang mainnya paling awal)
/// seharusnya punya 12 lencana tapi cuma tercatat 3.
///
/// Fungsi ini idempoten -- cuma nambahin yang kurang, nggak pernah
/// nyentuh yang udah ada, dan aman dipanggil berkali-kali.
class AchievementRepairService {
  /// Balikin jumlah lencana yang baru ditambahin (0 = udah lengkap).
  static Future<int> repairMissing(String childId) async {
    if (childId.isEmpty) return 0;
    final supabase = Supabase.instance.client;

    try {
      // 1. Misi apa aja yang udah beneran diselesaikan anak ini.
      final logs = await supabase
          .from('mission_logs')
          .select('mission_id')
          .eq('child_id', childId)
          .eq('status', 'completed');
      if (logs.isEmpty) return 0;

      final missionIds = logs
          .map((l) => l['mission_id'] as String?)
          .whereType<String>()
          .toSet()
          .toList();
      if (missionIds.isEmpty) return 0;

      // 2. Dari misi-misi itu, mana yang emang ngasih lencana.
      final missions = await supabase
          .from('missions_master')
          .select('id, achievement_reward_id')
          .inFilter('id', missionIds);

      final Set<String> seharusnyaPunya = missions
          .map((m) => m['achievement_reward_id'] as String?)
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .toSet();
      if (seharusnyaPunya.isEmpty) return 0;

      // 3. Yang udah tercatat.
      final existing = await supabase
          .from('child_achievements')
          .select('achievement_id')
          .eq('child_id', childId);
      final Set<String> sudahPunya = existing
          .map((a) => a['achievement_id'] as String?)
          .whereType<String>()
          .toSet();

      // 4. Selisihnya yang ditambal.
      final kurang = seharusnyaPunya.difference(sudahPunya);
      if (kurang.isEmpty) return 0;

      await supabase.from('child_achievements').insert([
        for (final achievementId in kurang)
          {'child_id': childId, 'achievement_id': achievementId},
      ]);

      debugPrint("Menambal ${kurang.length} lencana yang kelewat buat $childId");
      return kurang.length;
    } catch (e) {
      // Nggak fatal -- ini perbaikan latar belakang, bukan alur utama.
      debugPrint("Gagal menambal lencana: $e");
      return 0;
    }
  }
}
