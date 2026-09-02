import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'child_provider.dart';

/// Dulu ini FutureProvider (nembak sekali doang pas provider pertama
/// dibuat / manual di-invalidate). Notifikasi baru yang kebentuk lewat
/// trigger DB (misi selesai, lencana baru, dst.) sementara halaman
/// Notifikasi lagi kebuka nggak bakal keliatan sampai user keluar-masuk
/// halaman lagi. Sekarang StreamProvider, sama kayak childDataProvider/
/// childrenListProvider — otomatis dorong data baru tiap ada perubahan.
///
/// Di-scope per ANAK yang lagi aktif (bukan cuma per parent) -- tabel
/// `notifications` udah punya kolom `child_id` (ditambah pas kerjaan
/// multi-anak), tapi provider ini dulu nggak pernah makai kolom itu, jadi
/// kalau 1 akun parent punya >1 anak, notifikasi kedua/semua anaknya
/// kecampur jadi 1 feed nggak jelas punya siapa. RLS udah nge-scope ke
/// `parent_id = auth.uid()` di server, jadi filter `child_id` doang di
/// sini udah cukup aman -- `.stream()` cuma dukung 1 filter kolom, nggak
/// bisa nge-AND-in child_id+parent_id sekaligus.
final notificationsProvider = StreamProvider<List<Map<String, dynamic>>>((
  ref,
) {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return Stream.value([]);

  final childId = ref.watch(selectedChildIdProvider);
  if (childId == null || childId.isEmpty) return Stream.value([]);

  return Supabase.instance.client
      .from('notifications')
      .stream(primaryKey: ['id'])
      .eq('child_id', childId)
      .order('created_at', ascending: false);
});

/// Tandai satu notifikasi sudah dibaca. Sebelumnya kolom `is_read` cuma
/// pernah DIBACA dari database, nggak pernah ditulis balik dari app —
/// jadi titik biru "belum dibaca" nempel selamanya walau notifnya udah
/// dibuka.
final markNotificationReadProvider = Provider(
  (ref) => (String notifId) async {
    try {
      await Supabase.instance.client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notifId);
      ref.invalidate(notificationsProvider);
    } catch (_) {
      // Nggak fatal — kalau gagal, notifikasi cuma tetap kelihatan "belum dibaca".
    }
  },
);

/// Tandai SEMUA notifikasi ANAK YANG LAGI AKTIF sudah dibaca. Balikin
/// `true`/`false` (dulu nggak balikin apa-apa dan gagalnya ditelan
/// diem-diem di sisi provider — caller nggak punya cara ngasih tau user
/// kalau operasinya gagal, mis. lagi offline). Di-scope per child_id juga
/// (dulu per parent_id doang) -- kalau nggak, "Tandai semua dibaca" pas
/// lagi liat notifikasi anak A diem-diem ikut nandain punya anak B juga,
/// padahal yang B nggak pernah keliatan di layar ini.
final markAllNotificationsReadProvider = Provider(
  (ref) => () async {
    final user = Supabase.instance.client.auth.currentUser;
    final childId = ref.read(selectedChildIdProvider);
    if (user == null || childId == null || childId.isEmpty) return false;
    try {
      await Supabase.instance.client
          .from('notifications')
          .update({'is_read': true})
          .eq('parent_id', user.id)
          .eq('child_id', childId)
          .eq('is_read', false);
      ref.invalidate(notificationsProvider);
      return true;
    } catch (_) {
      return false;
    }
  },
);

/// Hapus SEMUA notifikasi ANAK YANG LAGI AKTIF. Balikin `true`/`false`
/// (lihat catatan di markAllNotificationsReadProvider di atas -- sama,
/// di-scope per child_id biar nggak diem-diem hapus punya anak lain).
final clearAllNotificationsProvider = Provider(
  (ref) => () async {
    final user = Supabase.instance.client.auth.currentUser;
    final childId = ref.read(selectedChildIdProvider);
    if (user == null || childId == null || childId.isEmpty) return false;
    try {
      await Supabase.instance.client
          .from('notifications')
          .delete()
          .eq('parent_id', user.id)
          .eq('child_id', childId);
      ref.invalidate(notificationsProvider);
      return true;
    } catch (_) {
      return false;
    }
  },
);
