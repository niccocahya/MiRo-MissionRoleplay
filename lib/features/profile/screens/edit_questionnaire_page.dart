import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/child_questionnaire_provider.dart';
import '../../../core/providers/language_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/responsive.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_state_views.dart';
import '../../../shared/widgets/app_choice_chip.dart';
import '../../../shared/widgets/app_screen_header.dart';
import '../../../shared/widgets/section_header.dart';

const Map<String, Map<String, String>> _t = {
  'en': {
    'title': "Interests & Learning Style",
    'desc':
        "This shapes Mink's context and mission recommendations. Update it any time your child's interests change.",
    'section_interests': "Favorite activities",
    'section_learning': "Learning style",
    'section_goals': "Skills to focus on (max 3)",
    'section_time': "Play time together",
    'act_draw': "Drawing",
    'act_read': "Reading",
    'act_speak': "Speaking",
    'act_music': "Music",
    'act_sport': "Sport",
    'style_visual': "Visual",
    'style_auditory': "Auditory",
    'style_kinesthetic': "Kinesthetic",
    'skill_motor': "Motor skills",
    'skill_creat': "Creativity",
    'skill_emp': "Empathy",
    'skill_lit': "Literacy",
    'skill_think': "Thinking skills",
    'time_15m': "15 min",
    'time_30m': "30 min",
    'time_1h': "1 hour",
    'time_1_5h': "1.5 hours",
    'time_2h': "2 hours",
    'btn_save': "Save",
    'err_incomplete': "Please fill in every section first.",
    'err_max_goals': "You can only pick up to 3. Unpick one first.",
    'saved': "Saved!",
    'err_save': "Failed to save: ",
  },
  'id': {
    'title': "Minat & Gaya Belajar",
    'desc':
        "Ini ngebentuk konteks buat Mink dan rekomendasi misi. Update kapan aja kalau minat anak berubah.",
    'section_interests': "Kegiatan kesukaan",
    'section_learning': "Gaya belajar",
    'section_goals': "Keahlian yang mau difokuskan (maks 3)",
    'section_time': "Waktu bermain bersama",
    'act_draw': "Menggambar",
    'act_read': "Membaca",
    'act_speak': "Berbicara",
    'act_music': "Musik",
    'act_sport': "Olahraga",
    'style_visual': "Visual",
    'style_auditory': "Auditori",
    'style_kinesthetic': "Kinestetik",
    'skill_motor': "Keahlian motorik",
    'skill_creat': "Kreativitas",
    'skill_emp': "Empati",
    'skill_lit': "Literasi",
    'skill_think': "Keahlian berpikir",
    'time_15m': "15 mnt",
    'time_30m': "30 mnt",
    'time_1h': "1 jam",
    'time_1_5h': "1,5 jam",
    'time_2h': "2 jam",
    'btn_save': "Simpan",
    'err_incomplete': "Isi dulu semua bagiannya ya.",
    'err_max_goals': "Maksimal cuma boleh pilih 3. Batalin salah satu dulu.",
    'saved': "Tersimpan!",
    'err_save': "Gagal menyimpan: ",
  },
};

const List<String> _kInterestIds = ["Drawing", "Reading", "Speaking", "Music", "Sport"];
const List<String> _kLearningStyleIds = ["Visual", "Auditori", "Kinestetik"];
const List<String> _kGoalIds = [
  "Motor skills",
  "Creativity",
  "Empathy",
  "Literacy",
  "Thinking skills",
];
const List<String> _kTimeIds = ["15_min", "30_min", "1_hour", "1_5_hours", "2_hours"];

/// Isi/edit kuisioner minat & gaya belajar KAPAN AJA setelah onboarding --
/// sebelumnya data ini (tabel `questionnaires`) cuma pernah ditulis SEKALI
/// pas submit identify_page.dart pertama kali, dan nggak ada layar/tombol
/// apa pun buat isi ulang. Kartu "profil belum lengkap" di Profile janji
/// bisa ngelengkapin ini, tapi tap-nya cuma buka child-switcher (ganti
/// foto doang) -- dead end. Sekarang ada tempatnya beneran, dan bisa dibuka
/// ulang kapan aja buat update kalau minat anak berubah seiring waktu.
class EditQuestionnairePage extends ConsumerStatefulWidget {
  final String childId;

  const EditQuestionnairePage({super.key, required this.childId});

  @override
  ConsumerState<EditQuestionnairePage> createState() =>
      _EditQuestionnairePageState();
}

class _EditQuestionnairePageState extends ConsumerState<EditQuestionnairePage> {
  List<String> _interests = [];
  List<String> _learningStyles = [];
  List<String> _goals = [];
  String? _timePreference;
  bool _initialized = false;
  bool _isSaving = false;

