import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// PASTIKAN PATH IMPORT INI SESUAI DENGAN STRUKTUR FOLDER KAMU
import './screens/all_certificates_page.dart';
import './screens/certificate_detail_page.dart';
import './data/certificate_provider.dart';
import '../../core/providers/language_provider.dart';
import '../../core/providers/child_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/responsive.dart';
import '../../shared/widgets/app_bottom_sheet.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_state_views.dart';

// ==========================================
// PROVIDER REAL-TIME 1: MENGHITUNG TOTAL MISI SELESAI
// ==========================================
final totalMissionsCompletedProvider = StreamProvider.family<int, String>((
  ref,
  childId,
) {
  if (childId.isEmpty) return Stream.value(0);

  final supabase = Supabase.instance.client;
  return supabase
      .from('mission_logs')
      .stream(primaryKey: ['id'])
      .eq('child_id', childId)
      .map((event) {
        return event.where((row) => row['status'] == 'completed').length;
      });
});

// ==========================================
// PROVIDER REAL-TIME 2: MENGHITUNG TOTAL LENCANA (ACHIEVEMENTS)
// ==========================================
final unlockedAchievementsCountProvider = StreamProvider.family<int, String>((
  ref,
  childId,
) {
  if (childId.isEmpty) return Stream.value(0);

  final supabase = Supabase.instance.client;
  return supabase
      .from('child_achievements')
      .stream(
        primaryKey: ['child_id', 'achievement_id'],
      ) // Primary key komposit
      .eq('child_id', childId)
      .map((event) => event.length);
});

// allCertificatesProvider sekarang di ./data/certificate_provider.dart
// (dulu di sini juga ada 1 salinan lagi di all_certificates_page.dart —
// dua provider dengan nama identik, isi identik, di file berbeda).

