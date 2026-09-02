import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'child_provider.dart';
import 'child_questionnaire_provider.dart';

/// Seberapa lengkap profil anak yang lagi aktif. Dulu nggak ada cara buat
/// orang tua tau ada data OPSIONAL yang belum diisi (foto profil,
/// kuisioner minat/gaya belajar pas onboarding) selain nemu sendiri --
/// data beneran nunjukin foto profil hampir SELALU kosong (langkahnya
/// dilewatin pas onboarding) padahal ada di mana-mana di UI (avatar
/// header, kartu misi, dst).
class ProfileCompletenessInfo {
  const ProfileCompletenessInfo({
    required this.completed,
    required this.total,
    required this.missingPhoto,
    required this.missingQuestionnaire,
  });

  final int completed;
  final int total;
  final bool missingPhoto;
  final bool missingQuestionnaire;

  double get ratio => total == 0 ? 1.0 : completed / total;
  bool get isComplete => completed >= total;
}

final profileCompletenessProvider = Provider<ProfileCompletenessInfo>((ref) {
  final childData = ref.watch(childDataProvider).value;
  final String childId = childData?['id'] as String? ?? '';

  final questionnaire = childId.isEmpty
      ? null
      : ref.watch(childQuestionnaireProvider(childId)).value;

  final bool hasPhoto =
      (childData?['avatar_url'] as String?)?.isNotEmpty ?? false;
  final bool hasQuestionnaire = questionnaire != null;

  int completed = 0;
  const int total = 2;
  if (hasPhoto) completed++;
  if (hasQuestionnaire) completed++;

  return ProfileCompletenessInfo(
    completed: completed,
    total: total,
    missingPhoto: !hasPhoto,
    missingQuestionnaire: !hasQuestionnaire,
  );
});
