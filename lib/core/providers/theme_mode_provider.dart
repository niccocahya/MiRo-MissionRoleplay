import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preferensi tema (dark mode) — sebelumnya app cuma punya mode terang,
/// nggak ada opsi sama sekali.
///
/// Default `light` (BUKAN `system`) -- awalnya dicoba `system` biar user
/// baru otomatis dapat dark mode kalau HP-nya di-set dark, tapi layar
/// onboarding/login (background gradasi pastel-nya sengaja SELALU terang,
/// nggak ikut tema) belum di-migrasi ke token warna yang reaktif ke dark
/// mode -- jadinya teks & kotak input di situ ikut kepakein warna dark
/// mode di atas background yang tetep terang, kontrasnya jadi rusak
/// (teks nyaris nggak keliatan). Default balik ke `light` biar user baru
/// nggak nemuin itu duluan; dark mode masih bisa dipilih manual di
/// Pengaturan.
enum AppThemeMode { system, light, dark }

extension AppThemeModeX on AppThemeMode {
  String label(String lang) => switch (this) {
    AppThemeMode.system => lang == 'id' ? 'Ikuti Sistem' : 'System',
    AppThemeMode.light => lang == 'id' ? 'Terang' : 'Light',
    AppThemeMode.dark => lang == 'id' ? 'Gelap' : 'Dark',
  };
}

class ThemeModeNotifier extends Notifier<AppThemeMode> {
  static const _key = 'theme_mode';

  @override
  AppThemeMode build() {
    _load();
    return AppThemeMode.light;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved == null) return;
    state = AppThemeMode.values.firstWhere(
      (e) => e.name == saved,
      orElse: () => AppThemeMode.light,
    );
  }

  Future<void> setMode(AppThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, AppThemeMode>(
  () => ThemeModeNotifier(),
);