// ==========================================
// PROVIDER REAL-TIME: MENGHITUNG LENCANA YANG SUDAH DIBUKA PER ROLE
// ==========================================
final certificateProgressProvider =
    StreamProvider.family<Map<String, int>, String>((ref, childId) {
      if (childId.isEmpty) return Stream.value({});

      final supabase = Supabase.instance.client;
      return supabase
          .from('child_achievements')
          .stream(
            primaryKey: ['child_id', 'achievement_id'],
          ) // Stream data achievement
          .eq('child_id', childId)
          .asyncMap((achievements) async {
            if (achievements.isEmpty) return <String, int>{};

            try {
              // Trik Join Manual untuk Stream: Ambil semua ID role dari master
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

// ==========================================
// DICTIONARY (KAMUS BAHASA PROFIL)
// ==========================================
const Map<String, Map<String, String>> _t = {
  'en': {
    'parent_prefix': "Parent",
    'parent_greeting': "Parent of",
    'edit_profile': "EDIT PROFILE",
    'your_plan': "YOUR PLAN",
    'free_user': "Free User",
    'monthly_plan': "MONTHLY PLAN",
    'plan_desc': "Access to 3\nbeginner missions",
    'plan_detail': "Plan Details",
    'upgrade_plan': "Upgrade Plan",
    'certificate_title': "Certificates of Achievement",
    'view_all_cert': "View all certificates",
    'current_progress': "CURRENT PROGRESS",
    'badges': "Badges",
    'done': "Completed!",
    'done_suffix': "Completed",
    'quick_stats': "Quick Statistics",
    'total_missions': "TOTAL MISSIONS",
    'total_exp': "TOTAL EXP",
    'level': "LEVEL",
    'menu_child_data': "Child Data",
    'menu_settings': "Settings",
    'menu_help': "Help Center",
    'logout': "Log Out",
    'edit_profile_title': "Edit Profile",
    'parent_name_label': "Parent's Name",
    'child_name_label': "Child's Name",
    'btn_save': "Save Changes",
    'update_success': "Profile updated successfully!",
    'lang_setting': "App Language",
    'notif_setting': "Push Notifications",
    'contact_us': "Contact Support",
    'child_detail_title': "Child Details",
    'age': "Years Old",
    'default_child': "Child",
    'err_logout': "Failed to log out: ",
    'err_save': "Failed to save: ",
    'help_desc':
        "The MiRO CS team is ready to help you anytime. Please contact us via Email or WhatsApp.",
  },
  'id': {
    'parent_prefix': "Ibu/Bapak",
    'parent_greeting': "Orang Tua dari",
    'edit_profile': "EDIT PROFIL",
    'your_plan': "PAKETMU",
    'free_user': "Pengguna Gratis",
    'monthly_plan': "PAKET BULANAN",
    'plan_desc': "Akses ke 3\nmisi pemula",
    'plan_detail': "Detail Paket",
    'upgrade_plan': "Tingkatkan Paket",
    'certificate_title': "Sertifikat Pencapaian",
    'view_all_cert': "Lihat semua sertifikat",
    'current_progress': "PROGRES SAAT INI",
    'badges': "Lencana",
    'done': "Selesai!",
    'done_suffix': "Selesai",
    'quick_stats': "Statistik Cepat",
    'total_missions': "TOTAL MISI",
    'total_exp': "TOTAL EXP",
    'level': "LEVEL",
    'menu_child_data': "Data Anak",
    'menu_settings': "Pengaturan",
    'menu_help': "Pusat Bantuan",
    'logout': "Keluar",
    'edit_profile_title': "Edit Profil",
    'parent_name_label': "Nama Ibu/Bapak",
    'child_name_label': "Nama Anak",
    'btn_save': "Simpan Perubahan",
    'update_success': "Profil berhasil diperbarui!",
    'lang_setting': "Bahasa Aplikasi",
    'notif_setting': "Notifikasi Aplikasi",
    'contact_us': "Hubungi Bantuan",
    'child_detail_title': "Detail Anak",
    'age': "Tahun",
    'default_child': "Anak",
    'err_logout': "Gagal logout: ",
    'err_save': "Gagal menyimpan: ",
    'help_desc':
        "Tim CS MiRO siap membantu Bunda & Ayah kapan saja. Silakan hubungi kami via Email atau WhatsApp.",
  },
};

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  void _navigateToFullscreen(Widget screen) {
    Navigator.of(
      context,
      rootNavigator: true,
    ).push(MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _handleLogout(Map<String, String> texts) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AppLoading(),
    );

    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        Navigator.pop(context);
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${texts['err_logout']}$e"),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  void _showEditProfileModal(
    Map<String, String> texts,
    String currentParentName,
    String currentChildName,
    String childId,
  ) {
    final parentController = TextEditingController(text: currentParentName);
    final childController = TextEditingController(text: currentChildName);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            bool isLoading = false;

            Future<void> saveProfile() async {
              if (parentController.text.trim().isEmpty ||
                  childController.text.trim().isEmpty) {
                return;
              }

              setModalState(() => isLoading = true);

              try {
                final supabase = Supabase.instance.client;
                await supabase.auth.updateUser(
                  UserAttributes(
                    data: {'full_name': parentController.text.trim()},
                  ),
                );
                if (childId.isNotEmpty) {
                  await supabase
                      .from('children')
                      .update({'name': childController.text.trim()})
                      .eq('id', childId);
                }

                if (mounted) {
                  ref.invalidate(childDataProvider);
                  setState(() {});
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(texts['update_success']!),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  setModalState(() => isLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("${texts['err_save']}$e"),
                      backgroundColor: AppColors.danger,
                    ),
                  );
                }
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: AppBottomSheet(
                title: texts['edit_profile_title']!,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      texts['parent_name_label']!,
                      style: AppTextStyles.bodyBold(
                        color: AppColors.primary.withValues(alpha: 0.7),
                      ).copyWith(fontSize: 12),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: parentController,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md + 4),
                    Text(
                      texts['child_name_label']!,
                      style: AppTextStyles.bodyBold(
                        color: AppColors.primary.withValues(alpha: 0.7),
                      ).copyWith(fontSize: 12),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: childController,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : saveProfile,
                        style: ElevatedButton.styleFrom(
                          disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.5),
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          elevation: 2,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              )
                            : Text(texts['btn_save']!, style: AppTextStyles.button().copyWith(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showChildDataModal(
    Map<String, String> texts,
    Map<String, dynamic> childData,
  ) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return AppBottomSheet(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.accentTint,
                child: Text("👦🏻", style: TextStyle(fontSize: 40)),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                childData['name'] ?? texts['default_child']!,
                style: AppTextStyles.h1().copyWith(fontSize: 24),
              ),
              Text(
                "${childData['age'] ?? '-'} ${texts['age']}",
                style: AppTextStyles.bodyLarge(
                  color: AppColors.primary.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMiniStatBox(
                    "⭐",
                    texts['level']!,
                    "${childData['current_level'] ?? 1}",
                  ),
                  _buildMiniStatBox(
                    "🔥",
                    "Streak",
                    "${childData['current_streak'] ?? 0}",
                  ),
                  _buildMiniStatBox("✨", "XP", "${childData['total_xp'] ?? 0}"),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMiniStatBox(String icon, String label, String value) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm + 4),
          decoration: BoxDecoration(
            color: AppColors.background,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Text(icon, style: const TextStyle(fontSize: 24)),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(value, style: AppTextStyles.bodyBold().copyWith(fontSize: 16)),
        Text(
          label,
          style: AppTextStyles.caption(
            color: AppColors.primary.withValues(alpha: 0.6),
          ).copyWith(fontWeight: FontWeight.bold, fontSize: 10),
        ),
      ],
    );
  }

  void _showSettingsModal(Map<String, String> texts, String currentLang) {
    bool isNotifEnabled = true;

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AppBottomSheet(
              title: texts['menu_settings']!,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Setting Notifikasi
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.primaryTint,
                        borderRadius: BorderRadius.circular(AppSpacing.sm + 4),
                      ),
                      child: const Icon(
                        Icons.notifications_active_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    title: Text(texts['notif_setting']!, style: AppTextStyles.bodyBold()),
                    trailing: Switch(
                      value: isNotifEnabled,
                      activeColor: AppColors.accent,
                      onChanged: (val) =>
                          setModalState(() => isNotifEnabled = val),
                    ),
                  ),
                  const Divider(),

                  // Setting Bahasa
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.accentTint,
                        borderRadius: BorderRadius.circular(AppSpacing.sm + 4),
                      ),
                      child: const Icon(Icons.language_rounded, color: AppColors.gold),
                    ),
                    title: Text(texts['lang_setting']!, style: AppTextStyles.bodyBold()),
                    trailing: DropdownButton<String>(
                      value: currentLang,
                      underline: const SizedBox(),
                      icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
                      style: AppTextStyles.bodyBold(),
                      items: const [
                        DropdownMenuItem(value: 'id', child: Text("🇮🇩 IND")),
                        DropdownMenuItem(value: 'en', child: Text("🇬🇧 ENG")),
                      ],
                      onChanged: (newLang) {
                        if (newLang != null) {
                          ref
                              .read(languageProvider.notifier)
                              .setLanguage(newLang);
                          Navigator.pop(ctx);
                        }
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showHelpCenterDialog(Map<String, String> texts) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        contentPadding: const EdgeInsets.all(AppSpacing.lg),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: const BoxDecoration(color: AppColors.primaryTint, shape: BoxShape.circle),
              child: const Icon(Icons.support_agent_rounded, size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(texts['menu_help']!, style: AppTextStyles.h2()),
            const SizedBox(height: AppSpacing.sm + 4),
            Text(
              texts['help_desc']!,
              textAlign: TextAlign.center,
              style: AppTextStyles.body().copyWith(fontSize: 13),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(ctx),
              icon: const Icon(Icons.mail_rounded, color: Colors.white, size: 18),
              label: Text("cs@miroapp.com", style: AppTextStyles.button()),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _calculateLevel(int totalXp) {
    if (totalXp < 100) return 1;
    if (totalXp < 250) return 2;
    if (totalXp < 500) return 3;
    return 4;
  }

  @override
  Widget build(BuildContext context) {
    // Tarik Bahasa Aktif
    final lang = ref.watch(languageProvider);
    final texts = _t[lang] ?? _t['en']!;

    final childDataAsync = ref.watch(childDataProvider);
    final childData = childDataAsync.value ?? {};
    final String childId = childData['id'] ?? '';
    final String childName = childData['name'] ?? texts['default_child']!;
    final int totalXp = childData['total_xp'] ?? 0;
    final int childLevel = _calculateLevel(totalXp);

    final currentUser = Supabase.instance.client.auth.currentUser;
    final String parentName =
        currentUser?.userMetadata?['full_name'] ??
        currentUser?.email?.split('@')[0] ??
        "Guest";

    final totalMissionsAsync = ref.watch(
      totalMissionsCompletedProvider(childId),
    );

    // MENARIK DATA SERTIFIKAT LANGSUNG DARI DATABASE
    final allCertsAsync = ref.watch(allCertificatesProvider);

    final int totalMissions = totalMissionsAsync.value ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 120),
          child: ResponsiveCenter(
            maxWidth: 640,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderProfile(context, texts, parentName, childName, childId),
                _buildSubscriptionSection(context, texts, parentName),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: context.pageHPadding),
                        child: Text(texts['certificate_title']!, style: AppTextStyles.h1().copyWith(fontSize: 22)),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // ===============================================
                      // CAROUSEL SERTIFIKAT (UI BARU: BISA DI-SWIPE)
                      // ===============================================
                      allCertsAsync.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.all(AppSpacing.lg),
                          child: AppLoading(),
                        ),
                        error: (e, s) => const SizedBox(),
                        data: (certs) {
                          if (certs.isEmpty) return const SizedBox();

                          return SizedBox(
                            height: 190, // Beri sedikit extra height untuk shadow
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              itemCount: certs.length,
                              // Tambahkan padding awal dan akhir agar estetik
                              padding: EdgeInsets.symmetric(horizontal: context.pageHPadding),
                              itemBuilder: (context, index) {
                                final cert = certs[index];

                                return Consumer(
                                  builder: (context, ref, child) {
                                    final String roleId = cert['role_id'] ?? '';
                                    final certProgressAsync = ref.watch(
                                      certificateProgressProvider(childId),
                                    );

                                    final int unlockedBadges =
                                        certProgressAsync.value?[roleId] ?? 0;

                                    return Padding(
                                      // Spasi antar sertifikat
                                      padding: const EdgeInsets.only(right: AppSpacing.md),
                                      child: GestureDetector(
                                        onTap: () => _navigateToFullscreen(
                                          CertificateDetailPage(certData: cert),
                                        ),
                                        child: _buildEstetikAchievementCard(
                                          context,
                                          texts,
                                          cert,
                                          unlockedBadges,
                                          lang, // MELEMPAR BAHASA AKTIF
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: AppSpacing.md + 4),
                      Center(
                        child: GestureDetector(
                          onTap: () =>
                              _navigateToFullscreen(const AllCertificatesPage()),
                          child: Container(
                            padding: const EdgeInsets.only(bottom: 2),
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: AppColors.primary, width: 2),
                              ),
                            ),
                            child: Text(
                              texts['view_all_cert']!,
                              style: AppTextStyles.bodyBold().copyWith(fontSize: 13),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildQuickStats(context, texts, totalMissions, totalXp, childLevel),

                _buildMenuList(context, texts, childData, lang),

                _buildLogoutButton(context, texts),
                const SizedBox(height: AppSpacing.xl + AppSpacing.sm),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderProfile(
    BuildContext context,
    Map<String, String> texts,
    String parentName,
    String childName,
    String childId,
  ) {
    final hPad = context.pageHPadding;
    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, AppSpacing.xl, hPad, AppSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${texts['parent_prefix']} $parentName",
                  style: AppTextStyles.h1().copyWith(letterSpacing: -0.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "${texts['parent_greeting']} $childName",
                  style: AppTextStyles.bodyBold(
                    color: AppColors.primary.withValues(alpha: 0.6),
                  ).copyWith(fontSize: 14),
                ),
                const SizedBox(height: AppSpacing.sm + 4),
                _buildEditButton(texts, parentName, childName, childId),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          _buildAvatarStack(),
        ],
      ),
    );
  }

  Widget _buildEditButton(
    Map<String, String> texts,
    String parentName,
    String childName,
    String childId,
  ) {
    return GestureDetector(
      onTap: () => _showEditProfileModal(texts, parentName, childName, childId),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + 4, vertical: AppSpacing.xs + 2),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.sm + 10),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.edit, color: AppColors.primary, size: 12),
            const SizedBox(width: AppSpacing.xs + 2),
            Text(
              texts['edit_profile']!,
              style: AppTextStyles.caption(color: AppColors.primary).copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarStack() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.accentTint,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))],
      ),
      alignment: Alignment.center,
      child: const Text("👩🏻", style: TextStyle(fontSize: 36)),
    );
  }

  Widget _buildSubscriptionSection(
    BuildContext context,
    Map<String, String> texts,
    String parentName,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.pageHPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            texts['your_plan']!,
            style: AppTextStyles.bodyBold(
              color: AppColors.primary.withValues(alpha: 0.7),
            ).copyWith(fontSize: 11, letterSpacing: 1.5),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            height: 150,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF4b4b4b), Color(0xFF6e6e6e), Color(0xFFa3a3a3)],
              ),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))],
            ),
            child: Stack(
              children: [
                Positioned(
                  top: AppSpacing.md,
                  right: AppSpacing.md + 4,
                  child: Text(
                    "MIRO",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                Positioned(
                  top: -50,
                  right: -50,
                  child: Transform.rotate(
                    angle: 0.2,
                    child: Container(
                      width: 150,
                      height: 300,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.accentTint,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        alignment: Alignment.center,
                        child: const Text("👩🏻", style: TextStyle(fontSize: 20)),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        "${texts['parent_prefix']} $parentName",
                        style: AppTextStyles.h3(color: Colors.white).copyWith(fontSize: 18),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Text(
                            texts['free_user']!,
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Icon(Icons.arrow_forward_ios, color: Colors.white.withValues(alpha: 0.7), size: 10),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.verified, color: AppColors.primary, size: 16),
                  const SizedBox(width: AppSpacing.sm),
                  Text(texts['monthly_plan']!, style: AppTextStyles.bodyBold()),
                ],
              ),
              Text(
                texts['plan_desc']!,
                textAlign: TextAlign.right,
                style: AppTextStyles.caption(
                  color: AppColors.primary.withValues(alpha: 0.6),
                ).copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm + 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
                    elevation: 2,
                  ),
                  child: Text(texts['plan_detail']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: AppSpacing.sm + 4),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm + 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
                    elevation: 4,
                  ),
                  child: Text(texts['upgrade_plan']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =====================================================
  // KARTU ACHIEVEMENT ESTETIK UNTUK CAROUSEL PROFILE
  // =====================================================
  Widget _buildEstetikAchievementCard(
    BuildContext context,
    Map<String, String> texts,
    Map<String, dynamic> cert,
    int dbUnlockedBadges,
    String lang,
  ) {
    // Lebar kartu statis agar konsisten saat di-scroll
    final cardWidth = context.screenWidth * 0.8;

    final previewBadges = (cert['badges'] as List).take(3).toList();
    final totalBadges = (cert['badges'] as List).length;

    int displayUnlocked = dbUnlockedBadges > totalBadges
        ? totalBadges
        : dbUnlockedBadges;

    // Status Teks (Dinamis dari Dictionary)
    final String statusText = displayUnlocked >= totalBadges
        ? texts['done']!
        : "$displayUnlocked/$totalBadges ${texts['done_suffix']}";

    // Judul & Kategori Dinamis
    final String roleLabel = lang == 'id'
        ? cert['roleLabelId']
        : cert['roleLabelEn'];
    final String cardTitle = lang == 'id'
        ? cert['cardTitleId']
        : cert['cardTitleEn'];

    return SizedBox(
      height: 180,
      width: cardWidth,
      child: Container(
        width: cardWidth,
        height: 180,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: cert['gradient'] ?? [AppColors.primary, AppColors.primaryLight],
          ),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // GAMBAR PINGUIN BACKGROUND (TRANSPARAN DI KANAN BAWAH)
            Positioned(
              bottom: -10,
              right: -10,
              child: Opacity(
                opacity: 0.2, // Super transparan jadi watermark
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
              top: AppSpacing.md,
              right: AppSpacing.md,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.accentTint,
                  borderRadius: BorderRadius.circular(AppSpacing.sm + 4),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                ),
                alignment: Alignment.center,
                child: const Text("👦🏻", style: TextStyle(fontSize: 24)),
              ),
            ),

            // KONTEN TEKS & BADGE
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
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
                      shadows: const [Shadow(color: Colors.black45, blurRadius: 2)],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),

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

                  // Teks "0/3 Selesai" Dinamis
                  Text(
                    statusText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs + 2),

                  // BARISAN BADGE DI KIRI BAWAH
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      ...previewBadges.asMap().entries.map((entry) {
                        int index = entry.key;
                        var badge = entry.value;
                        bool isUnlocked = index < displayUnlocked;

                        return Container(
                          margin: const EdgeInsets.only(right: AppSpacing.sm),
                          padding: const EdgeInsets.all(AppSpacing.sm),
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
                              ? Text(badge['emoji'] ?? '🏅', style: const TextStyle(fontSize: 16))
                              : const Icon(Icons.lock, size: 16, color: Colors.white38),
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
                              shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
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

  Widget _buildQuickStats(
    BuildContext context,
    Map<String, String> texts,
    int totalMissions,
    int totalXp,
    int level,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.pageHPadding, vertical: AppSpacing.sm + 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(texts['quick_stats']!, style: AppTextStyles.h1().copyWith(fontSize: 22)),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _buildStatCard(totalMissions.toString(), texts['total_missions']!),
              const SizedBox(width: AppSpacing.md),
              _buildStatCard(totalXp.toString(), texts['total_exp']!),
              const SizedBox(width: AppSpacing.md),
              _buildStatCard(level.toString(), texts['level']!),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Expanded(
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.sm + 4),
        child: SizedBox(
          height: 100 - (AppSpacing.sm + 4) * 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: AppTextStyles.h1(color: AppColors.accent).copyWith(fontSize: 28),
              ),
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppTextStyles.caption(color: AppColors.primary).copyWith(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuList(
    BuildContext context,
    Map<String, String> texts,
    Map<String, dynamic> childData,
    String currentLang,
  ) {
    return Padding(
      padding: EdgeInsets.all(context.pageHPadding),
      child: Column(
        children: [
          _buildMenuItem(
            texts['menu_child_data']!,
            Icons.child_care_rounded,
            () => _showChildDataModal(texts, childData),
          ),
          _buildMenuItem(
            texts['menu_settings']!,
            Icons.settings_rounded,
            () => _showSettingsModal(texts, currentLang),
          ),
          _buildMenuItem(
            texts['menu_help']!,
            Icons.help_outline_rounded,
            () => _showHelpCenterDialog(texts),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(String title, IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        leading: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.primaryTint,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        title: Text(title, style: AppTextStyles.bodyBold().copyWith(fontSize: 15)),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          color: AppColors.primary.withValues(alpha: 0.5),
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, Map<String, String> texts) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.pageHPadding),
      child: ElevatedButton(
        onPressed: () => _handleLogout(texts),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
          elevation: 4,
        ),
        child: Text(texts['logout']!, style: AppTextStyles.button().copyWith(fontSize: 18)),
      ),
    );
  }
}
