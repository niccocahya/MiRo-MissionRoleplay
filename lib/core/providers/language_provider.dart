import 'package:flutter/foundation.dart'; // Untuk pakai debugPrint
import 'package:flutter_riverpod/flutter_riverpod.dart'; // JANGAN PAKAI legacy.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Provider utama untuk bahasa (Default: English)
final languageProvider = NotifierProvider<LanguageNotifier, String>(() {
  return LanguageNotifier();
});

class LanguageNotifier extends Notifier<String> {
  // Provider ini dibuat SEKALI, jauh di awal (di-watch dari MyApp sejak app
  // pertama kali render) -- _loadSavedLanguage() di bawah cuma baca
  // SharedPreferences SEKALI itu juga, saat provider ini pertama kebentuk.
  // Kalau user manggil setLanguage() (mis. milih bahasa di onboarding)
  // SEBELUM load awal itu selesai, load yang telat itu bisa nimpa balik
  // pilihan user yang udah beres duluan -- guard ini yang nyegah itu (sama
  // persis kayak proteksi yang dulu ada di provider bahasa terpisah punya
  // onboarding, sebelum provider itu dibubarin & disatuin ke sini).
  bool _hasManuallySelected = false;

  @override
  String build() {
    // Tarik bahasa dari penyimpanan lokal secara asinkron
    _loadSavedLanguage();
    // 🔥 PERBAIKAN 1: Ubah default ke 'en' (bukan 'id')
    return 'en';
  }

  // Load bahasa saat aplikasi pertama kali dibuka
  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    // 🔥 PERBAIKAN 2: Gunakan key yang konsisten dengan onboarding: 'lang'
    // Fallback tetap 'en' agar default global Inggris
    final savedLang = prefs.getString('lang') ?? 'en';
    if (state != savedLang && !_hasManuallySelected) {
      state = savedLang;
    }
  }

  // Fungsi ganti bahasa utama
  Future<void> setLanguage(String code) async {
    _hasManuallySelected = true;
    state = code;

    // 1. Simpan Lokal dengan key 'lang' (konsisten)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lang', code);

    // 2. Simpan ke Database (Jika user sudah login)
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client
            .from('parents')
            .update({'language_code': code})
            .eq('id', user.id);
        debugPrint("✅ Database language updated to: $code");
      }
    } catch (e) {
      debugPrint("❌ Gagal update bahasa di database: $e");
    }
  }

  // Alias penyelamat! Biar kodingan OnboardingPage yang tadi pakai nama .setLang() nggak error
  Future<void> setLang(String code) => setLanguage(code);
}
