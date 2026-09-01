import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preferensi ukuran teks (aksesibilitas) — belum ada sama sekali
/// sebelumnya, orang tua/anak dengan penglihatan lemah nggak punya cara
/// bikin tulisannya lebih besar.
enum AppTextSize { small, medium, large }

extension AppTextSizeX on AppTextSize {
  double get scaleFactor => switch (this) {
    AppTextSize.small => 0.9,
    AppTextSize.medium => 1.0,
    AppTextSize.large => 1.15,
  };

  String label(String lang) => switch (this) {
    AppTextSize.small => lang == 'id' ? 'Kecil' : 'Small',
    AppTextSize.medium => lang == 'id' ? 'Sedang' : 'Medium',
    AppTextSize.large => lang == 'id' ? 'Besar' : 'Large',
  };
}

class TextSizeNotifier extends Notifier<AppTextSize> {
  static const _key = 'text_size';

  @override
  AppTextSize build() {
    _load();
    return AppTextSize.medium;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved == null) return;
    state = AppTextSize.values.firstWhere(
      (e) => e.name == saved,
      orElse: () => AppTextSize.medium,
    );
  }

  Future<void> setSize(AppTextSize size) async {
    state = size;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, size.name);
  }
}

final textSizeProvider = NotifierProvider<TextSizeNotifier, AppTextSize>(
  () => TextSizeNotifier(),
);
