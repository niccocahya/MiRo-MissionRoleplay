import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Refleksi (perasaan orang tua/anak + catatan singkat) yang diisi di
/// MissionReflectionScreen abis nyelesein misi -- dulu data ini CUMA
/// PERNAH DITULIS, nggak pernah ditampilin lagi ke mana pun setelahnya.
/// Whole screen buat ngumpulin data yang cukup personal/emosional
/// (gimana perasaan Bunda/Ayah & anak pas ngerjain misi ini), tapi
/// jawabannya nggak pernah kelihatan lagi -- dead end.
final missionReflectionProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, missionLogId) async {
  if (missionLogId.isEmpty) return null;

  return Supabase.instance.client
      .from('reflections')
      .select()
      .eq('mission_log_id', missionLogId)
      .order('created_at', ascending: false)
      .limit(1)
      .maybeSingle();
});
