import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/app_screen_header.dart';

/// Halaman teks legal generik (dipakai buat Syarat & Ketentuan dan
/// Kebijakan Privasi) — sebelumnya nggak ada link ke keduanya di
/// manapun di app, padahal ini wajib buat app yang nyimpen data anak.
class LegalPage extends StatelessWidget {
  const LegalPage({super.key, required this.title, required this.sections});

  final String title;
  final List<LegalSection> sections;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppScreenHeader(title: title),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                itemCount: sections.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.lg),
                itemBuilder: (context, i) {
                  final section = sections[i];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(section.heading, style: AppTextStyles.h3()),
                      const SizedBox(height: AppSpacing.sm),
                      Text(section.body, style: AppTextStyles.bodyLarge(color: AppColors.textSecondary)),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LegalSection {
  const LegalSection(this.heading, this.body);
  final String heading;
  final String body;
}

/// Draf awal — sebaiknya di-review sama yang paham hukum perlindungan
/// data anak sebelum app-nya beneran dirilis publik, tapi ini konten
/// nyata yang mencerminkan data yang beneran dikumpulin app ini
/// (bukan placeholder lorem ipsum).
const List<LegalSection> kPrivacyPolicyId = [
  LegalSection(
    'Data apa yang kami kumpulkan',
    'Dari orang tua: nama, email, dan bahasa pilihan. Dari profil anak: nama, usia, dan foto profil (opsional). Dari aktivitas: progres misi, skor 5 skill (kognitif, empati, kreativitas, literasi, motorik), foto jurnal misi yang diunggah, dan pesan percakapan dengan asisten Mink.',
  ),
  LegalSection(
    'Kenapa data ini dikumpulkan',
    'Buat nampilin progres anak ke orang tua, ngasih rekomendasi misi yang sesuai skill anak, dan bikin balasan Mink terasa personal. Kami nggak jual data ini ke pihak manapun.',
  ),
  LegalSection(
    'Pihak ketiga yang terlibat',
    'Data disimpan di Supabase (server database). Pesan yang dikirim ke Mink diproses oleh Groq (penyedia AI) buat menghasilkan balasan — pesan chat dikirim ke Groq tapi nggak dipakai buat melatih model mereka secara permanen sesuai kebijakan mereka sendiri.',
  ),
  LegalSection(
    'Foto anak',
    'Foto profil dan foto jurnal misi disimpan di storage milik kami dan hanya bisa diakses oleh akun orang tua yang mengunggahnya. Kami nggak membagikan foto ini ke publik atau pihak ketiga.',
  ),
  LegalSection(
    'Hak kamu',
    'Kamu bisa minta salinan data anakmu atau minta akunmu dihapus kapan saja dengan menghubungi kami di cs@miroapp.com.',
  ),
];

const List<LegalSection> kPrivacyPolicyEn = [
  LegalSection(
    'What we collect',
    'From parents: name, email, and language preference. From child profiles: name, age, and profile photo (optional). From activity: mission progress, scores across 5 skills (cognitive, empathy, creativity, literacy, motor), uploaded mission journal photos, and chat messages with the Mink assistant.',
  ),
  LegalSection(
    'Why we collect it',
    "To show your child's progress, recommend missions matched to their skills, and make Mink's replies feel personal. We do not sell this data to anyone.",
  ),
  LegalSection(
    'Third parties involved',
    'Data is stored on Supabase. Messages sent to Mink are processed by Groq (an AI provider) to generate replies.',
  ),
  LegalSection(
    "Your child's photos",
    'Profile and mission journal photos are stored in our storage and only accessible by the parent account that uploaded them.',
  ),
  LegalSection(
    'Your rights',
    "You can request a copy of your child's data or ask us to delete your account anytime by contacting cs@miroapp.com.",
  ),
];

const List<LegalSection> kTermsOfServiceId = [
  LegalSection(
    'Buat siapa app ini',
    'MiRO dipakai oleh orang tua/wali untuk mendampingi anak menjalankan misi di dunia nyata. Akun didaftarkan dan dikelola oleh orang dewasa.',
  ),
  LegalSection(
    'Konten yang kamu unggah',
    'Foto jurnal misi yang diunggah tetap milikmu. Dengan mengunggahnya, kamu ngasih izin ke MiRO buat nampilinnya di dalam app (mis. di kolase jurnal), bukan buat dipublikasikan ke luar app.',
  ),
  LegalSection(
    'Batasan penggunaan',
    'Mink (asisten AI) dirancang buat bahas parenting dan fitur MiRO aja — bukan pengganti nasihat medis atau psikologis profesional.',
  ),
  LegalSection(
    'Perubahan layanan',
    'Fitur bisa berubah, ditambah, atau dihapus seiring waktu. Kami akan berusaha kasih tau perubahan besar lewat notifikasi in-app.',
  ),
];

const List<LegalSection> kTermsOfServiceEn = [
  LegalSection(
    'Who this app is for',
    'MiRO is used by parents/guardians to guide their child through real-world missions. Accounts are registered and managed by an adult.',
  ),
  LegalSection(
    'Content you upload',
    "Mission journal photos you upload remain yours. Uploading them grants MiRO permission to display them within the app, not to publish them outside it.",
  ),
  LegalSection(
    'Usage limits',
    "Mink (the AI assistant) is designed to discuss parenting and MiRO features only — it's not a substitute for professional medical or psychological advice.",
  ),
  LegalSection(
    'Changes to the service',
    'Features may change, be added, or removed over time. We will try to notify you of major changes via in-app notification.',
  ),
];
