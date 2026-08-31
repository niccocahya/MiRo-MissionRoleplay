import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final notificationsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;

  if (user == null) return [];

  final response = await supabase
      .from('notifications')
      .select()
      .eq('parent_id', user.id)
      .order('created_at', ascending: false);

  return List<Map<String, dynamic>>.from(response);
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
