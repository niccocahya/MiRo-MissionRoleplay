import 'package:supabase_flutter/supabase_flutter.dart';

/// Hapus akun sendiri (dan semua data anak yang menempel) secara
/// permanen — dulu cuma bisa lewat email manual ke CS walau Privacy
/// Policy udah janji bisa kapan saja. Client biasa nggak bisa hapus baris
/// `auth.users` miliknya sendiri (butuh service role), jadi ini manggil
/// edge function `delete-account` yang jalan dengan hak akses lebih
/// tinggi tapi cuma buat akun si pemanggil sendiri (diverifikasi dari
/// JWT-nya, bukan dari input apapun yang dikontrol client).
class AccountDeletionService {
  static Future<void> deleteAccount() async {
    final response = await Supabase.instance.client.functions.invoke(
      'delete-account',
    );

    if (response.status != 200) {
      final error = (response.data is Map) ? response.data['error'] : null;
      throw Exception(error ?? 'Gagal menghapus akun (status ${response.status})');
    }

    await Supabase.instance.client.auth.signOut();
  }
}
