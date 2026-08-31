class MissionModel {
  final String id;
  final String roleId;
  final String titleId;
  final String titleEn;
  final String descriptionId;
  final String descriptionEn;
  final String? duration; // ✅ DITAMBAHKAN AGAR TIDAK ERROR DI INTRO SCREEN
  final List<dynamic> toolsId;
  final List<dynamic> toolsEn;
  final List<dynamic> stepsId;
  final List<dynamic> stepsEn;
  final String? parentMaterialId;
  final String? parentMaterialEn;
  final Map<String, dynamic> skillsReward;
  final int xpReward;

  MissionModel({
    required this.id,
    required this.roleId,
    required this.titleId,
    required this.titleEn,
    required this.descriptionId,
    required this.descriptionEn,
    this.duration,
    required this.toolsId,
    required this.toolsEn,
    required this.stepsId,
    required this.stepsEn,
    this.parentMaterialId,
    this.parentMaterialEn,
    required this.skillsReward,
    required this.xpReward,
  });

  factory MissionModel.fromJson(Map<String, dynamic> json) {
    return MissionModel(
      id: json['id'] ?? '',
      roleId: json['role_id'] ?? '',
      titleId: json['title_id'] ?? '',
      titleEn: json['title_en'] ?? '',
      descriptionId: json['description_id'] ?? '',
      descriptionEn: json['description_en'] ?? '',
      duration: json['duration']?.toString(), // ✅ Ambil durasi dari DB
      toolsId: json['tools_id'] ?? [],
      toolsEn: json['tools_en'] ?? [],
      stepsId: json['steps_id'] ?? [],
      stepsEn: json['steps_en'] ?? [],
      parentMaterialId: json['parent_material_id'],
      parentMaterialEn: json['parent_material_en'],
      skillsReward: json['skills_reward'] ?? {},
      xpReward: json['xp_reward'] ?? 10,
    );
  }
}
