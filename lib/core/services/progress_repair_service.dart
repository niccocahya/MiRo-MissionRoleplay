import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/skills.dart';

/// Menambal hadiah misi yang seharusnya udah didapat tapi nggak tercatat.
///
/// ## Kenapa ini perlu ada
///
/// `_syncToDatabase` di mission_journal_screen.dart nulis ke LIMA tempat
/// berturut-turut (mission_logs, children.total_xp, child_role_progress,
/// child_stats, child_achievements) dan sama sekali nggak atomik --
/// Supabase/PostgREST nggak ngasih transaksi lintas-request dari client.
/// Kalau koneksi putus di tengah, sebagian kesimpen dan sisanya hilang.
///
/// Layar jurnal sekarang udah bisa nerusin percobaan yang gagal selama
/// layarnya masih kebuka (lihat penanda `_stepXxxApplied` di sana). Tapi
/// kalau app-nya keburu ditutup, atau perangkatnya mati, nggak ada lagi
/// yang bakal nerusin -- di situlah fungsi ini masuk, dipanggil pas Home
/// kebuka.
///
/// ## Bukti ini beneran kejadian
///
/// Di database: satu anak (yang mainnya paling awal) kurang 20 poin
/// kreativitas + 10 motorik dibanding total `earned_skills` dari misi
/// yang dia selesaikan, dan dia juga cuma punya 3 dari 12 lencana yang
/// seharusnya. Anak-anak lain cocok persis.
///
/// ## Aturan yang dipegang
///
/// `mission_logs` berstatus 'completed' adalah SATU-SATUNYA sumber
/// kebenaran -- di seluruh app cuma ada satu tempat yang nulis
/// `total_xp` dan satu yang nulis `unlocked_level`, dua-duanya di layar
/// jurnal, jadi nilai yang benar selalu bisa dihitung ulang dari log.
///
/// Fungsi ini **cuma menaikkan, nggak pernah menurunkan**. Kalau nilai di
/// database lebih TINGGI dari hasil hitung ulang, itu dibiarkan apa
/// adanya. Alasannya: penurunan nilai bakal kerasa seperti hukuman buat
/// anak yang nggak salah apa-apa, dan selisih ke atas bisa datang dari
/// hal yang sah (data uji, atau pemberian manual di masa depan). Menambal
/// yang kurang aman; mencabut yang udah terlanjur dikasih nggak.
///
/// Idempoten -- aman dipanggil berkali-kali.
class ProgressRepairService {
  /// Balikin ringkasan singkat apa aja yang ditambal (kosong = nggak ada
  /// yang kurang). Dipakai buat log; alur app nggak bergantung ke ini.
  static Future<List<String>> repairMissing(String childId) async {
    if (childId.isEmpty) return const [];
    final supabase = Supabase.instance.client;
    final ditambal = <String>[];

    try {
      // ---- Sumber kebenaran: misi UNIK yang beneran selesai ----------
      // Di-dedupe per mission_id: dulu pernah ada celah yang bikin satu
      // misi kecatat selesai berkali-kali (udah ditutup). Log dobel itu
      // nggak boleh dihitung dua kali, atau perbaikan ini malah bikin
      // XP-nya menggelembung.
      final logs = await supabase
          .from('mission_logs')
          .select('mission_id, earned_xp, earned_skills')
          .eq('child_id', childId)
          .eq('status', 'completed');
      if (logs.isEmpty) return const [];

      final Map<String, Map<String, dynamic>> perMisi = {};
      for (final l in logs) {
        final id = l['mission_id'] as String?;
        if (id != null && id.isNotEmpty) perMisi.putIfAbsent(id, () => l);
      }
      if (perMisi.isEmpty) return const [];
      final missionIds = perMisi.keys.toList();

      final missions = await supabase
          .from('missions_master')
          .select('id, role_id, xp_reward, achievement_reward_id')
          .inFilter('id', missionIds);
      final Map<String, Map<String, dynamic>> misiById = {
        for (final m in missions) m['id'] as String: m,
      };

      // ---- 1. Total XP ------------------------------------------------
      int xpSeharusnya = 0;
      for (final e in perMisi.entries) {
        // earned_xp di log adalah nilai yang BENERAN dijanjikan waktu itu;
        // xp_reward di katalog bisa aja udah diubah sejak misi itu selesai.
        xpSeharusnya += (e.value['earned_xp'] as int?) ??
            (misiById[e.key]?['xp_reward'] as int? ?? 0);
      }

      final childRow = await supabase
          .from('children')
          .select('total_xp')
          .eq('id', childId)
          .maybeSingle();
      final int xpSekarang = (childRow?['total_xp'] as int?) ?? 0;
      if (xpSeharusnya > xpSekarang) {
        await supabase
            .from('children')
            .update({'total_xp': xpSeharusnya}).eq('id', childId);
        ditambal.add("XP $xpSekarang -> $xpSeharusnya");
      }

      // ---- 2. Level terbuka per peran ---------------------------------
      final Map<String, int> selesaiPerPeran = {};
      for (final e in perMisi.entries) {
        final roleId = misiById[e.key]?['role_id'] as String?;
        if (roleId == null || roleId.isEmpty) continue;
        selesaiPerPeran[roleId] = (selesaiPerPeran[roleId] ?? 0) + 1;
      }

      if (selesaiPerPeran.isNotEmpty) {
        final progresRows = await supabase
            .from('child_role_progress')
            .select('role_id, unlocked_level')
            .eq('child_id', childId);
        final Map<String, int> levelSekarang = {
          for (final r in progresRows)
            r['role_id'] as String: (r['unlocked_level'] as int?) ?? 1,
        };

        for (final e in selesaiPerPeran.entries) {
          final seharusnya = e.value + 1; // n misi selesai -> level n+1 kebuka
          final sekarang = levelSekarang[e.key];
          if (sekarang == null) {
            await supabase.from('child_role_progress').insert({
              'child_id': childId,
              'role_id': e.key,
              'unlocked_level': seharusnya,
            });
            ditambal.add("level ${e.key} -> $seharusnya (baris baru)");
          } else if (seharusnya > sekarang) {
            await supabase
                .from('child_role_progress')
                .update({'unlocked_level': seharusnya})
                .eq('child_id', childId)
                .eq('role_id', e.key);
            ditambal.add("level ${e.key} $sekarang -> $seharusnya");
          }
        }
      }

      // ---- 3. Poin skill ----------------------------------------------
      final Map<String, int> skillSeharusnya = {};
      for (final l in perMisi.values) {
        final raw = l['earned_skills'];
        if (raw is! Map) continue;
        raw.forEach((key, value) {
          if (value is! int) return;
          final kolom = skillStatColumn(key.toString());
          skillSeharusnya[kolom] = (skillSeharusnya[kolom] ?? 0) + value;
        });
      }

      if (skillSeharusnya.isNotEmpty) {
        final statsRow = await supabase
            .from('child_stats')
            .select()
            .eq('child_id', childId)
            .maybeSingle();

        if (statsRow == null) {
          await supabase
              .from('child_stats')
              .insert({'child_id': childId, ...skillSeharusnya});
          ditambal.add("child_stats dibuat");
        } else {
          final Map<String, dynamic> perluNaik = {};
          for (final e in skillSeharusnya.entries) {
            final sekarang = statsRow[e.key] as int? ?? 0;
            if (e.value > sekarang) perluNaik[e.key] = e.value;
          }
          if (perluNaik.isNotEmpty) {
            await supabase
                .from('child_stats')
                .update(perluNaik)
                .eq('child_id', childId);
            ditambal.add("skill ${perluNaik.keys.join(', ')}");
          }
        }
      }

      // ---- 4. Lencana --------------------------------------------------
      final Set<String> lencanaSeharusnya = perMisi.keys
          .map((id) => misiById[id]?['achievement_reward_id'] as String?)
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .toSet();

      if (lencanaSeharusnya.isNotEmpty) {
        final punya = await supabase
            .from('child_achievements')
            .select('achievement_id')
            .eq('child_id', childId);
        final Set<String> sudahPunya = punya
            .map((a) => a['achievement_id'] as String?)
            .whereType<String>()
            .toSet();

        final kurang = lencanaSeharusnya.difference(sudahPunya);
        if (kurang.isNotEmpty) {
          await supabase.from('child_achievements').insert([
            for (final id in kurang)
              {'child_id': childId, 'achievement_id': id},
          ]);
          ditambal.add("${kurang.length} lencana");
        }
      }

      if (ditambal.isNotEmpty) {
        debugPrint("Menambal progres $childId: ${ditambal.join(' | ')}");
      }
      return ditambal;
    } catch (e) {
      // Nggak fatal -- ini perbaikan latar belakang, bukan alur utama.
      debugPrint("Gagal menambal progres: $e");
      return const [];
    }
  }
}
