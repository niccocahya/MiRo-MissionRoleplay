import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Total misi yang udah beneran selesai (bukan cuma diambil) buat 1 anak,
/// realtime. Dulu didefinisikan langsung di dalam profile_page.dart --
/// dipindah ke sini biar bisa dipakai provider/halaman lain juga (mis.
/// pemicu app-rating prompt di Home) tanpa import silang antar-fitur.
final totalMissionsCompletedProvider = StreamProvider.family<int, String>((
  ref,
  childId,
) {
  if (childId.isEmpty) return Stream.value(0);

  final supabase = Supabase.instance.client;
  return supabase
      .from('mission_logs')
      .stream(primaryKey: ['id'])
      .eq('child_id', childId)
      .map((event) {
        return event.where((row) => row['status'] == 'completed').length;
      });
});
