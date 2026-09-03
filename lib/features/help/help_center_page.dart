import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_info.dart';
import '../../core/providers/child_provider.dart';
import '../../core/providers/language_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/responsive.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_screen_header.dart';
import '../../shared/widgets/fun_background_decorations.dart';
import '../../shared/widgets/star_rating_row.dart';
import '../../shared/widgets/penguin_chat_bot.dart';
import '../../shared/widgets/section_header.dart';

const Map<String, Map<String, String>> _t = {
  'en': {
    'title': "Help Center",
    'faq_title': "Frequently Asked Questions",
    'faq_q1': "How do missions work?",
    'faq_a1':
        "Each role (Chef, Doctor, Artist, Athlete, Teacher) has a short path of real-world missions. Complete one to unlock the next — they're locked in order so your child always knows what's next.",
    'faq_q2': "Why is a mission locked?",
    'faq_a2':
        "Missions within a role unlock one at a time as your child completes the previous one. This keeps the path simple and avoids overwhelming them with choices.",
    'faq_q3': "What are XP and levels for?",
    'faq_a3':
        "Every completed mission gives XP. Collecting enough XP levels your child up — it's just a fun way to show progress, it doesn't unlock or lock anything else.",
    'faq_q4': "How are certificates earned?",
    'faq_a4':
        "Certificates unlock automatically after completing enough missions in a role. Check Profile → All Certificates to see progress per role.",
    'faq_q5': "What is Mink (the chat assistant)?",
    'faq_a5':
        "Mink is an in-app assistant for parenting questions and how to use MiRO. It's not a substitute for professional medical or psychological advice.",
    'faq_q6': "Is my child's data safe?",
    'faq_a6':
        "Photos and progress are private to your account. See Settings → About → Privacy Policy for full details.",
    'open_mink_chat': "Open Mink Chat",
    'feedback_title': "Send Feedback",
    'feedback_desc':
        "Found a bug, or have an idea to make MiRO better? Let us know.",
    'type_feedback': "Suggestion",
    'type_bug': "Report a Bug",
    'rating_label': "How would you rate MiRO?",
    'message_hint': "Tell us more...",
    'btn_send': "Send",
    'err_empty': "Please write your message first.",
    'sent_success': "Thanks! Your feedback has been sent.",
    'sent_error': "Failed to send: ",
    'contact_title': "Contact Us",
    'contact_desc': "Our team usually replies within 1-2 business days.",
    'copied': "Email copied to clipboard",
  },
  'id': {
    'title': "Pusat Bantuan",
    'faq_title': "Pertanyaan yang Sering Ditanyakan",
    'faq_q1': "Bagaimana cara kerja misi?",
    'faq_a1':
        "Tiap peran (Koki, Dokter, Pelukis, Atlet, Guru) punya jalur pendek berisi misi dunia nyata. Selesaikan satu buat buka misi berikutnya — misinya terkunci berurutan biar anak selalu tahu langkah selanjutnya.",
    'faq_q2': "Kenapa misi ini terkunci?",
    'faq_a2':
        "Misi dalam satu peran terbuka satu-satu setelah misi sebelumnya selesai. Ini biar jalurnya simpel dan anak nggak bingung harus pilih yang mana.",
    'faq_q3': "XP dan level itu buat apa?",
    'faq_a3':
        "Tiap misi selesai ngasih XP. Kumpulin XP bikin anak naik level — ini cuma cara seru buat nunjukin progres, nggak ngunci/buka fitur lain.",
    'faq_q4': "Gimana cara dapat sertifikat?",
    'faq_a4':
        "Sertifikat kebuka otomatis setelah menyelesaikan cukup banyak misi di satu peran. Cek Profil → Semua Sertifikat buat lihat progresnya per peran.",
    'faq_q5': "Mink (asisten chat) itu apa?",
    'faq_a5':
        "Mink adalah asisten dalam app buat bahas seputar parenting dan cara pakai MiRO. Bukan pengganti nasihat medis atau psikologis profesional.",
    'faq_q6': "Data anak saya aman nggak?",
    'faq_a6':
        "Foto dan progres cuma bisa diakses dari akunmu sendiri. Detail lengkap ada di Pengaturan → Tentang → Kebijakan Privasi.",
    'open_mink_chat': "Buka Chat Mink",
    'feedback_title': "Kirim Masukan",
    'feedback_desc':
        "Nemu bug, atau ada ide biar MiRO makin baik? Kabari kami.",
    'type_feedback': "Masukan",
    'type_bug': "Lapor Bug",
    'rating_label': "Menurutmu, MiRO dapat nilai berapa?",
    'message_hint': "Ceritakan lebih lanjut...",
    'btn_send': "Kirim",
    'err_empty': "Tulis pesannya dulu ya.",
    'sent_success': "Makasih! Masukanmu sudah terkirim.",
    'sent_error': "Gagal mengirim: ",
    'contact_title': "Hubungi Kami",
    'contact_desc': "Tim kami biasanya balas dalam 1-2 hari kerja.",
    'copied': "Email disalin ke clipboard",
  },
};

