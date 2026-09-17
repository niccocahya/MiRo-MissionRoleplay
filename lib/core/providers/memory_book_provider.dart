import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/date_utils.dart';

/// Satu foto journal + konteks misi yang menghasilkannya -- dulu foto-foto
/// ini cuma bisa dibuka lagi SATU MISI PER SATU MISI lewat "replay" di
/// Progress (tap 1 misi selesai -> journal-nya sendiri). Nggak ada galeri
/// terpadu yang nunjukin semua kenangan sekaligus, padahal app ini
/// photo-heavy (tiap step misi minta foto).
class MemoryPhoto {
  const MemoryPhoto({
    required this.imageUrl,
    required this.roleId,
    required this.missionTitleId,
    required this.missionTitleEn,
    required this.takenAt,
  });

  final String imageUrl;
  final String roleId;
  final String missionTitleId;
  final String missionTitleEn;
  final DateTime? takenAt;

  String missionTitle(String lang) => lang == 'id' ? missionTitleId : missionTitleEn;
}

/// Ambil datanya lewat 3 query terpisah lalu digabung di client, sama pola
/// dengan fitur replay misi di progress_page.dart.
///
/// Dulu ini TERPAKSA begitu: `mission_logs.mission_id` bertipe text
/// sementara `missions_master.id` uuid, jadi nggak ada foreign key di
/// antara keduanya dan PostgREST nggak bisa embed-join otomatis. Sekarang
/// FK-nya udah ada (lihat migrasi `add_missing_content_foreign_keys`), jadi
/// embed-join sebenarnya sudah mungkin -- tetap dibiarkan 3 query karena
/// sudah jalan dan teruji, bukan lagi karena nggak bisa.
///
/// Dulu ini `FutureProvider` -- sekali ambil per `childId`, nggak pernah
/// kehitung ulang lagi buat sisa sesi app (sama kayak bug yang sempat ada
/// di `childRoleProgressProvider`/`skillTrendProvider`). Foto misi yang baru
/// diselesaikan nggak nongol di galeri sampai app ditutup total & dibuka
/// ulang. Sekarang `.stream()` di `mission_logs` (tabel yang punya
/// `child_id`, jadi bisa difilter per anak) + `.asyncMap()` buat nge-join
/// `journals`/`missions_master` ulang tiap ada perubahan -- pola yang sama
/// kayak `childAchievementsProvider` di home_page.dart.
final memoryBookProvider =
    StreamProvider.family<List<MemoryPhoto>, String>((ref, childId) {
  if (childId.isEmpty) return Stream.value([]);

  final supabase = Supabase.instance.client;

  return supabase
      .from('mission_logs')
      .stream(primaryKey: ['id'])
      .eq('child_id', childId)
      .asyncMap((event) async {
    final logs = event.where((l) => l['status'] == 'completed').toList();
    if (logs.isEmpty) return <MemoryPhoto>[];

    final logIds = logs.map((l) => l['id'] as String).toList();
    final missionIds = logs.map((l) => l['mission_id'] as String).toSet().toList();

    final journals = await supabase
        .from('journals')
        .select('mission_log_id, image_url, created_at')
        .inFilter('mission_log_id', logIds);
    if (journals.isEmpty) return <MemoryPhoto>[];

    final missions = await supabase
        .from('missions_master')
        .select('id, role_id, title_id, title_en')
        .inFilter('id', missionIds);

    final Map<String, Map<String, dynamic>> logById = {
      for (final l in logs) l['id'] as String: l,
    };
    final Map<String, Map<String, dynamic>> missionById = {
      for (final m in missions) m['id'] as String: m,
    };

    final photos = <MemoryPhoto>[];
    for (final j in journals) {
      final String? imageUrl = j['image_url'] as String?;
      if (imageUrl == null || imageUrl.isEmpty) continue;

      final log = logById[j['mission_log_id']];
      final mission = log == null ? null : missionById[log['mission_id']];

      photos.add(MemoryPhoto(
        imageUrl: imageUrl,
        roleId: mission?['role_id'] as String? ?? '',
        missionTitleId: mission?['title_id'] as String? ?? '',
        missionTitleEn: mission?['title_en'] as String? ?? '',
        takenAt: parseDateSafely(
          (j['created_at'] ?? log?['completed_at'] ?? '').toString(),
        ),
      ));
    }

    photos.sort((a, b) {
      if (a.takenAt == null || b.takenAt == null) return 0;
      return b.takenAt!.compareTo(a.takenAt!);
    });
    return photos;
  });
});
