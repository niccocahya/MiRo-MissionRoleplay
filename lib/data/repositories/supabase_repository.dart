import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider supaya Service ini bisa dipanggil di mana saja pakai Riverpod
final supabaseRepositoryProvider = Provider((ref) => SupabaseRepository());

class SupabaseRepository {
  final _client = Supabase.instance.client;

  /// Fungsi untuk mendaftarkan profil anak dan kuesionernya.
  /// Sekarang mengembalikan [String] berupa childId agar bisa digunakan di UI.
  Future<String> submitOnboardingData({
    required String name,
    required int age,
    required List<String> interests,
    required List<String> learningStyles,
    required List<String> parentGoals,
    required String timePreference,
    String? avatarUrl, // 🔥 PARAMETER BARU DITAMBAHKAN DI SINI
  }) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) throw Exception("User belum login!");

      // 1. Simpan ke tabel children
      // Menggunakan .select().single() untuk mendapatkan data yang baru saja dimasukkan
      final childResponse = await _client
          .from('children')
          .insert({
            'parent_id': currentUser.id,
            'name': name,
            'age': age,
            'avatar_url': avatarUrl, // 🔥 FOTO DISIMPAN KE KOLOM INI
          })
          .select()
          .single();

      final String childId = childResponse['id'];

      // 2. Simpan ke tabel questionnaires
      await _client.from('questionnaires').insert({
        'child_id': childId,
        'interests': interests,
        'learning_styles': learningStyles,
        'parent_goals': parentGoals,
        'time_preference': timePreference,
      });

      // 3. Inisialisasi Stats Radar Chart (Biar awal-awal tidak null/error)
      await _client.from('child_stats').insert({
        'child_id': childId,
        // Kolom lainnya akan mengikuti default value di database (misal: 0)
      });

      // 4. Inisialisasi progres peta misi (Batch Insert lebih disarankan)
      final roles = ['doctor', 'chef', 'artist', 'teacher', 'athlete'];

      // Membuat list data untuk dimasukkan sekaligus (lebih cepat daripada loop await)
      final List<Map<String, dynamic>> progressData = roles
          .map(
            (role) => {
              'child_id': childId,
              'role_id': role,
              'unlocked_level': 1,
            },
          )
          .toList();

      await _client.from('child_role_progress').insert(progressData);

      // 5. Kembalikan ID anak yang baru dibuat
      return childId;
    } catch (e) {
      // Log error secara detail untuk debugging
      debugPrint("Error in submitOnboardingData: $e");
      throw Exception("Gagal menyimpan data: $e");
    }
  }
}