  void _prefill(Map<String, dynamic>? existing) {
    if (_initialized || existing == null) return;
    _initialized = true;
    _interests = List<String>.from(existing['interests'] ?? []);
    _learningStyles = List<String>.from(existing['learning_styles'] ?? []);
    _goals = List<String>.from(existing['parent_goals'] ?? []);
    _timePreference = existing['time_preference'] as String?;
  }

  Future<void> _save(Map<String, String> texts) async {
    if (_interests.isEmpty ||
        _learningStyles.isEmpty ||
        _goals.isEmpty ||
        _timePreference == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(texts['err_incomplete']!)));
      return;
    }

    setState(() => _isSaving = true);
    try {
      // Unique constraint di child_id (satu kuisioner per anak) jadi
      // upsert ini beneran INSERT pas pertama kali diisi, atau UPDATE pas
      // diedit ulang -- satu jalur buat dua kasus.
      await Supabase.instance.client.from('questionnaires').upsert({
        'child_id': widget.childId,
        'interests': _interests,
        'learning_styles': _learningStyles,
        'parent_goals': _goals,
        'time_preference': _timePreference,
      }, onConflict: 'child_id');

      ref.invalidate(childQuestionnaireProvider(widget.childId));

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(texts['saved']!)));
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("${texts['err_save']}$e")));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _toggleMulti(
    List<String> list,
    String id,
    void Function(List<String>) apply, {
    int? max,
    String? maxErrorText,
  }) {
    final next = List<String>.from(list);
    if (next.contains(id)) {
      next.remove(id);
    } else {
      if (max != null && next.length >= max) {
        if (maxErrorText != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(maxErrorText)));
        }
        return;
      }
      next.add(id);
    }
    setState(() => apply(next));
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final texts = _t[lang] ?? _t['en']!;
    final hPad = context.pageHPadding;

    final questionnaireAsync = ref.watch(childQuestionnaireProvider(widget.childId));
    _prefill(questionnaireAsync.value);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppScreenHeader(title: texts['title']!),
            Expanded(
              child: questionnaireAsync.when(
                loading: () => const AppLoading(),
                error: (e, s) => AppErrorView(message: "$e"),
                data: (_) => ListView(
                  padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 40),
                  children: [
                    Text(
                      texts['desc']!,
                      style: AppTextStyles.body(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    SectionHeader(title: texts['section_interests']!),
                    AppCard(
                      child: _chipWrap(
                        _kInterestIds,
                        _interests,
                        (id) => 'act_${id.toLowerCase()}',
                        texts,
                        onTap: (id) => _toggleMulti(
                          _interests,
                          id,
                          (l) => _interests = l,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    SectionHeader(title: texts['section_learning']!),
                    AppCard(
                      child: _chipWrap(
                        _kLearningStyleIds,
                        _learningStyles,
                        (id) => switch (id) {
                          'Visual' => 'style_visual',
                          'Auditori' => 'style_auditory',
                          _ => 'style_kinesthetic',
                        },
                        texts,
                        onTap: (id) => setState(
                          () => _learningStyles = [id],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    SectionHeader(title: texts['section_goals']!),
                    AppCard(
                      child: _chipWrap(
                        _kGoalIds,
                        _goals,
                        (id) => switch (id) {
                          'Motor skills' => 'skill_motor',
                          'Creativity' => 'skill_creat',
                          'Empathy' => 'skill_emp',
                          'Literacy' => 'skill_lit',
                          _ => 'skill_think',
                        },
                        texts,
                        onTap: (id) => _toggleMulti(
                          _goals,
                          id,
                          (l) => _goals = l,
                          max: 3,
                          maxErrorText: texts['err_max_goals'],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    SectionHeader(title: texts['section_time']!),
                    AppCard(
                      child: _chipWrap(
                        _kTimeIds,
                        _timePreference == null ? [] : [_timePreference!],
                        (id) => switch (id) {
                          '15_min' => 'time_15m',
                          '30_min' => 'time_30m',
                          '1_hour' => 'time_1h',
                          '1_5_hours' => 'time_1_5h',
                          _ => 'time_2h',
                        },
                        texts,
                        onTap: (id) => setState(() => _timePreference = id),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    AppButton(
                      label: texts['btn_save']!,
                      isLoading: _isSaving,
                      onPressed: () => _save(texts),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chipWrap(
    List<String> ids,
    List<String> selected,
    String Function(String id) labelKeyOf,
    Map<String, String> texts, {
    required void Function(String id) onTap,
  }) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: ids
          .map(
            (id) => AppChoiceChip(
              label: texts[labelKeyOf(id)] ?? id,
              selected: selected.contains(id),
              style: AppChipStyle.soft,
              onTap: () => onTap(id),
            ),
          )
          .toList(),
    );
  }
}
