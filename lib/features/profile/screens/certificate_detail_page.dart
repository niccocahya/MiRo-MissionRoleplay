import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/child_provider.dart';
import '../../../core/providers/language_provider.dart'; // Wajib narik provider bahasa
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/back_button.dart'; // Wajib narik custom back button

// ==========================================
// PROVIDER DINAMIS: MENGHITUNG BADGE KHUSUS ROLE INI
// ==========================================
final roleUnlockedCountProvider = FutureProvider.autoDispose.family<int, String>((
  ref,
  params,
) async {
  final parts = params.split('|');
  if (parts.length != 2) return 0;

  final childId = parts[0];
  final roleId = parts[1]; // Sekarang isinya beneran "chef", bukan "cert_chef"

  if (childId.isEmpty || roleId.isEmpty) return 0;

  try {
    final supabase = Supabase.instance.client;

    // Tarik semua achievement milik anak ini (Sama persis kayak di All Certificates)
    final response = await supabase
        .from('child_achievements')
        .select('achievements_master!inner(role_id)')
        .eq('child_id', childId);

    // Hitung manual di Dart agar kebal dari bug filter Supabase
    int count = 0;
    for (var item in response) {
      final dbRoleId =
          item['achievements_master']['role_id']?.toString() ?? 'unknown';
      if (dbRoleId == roleId) {
        count++;
      }
    }

    return count;
  } catch (e) {
    debugPrint("Gagal memuat jumlah lencana role $roleId: $e");
    return 0;
  }
});

// ==========================================
// DICTIONARY (KAMUS BAHASA DETAIL SERTIFIKAT)
// ==========================================
const Map<String, Map<String, String>> _t = {
  'en': {
    'title': "Your Certificate",
    'category_fallback': "CERTIFICATE CATEGORY",
    'done_full': "Completed!",
    'done_suffix': "Completed",
    'support_missions': "SUPPORT MISSIONS",
    'download': "Download",
    'share': "Share",
    'locked_warning': "Complete all missions to unlock the certificate!",
    'save_success': "Certificate saved to gallery! 🎉",
    'save_fail': "Failed to save the certificate.",
    'share_text': "Look at my child's certificate on MiRO! 🐧✨",
  },
  'id': {
    'title': "Sertifikat Anda",
    'category_fallback': "KATEGORI SERTIFIKAT",
    'done_full': "Selesai!",
    'done_suffix': "Selesai",
    'support_missions': "MISI PENDUKUNG",
    'download': "Unduh",
    'share': "Bagikan",
    'locked_warning': "Selesaikan semua misi untuk membuka sertifikat!",
    'save_success': "Sertifikat berhasil disimpan ke Galeri! 🎉",
    'save_fail': "Gagal menyimpan sertifikat.",
    'share_text': "Yuk lihat sertifikat anakku di MiRO! 🐧✨",
  },
};

class CertificateDetailPage extends ConsumerWidget {
  final Map<String, dynamic> certData;

  // Bukan const lagi — butuh field GlobalKey buat nge-capture banner
  // sertifikat pas Unduh/Bagikan dipencet (GlobalKey() bukan ekspresi
  // const).
  CertificateDetailPage({super.key, required this.certData});

  final GlobalKey _certificateKey = GlobalKey();

  Future<Uint8List?> _captureCertificate() async {
    try {
      final boundary = _certificateKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint("Gagal mengambil gambar sertifikat: $e");
      return null;
    }
  }

