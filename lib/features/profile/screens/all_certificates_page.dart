import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// PASTIKAN IMPORT INI SESUAI
import 'certificate_detail_page.dart';
import '../data/certificate_provider.dart';
import '../../../core/router/app_page_transition.dart';
import '../../../core/providers/child_provider.dart';
import '../../../core/providers/language_provider.dart'; // Wajib panggil otak bahasa
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/responsive.dart';
import '../../../shared/widgets/app_state_views.dart';
import '../../../shared/widgets/back_button.dart'; // Wajib panggil tombol kembali estetik

// allCertificatesProvider & certificateProgressProvider sekarang di
// ../data/certificate_provider.dart (dulu ada salinan identik dari
// keduanya di sini DAN di profile_page.dart — versi certificateProgress
// di sini pakai FutureProvider fetch-sekali, beda dari versi StreamProvider
// realtime di profile_page.dart, jadi progres di halaman ini nggak update
// otomatis pas ada lencana baru terbuka sampai halaman dibuka ulang).

// ==========================================
// DICTIONARY (KAMUS BAHASA)
// ==========================================
const Map<String, Map<String, String>> _t = {
  'en': {
    'title': "All Certificates",
    'err_cert': "Failed to load certificates: ",
    'empty_cert': "No certificate data available yet.",
    'err_prog': "Failed to load progress: ",
    'done_full': "Completed!",
    'done_suffix': "Completed",
  },
  'id': {
    'title': "Semua Sertifikat",
    'err_cert': "Gagal memuat sertifikat: ",
    'empty_cert': "Belum ada data sertifikat.",
    'err_prog': "Gagal memuat progres: ",
    'done_full': "Selesai!",
    'done_suffix': "Selesai",
  },
};

class AllCertificatesPage extends ConsumerWidget {
  // Constructor kosong karena data ditarik langsung dari Provider
  const AllCertificatesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 0. Tarik Bahasa
    final lang = ref.watch(languageProvider);
    final texts = _t[lang] ?? _t['en']!;

    // 1. Dapatkan ID Anak dari Provider Utama
    final childDataAsync = ref.watch(childDataProvider);
    final String childId = childDataAsync.value?['id'] ?? '';

    // 2. Dapatkan Master Sertifikat & Progress
    final allCertsAsync = ref.watch(allCertificatesProvider);
    final certProgressAsync = ref.watch(certificateProgressProvider(childId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // HEADER SEDERHANA
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 40, 24, 16),
            child: Row(
              children: [
                CustomBackButton(onPressed: () => Navigator.of(context).pop()),
                const SizedBox(width: 8),
                Text(
                  texts['title']!,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // LIST SEMUA SERTIFIKAT DINAMIS
          Expanded(
            child: allCertsAsync.when(
              loading: () => const AppLoading(),
              error: (e, s) => AppErrorView(message: "${texts['err_cert']}$e"),
              data: (allCerts) {
                if (allCerts.isEmpty) {
                  return AppEmptyState(message: texts['empty_cert']!);
                }

                return certProgressAsync.when(
                  loading: () => const AppLoading(),
                  error: (e, s) => AppErrorView(message: "${texts['err_prog']}$e"),
                  data: (roleCounts) {
                    return ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: allCerts.length,
                      itemBuilder: (context, index) {
                        final cert = allCerts[index];
                        final String roleId = cert['role_id'] ?? '';
                        final int dbUnlockedBadges = roleCounts[roleId] ?? 0;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.of(context, rootNavigator: true).push(
                                appPageRoute(
                                  CertificateDetailPage(certData: cert),
                                ),
                              );
                            },
                            child: _buildAchievementCard(
                              context,
                              cert,
                              dbUnlockedBadges,
                              texts,
                              lang, // Kirim bahasa aktif ke dalam fungsi
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // WIDGET KARTU ACHIEVEMENT (100% POLOS TANPA TUMPUKAN PUTIH)
  Widget _buildAchievementCard(
    BuildContext context,
    Map<String, dynamic> cert,
    int dbUnlockedCount,
    Map<String, String> texts,
    String lang,
  ) {
    // Kita buat cardWidth statis proporsional, misalnya 88% dari layar
    final cardWidth = context.screenWidth * 0.88;

    final totalBadges = (cert['badges'] as List).length;
    final unlockedCount = dbUnlockedCount > totalBadges
        ? totalBadges
        : dbUnlockedCount;

    // Gunakan Teks Dinamis
    final String statusText = unlockedCount >= totalBadges
        ? texts['done_full']!
        : "$unlockedCount/$totalBadges ${texts['done_suffix']}";

    final previewBadges = (cert['badges'] as List).take(3).toList();

    // Tentukan Teks Label berdasarkan bahasa
    final String roleLabel = lang == 'id'
        ? cert['roleLabelId']
        : cert['roleLabelEn'];
    final String cardTitle = lang == 'id'
        ? cert['cardTitleId']
        : cert['cardTitleEn'];

    // Langsung tembak Center dan Container kartunya aja!
    return Center(
      child: Container(
        width: cardWidth,
        height: 180,
        decoration: BoxDecoration(
          // BACKGROUND DINAMIS DARI DATABASE
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors:
                cert['gradient'] ??
                [AppColors.primary, AppColors.primaryLight],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // GAMBAR PINGUIN BACKGROUND (TRANSPARAN DI KANAN BAWAH)
            Positioned(
              bottom: -10,
              right: -10,
              child: Opacity(
                opacity: 0.2, // Watermark transparan
                child: Image.asset(
                  cert['characterImg'],
                  width: 140,
                  fit: BoxFit.contain,
                  errorBuilder: (c, e, s) => const SizedBox(),
                ),
              ),
            ),

            // FOTO ANAK KANAN ATAS
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.accentTint,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Text("👦🏻", style: TextStyle(fontSize: 24)),
              ),
            ),

            // KONTEN TEKS & BADGE
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kategori Role Dinamis
                  Text(
                    roleLabel,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      shadows: const [
                        Shadow(color: Colors.black45, blurRadius: 2),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Judul Sertifikat Dinamis
                  SizedBox(
                    width: cardWidth * 0.6,
                    child: Text(
                      cardTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                        shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  const Spacer(),

                  // Teks "X/Y Selesai" (Dinamis)
                  Text(
                    statusText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                    ),
                  ),
                  const SizedBox(height: 6),

                  // BARISAN BADGE DI KIRI BAWAH
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      ...previewBadges.asMap().entries.map((entry) {
                        int index = entry.key;
                        var badge = entry.value;
                        bool isUnlocked = index < unlockedCount;

                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isUnlocked
                                  ? Colors.white.withValues(alpha: 0.8)
                                  : Colors.white.withValues(alpha: 0.2),
                            ),
                            color: isUnlocked
                                ? Colors.white.withValues(alpha: 0.2)
                                : Colors.white.withValues(alpha: 0.05),
                          ),
                          alignment: Alignment.center,
                          child: isUnlocked
                              ? Text(
                                  badge['emoji'] ?? '🏅',
                                  style: const TextStyle(fontSize: 16),
                                )
                              : const Icon(
                                  Icons.lock,
                                  size: 16,
                                  color: Colors.white38,
                                ),
                        );
                      }),
                      if (totalBadges > previewBadges.length)
                        const Padding(
                          padding: EdgeInsets.only(left: 4, bottom: 8),
                          child: Text(
                            "...",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(color: Colors.black45, blurRadius: 4),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
