import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/role_visuals.dart';
import '../../../core/theme/app_colors.dart';

/// Semua sertifikat (master data) + metadata visualnya (gradient, label
/// role, lencana yang dibutuhkan).
///
/// Sebelumnya provider ini (query + logika gradient/label per role) ditulis
/// ulang persis sama di 2 file terpisah (`profile_page.dart` dan
/// `all_certificates_page.dart`) — bahkan dengan nama provider yang identik,
/// cuma "menang" secara diam-diam karena Dart mengutamakan deklarasi lokal.
/// Sekarang cuma di sini, dipakai oleh keduanya.
final allCertificatesProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  try {
    final supabase = Supabase.instance.client;
    final certsRes = await supabase.from('certifications_master').select();
    final achRes = await supabase.from('achievements_master').select();

    Map<String, dynamic> achMap = {};
    for (var a in achRes) {
      achMap[a['id']] = a;
    }

    List<Map<String, dynamic>> mappedCerts = [];

    for (var c in certsRes) {
      String role = c['role_id'];
      List<dynamic> reqIds = c['required_achievement_ids'] ?? [];

      // Warna badge dari role_visuals.dart (sumber tunggal); gradient
      // 2-stop & label "CILIK"/"LITTLE" ini spesifik buat kartu sertifikat.
      final Color badgeColor =
          (roleVisualById(role) ?? kUnknownRoleVisual).badgeColor;
      List<Color> gradient;
      String roleLabelId = "";
      String roleLabelEn = "";

      if (role == 'chef') {
        gradient = [const Color(0xFFA5CBEB), badgeColor];
        roleLabelId = "KOKI CILIK";
        roleLabelEn = "LITTLE CHEF";
      } else if (role == 'doctor') {
        gradient = [const Color(0xFFB9E4C9), badgeColor];
        roleLabelId = "DOKTER CILIK";
        roleLabelEn = "LITTLE DOCTOR";
      } else if (role == 'artist') {
        gradient = [AppColors.gold, badgeColor];
        roleLabelId = "PELUKIS CILIK";
        roleLabelEn = "LITTLE ARTIST";
      } else if (role == 'athlete') {
        gradient = [const Color(0xFFFFCC80), badgeColor];
        roleLabelId = "ATLET CILIK";
        roleLabelEn = "LITTLE ATHLETE";
      } else if (role == 'teacher') {
        gradient = [const Color(0xFF80CBC4), badgeColor];
        roleLabelId = "GURU CILIK";
        roleLabelEn = "LITTLE TEACHER";
      } else {
        gradient = [const Color(0xFFB0BEC5), badgeColor];
        roleLabelId = role.toUpperCase();
        roleLabelEn = role.toUpperCase();
      }

      List<Map<String, dynamic>> badges = [];
      for (var reqId in reqIds) {
        var ach = achMap[reqId];
        if (ach != null) {
          badges.add({
            'id': ach['id'],
            'nameId': ach['title_id'],
            'nameEn': ach['title_en'],
            'emoji': ach['icon_url'],
            'color': badgeColor,
          });
        }
      }

      mappedCerts.add({
        'id': c['id'],
        'role_id': role,
        'roleLabelId': roleLabelId,
        'roleLabelEn': roleLabelEn,
        'cardTitleId': c['title_id'],
        'cardTitleEn': c['title_en'],
        'characterImg': c['icon_url'],
        'gradient': gradient,
        'badges': badges,
      });
    }

    return mappedCerts;
  } catch (e) {
    debugPrint("Gagal memuat master sertifikat: $e");
    return [];
  }
});

/// Jumlah lencana yang sudah terbuka per role, buat progres sertifikat
/// ("3/5 lencana"). Sama seperti allCertificatesProvider di atas, dulu ada
/// DUA deklarasi top-level bernama sama persis di file terpisah
/// (profile_page.dart pakai StreamProvider realtime, all_certificates_page
/// .dart pakai FutureProvider fetch-sekali) -- masing-masing "menang" cuma
/// di file-nya sendiri. Akibatnya progres di halaman Profil update
/// realtime pas lencana baru kebuka, tapi halaman "Semua Sertifikat" tetap
/// nunjukin angka lama sampai di-buka ulang. Sekarang satu StreamProvider
/// di sini dipakai keduanya.
final certificateProgressProvider =
    StreamProvider.family<Map<String, int>, String>((ref, childId) {
      if (childId.isEmpty) return Stream.value({});

      final supabase = Supabase.instance.client;
      return supabase
          .from('child_achievements')
          .stream(primaryKey: ['child_id', 'achievement_id'])
          .eq('child_id', childId)
          .asyncMap((achievements) async {
            if (achievements.isEmpty) return <String, int>{};

            try {
              final achievementIds = achievements
                  .map((a) => a['achievement_id'])
                  .toSet()
                  .toList();
              final masterRes = await supabase
                  .from('achievements_master')
                  .select('id, role_id')
                  .inFilter('id', achievementIds);

              final masterMap = {
                for (var item in masterRes) item['id']: item['role_id'],
              };

              Map<String, int> roleCounts = {};
              for (var item in achievements) {
                final roleId =
                    masterMap[item['achievement_id']]?.toString() ?? 'unknown';
                roleCounts[roleId] = (roleCounts[roleId] ?? 0) + 1;
              }
              return roleCounts;
            } catch (e) {
              debugPrint("Gagal memuat progres sertifikat stream: $e");
              return <String, int>{};
            }
          });
    });
