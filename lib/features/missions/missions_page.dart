import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// JALUR IMPORT
import 'data/mission_provider.dart';
import 'screens/mission_path_screen.dart';
import '../../core/providers/language_provider.dart'; // Wajib narik provider bahasa

class MissionsPage extends ConsumerWidget {
  const MissionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Tarik Bahasa Asli dari Database/Lokal
    final lang = ref.watch(languageProvider);

    // 2. Tarik Data Misi dari Database
    final missionsAsync = ref.watch(missionsProvider);

    // Dictionary Papan Nama Role (Dinamis)
    final Map<String, Map<String, String>> roleTitles = {
      'en': {
        'chef': 'Chef',
        'doctor': 'Doctor',
        'artist': 'Artist',
        'athlete': 'Athlete',
        'teacher': 'Teacher',
      },
      'id': {
        'chef': 'Koki',
        'doctor': 'Dokter',
        'artist': 'Pelukis',
        'athlete': 'Atlet',
        'teacher': 'Guru',
      },
    };

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FB),
      body: missionsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF0A264F)),
        ),
        error: (err, stack) => Center(
          child: Text(
            lang == 'id' ? "Masalah koneksi: $err" : "Connection error: $err",
          ),
        ),
        data: (missions) {
          if (missions.isEmpty) {
            return Center(
              child: Text(
                lang == 'id'
                    ? "Data misi tidak ditemukan"
                    : "Mission data not found",
              ),
            );
          }

          // Ambil data misi pertama untuk membaca roleId-nya
          final firstMission = missions.first;
          final String roleId = firstMission.roleId;

          // BUG FIXED: Pakai String mutlak sebagai fallback agar Dart tidak nangis
          final String roleName =
              roleTitles[lang]?[roleId] ??
              (lang == 'id' ? 'Penjelajah' : 'Explorer');

          // LANGSUNG RENDER PATH SCREEN DENGAN DATA DINAMIS
          return MissionPathScreen(roleId: roleId, roleName: roleName);
        },
      ),
    );
  }
}