/// Pusat Bantuan — sebelumnya cuma dialog kecil dengan 1 tombol email yang
/// nggak ngapa-ngapain selain nutup dialognya sendiri. Sekarang halaman
/// penuh: FAQ, form kirim masukan/lapor bug (tersimpan ke tabel `feedback`),
/// dan kontak email yang beneran bisa disalin.
class HelpCenterPage extends ConsumerStatefulWidget {
  const HelpCenterPage({super.key});

  @override
  ConsumerState<HelpCenterPage> createState() => _HelpCenterPageState();
}

class _HelpCenterPageState extends ConsumerState<HelpCenterPage> {
  final _messageController = TextEditingController();
  String _type = 'feedback';
  int _rating = 5;
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit(Map<String, String> texts) async {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(texts['err_empty']!)));
      return;
    }

    setState(() => _isSending = true);
    try {
      final parentId = Supabase.instance.client.auth.currentUser?.id;
      final childId = ref.read(childDataProvider).value?['id'];

      await Supabase.instance.client.from('feedback').insert({
        'parent_id': parentId,
        'child_id': childId,
        'type': _type,
        'rating': _type == 'feedback' ? _rating : null,
        'message': message,
        'app_version': kAppVersion,
      });

      if (!mounted) return;
      _messageController.clear();
      setState(() => _rating = 5);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(texts['sent_success']!)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("${texts['sent_error']}$e")));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final texts = _t[lang] ?? _t['en']!;
    final hPad = context.pageHPadding;

    final faqEntries = [
      (texts['faq_q1']!, texts['faq_a1']!),
      (texts['faq_q2']!, texts['faq_a2']!),
      (texts['faq_q3']!, texts['faq_a3']!),
      (texts['faq_q4']!, texts['faq_a4']!),
      (texts['faq_q5']!, texts['faq_a5']!),
      (texts['faq_q6']!, texts['faq_a6']!),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      // Ini layar FORM (kirim pertanyaan/kesan) -- sentuhan minimal doang
      // biar nggak ganggu kolom isian.
      body: Stack(
        children: [
          const Positioned(
            top: 60,
            right: 24,
            child: Sparkle(size: 16, color: AppColors.info),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppScreenHeader(title: texts['title']!),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 40),
                    children: [
                      SectionHeader(title: texts['faq_title']!),
                      AppCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            for (int i = 0; i < faqEntries.length; i++) ...[
                              if (i > 0) const Divider(height: 1),
                              Theme(
                                data: Theme.of(context).copyWith(
                                  dividerColor: Colors.transparent,
                                ),
                                child: ExpansionTile(
                                  title: Text(
                                    faqEntries[i].$1,
                                    style: AppTextStyles.bodyBold()
                                        .copyWith(fontSize: 14),
                                  ),
                                  childrenPadding: const EdgeInsets.fromLTRB(
                                    AppSpacing.md,
                                    0,
                                    AppSpacing.md,
                                    AppSpacing.md,
                                  ),
                                  expandedCrossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      faqEntries[i].$2,
                                      style: AppTextStyles.body(
                                        color: AppColors.textSecondary,
                                      ).copyWith(fontSize: 13, height: 1.4),
                                    ),
                                    // Entri FAQ ini (index 4) khusus jelasin Mink,
                                    // tapi dulu nggak ada tombol buat langsung
                                    // buka chat-nya dari sini -- harus nutup Help
                                    // Center dulu baru cari-cari bola Mink sendiri.
                                    if (i == 4) ...[
                                      const SizedBox(height: AppSpacing.sm + 4),
                                      GestureDetector(
                                        onTap: () {
                                          ref
                                              .read(showChatbotGlobalProvider
                                                  .notifier)
                                              .show();
                                          ref
                                              .read(chatWindowOpenProvider
                                                  .notifier)
                                              .open();
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: AppSpacing.md,
                                            vertical: AppSpacing.sm + 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.accentTint,
                                            borderRadius: BorderRadius.circular(
                                                AppRadius.md),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.chat_bubble_rounded,
                                                  color: AppColors.accent,
                                                  size: 16),
                                              const SizedBox(
                                                  width: AppSpacing.xs + 2),
                                              Text(
                                                texts['open_mink_chat']!,
                                                style: AppTextStyles.bodyBold(
                                                        color: AppColors.accent)
                                                    .copyWith(fontSize: 13),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      SectionHeader(title: texts['feedback_title']!),
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              texts['feedback_desc']!,
                              style: AppTextStyles.caption(
                                  color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              children: [
                                Expanded(
                                  child: _typeChip(
                                    'feedback',
                                    texts['type_feedback']!,
                                    Icons.lightbulb_rounded,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: _typeChip(
                                    'bug',
                                    texts['type_bug']!,
                                    Icons.bug_report_rounded,
                                  ),
                                ),
                              ],
                            ),
                            if (_type == 'feedback') ...[
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                texts['rating_label']!,
                                style: AppTextStyles.bodyBold()
                                    .copyWith(fontSize: 13),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              StarRatingRow(
                                rating: _rating,
                                size: 30,
                                onRate: (v) => setState(() => _rating = v),
                              ),
                            ],
                            const SizedBox(height: AppSpacing.md),
                            TextField(
                              controller: _messageController,
                              maxLines: 4,
                              decoration: InputDecoration(
                                hintText: texts['message_hint'],
                                filled: true,
                                fillColor: AppColors.background,
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.md),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            AppButton(
                              label: texts['btn_send']!,
                              isLoading: _isSending,
                              onPressed: () => _submit(texts),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      SectionHeader(title: texts['contact_title']!),
                      AppCard(
                        onTap: () async {
                          await Clipboard.setData(
                            const ClipboardData(text: kSupportEmail),
                          );
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(
                              SnackBar(content: Text(texts['copied']!)));
                        },
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              decoration: BoxDecoration(
                                color: AppColors.primaryTint,
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.sm + 4),
                              ),
                              child: Icon(Icons.mail_rounded,
                                  color: AppColors.primary),
                            ),
                            const SizedBox(width: AppSpacing.sm + 2),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    kSupportEmail,
                                    style: AppTextStyles.bodyBold(),
                                  ),
                                  Text(
                                    texts['contact_desc']!,
                                    style: AppTextStyles.caption(
                                        color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.copy_rounded,
                                color: AppColors.textMuted, size: 18),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _typeChip(String value, String label, IconData icon) {
    final bool selected = _type == value;
    return GestureDetector(
      onTap: () => setState(() => _type = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentTint : AppColors.background,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.border,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                size: 18,
                color: selected ? AppColors.accent : AppColors.textMuted),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.caption(
                color: selected ? AppColors.accent : AppColors.textSecondary,
              ).copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
