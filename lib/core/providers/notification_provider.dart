import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Dulu ini FutureProvider (nembak sekali doang pas provider pertama
/// dibuat / manual di-invalidate). Notifikasi baru yang kebentuk lewat
/// trigger DB (misi selesai, lencana baru, dst.) sementara halaman
/// Notifikasi lagi kebuka nggak bakal keliatan sampai user keluar-masuk
/// halaman lagi. Sekarang StreamProvider, sama kayak childDataProvider/
/// childrenListProvider — otomatis dorong data baru tiap ada perubahan.
final notificationsProvider = StreamProvider<List<Map<String, dynamic>>>((
  ref,
) {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return Stream.value([]);

  return Supabase.instance.client
      .from('notifications')
      .stream(primaryKey: ['id'])
      .eq('parent_id', user.id)
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

/// Tandai SEMUA notifikasi sudah dibaca sekaligus. Balikin `true`/`false`
/// (dulu nggak balikin apa-apa dan gagalnya ditelan diem-diem di sisi
/// provider — caller nggak punya cara ngasih tau user kalau operasinya
/// gagal, mis. lagi offline).
final markAllNotificationsReadProvider = Provider(
  (ref) => () async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return false;
    try {
      await Supabase.instance.client
          .from('notifications')
          .update({'is_read': true})
          .eq('parent_id', user.id)
          .eq('is_read', false);
      ref.invalidate(notificationsProvider);
      return true;
    } catch (_) {
      return false;
    }
  },
);

/// Hapus SEMUA notifikasi milik parent yang login. Balikin `true`/`false`
/// (lihat catatan di markAllNotificationsReadProvider di atas).
final clearAllNotificationsProvider = Provider(
  (ref) => () async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return false;
    try {
      await Supabase.instance.client
          .from('notifications')
          .delete()
          .eq('parent_id', user.id);
      ref.invalidate(notificationsProvider);
      return true;
    } catch (_) {
      return false;
    }
  },
);
