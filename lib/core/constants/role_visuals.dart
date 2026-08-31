import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Skill yang dilatih oleh sebuah role (dipakai di bottom sheet detail role).
class RoleSkill {
  const RoleSkill({required this.nameId, required this.nameEn, required this.icon});

  final String nameId;
  final String nameEn;
  final String icon;

  String name(String lang) => lang == 'id' ? nameId : nameEn;
}

/// Metadata visual 1 role (Koki/Dokter/Pelukis/Atlet/Guru).
///
/// Sebelumnya data ini (nama, warna kartu, path gambar penguin) ditulis
/// ulang secara terpisah di minimal 5 file (`home_page.dart`,
/// `progress_page.dart`, `profile_page.dart`, `mission_journal_screen.dart`,
/// `all_certificates_page.dart`) — kadang pakai if-chain per role, kadang
/// literal Map. Sekarang cuma di sini. Tabel `roles_master` di Supabase
/// baru punya kolom nama (belum ada gambar/warna), jadi bagian visual ini
/// masih perlu di-hardcode di client sampai kolomnya ditambah.
class RoleVisual {
  const RoleVisual({
    required this.id,
    required this.nameId,
    required this.nameEn,
    required this.descriptionId,
    required this.descriptionEn,
    required this.skills,
    required this.penguinIcon,
    required this.bgImage,
    required this.tint,
    required this.badgeColor,
  });

  final String id;
  final String nameId;
  final String nameEn;
  final String descriptionId;
  final String descriptionEn;
  final List<RoleSkill> skills;
  final String penguinIcon;
  final String bgImage;
  final Color tint;
  final Color badgeColor;

  String name(String lang) => lang == 'id' ? nameId : nameEn;
  String description(String lang) => lang == 'id' ? descriptionId : descriptionEn;
}

const List<RoleVisual> kRoleVisuals = [
  RoleVisual(
    id: 'artist',
    nameId: 'Pelukis',
    nameEn: 'Artist',
    descriptionId: 'Ekspresikan dirimu lewat warna, bentuk, dan kreativitas.',
    descriptionEn: 'Express yourself through colors, shapes, and creativity.',
    skills: [
      RoleSkill(nameId: 'Kreativitas', nameEn: 'Creativity', icon: '🎨'),
      RoleSkill(nameId: 'Motorik', nameEn: 'Motor Skills', icon: '🧩'),
    ],
    penguinIcon: 'assets/images/penguin_artist.png',
    bgImage: 'assets/images/artist_trans.png',
    tint: AppColors.accentTint,
    badgeColor: AppColors.accent,
  ),
  RoleVisual(
    id: 'chef',
    nameId: 'Koki',
    nameEn: 'Chef',
    descriptionId: 'Belajar membuat makanan sambil mengenal tekstur dan rasa.',
    descriptionEn:
        'Learn to make food while getting to know textures and flavors.',
    skills: [
      RoleSkill(nameId: 'Kognitif', nameEn: 'Cognitive', icon: '🧠'),
      RoleSkill(nameId: 'Motorik', nameEn: 'Motor Skills', icon: '🧩'),
    ],
    penguinIcon: 'assets/images/penguin_chef.png',
    bgImage: 'assets/images/chef_trans.png',
    tint: AppColors.primaryTint,
    badgeColor: Color(0xFF75AADB),
  ),
  RoleVisual(
    id: 'doctor',
    nameId: 'Dokter',
    nameEn: 'Doctor',
    descriptionId:
        'Jelajahi tubuh manusia dan belajar merawat orang lain tanpa gawai.',
    descriptionEn:
        'Explore the human body and learn how to care for others screen free.',
    skills: [
      RoleSkill(nameId: 'Kognitif', nameEn: 'Cognitive', icon: '🧠'),
      RoleSkill(nameId: 'Empati', nameEn: 'Empathy', icon: '💗'),
    ],
    penguinIcon: 'assets/images/penguin_doctor.png',
    bgImage: 'assets/images/doctor_trans.png',
    tint: AppColors.successTint,
    badgeColor: Color(0xFF81C784),
  ),
  RoleVisual(
    id: 'athlete',
    nameId: 'Atlet',
    nameEn: 'Athlete',
    descriptionId: 'Latih ketangkasan fisik dan sportivitasmu sejak dini.',
    descriptionEn: 'Train your physical agility and sportsmanship early on.',
    skills: [
      RoleSkill(nameId: 'Motorik', nameEn: 'Motoric', icon: '🏃'),
      RoleSkill(nameId: 'Kognitif', nameEn: 'Cognitive', icon: '🧠'),
    ],
    penguinIcon: 'assets/images/penguin_athlete.png',
    bgImage: 'assets/images/frost.png',
    tint: Color(0xFFFFF0E6),
    badgeColor: Color(0xFFFFB74D),
  ),
  RoleVisual(
    id: 'teacher',
    nameId: 'Guru',
    nameEn: 'Teacher',
    descriptionId: 'Berbagi ilmu dan latih komunikasimu dengan gembira.',
    descriptionEn: 'Share knowledge and train your communication happily.',
    skills: [
      RoleSkill(nameId: 'Literasi', nameEn: 'Literacy', icon: '📚'),
      RoleSkill(nameId: 'Empati', nameEn: 'Empathy', icon: '💗'),
    ],
    penguinIcon: 'assets/images/penguin_teacher.png',
    bgImage: 'assets/images/frost.png',
    tint: Color(0xFFE6FAF0),
    badgeColor: Color(0xFF4DB6AC),
  ),
];

RoleVisual? roleVisualById(String? id) {
  if (id == null) return null;
  for (final r in kRoleVisuals) {
    if (r.id == id) return r;
  }
  return null;
}

/// Fallback dipakai kalau role_id dari database nggak ketemu di daftar di atas.
const RoleVisual kUnknownRoleVisual = RoleVisual(
  id: 'unknown',
  nameId: 'Penjelajah',
  nameEn: 'Explorer',
  descriptionId: '',
  descriptionEn: '',
  skills: [],
  penguinIcon: 'assets/images/penguin_head.png',
  bgImage: 'assets/images/frost.png',
  tint: AppColors.primaryTint,
  badgeColor: Color(0xFF90A4AE),
);
