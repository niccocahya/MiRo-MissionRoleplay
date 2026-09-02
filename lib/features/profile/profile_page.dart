import 'dart:async';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// PASTIKAN PATH IMPORT INI SESUAI DENGAN STRUKTUR FOLDER KAMU
import './screens/all_certificates_page.dart';
import './screens/certificate_detail_page.dart';
import './data/certificate_provider.dart';
import '../../core/router/app_page_transition.dart';
import '../../core/app_info.dart';
import '../../core/providers/language_provider.dart';
import '../../core/providers/child_provider.dart';
import '../../core/providers/child_questionnaire_provider.dart';
import '../../core/providers/profile_completeness_provider.dart';
import '../../core/providers/notification_prefs_provider.dart';
import '../../core/providers/text_size_provider.dart';
import '../../core/providers/theme_mode_provider.dart';
import '../../core/providers/streak_provider.dart';
import '../../core/utils/level_utils.dart';
import '../../core/services/account_deletion_service.dart';
import '../../core/services/data_export_service.dart';
import '../../core/services/storage_upload_service.dart';
import '../help/help_center_page.dart';
import '../legal/legal_page.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/responsive.dart';
import '../../shared/widgets/app_bottom_sheet.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_state_views.dart';
import '../../shared/widgets/coming_soon_badge.dart';

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

// allCertificatesProvider & certificateProgressProvider sekarang di
// ./data/certificate_provider.dart (dulu di sini juga ada 1 salinan lagi
// dari keduanya di all_certificates_page.dart — provider dengan nama
// identik di file berbeda, "Semua Sertifikat" pakai versi FutureProvider
// fetch-sekali jadi progresnya nggak update realtime kayak di sini).

