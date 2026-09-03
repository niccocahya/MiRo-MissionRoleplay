import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Hapus SATU anak (beserta semua jejaknya) dari akun orang tua.
///
/// Dulu multi-anak cuma bisa NAMBAH: begitu satu anak kebuat -- entah
/// salah ketik, dobel, atau cuma buat nyoba-nyoba -- nggak ada cara buat
/// ngilangin selain hapus SELURUH akun. Ini ngasih jalan keluar yang
/// sepadan sama tombol "Tambah Anak" yang udah ada.
///
/// Baris-baris turunannya (mission_logs -> journals/reflections,
/// child_stats, child_role_progress, child_achievements, questionnaires)
/// kehapus otomatis lewat FK ON DELETE CASCADE -- yang NGGAK otomatis itu
/// FILE-nya di Storage, jadi itu dibersihin manual di sini dulu. Kalau
/// nggak, foto-foto misi anak yang udah dihapus bakal nyangkut selamanya
/// makan kuota storage tanpa ada yang bisa nampilin/hapus lagi.
class ChildDeletionService {
  /// Hapus foto-foto milik [childId] dari Storage, lalu baris `children`-nya.
  static Future<void> deleteChild({
    required String childId,
    String? avatarUrl,
  }) async {
    final supabase = Supabase.instance.client;

    // 1. Kumpulin URL foto jurnal anak ini (lewat mission_logs -> journals).
    final List<String> photoUrls = [];
    try {
      final logs = await supabase
          .from('mission_logs')
          .select('id')
          .eq('child_id', childId);
      final logIds = logs.map((l) => l['id'] as String).toList();

      if (logIds.isNotEmpty) {
        final journals = await supabase
            .from('journals')
            .select('image_url')
            .inFilter('mission_log_id', logIds);
        for (final j in journals) {
          final url = j['image_url'] as String?;
          if (url != null && url.isNotEmpty) photoUrls.add(url);
        }
      }
    } catch (e) {
      debugPrint("Gagal ngumpulin foto jurnal buat dibersihin: $e");
    }

    if (avatarUrl != null && avatarUrl.isNotEmpty) photoUrls.add(avatarUrl);

    // 2. Hapus file-filenya dari bucket masing-masing. Sengaja SEBELUM
    //    baris DB-nya dihapus -- kalau urutannya kebalik dan langkah ini
    //    gagal, kita udah nggak punya daftar URL-nya lagi buat nyoba lagi.
    await _removeFromStorage(photoUrls);

    // 3. Baru hapus anaknya; sisanya ngikut lewat cascade.
    await supabase.from('children').delete().eq('id', childId);
  }

  static Future<void> _removeFromStorage(List<String> publicUrls) async {
    // Path publik Supabase Storage bentuknya:
    //   .../storage/v1/object/public/{bucket}/{path...}
    final Map<String, List<String>> byBucket = {};
    for (final url in publicUrls) {
      for (final bucket in const ['mission-assets', 'user_photo']) {
        final marker = '/$bucket/';
        final idx = url.indexOf(marker);
        if (idx == -1) continue;
        byBucket
            .putIfAbsent(bucket, () => [])
            .add(url.substring(idx + marker.length));
        break;
      }
    }

    for (final entry in byBucket.entries) {
      try {
        await Supabase.instance.client.storage
            .from(entry.key)
            .remove(entry.value);
      } catch (e) {
        // Nggak fatal -- anaknya tetep kehapus, ini cuma bersih-bersih.
        debugPrint("Gagal hapus file di bucket ${entry.key}: $e");
      }
    }
  }
}