  Future<void> _downloadCertificate(
    BuildContext context,
    Map<String, String> texts,
  ) async {
    final bytes = await _captureCertificate();
    if (bytes == null) return;
    if (!context.mounted) return;
    try {
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(
        '${tempDir.path}/MiRO_Sertifikat_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await tempFile.writeAsBytes(bytes);

      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) await Gal.requestAccess();
      await Gal.putImage(tempFile.path);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(texts['save_success']!), backgroundColor: AppColors.success),
      );
    } catch (e) {
      debugPrint("Gagal menyimpan sertifikat: $e");
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(texts['save_fail']!), backgroundColor: AppColors.danger),
      );
    }
  }

  Future<void> _shareCertificate(
    BuildContext context,
    Map<String, String> texts,
  ) async {
    final bytes = await _captureCertificate();
    if (bytes == null) return;
    final tempDir = await getTemporaryDirectory();
    final file = File(
      '${tempDir.path}/miro_certificate_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(bytes);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: texts['share_text']!),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 0. Tarik bahasa dari provider
    final lang = ref.watch(languageProvider);
    final texts = _t[lang] ?? _t['en']!;

    // 1. Dapatkan ID Anak & NAMA dari Provider Utama
    final childDataAsync = ref.watch(childDataProvider);
    final childData = childDataAsync.value ?? {};
    final String childId = childData['id'] ?? '';
    final String childName = childData['name'] ?? "Anak";

    // 2. TENTUKAN ROLE ID
    final String roleId = certData['role_id'] ?? 'unknown';

    // 3. Tarik data jumlah lencana yang sudah terbuka dari Database!
    final unlockedCountAsync = ref.watch(
      roleUnlockedCountProvider('$childId|$roleId'),
    );
    final int dbUnlockedCount = unlockedCountAsync.value ?? 0;

    // LOGIC CHECK DINAMIS
    final List badges = certData['badges'] ?? [];
    final int totalBadges = badges.length;

    // Cegah angka melebihi batas maksimal lencana yang ada di desain
    final int unlockedCount = dbUnlockedCount > totalBadges
        ? totalBadges
        : dbUnlockedCount;
    final bool isComplete = unlockedCount >= totalBadges;

    // Gunakan Teks Dinamis untuk "Selesai"
    final String statusText = isComplete
        ? texts['done_full']!
        : "$unlockedCount/$totalBadges ${texts['done_suffix']}";

    // Tentukan Teks Label & Title berdasarkan bahasa
    final String roleLabel = lang == 'id'
        ? certData['roleLabelId'] ?? texts['category_fallback']!
        : certData['roleLabelEn'] ?? texts['category_fallback']!;
    final String cardTitle = lang == 'id'
        ? certData['cardTitleId'] ?? 'Sertifikat'
        : certData['cardTitleEn'] ?? 'Certificate';

    // Ambil maksimal 3 badge untuk di-preview di kartu utama
    final previewBadges = badges.take(3).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      // NAVBAR OTOMATIS HILANG DI SINI (Scaffold Fullscreen)
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // HEADER DENGAN BACK BUTTON BARU
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 40, 24, 16),
              child: Row(
                children: [
                  CustomBackButton(
                    onPressed: () =>
                        Navigator.of(context).pop(), // Kembali ke List Semua
                  ),
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

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    roleLabel,
                    style: TextStyle(
                      color: AppColors.primary.withValues(alpha: 0.5),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ===============================================
                  // BANNER SERTIFIKAT UTAMA
                  // ===============================================
                  // Dibungkus RepaintBoundary biar bannernya bisa
                  // di-screenshot buat tombol Unduh/Bagikan di bawah
                  // (dulu 2 tombol itu keliatan aktif tapi onPressed-nya
                  // kosongan, nggak ngapa-ngapain sama sekali).
                  RepaintBoundary(
                    key: _certificateKey,
                    child: Container(
                    width: double.infinity,
                    height: 240,
                    decoration: BoxDecoration(
                      // MENGGUNAKAN GRADIENT BAWAAN ROLE DARI DB
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors:
                            certData['gradient'] ??
                            [AppColors.primary, AppColors.primaryLight],
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 15,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        // 1. PINGUIN BACKGROUND DI KANAN
                        Positioned(
                          bottom: -30,
                          right: -20,
                          child: Opacity(
                            opacity: 0.25, // Transparan agar tidak nabrak text
                            child: Image.asset(
                              certData['characterImg'],
                              width: 180,
                              fit: BoxFit.contain,
                              errorBuilder: (c, e, s) => const SizedBox(),
                            ),
                          ),
                        ),

                        // 2. FOTO ANAK & NAMA DI TENGAH-KANAN
                        Align(
                          alignment: const Alignment(
                            0.75,
                            0.0,
                          ), // Center-Right Alignment
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 65,
                                height: 65,
                                decoration: BoxDecoration(
                                  color: AppColors.accentTint,
                                  borderRadius: BorderRadius.circular(
                                    16,
                                  ), // Frame Kotak Rounded
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ), // Frame Putih
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: const Text(
                                  "👦🏻",
                                  style: TextStyle(fontSize: 32),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                childName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black45,
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // 3. ROLE & JUDUL DI KIRI ATAS
                        Positioned(
                          top: 24,
                          left: 24,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                roleLabel,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              SizedBox(
                                width:
                                    180, // Dibatasi agar tidak numpuk sama foto
                                child: Text(
                                  cardTitle,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    height: 1.2,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black45,
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // 4. BADGES & TEKS PROGRESS DI KIRI BAWAH
                        Positioned(
                          bottom: 24,
                          left: 24,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                statusText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black45,
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: previewBadges.asMap().entries.map((
                                  entry,
                                ) {
                                  int index = entry.key;
                                  var badge = entry.value;
                                  bool isUnlocked = index < unlockedCount;

                                  return Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isUnlocked
                                            ? Colors.white.withValues(
                                                alpha: 0.8,
                                              )
                                            : Colors.white.withValues(
                                                alpha: 0.2,
                                              ),
                                        width: 1.5,
                                      ),
                                      color: isUnlocked
                                          ? Colors.white.withValues(alpha: 0.2)
                                          : Colors.white.withValues(
                                              alpha: 0.05,
                                            ),
                                      boxShadow: isUnlocked
                                          ? const [
                                              BoxShadow(
                                                color: Colors.black12,
                                                blurRadius: 4,
                                                offset: Offset(0, 2),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    alignment: Alignment.center,
                                    child: isUnlocked
                                        ? Text(
                                            badge['emoji'] ?? '🏅',
                                            style: const TextStyle(
                                              fontSize: 16,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.lock,
                                            size: 16,
                                            color: Colors.white38,
                                          ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ===============================================
                  // TOMBOL UNDUH & BAGIKAN
                  // ===============================================
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          texts['download']!,
                          AppColors.accent,
                          isComplete,
                          isComplete ? () => _downloadCertificate(context, texts) : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildActionButton(
                          texts['share']!,
                          AppColors.primary,
                          isComplete,
                          isComplete ? () => _shareCertificate(context, texts) : null,
                        ),
                      ),
                    ],
                  ),
                  if (!isComplete)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        texts['locked_warning']!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.red.shade400,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                  const SizedBox(height: 40),

                  // ===============================================
                  // GRID LENCANA EKSPLORASI (DETAIL) DENGAN STYLING BARU
                  // ===============================================
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 20,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              texts['support_missions']!,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                            Text(
                              "$unlockedCount/$totalBadges",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 32),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                childAspectRatio: 0.7,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 24,
                              ),
                          itemCount: badges.length,
                          itemBuilder: (context, index) {
                            final b = badges[index];

                            // LOGIC DINAMIS: Cek apakah index ini masuk hitungan unlocked
                            final bool isLocked = index >= unlockedCount;

                            // LOGIC DINAMIS: Nama badge menyesuaikan bahasa
                            final String badgeName = lang == 'id'
                                ? b['nameId']
                                : b['nameEn'];

                            return Column(
                              children: [
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        // STYLING BARU: Warna dasar lencana sedikit transparan untuk kesan premium
                                        color: isLocked
                                            ? Colors.grey.shade100
                                            : b['color'].withValues(
                                                alpha: 0.15,
                                              ),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isLocked
                                              ? Colors.grey.shade300
                                              : b['color'].withValues(
                                                  alpha: 0.8,
                                                ),
                                          width: 2,
                                        ),
                                        // Efek glowing jika sudah terbuka
                                        boxShadow: isLocked
                                            ? null
                                            : [
                                                BoxShadow(
                                                  color: b['color'].withValues(
                                                    alpha: 0.3,
                                                  ),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                      ),
                                      alignment: Alignment.center,
                                      child: isLocked
                                          ? const Icon(
                                              Icons.lock,
                                              size: 24,
                                              color: Colors.grey,
                                            )
                                          : Text(
                                              b['emoji'] ?? '🏅',
                                              style: const TextStyle(
                                                fontSize: 28,
                                              ),
                                            ),
                                    ),
                                    if (isLocked)
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.lock,
                                            size: 10,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  badgeName, // SEKARANG NAMA LENCANA MENGIKUTI BAHASA!
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    Color color,
    bool enabled,
    VoidCallback? onPressed,
  ) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        disabledBackgroundColor: Colors.grey.shade300,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
        elevation: enabled ? 4 : 0,
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }
}
