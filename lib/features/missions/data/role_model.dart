class RoleModel {
  final String id;
  final String nameId;
  final String nameEn;
  final String descriptionId;
  final String descriptionEn;
  final List<dynamic> skills;
  final String? bgImage;
  final String? cardImage;
  final String cardBgColor;

  RoleModel({
    required this.id,
    required this.nameId,
    required this.nameEn,
    required this.descriptionId,
    required this.descriptionEn,
    required this.skills,
    this.bgImage,
    this.cardImage,
    required this.cardBgColor,
  });

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    return RoleModel(
      id: json['id'] ?? '',
      nameId: json['role_name_id'] ?? '',
      nameEn: json['role_name_en'] ?? '',
      descriptionId: json['description_id'] ?? '',
      descriptionEn: json['description_en'] ?? '',
      skills: json['skills'] ?? [],
      bgImage: json['bg_image'],
      cardImage: json['card_image'],
      cardBgColor: json['card_bg_color'] ?? '0xFF0A264F',
    );
  }
}
