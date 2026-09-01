import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Jawaban kuisioner awal (minat, gaya belajar, fokus pengembangan, waktu
/// bermain) yang diisi orang tua pas onboarding — sebelumnya cuma pernah
/// ditulis ke tabel `questionnaires` sekali dan nggak pernah ditampilkan
/// lagi ke mana pun, jadi orang tua nggak bisa lihat lagi apa yang mereka
/// isi dulu.
final childQuestionnaireProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, childId) async {
  if (childId.isEmpty) return null;

  final response = await Supabase.instance.client
      .from('questionnaires')
      .select()
      .eq('child_id', childId)
      .order('created_at', ascending: false)
      .limit(1)
      .maybeSingle();

  return response;
});

/// Label waktu bermain yang dipilih orang tua pas onboarding — id-nya
/// disimpan mentah ("15_min", "1_5_hours", dst.) jadi butuh dipetakan
/// balik ke teks yang enak dibaca.
const Map<String, String> kTimePreferenceLabelsId = {
  '15_min': "15 menit",
  '30_min': "30 menit",
  '1_hour': "1 jam",
  '1_5_hours': "1,5 jam",
  '2_hours': "2 jam",
};

const Map<String, String> kTimePreferenceLabelsEn = {
  '15_min': "15 min",
  '30_min': "30 min",
  '1_hour': "1 hour",
  '1_5_hours': "1.5 hours",
  '2_hours': "2 hours",
};

String timePreferenceLabel(String? id, String lang) {
  if (id == null) return '-';
  final map = lang == 'id' ? kTimePreferenceLabelsId : kTimePreferenceLabelsEn;
  return map[id] ?? id;
}
