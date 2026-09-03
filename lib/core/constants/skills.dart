/// Definisi 5 skill yang dilatih app ini.
///
/// Sebelumnya pengetahuan yang SAMA soal 5 skill ini kesebar di 5 file dan
/// masing-masing cuma tau sepotong:
/// - progress_page.dart: label ID/EN (di dalam kamus `_t`-nya) + daftar
///   key buat chip tren
/// - report_pdf_service.dart: label ID/EN-nya SENDIRI, ditulis ulang
/// - mission_journal_screen.dart: pemetaan key (termasuk varian bahasa
///   Indonesia) ke nama kolom `child_stats`
/// - mission_intro_screen.dart: emoji per skill
/// - skill_trend_provider.dart: daftar key lagi
///
/// Efeknya: nambah/ganti satu skill berarti nyisir 5 file, dan gampang
/// kelewat satu (mis. skill baru muncul di Progres tapi hilang di PDF).
class SkillDef {
  const SkillDef({
    required this.key,
    required this.statColumn,
    required this.nameId,
    required this.nameEn,
    required this.emoji,
    this.aliases = const [],
  });

  /// Key kanonik, sama dengan yang dipakai di `missions_master.skills_reward`
  /// dan `mission_logs.earned_skills`.
  final String key;

  /// Nama kolom di tabel `child_stats`.
  final String statColumn;

  final String nameId;
  final String nameEn;
  final String emoji;

  /// Ejaan lain yang mungkin nyangkut di data lama (dulu sempat ada key
  /// berbahasa Indonesia).
  final List<String> aliases;

  String name(String lang) => lang == 'id' ? nameId : nameEn;
}

const List<SkillDef> kSkills = [
  SkillDef(
    key: 'cognitive',
    statColumn: 'cognitive_score',
    nameId: 'Kognitif',
    nameEn: 'Cognitive',
    emoji: '🧠',
    aliases: ['kognitif'],
  ),
  SkillDef(
    key: 'empathy',
    statColumn: 'empathy_score',
    nameId: 'Empati',
    nameEn: 'Empathy',
    emoji: '💗',
    aliases: ['empati'],
  ),
  SkillDef(
    key: 'creativity',
    statColumn: 'creativity_score',
    nameId: 'Kreativitas',
    nameEn: 'Creativity',
    emoji: '🎨',
    aliases: ['kreativitas'],
  ),
  SkillDef(
    key: 'literacy',
    statColumn: 'literacy_score',
    nameId: 'Literasi',
    nameEn: 'Literacy',
    emoji: '📚',
    aliases: ['literasi'],
  ),
  SkillDef(
    key: 'motoric',
    statColumn: 'motoric_score',
    nameId: 'Motorik',
    nameEn: 'Motoric',
    emoji: '🧩',
    aliases: ['motorik'],
  ),
];

/// Daftar key kanonik, urutannya tetap (dipakai buat chip/urutan tampilan).
final List<String> kSkillKeys = kSkills.map((s) => s.key).toList();

/// Cari skill dari key apa pun ejaannya (case-insensitive, termasuk alias
/// bahasa Indonesia). `null` kalau nggak dikenal.
SkillDef? skillByKey(String? rawKey) {
  if (rawKey == null) return null;
  final k = rawKey.toLowerCase().trim();
  for (final s in kSkills) {
    if (s.key == k || s.aliases.contains(k)) return s;
  }
  return null;
}

/// Nama kolom `child_stats` buat sebuah key skill. Fallback `{key}_score`
/// dipertahankan biar perilakunya sama persis kayak sebelum disatuin.
String skillStatColumn(String rawKey) =>
    skillByKey(rawKey)?.statColumn ?? '${rawKey.toLowerCase()}_score';

/// Emoji buat sebuah key skill (bintang kalau nggak dikenal).
String skillEmoji(String rawKey) => skillByKey(rawKey)?.emoji ?? '🌟';
