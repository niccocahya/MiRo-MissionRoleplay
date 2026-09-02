import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/providers/language_provider.dart';
import '../../core/providers/notification_prefs_provider.dart';
import '../../core/providers/notification_provider.dart';
import '../../shared/widgets/back_button.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_state_views.dart';

// ==========================================
// 1. DICTIONARY KAMUS BAHASA
// ==========================================
const Map<String, Map<String, String>> _t = {
  'en': {
    'title': "Notifications",
    'empty_title': "No Notifications Yet",
    'empty_desc':
        "When you have new updates or reminders, they'll appear here.",
    'mark_all_read': "Mark all as read",
    'clear_all': "Clear all",
    'confirm_clear_title': "Clear all notifications?",
    'confirm_clear_desc': "This can't be undone.",
    'cancel': "Cancel",
    'delete': "Delete",
    'err_mark_all_failed': "Couldn't mark all as read. Check your connection and try again.",
    'err_clear_all_failed': "Couldn't clear notifications. Check your connection and try again.",
  },
  'id': {
    'title': "Notifikasi",
    'empty_title': "Belum Ada Notifikasi",
    'empty_desc': "Pembaruan atau pengingat baru akan muncul di sini.",
    'mark_all_read': "Tandai semua dibaca",
    'clear_all': "Hapus semua",
    'confirm_clear_title': "Hapus semua notifikasi?",
    'confirm_clear_desc': "Nggak bisa dibatalin kalau udah dihapus.",
    'cancel': "Batal",
    'delete': "Hapus",
    'err_mark_all_failed': "Gagal nandain semua dibaca. Cek koneksimu terus coba lagi.",
    'err_clear_all_failed': "Gagal hapus notifikasi. Cek koneksimu terus coba lagi.",
  },
};

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final texts = _t[lang] ?? _t['en']!;

    // Memantau data langsung dari Supabase
    final notifsAsync = ref.watch(notificationsProvider);
    // visibleNotificationsProvider udah nyaring kategori yang dimatikan
    // lewat Settings (dulu halaman ini nyaring ulang manual di sini,
    // duplikat dari provider yang sama persis, gampang out-of-sync kalau
    // logic filternya berubah di satu tempat doang).
    final visibleNotifs = ref.watch(visibleNotificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ==================== KONTEN UTAMA (LIST/EMPTY STATE) ====================
          notifsAsync.when(
            loading: () => const AppLoading(),
            error: (error, stack) => AppErrorView(message: "Error: $error"),
            data: (_) {
              if (visibleNotifs.isEmpty) {
                return _buildEmptyState(texts);
              }

              return ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 120, 24, 16),
                itemCount: visibleNotifs.length,
                itemBuilder: (context, index) {
                  final notif = visibleNotifs[index];
                  final bool isRead = notif['is_read'] ?? false;
                  return GestureDetector(
                    onTap: isRead
                        ? null
                        : () => ref.read(markNotificationReadProvider)(notif['id']),
                    child: _buildNotificationCard(notif, lang),
                  );
                },
              );
            },
          ),

          // ==================== HEADER JUDUL CUSTOM ====================
          Positioned(
            top: 68,
            left: 0,
            right: 0,
            child: Text(
              texts['title']!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // ==================== CUSTOM BACK BUTTON MILIKMU ====================
          CustomBackButton(onPressed: () => context.pop()),

          // ==================== MENU: TANDAI SEMUA / HAPUS SEMUA ====================
          // Digerbang pakai visibleNotifs (list yang KELIATAN), bukan
          // notifsAsync.value mentah — dulu kalau satu-satunya notifikasi
          // yang ada kebetulan dari kategori yang dimatikan di Settings,
          // list-nya keliatan kosong (empty state tampil) tapi menu "⋮"
          // tetap muncul, nawarin aksi buat notifikasi yang nggak ada yang
          // keliatan.
          if (visibleNotifs.isNotEmpty)
            Positioned(
              top: 60,
              right: 24,
              child: SafeArea(
                child: PopupMenuButton<String>(
                  icon: Icon(Icons.more_horiz_rounded, color: AppColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  onSelected: (value) async {
                    if (value == 'mark_all') {
                      final ok = await ref.read(markAllNotificationsReadProvider)();
                      if (!ok && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(texts['err_mark_all_failed']!)),
                        );
                      }
                    } else if (value == 'clear_all') {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text(texts['confirm_clear_title']!),
                          content: Text(texts['confirm_clear_desc']!),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: Text(texts['cancel']!),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: Text(
                                texts['delete']!,
                                style: TextStyle(color: AppColors.danger),
                              ),
                            ),
                          ],
                        ),
                      );
                      if (confirmed ?? false) {
                        final ok = await ref.read(clearAllNotificationsProvider)();
                        if (!ok && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(texts['err_clear_all_failed']!)),
                          );
                        }
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'mark_all',
                      child: Text(texts['mark_all_read']!),
                    ),
                    PopupMenuItem(
                      value: 'clear_all',
                      child: Text(
                        texts['clear_all']!,
                        style: TextStyle(color: AppColors.danger),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ==================== WIDGET: KARTU NOTIFIKASI ====================
  Widget _buildNotificationCard(Map<String, dynamic> notif, String lang) {
    final bool isRead = notif['is_read'] ?? false;

    // ANTI-CRASH: Selalu kasih fallback string kosong jika dari DB null
    final String title = lang == 'id'
        ? (notif['title_id'] ?? 'Notifikasi')
        : (notif['title_en'] ?? 'Notification');
    final String desc = lang == 'id'
        ? (notif['desc_id'] ?? '')
        : (notif['desc_en'] ?? '');

    // ANTI-CRASH: Parsing tanggal aman pakai Try-Catch
    String timeFormatted = '-';
    if (notif['created_at'] != null &&
        notif['created_at'].toString().isNotEmpty) {
      try {
        final DateTime createdAt = DateTime.parse(
          notif['created_at'],
        ).toLocal();
        timeFormatted = DateFormat('HH:mm').format(createdAt);
      } catch (e) {
        debugPrint('Error parsing date for notif: $e');
      }
    }

    IconData iconData;
    Color iconBgColor;
    Color iconColor;

    switch (notif['type']) {
      case 'mission_completed':
        iconData = Icons.check_circle_rounded;
        iconBgColor = AppColors.successTint;
        iconColor = AppColors.success;
        break;
      case 'achievement':
      case 'reward':
        iconData = Icons.emoji_events_rounded;
        iconBgColor = AppColors.goldTint;
        iconColor = AppColors.accent;
        break;
      case 'certificate':
        iconData = Icons.school_rounded;
        iconBgColor = AppColors.primaryTint;
        iconColor = AppColors.primary;
        break;
      case 'reminder':
        iconData = Icons.access_time_filled_rounded;
        iconBgColor = AppColors.successTint;
        iconColor = AppColors.success;
        break;
      case 'info':
      default:
        iconData = Icons.info_rounded;
        iconBgColor = AppColors.primaryTint;
        iconColor = AppColors.primaryLighter;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isRead ? Colors.white : const Color(0xFFF0F5FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRead
              ? AppColors.primary.withValues(alpha: 0.05)
              : AppColors.primaryLighter.withValues(alpha: 0.5),
          width: isRead ? 1 : 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(iconData, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 14,
                          fontWeight: isRead
                              ? FontWeight.w600
                              : FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeFormatted,
                      style: TextStyle(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  desc,
                  style: TextStyle(
                    color: AppColors.primary.withValues(alpha: 0.6),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (!isRead) ...[
            const SizedBox(width: 8),
            Container(
              margin: const EdgeInsets.only(top: 6),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==================== WIDGET: STATE KOSONG ====================
  Widget _buildEmptyState(Map<String, String> texts) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Opacity(
              opacity: 0.5,
              child: Image.asset(
                // 'penguin_sleeping.png' nggak pernah ada di assets, jadi
                // ilustrasi ini selama ini SELALU jatuh ke fallback icon.
                'assets/images/penguin_peek.png',
                height: 150,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.notifications_off_rounded,
                  size: 80,
                  color: AppColors.primaryLighter,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              texts['empty_title']!,
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              texts['empty_desc']!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.primary.withValues(alpha: 0.6),
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
