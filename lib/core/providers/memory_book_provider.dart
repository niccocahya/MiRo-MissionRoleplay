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

/// `mission_logs.mission_id` nggak punya foreign key ke `missions_master`
/// (beda dari child_id yang beneran FK) jadi PostgREST nggak bisa embed-join
/// otomatis di sini -- 3 query terpisah + gabung manual di client, sama
/// pola yang dipakai fitur replay misi di progress_page.dart.
final memoryBookProvider =
    FutureProvider.family<List<MemoryPhoto>, String>((ref, childId) async {
  if (childId.isEmpty) return [];

  final supabase = Supabase.instance.client;

  final logs = await supabase
      .from('mission_logs')
      .select('id, mission_id, completed_at')
      .eq('child_id', childId)
      .eq('status', 'completed');
  if (logs.isEmpty) return [];

  final logIds = logs.map((l) => l['id'] as String).toList();
  final missionIds = logs.map((l) => l['mission_id'] as String).toSet().toList();

  final journals = await supabase
      .from('journals')
      .select('mission_log_id, image_url, created_at')
      .inFilter('mission_log_id', logIds);
  if (journals.isEmpty) return [];

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
