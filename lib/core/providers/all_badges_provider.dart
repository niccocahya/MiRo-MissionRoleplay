import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/date_utils.dart';

/// Satu badge (dari katalog `achievements_master`), digabung sama status
/// terbuka/belum + tanggal buka anak yang aktif. Sebelumnya nggak ada
/// tempat buat liat SEMUA badge sekaligus (baik yang udah maupun belum
/// terbuka) — badge cuma keliatan sepotong-sepotong: strip "terbaru" di
/// Home (cuma beberapa terakhir) dan nempel di dalam kartu sertifikat
/// (cuma badge yang jadi syarat sertifikat itu doang).
class BadgeEntry {
  const BadgeEntry({
    required this.id,
    required this.roleId,
    required this.titleId,
    required this.titleEn,
    required this.descriptionId,
    required this.descriptionEn,
    required this.icon,
    required this.unlockedAt,
  });

  final String id;
  final String roleId;
  final String titleId;
  final String titleEn;
  final String descriptionId;
  final String descriptionEn;
  final String icon;
  final DateTime? unlockedAt;

  bool get isUnlocked => unlockedAt != null;

  String title(String lang) => lang == 'id' ? titleId : titleEn;
  String description(String lang) => lang == 'id' ? descriptionId : descriptionEn;
}

/// Katalog lengkap badge (jarang berubah) — dipisah dari status per-anak
/// biar nggak nembak query ini ulang tiap ada perubahan `child_achievements`.
final _achievementsMasterProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final res = await Supabase.instance.client.from('achievements_master').select();
  return List<Map<String, dynamic>>.from(res);
});

/// Semua badge + status terbuka/belum buat 1 anak, realtime (StreamProvider
/// atas `child_achievements`, sama pola dengan certificateProgressProvider)
/// — badge baru kebuka langsung keliatan di sini tanpa perlu buka ulang
/// layarnya.
final allBadgesProvider =
    StreamProvider.family<List<BadgeEntry>, String>((ref, childId) {
  if (childId.isEmpty) return Stream.value([]);

  return Supabase.instance.client
      .from('child_achievements')
      .stream(primaryKey: ['child_id', 'achievement_id'])
      .eq('child_id', childId)
      .asyncMap((earned) async {
    final master = await ref.watch(_achievementsMasterProvider.future);

    final Map<String, DateTime?> earnedMap = {
      for (final row in earned)
        row['achievement_id'] as String:
            parseDateSafely(row['unlocked_at']?.toString() ?? ''),
    };

    final entries = master.map((m) {
      final String id = m['id'] as String;
      return BadgeEntry(
        id: id,
        roleId: m['role_id'] as String? ?? '',
        titleId: m['title_id'] as String? ?? '',
        titleEn: m['title_en'] as String? ?? '',
        descriptionId: m['description_id'] as String? ?? '',
        descriptionEn: m['description_en'] as String? ?? '',
        icon: m['icon_url'] as String? ?? '🏅',
        unlockedAt: earnedMap[id],
      );
    }).toList();

    // Terbuka duluan (terbaru duluan), baru yang masih terkunci.
    entries.sort((a, b) {
      if (a.isUnlocked != b.isUnlocked) return a.isUnlocked ? -1 : 1;
      if (a.isUnlocked && b.isUnlocked) {
        return b.unlockedAt!.compareTo(a.unlockedAt!);
      }
      return 0;
    });
    return entries;
  });
});
