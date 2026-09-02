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

  /// Hapus foto profil lama dari bucket `user_photo`. Nama file di atas
  /// selalu unik (ada timestamp), jadi tiap ganti foto bikin file BARU --
  /// dulu file lamanya nggak pernah dihapus, numpuk terus selamanya di
  /// storage tiap kali orang tua ganti foto anaknya. Dipanggil setelah
  /// avatar_url baru berhasil ke-set, dikasih URL lama yang mau dibuang.
  static Future<void> deleteProfilePhoto(String? publicUrl) async {
    if (publicUrl == null || publicUrl.isEmpty) return;
    const marker = '/user_photo/';
    final idx = publicUrl.indexOf(marker);
    if (idx == -1) return; // Bukan file dari bucket ini (mis. URL eksternal).

    final path = publicUrl.substring(idx + marker.length);
    try {
      await _bucket('user_photo').remove([path]);
    } catch (_) {
      // Nggak fatal -- foto barunya udah kepasang, ini cuma bersih-bersih.
    }
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
