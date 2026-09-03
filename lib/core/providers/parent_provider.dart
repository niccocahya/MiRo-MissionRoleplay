import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Nama orang tua, dibaca dari kolom `parents.full_name`.
///
/// SATU sumber kebenaran. Dulu nama orang tua kesimpen di DUA tempat yang
/// nggak pernah disinkron:
/// - tabel `parents.full_name` -- diisi pas registrasi, dibaca Home
/// - user metadata Supabase Auth (`userMetadata['full_name']`) -- ditulis
///   pas edit profil, dibaca layar Profil
///
/// Akibatnya: akun baru nampilin nama yang bener di Home tapi jatuh ke
/// potongan email di Profil (metadata-nya kosong, nggak pernah diisi pas
/// daftar); dan begitu namanya diedit, Profil ikut berubah tapi Home tetep
/// nampilin nama lama SELAMANYA. Sekarang dua-duanya baca dari sini, dan
/// edit profil nulis ke tabel `parents` (+ metadata, biar nggak basi).
///
/// Dulu provider ini juga ditaruh di dalam home_page.dart -- dipindah ke
/// sini karena sekarang dipakai lintas layar.
final parentNameProvider = FutureProvider<String>((ref) async {
  try {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return "";
    final res = await Supabase.instance.client
        .from('parents')
        .select('full_name')
        .eq('id', user.id)
        .maybeSingle();

    final String fromTable = (res?['full_name'] as String?)?.trim() ?? "";
    if (fromTable.isNotEmpty) return fromTable;

    // Cadangan buat akun lama yang namanya cuma sempat kesimpen di
    // metadata auth (sebelum edit profil ikut nulis ke tabel `parents`).
    final String fromMetadata =
        (user.userMetadata?['full_name'] as String?)?.trim() ?? "";
    if (fromMetadata.isNotEmpty) return fromMetadata;

    return user.email?.split('@').first ?? "";
  } catch (e) {
    return "";
  }
});