// ==========================================
// DICTIONARY (KAMUS BAHASA PROFIL)
// ==========================================
const Map<String, Map<String, String>> _t = {
  'en': {
    'parent_prefix': "Parent",
    'parent_greeting': "Parent of",
    'edit_profile': "EDIT PROFILE",
    'completeness_title': "Profile",
    'completeness_missing_photo': "Add a profile photo",
    'completeness_missing_questionnaire': "Fill in interests & learning style",
    'completeness_action': "Complete it",
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
    'confirm_logout_title': "Log out?",
    'confirm_logout_desc': "You'll need to log in again to access this account.",
    'edit_profile_title': "Edit Profile",
    'parent_name_label': "Parent's Name",
    'child_name_label': "Child's Name",
    'btn_save': "Save Changes",
    'update_success': "Profile updated successfully!",
    'lang_setting': "App Language",
    'notif_setting': "Push Notifications",
    'display_setting': "Text Size",
    'theme_setting': "Theme",
    'account_setting': "Account",
    'change_email': "Change Email",
    'change_password': "Change Password",
    'current_email_label': "Current email",
    'new_email_label': "New email",
    'new_password_label': "New password",
    'confirm_password_label': "Confirm new password",
    'btn_update': "Update",
    'email_update_sent':
        "Check your new email inbox to confirm the change.",
    'password_updated': "Password updated successfully.",
    'err_update': "Failed to update: ",
    'err_password_mismatch': "Passwords don't match.",
    'err_password_short': "Password must be at least 6 characters.",
    'danger_zone': "Danger Zone",
    'download_data': "Download My Data",
    'download_data_desc': "Get a copy of everything saved under your account, as a JSON file.",
    'download_success': "Export ready — check your share sheet.",
    'delete_account': "Delete Account",
    'delete_account_desc': "Permanently deletes your account and all your children's data. This cannot be undone.",
    'delete_confirm_title': "Delete your account?",
    'delete_confirm_desc':
        "This permanently deletes your account, all children's profiles, mission history, photos, and chat history. This cannot be undone.",
    'delete_confirm_hint': "Type DELETE to confirm",
    'delete_confirm_word': "DELETE",
    'btn_delete': "Delete Permanently",
    'account_deleted': "Your account has been deleted.",
    'err_delete': "Failed to delete account: ",
    'about_setting': "About",
    'app_version': "App Version",
    'terms_of_service': "Terms of Service",
    'privacy_policy': "Privacy Policy",
    'open_source_licenses': "Open Source Licenses",
    'contact_us': "Contact Support",
    'child_detail_title': "Child Details",
    'age': "Years Old",
    'default_child': "Child",
    'onboarding_answers': "From the onboarding questionnaire",
    'q_interests': "Favorite activities",
    'q_learning_style': "Learning style",
    'q_dev_focus': "Development focus",
    'q_play_time': "Play time together",
    'q_no_data': "No questionnaire data yet.",
    'err_logout': "Failed to log out: ",
    'err_save': "Failed to save: ",
    'switch_child_title': "Switch Child",
    'add_child': "+ Add Child",
    'err_load_children': "Failed to load children: ",
    'current_child_badge': "Active",
  },
  'id': {
    'parent_prefix': "Ibu/Bapak",
    'parent_greeting': "Orang Tua dari",
    'edit_profile': "EDIT PROFIL",
    'completeness_title': "Profil",
    'completeness_missing_photo': "Tambahin foto profil",
    'completeness_missing_questionnaire': "Isi minat & gaya belajar",
    'completeness_action': "Lengkapi",
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
    'confirm_logout_title': "Keluar dari akun?",
    'confirm_logout_desc': "Kamu perlu login lagi buat masuk ke akun ini.",
    'edit_profile_title': "Edit Profil",
    'parent_name_label': "Nama Ibu/Bapak",
    'child_name_label': "Nama Anak",
    'btn_save': "Simpan Perubahan",
    'update_success': "Profil berhasil diperbarui!",
    'lang_setting': "Bahasa Aplikasi",
    'notif_setting': "Notifikasi Aplikasi",
    'display_setting': "Ukuran Teks",
    'theme_setting': "Tema",
    'account_setting': "Akun",
    'change_email': "Ganti Email",
    'change_password': "Ganti Password",
    'current_email_label': "Email saat ini",
    'new_email_label': "Email baru",
    'new_password_label': "Password baru",
    'confirm_password_label': "Konfirmasi password baru",
    'btn_update': "Perbarui",
    'email_update_sent':
        "Cek inbox email barumu buat konfirmasi perubahan.",
    'password_updated': "Password berhasil diperbarui.",
    'err_update': "Gagal memperbarui: ",
    'err_password_mismatch': "Password tidak cocok.",
    'err_password_short': "Password minimal 6 karakter.",
    'danger_zone': "Zona Berbahaya",
    'download_data': "Unduh Data Saya",
    'download_data_desc': "Dapatkan salinan semua data di akunmu dalam bentuk file JSON.",
    'download_success': "Ekspor siap — cek menu bagikan yang muncul.",
    'delete_account': "Hapus Akun",
    'delete_account_desc': "Menghapus akun dan semua data anak secara permanen. Nggak bisa dibatalin.",
    'delete_confirm_title': "Hapus akun kamu?",
    'delete_confirm_desc':
        "Ini bakal hapus akun, semua profil anak, riwayat misi, foto, dan riwayat chat secara PERMANEN. Nggak bisa dibatalin.",
    'delete_confirm_hint': "Ketik HAPUS buat konfirmasi",
    'delete_confirm_word': "HAPUS",
    'btn_delete': "Hapus Permanen",
    'account_deleted': "Akun kamu sudah dihapus.",
    'err_delete': "Gagal menghapus akun: ",
    'about_setting': "Tentang",
    'app_version': "Versi Aplikasi",
    'terms_of_service': "Syarat & Ketentuan",
    'privacy_policy': "Kebijakan Privasi",
    'open_source_licenses': "Lisensi Open Source",
    'contact_us': "Hubungi Bantuan",
    'child_detail_title': "Detail Anak",
    'age': "Tahun",
    'default_child': "Anak",
    'onboarding_answers': "Dari kuisioner awal (onboarding)",
    'q_interests': "Kegiatan favorit",
    'q_learning_style': "Gaya belajar",
    'q_dev_focus': "Fokus pengembangan",
    'q_play_time': "Waktu bermain bersama",
    'q_no_data': "Belum ada data kuisioner.",
    'err_logout': "Gagal logout: ",
    'err_save': "Gagal menyimpan: ",
    'switch_child_title': "Ganti Anak",
    'add_child': "+ Tambah Anak",
    'err_load_children': "Gagal memuat daftar anak: ",
    'current_child_badge': "Aktif",
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
    ).push(appPageRoute(screen));
  }

  /// Dulu tombol Log Out langsung nge-logout tanpa konfirmasi sama
  /// sekali — nggak konsisten sama Hapus Akun yang justru minta ketik
  /// "HAPUS" dulu. Logout emang nggak sedestruktif itu (tinggal login
  /// lagi), tapi tetep sayang kalau ke-pencet nggak sengaja.
  Future<void> _confirmLogout(Map<String, String> texts) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(texts['confirm_logout_title']!),
        content: Text(texts['confirm_logout_desc']!),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(texts['cancel'] ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              texts['logout']!,
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await _handleLogout(texts);
    }
  }

  Future<void> _handleLogout(Map<String, String> texts) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AppLoading(),
    );

    try {
      await Supabase.instance.client.auth.signOut();
      // Kalau nggak dibersihkan, device yang dipakai gonta-ganti akun
      // bisa "nyangkut" ke id anak akun sebelumnya begitu akun baru login.
      await ref.read(selectedChildIdProvider.notifier).clear();
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
                      style: TextStyle(
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
                      style: TextStyle(
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
    final String childId = childData['id'] ?? '';
    final String lang = ref.read(languageProvider);

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return AppBottomSheet(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
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
                    // Bukan `childData['current_level']` — kolom itu di DB
                    // nggak pernah ditulis balik, selalu nyangkut di angka
                    // default. Level SELALU dihitung dari XP, biar sama
                    // kaya yang ditampilin Home & Progress.
                    "${calculateLevel(childData['total_xp'] ?? 0)}",
                  ),
                  Consumer(
                    builder: (context, ref, _) {
                      // Sama alasannya kaya level — `current_streak` juga
                      // kolom mati, streak beneran dihitung live dari
                      // riwayat misi (lihat streakProvider).
                      final streakAsync = ref.watch(streakProvider(childId));
                      return _buildMiniStatBox(
                        "🔥",
                        "Streak",
                        "${streakAsync.value ?? 0}",
                      );
                    },
                  ),
                  _buildMiniStatBox("✨", "XP", "${childData['total_xp'] ?? 0}"),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              const Divider(),
              const SizedBox(height: AppSpacing.sm),
              Consumer(
                builder: (context, ref, _) {
                  final questAsync = ref.watch(
                    childQuestionnaireProvider(childId),
                  );
                  return questAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                      child: SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    error: (e, s) => const SizedBox(),
                    data: (quest) => _buildQuestionnaireSummary(
                      texts,
                      lang,
                      quest,
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        );
      },
    );
  }

  /// Ringkasan jawaban kuisioner onboarding (minat, gaya belajar, fokus
  /// pengembangan, waktu bermain) — sebelumnya data ini nggak pernah
  /// ditampilkan lagi ke orang tua setelah diisi sekali di awal.
  Widget _buildQuestionnaireSummary(
    Map<String, String> texts,
    String lang,
    Map<String, dynamic>? quest,
  ) {
    if (quest == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Text(
          texts['q_no_data']!,
          style: AppTextStyles.caption(color: AppColors.textSecondary),
        ),
      );
    }

    final interests = (quest['interests'] as List?)?.cast<String>() ?? [];
    final learningStyles =
        (quest['learning_styles'] as List?)?.cast<String>() ?? [];
    final parentGoals = (quest['parent_goals'] as List?)?.cast<String>() ?? [];
    final String playTime = timePreferenceLabel(
      quest['time_preference'] as String?,
      lang,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          texts['onboarding_answers']!,
          style: AppTextStyles.caption(
            color: AppColors.textMuted,
          ).copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        const SizedBox(height: AppSpacing.sm + 4),
        _buildQuestionnaireRow(
          "🎨",
          texts['q_interests']!,
          interests.isEmpty ? '-' : interests.join(', '),
        ),
        _buildQuestionnaireRow(
          "🧠",
          texts['q_learning_style']!,
          learningStyles.isEmpty ? '-' : learningStyles.join(', '),
        ),
        _buildQuestionnaireRow(
          "🎯",
          texts['q_dev_focus']!,
          parentGoals.isEmpty ? '-' : parentGoals.join(', '),
        ),
        _buildQuestionnaireRow("⏰", texts['q_play_time']!, playTime),
      ],
    );
  }

  Widget _buildQuestionnaireRow(String icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs + 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.caption(color: AppColors.textMuted),
                ),
                Text(value, style: AppTextStyles.bodyBold().copyWith(fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
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
                  // Setting Notifikasi per kategori — sebelumnya cuma 1
                  // saklar `bool` lokal yang nggak disimpan & nggak
                  // connect ke apa pun (hilang tiap modal ditutup).
                  Text(
                    texts['notif_setting']!.toUpperCase(),
                    style: AppTextStyles.caption().copyWith(fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Consumer(
                    builder: (context, ref, _) {
                      final muted = ref.watch(notificationPrefsProvider);
                      return Column(
                        children: kNotificationCategories.map((cat) {
                          final enabled = !muted.contains(cat.id);
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            title: Text(
                              cat.label(currentLang),
                              style: AppTextStyles.body().copyWith(fontSize: 13),
                            ),
                            trailing: Switch(
                              value: enabled,
                              activeThumbColor: AppColors.accent,
                              onChanged: (val) => ref
                                  .read(notificationPrefsProvider.notifier)
                                  .toggle(cat.id, val),
                            ),
                          );
                        }).toList(),
                      );
                    },
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
                      child: Icon(Icons.language_rounded, color: AppColors.gold),
                    ),
                    title: Text(texts['lang_setting']!, style: AppTextStyles.bodyBold()),
                    trailing: DropdownButton<String>(
                      value: currentLang,
                      underline: const SizedBox(),
                      icon: Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
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
                        }
                      },
                    ),
                  ),
                  const Divider(),

                  // Setting Ukuran Teks — sebelumnya nggak ada opsi
                  // aksesibilitas ukuran teks sama sekali.
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.successTint,
                        borderRadius: BorderRadius.circular(AppSpacing.sm + 4),
                      ),
                      child: Icon(Icons.format_size_rounded, color: AppColors.success),
                    ),
                    title: Text(texts['display_setting']!, style: AppTextStyles.bodyBold()),
                    trailing: Consumer(
                      builder: (context, ref, _) {
                        final current = ref.watch(textSizeProvider);
                        return DropdownButton<AppTextSize>(
                          value: current,
                          underline: const SizedBox(),
                          icon: Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
                          style: AppTextStyles.bodyBold(),
                          items: AppTextSize.values
                              .map((s) => DropdownMenuItem(value: s, child: Text(s.label(currentLang))))
                              .toList(),
                          onChanged: (size) {
                            if (size != null) {
                              ref.read(textSizeProvider.notifier).setSize(size);
                            }
                          },
                        );
                      },
                    ),
                  ),
                  const Divider(),

                  // Setting Tema (dark mode) — sebelumnya app cuma punya
                  // mode terang, nggak ada opsi sama sekali.
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.primaryTint,
                        borderRadius: BorderRadius.circular(AppSpacing.sm + 4),
                      ),
                      child: Icon(Icons.dark_mode_rounded, color: AppColors.primary),
                    ),
                    title: Text(texts['theme_setting']!, style: AppTextStyles.bodyBold()),
                    trailing: Consumer(
                      builder: (context, ref, _) {
                        final current = ref.watch(themeModeProvider);
                        return DropdownButton<AppThemeMode>(
                          value: current,
                          underline: const SizedBox(),
                          icon: Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
                          style: AppTextStyles.bodyBold(),
                          items: AppThemeMode.values
                              .map((m) => DropdownMenuItem(value: m, child: Text(m.label(currentLang))))
                              .toList(),
                          onChanged: (mode) {
                            if (mode != null) {
                              ref.read(themeModeProvider.notifier).setMode(mode);
                            }
                          },
                        );
                      },
                    ),
                  ),
                  const Divider(),

                  // Bagian Akun — ganti email/password. Sebelumnya nggak
                  // ada cara sama sekali buat orang tua ganti kredensial
                  // login sendiri dari dalam app.
                  Text(
                    texts['account_setting']!.toUpperCase(),
                    style: AppTextStyles.caption().copyWith(fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: Icon(Icons.email_outlined, size: 20, color: AppColors.primary),
                    title: Text(texts['change_email']!, style: AppTextStyles.body()),
                    trailing: Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textMuted),
                    onTap: () => _showChangeEmailModal(texts),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: Icon(Icons.lock_outline_rounded, size: 20, color: AppColors.primary),
                    title: Text(texts['change_password']!, style: AppTextStyles.body()),
                    trailing: Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textMuted),
                    onTap: () => _showChangePasswordModal(texts),
                  ),
                  const Divider(),

                  // Bagian Tentang — versi app, syarat & ketentuan,
                  // kebijakan privasi, lisensi open source. Sebelumnya
                  // nggak ada satupun link legal di manapun di app.
                  Text(
                    texts['about_setting']!.toUpperCase(),
                    style: AppTextStyles.caption().copyWith(fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(texts['app_version']!, style: AppTextStyles.body()),
                    trailing: Text('v$kAppVersion', style: AppTextStyles.caption()),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(texts['terms_of_service']!, style: AppTextStyles.body()),
                    trailing: Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textMuted),
                    onTap: () => Navigator.of(context, rootNavigator: true).push(
                      appPageRoute(
                        LegalPage(
                          title: texts['terms_of_service']!,
                          sections: currentLang == 'id' ? kTermsOfServiceId : kTermsOfServiceEn,
                        ),
                      ),
                    ),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(texts['privacy_policy']!, style: AppTextStyles.body()),
                    trailing: Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textMuted),
                    onTap: () => Navigator.of(context, rootNavigator: true).push(
                      appPageRoute(
                        LegalPage(
                          title: texts['privacy_policy']!,
                          sections: currentLang == 'id' ? kPrivacyPolicyId : kPrivacyPolicyEn,
                        ),
                      ),
                    ),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(texts['open_source_licenses']!, style: AppTextStyles.body()),
                    trailing: Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textMuted),
                    onTap: () => showLicensePage(
                      context: context,
                      applicationName: kAppName,
                      applicationVersion: kAppVersion,
                    ),
                  ),
                  const Divider(),

                  // Zona Berbahaya — unduh data & hapus akun. Privacy
                  // Policy udah janji ini bisa "kapan saja", tapi
                  // sebelumnya cuma bisa lewat email manual ke CS.
                  Text(
                    texts['danger_zone']!.toUpperCase(),
                    style: AppTextStyles.caption(color: AppColors.danger).copyWith(fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: Icon(Icons.download_rounded, size: 20, color: AppColors.primary),
                    title: Text(texts['download_data']!, style: AppTextStyles.body()),
                    subtitle: Text(
                      texts['download_data_desc']!,
                      style: AppTextStyles.caption(color: AppColors.textSecondary),
                    ),
                    onTap: () => _handleDownloadData(texts),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: Icon(Icons.delete_forever_rounded, size: 20, color: AppColors.danger),
                    title: Text(
                      texts['delete_account']!,
                      style: AppTextStyles.body().copyWith(color: AppColors.danger, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      texts['delete_account_desc']!,
                      style: AppTextStyles.caption(color: AppColors.textSecondary),
                    ),
                    onTap: () => _showDeleteAccountModal(texts),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Ganti email login — pakai `updateUser` bawaan Supabase Auth. Email
  /// baru butuh dikonfirmasi dulu (Supabase kirim link ke alamat baru)
  /// sebelum beneran ganti, jadi bukan langsung aktif.
  void _showChangeEmailModal(Map<String, String> texts) {
    final emailController = TextEditingController();
    final currentEmail = Supabase.instance.client.auth.currentUser?.email ?? '-';

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> submit() async {
              final newEmail = emailController.text.trim();
              if (newEmail.isEmpty || !newEmail.contains('@')) return;
              setState(() => isSaving = true);
              try {
                await Supabase.instance.client.auth.updateUser(
                  UserAttributes(email: newEmail),
                );
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                if (!mounted) return;
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(content: Text(texts['email_update_sent']!)),
                );
              } catch (e) {
                setState(() => isSaving = false);
                if (!mounted) return;
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(content: Text("${texts['err_update']}$e")),
                );
              }
            }

            return AppBottomSheet(
              title: texts['change_email']!,
              child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${texts['current_email_label']}: $currentEmail",
                        style: AppTextStyles.caption(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: texts['new_email_label'],
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppButton(
                        label: texts['btn_update']!,
                        isLoading: isSaving,
                        onPressed: submit,
                      ),
                    ],
              ),
            );
          },
        );
      },
    );
  }

  /// Ganti password login lewat `updateUser` bawaan Supabase Auth.
  void _showChangePasswordModal(Map<String, String> texts) {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        bool isSaving = false;
        String? errorText;
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> submit() async {
              final pw = passwordController.text;
              final confirm = confirmController.text;
              if (pw.length < 6) {
                setState(() => errorText = texts['err_password_short']);
                return;
              }
              if (pw != confirm) {
                setState(() => errorText = texts['err_password_mismatch']);
                return;
              }
              setState(() {
                errorText = null;
                isSaving = true;
              });
              try {
                await Supabase.instance.client.auth.updateUser(
                  UserAttributes(password: pw),
                );
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                if (!mounted) return;
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(content: Text(texts['password_updated']!)),
                );
              } catch (e) {
                setState(() => isSaving = false);
                if (!mounted) return;
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(content: Text("${texts['err_update']}$e")),
                );
              }
            }

            return AppBottomSheet(
              title: texts['change_password']!,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: texts['new_password_label'],
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm + 4),
                  TextField(
                    controller: confirmController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: texts['confirm_password_label'],
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      errorText!,
                      style: AppTextStyles.caption(color: AppColors.danger),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    label: texts['btn_update']!,
                    isLoading: isSaving,
                    onPressed: submit,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Ekspor semua data akun jadi 1 file JSON lalu buka share sheet OS.
  Future<void> _handleDownloadData(Map<String, String> texts) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AppLoading(),
    );
    try {
      await DataExportService.exportAndShare();
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(texts['download_success']!)));
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("${texts['err_update']}$e")));
    }
  }

  /// Konfirmasi hapus akun — minta ketik "HAPUS"/"DELETE" dulu (bukan cuma
  /// tombol Ya/Tidak) karena ini operasi yang beneran nggak bisa
  /// dibatalin: hapus akun, semua anak, riwayat misi, foto, chat.
  void _showDeleteAccountModal(Map<String, String> texts) {
    final confirmController = TextEditingController();

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        bool isDeleting = false;
        String confirmText = '';
        return StatefulBuilder(
          builder: (context, setState) {
            final bool canDelete =
                confirmText.trim().toUpperCase() == texts['delete_confirm_word'];

            Future<void> confirmDelete() async {
              setState(() => isDeleting = true);
              try {
                await AccountDeletionService.deleteAccount();
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                if (!mounted) return;
                context.go('/');
                ScaffoldMessenger.of(
                  this.context,
                ).showSnackBar(SnackBar(content: Text(texts['account_deleted']!)));
              } catch (e) {
                setState(() => isDeleting = false);
                if (!mounted) return;
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(content: Text("${texts['err_delete']}$e")),
                );
              }
            }

            return AppBottomSheet(
              title: texts['delete_confirm_title']!,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    texts['delete_confirm_desc']!,
                    style: AppTextStyles.body(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: confirmController,
                    onChanged: (v) => setState(() => confirmText = v),
                    decoration: InputDecoration(
                      labelText: texts['delete_confirm_hint'],
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    label: texts['btn_delete']!,
                    variant: AppButtonVariant.danger,
                    isLoading: isDeleting,
                    onPressed: canDelete ? confirmDelete : null,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // calculateLevel()/calculateLevelInfo() dipindah ke
  // core/utils/level_utils.dart — dulu logika ini ditulis ulang terpisah
  // di home_page.dart dan progress_page.dart juga.

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
    final int childLevel = calculateLevel(totalXp);

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
                _buildHeaderProfile(
                  context,
                  texts,
                  parentName,
                  childName,
                  childId,
                  childData['avatar_url'] as String?,
                ),
                _buildProfileCompleteness(
                  context,
                  texts,
                  ref.watch(profileCompletenessProvider),
                ),
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
                              _navigateToFullscreen(AllCertificatesPage()),
                          child: Container(
                            padding: const EdgeInsets.only(bottom: 2),
                            decoration: BoxDecoration(
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
    String? avatarUrl,
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
          _buildAvatarStack(texts, childId, avatarUrl),
        ],
      ),
    );
  }

  // Dulu nggak ada indikator apa pun buat data OPSIONAL yang belum diisi
  // (foto profil, kuisioner minat/gaya belajar) -- di data beneran, foto
  // profil HAMPIR SELALU kosong (langkahnya gampang dilewatin pas
  // onboarding) padahal fotonya kepakai di banyak tempat (header ini,
  // kartu misi, dst). Nggak ditampilin sama sekali kalau udah 100% biar
  // nggak numpuk jadi noise permanen.
  Widget _buildProfileCompleteness(
    BuildContext context,
    Map<String, String> texts,
    ProfileCompletenessInfo info,
  ) {
    if (info.isComplete) return const SizedBox.shrink();
    final hPad = context.pageHPadding;

    final List<String> missing = [
      if (info.missingPhoto) texts['completeness_missing_photo']!,
      if (info.missingQuestionnaire) texts['completeness_missing_questionnaire']!,
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, 0, hPad, AppSpacing.md),
      child: GestureDetector(
        onTap: () => _showChildSwitcherModal(texts),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "${texts['completeness_title']!} ${(info.ratio * 100).round()}%",
                      style: AppTextStyles.bodyBold(),
                    ),
                  ),
                  Text(
                    texts['completeness_action']!,
                    style: AppTextStyles.caption(color: AppColors.accent)
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: AppColors.accent,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: LinearProgressIndicator(
                  value: info.ratio,
                  minHeight: 6,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation(AppColors.accent),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                missing.join(" • "),
                style: AppTextStyles.caption(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
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
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.sm + 10),
          border: Border.all(color: AppColors.border),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit, color: AppColors.primary, size: 12),
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

  // Sebelumnya avatar di sini selalu emoji statis, nggak pernah nampilin
  // foto asli walau `children.avatar_url` udah keisi pas onboarding.
  //
  // Tap avatar sekarang buka switcher ganti-anak (bukan langsung ganti
  // foto) — ganti foto dipindah ke dalam switcher-nya sendiri, di baris
  // anak yang lagi aktif (lihat `_ChildSwitcherTile`).
  Widget _buildAvatarStack(
    Map<String, String> texts,
    String childId,
    String? avatarUrl,
  ) {
    return GestureDetector(
      onTap: () => _showChildSwitcherModal(texts),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.accentTint,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))],
            ),
            alignment: Alignment.center,
            clipBehavior: Clip.antiAlias,
            child: (avatarUrl == null || avatarUrl.isEmpty)
                ? const Text("👦🏻", style: TextStyle(fontSize: 36))
                : ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: avatarUrl,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) =>
                          const Text("👦🏻", style: TextStyle(fontSize: 36)),
                    ),
                  ),
          ),
          Positioned(
            bottom: -2,
            right: -2,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// Sheet ganti-anak — sebelumnya nggak ada UI sama sekali buat lihat
  /// lebih dari 1 anak atau pindah di antara mereka; `childDataProvider`
  /// selalu diam-diam milih "anak yang paling baru dibuat". Daftar anak
  /// dari `childrenListProvider`, + tombol tambah anak yang masuk ke
  /// alur onboarding-anak yang sama (`IdentifyPage(isAddingChild: true)`),
  /// yang sebelumnya cuma bisa diakses sekali seumur hidup akun.
  void _showChildSwitcherModal(Map<String, String> texts) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return AppBottomSheet(
          title: texts['switch_child_title']!,
          child: Consumer(
            builder: (context, ref, _) {
              final childrenAsync = ref.watch(childrenListProvider);
              final currentId = ref.watch(selectedChildIdProvider);

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  childrenAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, s) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      child: Text(
                        "${texts['err_load_children']}$e",
                        style: AppTextStyles.body(color: AppColors.danger),
                      ),
                    ),
                    data: (children) => Column(
                      children: [
                        for (final c in children)
                          _buildChildSwitcherTile(
                            texts,
                            c,
                            isSelected: c['id'] == currentId,
                            onTap: () {
                              ref
                                  .read(selectedChildIdProvider.notifier)
                                  .setId(c['id'] as String);
                              Navigator.pop(ctx);
                            },
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                    label: texts['add_child']!,
                    variant: AppButtonVariant.outline,
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.push('/identify?mode=add');
                    },
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildChildSwitcherTile(
    Map<String, String> texts,
    Map<String, dynamic> child, {
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final String name = child['name'] ?? texts['default_child']!;
    final String? avatarUrl = child['avatar_url'] as String?;
    final int level = calculateLevel(child['total_xp'] ?? 0);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(AppSpacing.sm + 4),
        color: isSelected ? AppColors.accentTint : AppColors.surface,
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.accentTint,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  alignment: Alignment.center,
                  clipBehavior: Clip.antiAlias,
                  child: (avatarUrl == null || avatarUrl.isEmpty)
                      ? const Text("👦🏻", style: TextStyle(fontSize: 24))
                      : ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: avatarUrl,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) =>
                                const Text("👦🏻", style: TextStyle(fontSize: 24)),
                          ),
                        ),
                ),
                // Ganti foto cuma dari baris anak yang lagi aktif — buat
                // anak lain, pindah dulu baru bisa ganti fotonya.
                if (isSelected)
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: GestureDetector(
                      onTap: () => _changeAvatar(
                        child['id'] as String,
                        oldAvatarUrl: avatarUrl,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 10),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: AppSpacing.sm + 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTextStyles.bodyBold()),
                  Text(
                    "Lvl $level",
                    style: AppTextStyles.caption(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  texts['current_child_badge']!,
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _changeAvatar(String childId, {String? oldAvatarUrl}) async {
    if (childId.isEmpty) return;
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
      );
      if (picked == null) return;

      final url = await StorageUploadService.uploadProfilePhoto(File(picked.path));
      await Supabase.instance.client
          .from('children')
          .update({'avatar_url': url})
          .eq('id', childId);
      // Nggak perlu invalidate manual — childDataProvider stream-nya
      // realtime, otomatis kebaca begitu kolomnya ke-update.

      // Baru hapus foto LAMA setelah yang baru beneran kepasang -- kalau
      // upload/update di atas gagal, foto lama yang masih berfungsi nggak
      // ikut kehapus.
      unawaited(StorageUploadService.deleteProfilePhoto(oldAvatarUrl));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal ganti foto: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
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
                  Icon(Icons.verified, color: AppColors.primary, size: 16),
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
          // Belum ada sistem paket/pembayaran beneran, jadi 2 tombol ini
          // ditandain jelas belum bisa dipencet — sebelumnya keliatan aktif
          // tapi diem aja pas ditekan.
          Row(
            children: [
              Expanded(
                child: ComingSoonBadge(
                  child: ElevatedButton(
                    onPressed: null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      disabledBackgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm + 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
                      elevation: 2,
                    ),
                    child: Text(texts['plan_detail']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm + 4),
              Expanded(
                child: ComingSoonBadge(
                  child: ElevatedButton(
                    onPressed: null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm + 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
                      elevation: 4,
                    ),
                    child: Text(texts['upgrade_plan']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
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
            () => Navigator.of(
              context,
              rootNavigator: true,
            ).push(appPageRoute(HelpCenterPage())),
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
        onPressed: () => _confirmLogout(texts),
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
