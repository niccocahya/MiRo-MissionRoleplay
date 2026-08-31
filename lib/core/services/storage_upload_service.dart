import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Satu tempat buat semua upload ke Supabase Storage.
///
/// Sebelumnya upload foto ditulis manual & terpisah di 2 layar
/// (`identify_page.dart` buat foto profil, `mission_play_screen.dart` buat
/// foto jurnal misi) — dan keduanya menaruh file LANGSUNG di root bucket
/// (`user_photo`) atau di satu folder yang sama rata `USER_JOURNAL/` (semua
/// user numpuk di folder yang sama). Itu bikin storage nggak bisa dikasih
/// RLS per-user yang bener.
///
/// Sekarang semua file disimpan di folder `{user_id}/...` biar policy
/// storage bisa cek "apakah folder pertama di path = auth.uid() milik user
/// yang login" — lihat migration `scope_storage_policies_per_user`.
class StorageUploadService {
  static StorageFileApi _bucket(String name) =>
      Supabase.instance.client.storage.from(name);

  static String? get _uid => Supabase.instance.client.auth.currentUser?.id;

  /// Upload foto profil anak/orang tua ke bucket `user_photo`.
  static Future<String> uploadProfilePhoto(File file) async {
    final uid = _uid ?? 'anonymous';
    final ext = p.extension(file.path);
    final fileName = "profile_${DateTime.now().millisecondsSinceEpoch}$ext";
    final path = '$uid/$fileName';

    await _bucket('user_photo').upload(path, file);
    return _bucket('user_photo').getPublicUrl(path);
  }

  /// Upload foto langkah misi (jurnal) ke bucket `mission-assets`.
  static Future<String> uploadMissionStepPhoto({
    required String missionId,
    required int stepIndex,
    required File file,
  }) async {
    final uid = _uid ?? 'anonymous';
    final ext = p.extension(file.path);
    final fileName =
        "mission_${missionId}_step_${stepIndex}_${DateTime.now().millisecondsSinceEpoch}$ext";
    final path = '$uid/$fileName';

    await _bucket('mission-assets').upload(path, file);
    return _bucket('mission-assets').getPublicUrl(path);
  }
}
