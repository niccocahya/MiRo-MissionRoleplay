import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/providers/language_provider.dart';
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
  },
  'id': {
    'title': "Notifikasi",
    'empty_title': "Belum Ada Notifikasi",
    'empty_desc': "Pembaruan atau pengingat baru akan muncul di sini.",
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

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ==================== KONTEN UTAMA (LIST/EMPTY STATE) ====================
          notifsAsync.when(
            loading: () => const AppLoading(),
            error: (error, stack) => AppErrorView(message: "Error: $error"),
            data: (notifications) {
              if (notifications.isEmpty) {
                return _buildEmptyState(texts);
              }

              return ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 120, 24, 16),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notif = notifications[index];
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
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // ==================== CUSTOM BACK BUTTON MILIKMU ====================
          CustomBackButton(onPressed: () => context.pop()),
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
      case 'reward':
        iconData = Icons.emoji_events_rounded;
        iconBgColor = AppColors.goldTint;
        iconColor = AppColors.accent;
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
              decoration: const BoxDecoration(
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
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.notifications_off_rounded,
                  size: 80,
                  color: AppColors.primaryLighter,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              texts['empty_title']!,
              style: const TextStyle(
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
