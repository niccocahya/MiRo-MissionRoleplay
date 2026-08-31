import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Skor 5 skill anak (kognitif, empati, kreativitas, literasi, motorik) dari
/// tabel `child_stats`, realtime. Dipakai di halaman Progress (radar chart)
/// dan Home (rekomendasi misi berdasarkan skill terlemah).
final childStatsProvider = StreamProvider.family<Map<String, dynamic>, String>((
  ref,
  childId,
) {
  if (childId.isEmpty) return Stream.value({});
  return Supabase.instance.client
      .from('child_stats')
      .stream(primaryKey: ['child_id'])
      .eq('child_id', childId)
      .map((event) => event.isNotEmpty ? event.first : {});
});

/// role_id yang paling cocok dilatih berdasarkan skill anak yang PALING
/// RENDAH saat ini. Pemetaan skill->role sengaja 1-ke-1 (bukan pakai daftar
/// skill di role_visuals.dart yang beririsan antar role) supaya hasilnya
/// selalu satu jawaban yang jelas, bukan ambigu.
const Map<String, String> kSkillToRecommendedRole = {
  'cognitive_score': 'chef',
  'empathy_score': 'doctor',
  'creativity_score': 'artist',
  'literacy_score': 'teacher',
  'motoric_score': 'athlete',
};

String recommendedRoleFromStats(Map<String, dynamic> stats) {
  if (stats.isEmpty) return 'chef';

  String lowestKey = 'cognitive_score';
  double lowestValue = double.infinity;
  for (final key in kSkillToRecommendedRole.keys) {
    final value = (stats[key] ?? 0).toDouble();
    if (value < lowestValue) {
      lowestValue = value;
      lowestKey = key;
    }
  }
  return kSkillToRecommendedRole[lowestKey]!;
}
