import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_info.dart';
import '../../core/providers/app_rating_prompt_provider.dart';
import '../../core/providers/child_provider.dart';
import '../../core/providers/language_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import 'star_rating_row.dart';
import '../../features/help/help_center_page.dart';

const Map<String, Map<String, String>> _t = {
  'en': {
    'title': "How's MiRO going so far?",
    'desc': "Tap a star to let us know.",
    'later': "Maybe Later",
    'thanks_high': "Thanks so much for the love! 🎉",
    'thanks_low':
      "Thanks for the honesty. Tell us more in Help Center so we can improve.",
    'open_help': "Open",
  },
  'id': {
    'title': "Gimana pengalamanmu pakai MiRO sejauh ini?",
    'desc': "Ketuk salah satu bintang ya.",
    'later': "Nanti Aja",
    'thanks_high': "Makasih banyak buat cintanya! 🎉",
    'thanks_low':
      "Makasih udah jujur. Cerita lebih lanjut di Bantuan ya, biar kami bisa lebih baik lagi.",
    'open_help': "Buka",
  },
};

/// Dialog rating bintang -- muncul lewat appRatingPromptProvider (dipicu di
/// Home setelah anak nyelesein beberapa misi). Nyimpen ke tabel `feedback`
/// yang sama dipakai Help Center (type: 'app_rating'), jadi nggak perlu
/// skema baru.
class AppRatingDialog extends ConsumerStatefulWidget {
  // Dibutuhin cuma buat nge-snooze prompt-nya (geser ambang ke N misi lagi
  // ke depan) kalau di-"Nanti Aja".
  final int totalMissionsCompleted;

  const AppRatingDialog({super.key, required this.totalMissionsCompleted});

  @override
  ConsumerState<AppRatingDialog> createState() => _AppRatingDialogState();
}

class _AppRatingDialogState extends ConsumerState<AppRatingDialog> {
  bool _submitting = false;

  Future<void> _submit(int stars, Map<String, String> texts) async {
    if (_submitting) return;
    setState(() => _submitting = true);

    try {
      final parentId = Supabase.instance.client.auth.currentUser?.id;
      final childId = ref.read(childDataProvider).value?['id'];
      await Supabase.instance.client.from('feedback').insert({
        'parent_id': parentId,
        'child_id': childId,
        'type': 'app_rating',
        'rating': stars,
        'message': 'In-app rating prompt: $stars star(s)',
        'app_version': kAppVersion,
      });
    } catch (e) {
      debugPrint("Gagal simpan app rating: $e");
    }

    await ref.read(appRatingPromptProvider.notifier).markAnswered();
    if (!mounted) return;
    Navigator.of(context).pop();

    final messenger = ScaffoldMessenger.of(context);
    if (stars >= 4) {
      messenger.showSnackBar(SnackBar(content: Text(texts['thanks_high']!)));
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(texts['thanks_low']!),
          action: SnackBarAction(
            label: texts['open_help']!,
            onPressed: () {
              Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(builder: (_) => const HelpCenterPage()),
              );
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final texts = _t[lang] ?? _t['en']!;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      title: Text(texts['title']!, style: AppTextStyles.h3()),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(texts['desc']!, style: AppTextStyles.body()),
          const SizedBox(height: AppSpacing.md),
          // Dulu 5 bintangnya SELALU keisi emas walau belum dipilih --
          // keliatan kayak udah dinilai 5 dari sananya. Sekarang kosong
          // (outline) sampai beneran diketuk, sama kayak baris bintang di
          // jurnal misi & Pusat Bantuan.
          Center(
            child: StarRatingRow(
              rating: 0,
              enabled: !_submitting,
              onRate: (stars) => _submit(stars, texts),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _submitting
              ? null
              : () async {
                  await ref
                      .read(appRatingPromptProvider.notifier)
                      .dismissTemporarily(widget.totalMissionsCompleted);
                  if (mounted) Navigator.of(context).pop();
                },
          child: Text(texts['later']!, style: TextStyle(color: AppColors.textSecondary)),
        ),
      ],
    );
  }
}
