import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'notification_provider.dart';

/// Kategori notifikasi yang beneran dikirim app ini (cocokkan `type` di
/// tabel `notifications` dan trigger DB-nya). Dulu toggle "Notifikasi" di
/// Settings cuma 1 saklar `bool` lokal di dalam modal — nggak disimpan,
/// nggak connect ke apa pun, jadi hilang tiap modal ditutup dan nggak
/// pernah benar-benar mematikan apa pun.
class NotificationCategory {
  const NotificationCategory({
    required this.id,
    required this.labelId,
    required this.labelEn,
  });

  final String id;
  final String labelId;
  final String labelEn;

  String label(String lang) => lang == 'id' ? labelId : labelEn;
}

const List<NotificationCategory> kNotificationCategories = [
  NotificationCategory(
    id: 'mission_completed',
    labelId: 'Misi selesai',
    labelEn: 'Mission completed',
  ),
  NotificationCategory(
    id: 'achievement',
    labelId: 'Lencana baru',
    labelEn: 'New badges',
  ),
  NotificationCategory(
    id: 'certificate',
    labelId: 'Sertifikat baru',
    labelEn: 'New certificates',
  ),
];

/// Set kategori yang DIMATIKAN (bukan yang dinyalakan) — biar default-nya
/// "semua nyala" tanpa perlu nulis apa pun ke storage duluan.
class NotificationPrefsNotifier extends Notifier<Set<String>> {
  static const _key = 'muted_notification_categories';

  @override
  Set<String> build() {
    _load();
    return {};
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_key);
    if (saved != null) state = saved.toSet();
  }

  Future<void> toggle(String categoryId, bool enabled) async {
    final next = Set<String>.from(state);
    if (enabled) {
      next.remove(categoryId);
    } else {
      next.add(categoryId);
    }
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, next.toList());
  }
}

final notificationPrefsProvider =
    NotifierProvider<NotificationPrefsNotifier, Set<String>>(
  () => NotificationPrefsNotifier(),
);

/// Notifikasi setelah kategori yang dimatikan disaring keluar — dipakai di
/// mana pun notifikasi ditampilkan/dihitung (badge lonceng, daftar
/// notifikasi), supaya mematikan kategori beneran ngefek.
final visibleNotificationsProvider = Provider<List<Map<String, dynamic>>>((
  ref,
) {
  final notifs = ref.watch(notificationsProvider).value ?? [];
  final muted = ref.watch(notificationPrefsProvider);
  if (muted.isEmpty) return notifs;
  return notifs.where((n) => !muted.contains(n['type'])).toList();
});

/// Jumlah notifikasi yang belum dibaca dari kategori yang masih dinyalakan
/// — dulu ikon lonceng cuma nampilin titik oranye kosong, nggak pernah
/// nunjukin ada berapa banyak (dan nggak ngitung ulang setelah kategori
/// dimatikan).
final unreadNotificationCountProvider = Provider<int>((ref) {
  final notifs = ref.watch(visibleNotificationsProvider);
  return notifs.where((n) => n['is_read'] != true).length;
});
