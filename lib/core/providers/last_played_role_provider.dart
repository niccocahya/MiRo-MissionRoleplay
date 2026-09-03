import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Role yang TERAKHIR KALI beneran dimainkan -- dulu file ini namanya
/// "last VIEWED role" dan nyimpen ulang tiap kali tab Misi dibuka, atau
/// tiap kali role-nya diganti lewat pemilih. Itu bikin "default"-nya
/// gampang meleset: anak/orang tua yang cuma ngintip-ngintip role lain
/// (tanpa beneran mulai misinya) bakal ngegeser default berikutnya ke
/// role yang cuma dilirik doang, bukan yang beneran terakhir dimainkan.
///
/// Sekarang cuma di-update di SATU tempat: tombol "Mulai Misi" di
/// mission_intro_screen.dart, tepat pas misi beneran mulai dimainkan.
/// Sekadar buka tab Misi atau geser-geser pemilih role nggak lagi
/// ngubah nilai ini.
class LastPlayedRoleNotifier extends Notifier<String?> {
  // Key SharedPreferences lama dipertahankan (bukan diganti ikut nama
  // baru) biar preferensi yang udah kesimpen di device orang nggak ilang
  // gara-gara migrasi nama semata.
  static const _key = 'last_viewed_role_id';

  @override
  String? build() {
    _load();
    return null;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString(_key);
  }

  Future<void> setRole(String roleId) async {
    if (state == roleId) return;
    state = roleId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, roleId);
  }
}

final lastPlayedRoleProvider =
    NotifierProvider<LastPlayedRoleNotifier, String?>(
  () => LastPlayedRoleNotifier(),
);
