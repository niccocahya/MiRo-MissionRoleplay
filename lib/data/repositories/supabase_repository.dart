import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider supaya Service ini bisa dipanggil di mana saja pakai Riverpod
final supabaseRepositoryProvider = Provider((ref) => SupabaseRepository());

/// Dilempar kalau `submitOnboardingData` gagal DI TENGAH JALAN (setelah
/// baris `children`-nya sendiri berhasil kebuat, tapi salah satu dari 3
/// insert berikutnya gagal -- mis. koneksi putus). Bawa `childId` yang
/// SUDAH kebuat itu supaya pemanggil (identify_page.dart) bisa nyoba lagi
/// pakai id yang sama persis, bukan bikin baris `children` baru lagi.
class OnboardingSubmitException implements Exception {
  final String? childId;
  final Object cause;
  OnboardingSubmitException(this.childId, this.cause);
  @override
  String toString() => cause.toString();
}

class SupabaseRepository {
  final _client = Supabase.instance.client;

  /// Fungsi untuk mendaftarkan profil anak dan kuesionernya.
  /// Sekarang mengembalikan [String] berupa childId agar bisa digunakan di UI.
  ///
  /// Dulu ini 4 insert BERURUTAN tanpa jaring pengaman -- kalau salah satu
  /// dari 3 insert TERAKHIR gagal (koneksi putus dkk), baris `children`-nya
  /// udah kadung kebuat, tapi errornya cuma dilempar generik ke layar
  /// (pesan "Gagal menyimpan data") tanpa bawa info anak mana yang udah
  /// setengah jadi itu. Orang tua yang nyoba submit ULANG dari layar yang
  /// sama bakal manggil fungsi ini dari NOL lagi -- insert `children` BARU
  /// lagi, bikin baris anak duplikat/hantu (nama sama, questionnaire/stats
  /// kosong) tiap kali percobaannya gagal separuh jalan. Sekarang terima
  /// `existingChildId` opsional (dioper balik dari `OnboardingSubmitException`
  /// di percobaan sebelumnya) buat lanjutin dari titik gagalnya, dan 3
  /// insert terakhir pakai upsert (idempoten -- constraint uniknya udah
  /// dicek: questionnaires unique di child_id, child_stats PK child_id,
  /// child_role_progress PK (child_id, role_id)) biar aman diulang.
  Future<String> submitOnboardingData({
    required String name,
    required int age,
    required List<String> interests,
    required List<String> learningStyles,
    required List<String> parentGoals,
    required String timePreference,
    String? avatarUrl, // 🔥 PARAMETER BARU DITAMBAHKAN DI SINI
    String? existingChildId,
  }) async {
    String? childId = existingChildId;
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) throw Exception("User belum login!");

      // 1. Simpan ke tabel children (dilewati kalau ini percobaan ulang
      //    dan baris-nya udah ada dari percobaan sebelumnya).
      if (childId == null) {
        final childResponse = await _client
            .from('children')
            .insert({
              'parent_id': currentUser.id,
              // Dipangkas lagi di sini, bukan cuma di layar pemanggilnya --
              // ini satu-satunya pintu masuk baris `children`, jadi lebih
              // aman kalau aturannya dipegang di sini juga.
              'name': name.trim(),
              'age': age,
              'avatar_url': avatarUrl, // 🔥 FOTO DISIMPAN KE KOLOM INI
            })
            .select()
            .single();
        childId = childResponse['id'];
      }

      // 2. Simpan ke tabel questionnaires
      await _client.from('questionnaires').upsert({
        'child_id': childId,
        'interests': interests,
        'learning_styles': learningStyles,
        'parent_goals': parentGoals,
        'time_preference': timePreference,
      }, onConflict: 'child_id');

      // 3. Inisialisasi Stats Radar Chart (Biar awal-awal tidak null/error)
      await _client.from('child_stats').upsert({
        'child_id': childId,
        // Kolom lainnya akan mengikuti default value di database (misal: 0)
      }, onConflict: 'child_id');

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

      await _client
          .from('child_role_progress')
          .upsert(progressData, onConflict: 'child_id,role_id');

      // 5. Kembalikan ID anak yang baru dibuat
      return childId!;
    } catch (e) {
      // Log error secara detail untuk debugging
      debugPrint("Error in submitOnboardingData: $e");
      throw OnboardingSubmitException(childId, e);
    }
  }
}
