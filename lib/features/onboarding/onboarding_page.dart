import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/widgets/step_progress_bar.dart';
import '../../shared/widgets/back_button.dart';
import '../../shared/widgets/coming_soon_badge.dart';
import '../../core/providers/recent_accounts_provider.dart';
import '../../core/router/app_page_transition.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../legal/legal_page.dart';

// 🔥 IMPORT SAKLAR UTAMA DARI FILE CHATBOT
import '../../shared/widgets/penguin_chat_bot.dart';

// ==========================================
// 1. DICTIONARY (KAMUS BAHASA) - ENGLISH DEFAULT
// ==========================================
const Map<String, Map<String, String>> _t = {
  'en': {
    'splash_desc': 'Exciting adventures\nwithout screen time',
    'splash_tap': 'Tap anywhere to continue',
    'lang_title': 'Choose\nlanguage',
    'lang_desc': 'You can change this anytime',
    'btn_next': 'Next',
    'start_welcome': 'Welcome to MiRO',
    'start_title': 'Start your little\none\'s journey',
    'btn_login': 'Login',
    'btn_register': 'Register',
    'login_welcome': 'Welcome back!',
    'login_desc': 'Let\'s continue your journey',
    'reg_title': 'Create your account',
    'reg_desc': 'Start the learning journey today',
    'email_label': 'Email',
    'pass_label': 'Password',
    'name_label': 'Full Name',
    'conf_pass_label': 'Confirm Password',
    'btn_google': 'Continue with Google',
    'switch_reg': 'Don\'t have an account? Sign Up',
    'switch_login': 'Already have an account? Login',
    'email_hint': '(type your email)',
    'name_hint': '(type your full name)',
    'divider_signup': 'or Sign up with',
    'divider_login': 'or Login with',
    'err_password_mismatch': "Passwords do not match!",
    'err_email_taken': "This email is already registered. Try logging in instead.",
    'err_invalid_credentials': "Incorrect email or password.",
    'err_password_too_short': "Password must be at least 6 characters.",
    'err_invalid_email': "That doesn't look like a valid email address.",
    'err_auth_generic': "Something went wrong. Please check your connection and try again.",
    'err_must_agree_terms': "Please check the box to agree to the Terms & Privacy Policy first.",
    'err_profile_setup_failed': "Your account was created but we couldn't finish setting it up. Please try logging in -- if that doesn't work, try registering again.",
    'recent_accounts': "Recent accounts on this device",
  },
  'id': {
    'splash_desc': 'Petualangan seru\ntanpa layar gawai',
    'splash_tap': 'Ketuk di mana saja untuk lanjut',
    'lang_title': 'Pilih\nbahasa',
    'lang_desc': 'Kamu bisa mengubahnya kapan saja',
    'btn_next': 'Lanjut',
    'start_welcome': 'Selamat datang di MiRO',
    'start_title': 'Mulai perjalanan\nbelajar si kecil',
    'btn_login': 'Masuk',
    'btn_register': 'Daftar',
    'login_welcome': 'Selamat datang kembali!',
    'login_desc': 'Mari lanjutkan perjalananmu',
    'reg_title': 'Buat akun barumu',
    'reg_desc': 'Mulai perjalanan belajar si kecil hari ini',
    'email_label': 'Email',
    'pass_label': 'Kata Sandi',
    'name_label': 'Nama Lengkap',
    'conf_pass_label': 'Konfirmasi kata sandi',
    'btn_google': 'Lanjutkan dengan Google',
    'switch_reg': 'Belum punya akun? Buat Akun Baru',
    'switch_login': 'Sudah punya akun? Masuk',
    'email_hint': '(ketik email kamu)',
    'name_hint': '(ketik nama lengkapmu)',
    'divider_signup': 'atau daftar dengan',
    'divider_login': 'atau masuk dengan',
    'err_password_mismatch': "Password tidak cocok!",
    'err_email_taken': "Email ini udah kedaftar. Coba login aja langsung.",
    'err_invalid_credentials': "Email atau password salah.",
    'err_password_too_short': "Password minimal 6 karakter.",
    'err_invalid_email': "Format emailnya kayaknya belum bener.",
    'err_auth_generic': "Ada yang salah. Cek koneksi internetmu terus coba lagi ya.",
    'err_must_agree_terms': "Centang dulu kotak setuju Syarat & Kebijakan Privasi-nya ya.",
    'err_profile_setup_failed': "Akunmu udah kebuat tapi ada masalah pas nyelesein setup-nya. Coba login dulu ya -- kalau masih gagal, coba daftar ulang lagi.",
    'recent_accounts': "Akun yang pernah login di HP ini",
  },
};

enum OnboardingStep { splash, language, startJourney, login, register }

// ==========================================
// 2. PROVIDERS (MODERN RIVERPOD 2.0+ / 3.0+)
// ==========================================

final onboardingStepProvider =
    NotifierProvider<OnboardingStepNotifier, OnboardingStep>(() {
  return OnboardingStepNotifier();
});

class OnboardingStepNotifier extends Notifier<OnboardingStep> {
  @override
  OnboardingStep build() {
    return OnboardingStep.splash; // Initial state
  }

  void setStep(OnboardingStep step) {
    state = step;
  }
}

final selectedLanguageProvider = NotifierProvider<LanguageNotifier, String>(() {
  return LanguageNotifier();
});

class LanguageNotifier extends Notifier<String> {
  bool _hasManuallySelected = false;

  @override
  String build() {
    _init();
    return 'en'; // Initial state sementara
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLang = prefs.getString('lang');

    // Hanya timpa state JIKA user belum mengeklik tombol bahasa di layar
    if (savedLang != null && !_hasManuallySelected) {
      state = savedLang;
    }
  }

  Future<void> setLang(String code) async {
    _hasManuallySelected = true;
    state = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lang', code);
  }
}

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});
  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;

  // Dulu link ToS/Privacy di layar daftar cuma teks pasif — tombol
  // Daftar tetap aktif & langsung submit walau nggak pernah dicentang/
  // dibaca. Sekarang dijadiin gate beneran sebelum submit.
  bool _agreedToTerms = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(showChatbotGlobalProvider.notifier).hide();
    });
    _restoreSessionIfAny();
  }

  /// Sebelumnya app SELALU mulai dari splash/login, walau ada session
  /// Supabase yang masih valid (Supabase persist session-nya otomatis di
  /// device, tapi di sini nggak pernah dicek) — jadi orang tua yang udah
  /// login harus login ulang manual tiap kali app dibuka lagi. Sekarang
  /// dicek dulu pas halaman ini pertama kali muncul.
  Future<void> _restoreSessionIfAny() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return;

    setState(() => _isLoading = true);
    try {
      final children = await Supabase.instance.client
          .from('children')
          .select('id')
          .eq('parent_id', session.user.id)
          .limit(1);
      if (!mounted) return;
      if (children.isNotEmpty) {
        context.go('/home');
      } else {
        context.go('/identify');
      }
    } catch (e) {
      // Gagal cek (mis. lagi offline) — bukan fatal, biarin aja lanjut ke
      // alur onboarding/login normal daripada nyangkut di loading terus.
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  // ==========================================
  // 3. AUTH LOGIC (RLS & DATABASE SYNC)
  // ==========================================
  /// Dulu error registrasi/login ditampilin mentah dari
  /// `AuthException`/exception lain (`e.toString()`), selalu bahasa
  /// Inggris walau app-nya lagi di mode Indonesia, dan kadang bunyinya
  /// teknis banget (mis. "AuthApiException: User already registered").
  /// Sekarang dipetakan ke pesan yang jelas & ngikutin bahasa aktif —
  /// error asli-nya tetap di-log ke console buat debugging.
  String _friendlyAuthError(Object e, Map<String, String> texts) {
    final String raw = e is AuthException ? e.message : e.toString();
    final String lower = raw.toLowerCase();
    debugPrint("Auth error: $raw");

    if (lower.contains('already registered') || lower.contains('already exists')) {
      return texts['err_email_taken']!;
    }
    if (lower.contains('invalid login credentials')) {
      return texts['err_invalid_credentials']!;
    }
    if (lower.contains('password') && lower.contains('6 characters')) {
      return texts['err_password_too_short']!;
    }
    if (lower.contains('email') &&
        (lower.contains('invalid') || lower.contains('valid'))) {
      return texts['err_invalid_email']!;
    }
    return texts['err_auth_generic']!;
  }

  Future<void> _handleRegister() async {
    final lang = ref.read(selectedLanguageProvider);
    final texts = _t[lang] ?? _t['en']!;

    if (_passwordController.text != _confirmController.text) {
      _showMsg(texts['err_password_mismatch']!);
      return;
    }
    if (!_agreedToTerms) {
      _showMsg(texts['err_must_agree_terms']!);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final AuthResponse res = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (res.user != null) {
        // auth.signUp() sudah berhasil (user Supabase Auth udah kebuat)
        // begitu sampai sini -- kalau insert ke tabel parents di bawah ini
        // gagal (mis. koneksi putus di tengah jalan), dulu user itu jadi
        // "orphan": punya akun auth tapi nggak ada baris parents, dan
        // nyangkut nggak bisa daftar ulang (email udah "terdaftar") maupun
        // login normal (nanti crash pas coba bikin anak karena parent_id-nya
        // nggak ada). Nggak ada akses admin/service-role dari client buat
        // beneran rollback si auth user, jadi mitigasinya: signOut supaya
        // nggak nyangkut di sesi yang setengah jadi, dan pesan errornya
        // dibikin jelas suruh coba login -- _handleLogin() di bawah upsert
        // baris parents kalau belum ada, jadi self-heal pas mereka login.
        try {
          await supabase.from('parents').insert({
            'id': res.user!.id,
            'email': _emailController.text.trim(),
            'full_name': _nameController.text.trim(),
            'language_code': ref.read(selectedLanguageProvider),
          });
          await ref.read(recentAccountsProvider.notifier).remember(
                _emailController.text,
                _nameController.text,
              );
          if (mounted) context.go('/identify');
        } catch (insertError) {
          debugPrint("Gagal insert parents setelah signUp: $insertError");
          await supabase.auth.signOut();
          if (mounted) {
            _showMsg(texts['err_profile_setup_failed']!);
          }
        }
      }
    } catch (e) {
      _showMsg(_friendlyAuthError(e, texts));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogin() async {
    final lang = ref.read(selectedLanguageProvider);
    final texts = _t[lang] ?? _t['en']!;

    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final res = await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (res.user != null) {
        // UPDATE database pakai bahasa yang baru user pilih! (upsert, bukan
        // update biasa -- kalau baris parents-nya belum ada sama sekali,
        // misalnya karena insert-nya gagal pas registrasi dulu, ini bikinin
        // baris barunya sekarang juga daripada diem-diem gagal nge-update
        // 0 baris. Lihat catatan self-heal di _handleRegister().)
        await supabase.from('parents').upsert({
          'id': res.user!.id,
          'email': res.user!.email ?? _emailController.text.trim(),
          'language_code': ref.read(selectedLanguageProvider),
        });

        // Cek anak milik parent INI (dulu query ini nggak difilter
        // `parent_id` sama sekali — cek "ada anak di seluruh tabel" bukan
        // "anak milik akun ini". Juga pakai list+limit, bukan
        // `.maybeSingle()`, biar nggak error kalau parent ini udah punya
        // lebih dari 1 anak.)
        final children = await supabase
            .from('children')
            .select('id')
            .eq('parent_id', res.user!.id)
            .limit(1);

        await ref.read(recentAccountsProvider.notifier).remember(
              res.user!.email ?? _emailController.text,
              res.user!.userMetadata?['full_name'] ??
                  (res.user!.email ?? '').split('@').first,
            );

        if (mounted) {
          children.isEmpty ? context.go('/identify') : context.go('/home');
        }
      }
    } catch (e) {
      _showMsg(_friendlyAuthError(e, texts));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMsg(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    final step = ref.watch(onboardingStepProvider);
    final lang = ref.watch(selectedLanguageProvider);

    // 🔥 PERBAIKAN 1: SAFE FALLBACK AGAR TIDAK CRASH JIKA BAHASA ERROR
    final texts = _t[lang] ?? _t['en']!;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(showChatbotGlobalProvider)) {
        ref.read(showChatbotGlobalProvider.notifier).hide();
      }
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Background (Menjaga Styling Aslimu)
          if (step == OnboardingStep.splash)
            Container(color: AppColors.primary)
          else
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primaryLighter,
                    const Color(0xFFD3E3F2),
                    const Color(0xFFE9DFCE),
                  ],
                ),
              ),
            ),

          if (step != OnboardingStep.splash)
            Positioned.fill(
              child: Image.asset(
                'assets/images/snow.png',
                fit: BoxFit.cover,
                opacity: const AlwaysStoppedAnimation(0.65),
                // 🔥 PERBAIKAN 2: CEGAH GREY BOX JIKA GAMBAR GAGAL LOAD
                errorBuilder: (context, error, stackTrace) => const SizedBox(),
              ),
            ),

          SafeArea(child: _buildScreen(step, lang, texts)),

          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildScreen(
    OnboardingStep step,
    String lang,
    Map<String, String> texts,
  ) {
    switch (step) {
      case OnboardingStep.splash:
        return _buildSplashScreen(texts);
      case OnboardingStep.language:
        return _buildLanguageScreen(lang, texts);
      case OnboardingStep.startJourney:
        return _buildStartJourneyScreen(texts);
      case OnboardingStep.login:
        return _buildLoginScreen(texts);
      case OnboardingStep.register:
        return _buildRegisterScreen(texts);
    }
  }

  // ==================== SPLASH SCREEN ====================
  Widget _buildSplashScreen(Map<String, String> texts) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => ref
          .read(onboardingStepProvider.notifier)
          .setStep(OnboardingStep.language),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: 48,
            left: 40,
            child: Image.asset(
              'assets/images/logo_splash1.png',
              width: 70,
              errorBuilder: (c, e, s) => const SizedBox(),
            ),
          ),
          Positioned(
            top: 150,
            left: 40,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "MiRO",
                  style: TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  texts['splash_desc']!,
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.white70,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 40),
                Row(
                  children: const [
                    _Dot(active: true),
                    SizedBox(width: 10),
                    _Dot(active: false),
                    SizedBox(width: 10),
                    _Dot(active: false),
                  ],
                ),
                const SizedBox(height: 40),
                Text(
                  texts['splash_tap']!,
                  style: const TextStyle(color: Colors.white60, fontSize: 13),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: -30,
            right: -120,
            child: Image.asset(
              'assets/images/penguin_splash1.png',
              width: 480,
              fit: BoxFit.contain,
              errorBuilder: (c, e, s) => const SizedBox(),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== LANGUAGE SCREEN ====================
  Widget _buildLanguageScreen(String lang, Map<String, String> texts) {
    return Column(
      children: [
        const StepProgressBar(currentStep: 1, totalSteps: 3),
        const SizedBox(height: 64),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  texts['lang_title']!,
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  texts['lang_desc']!,
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.primary.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFB5C9DF).withValues(alpha: 0.5), // 🔥 PERBAIKAN 3
              borderRadius: BorderRadius.circular(28),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _languageOption("Bahasa Indonesia", "id", lang),
                const SizedBox(height: 12),
                _languageOption("English", "en", lang),
              ],
            ),
          ),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 0, 32, 40),
          child: ElevatedButton(
            onPressed: () => ref
                .read(onboardingStepProvider.notifier)
                .setStep(OnboardingStep.startJourney),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size(double.infinity, 60),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
            ),
            child: Text(
              texts['btn_next']!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _languageOption(String title, String value, String current) {
    final isSelected = current == value;
    return GestureDetector(
      onTap: () => ref.read(selectedLanguageProvider.notifier).setLang(value),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.65), // 🔥 PERBAIKAN 3
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.accent : Colors.grey,
                  width: 2.5,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: CircleAvatar(
                        radius: 6,
                        backgroundColor: AppColors.accent,
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // ==================== START JOURNEY SCREEN ====================
  Widget _buildStartJourneyScreen(Map<String, String> texts) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const StepProgressBar(currentStep: 2, totalSteps: 3),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: CustomBackButton(
                  onPressed: () => ref
                      .read(onboardingStepProvider.notifier)
                      .setStep(OnboardingStep.language),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 120,
          right: -130,
          child: Image.asset(
            'assets/images/penguin_splash2.png',
            width: 480,
            fit: BoxFit.contain,
            errorBuilder: (c, e, s) => const SizedBox(),
          ),
        ),
        Positioned(
          bottom: 40,
          left: 32,
          right: 32,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                texts['start_welcome']!,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                texts['start_title']!,
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                  height: 1.15,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 40),
              Row(
                children: [
                  Expanded(
                    child: _authChoiceBtn(
                      texts['btn_login']!,
                      AppColors.accent,
                      () => ref
                          .read(onboardingStepProvider.notifier)
                          .setStep(OnboardingStep.login),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _authChoiceBtn(
                      texts['btn_register']!,
                      AppColors.primary,
                      () => ref
                          .read(onboardingStepProvider.notifier)
                          .setStep(OnboardingStep.register),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _authChoiceBtn(String label, Color color, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 18, color: Colors.white),
      ),
    );
  }

  // Chip akun yang PERNAH login di device ini (max 3, terbaru duluan) --
  // tap buat isi cepet kolom email, password tetep harus diketik ulang
  // (nggak ada password/token yang disimpan). Berguna buat device yang
  // gantian dipakai lebih dari 1 orang tua/akun.
  Widget _buildRecentAccountsRow(Map<String, String> texts) {
    final accounts = ref.watch(recentAccountsProvider);
    if (accounts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          texts['recent_accounts']!,
          style: TextStyle(
            color: AppColors.primary.withValues(alpha: 0.6),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: accounts.map((account) {
            final label = account.displayName.isNotEmpty
                ? account.displayName
                : account.email;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _emailController.text = account.email;
                  _passwordController.clear();
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person_outline, size: 14, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(color: AppColors.primary, fontSize: 13),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ==================== LOGIN SCREEN ====================
  Widget _buildLoginScreen(Map<String, String> texts) {
    return Column(
      children: [
        const StepProgressBar(currentStep: 3, totalSteps: 3),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Align(
            alignment: Alignment.centerLeft,
            child: CustomBackButton(
              onPressed: () => ref
                  .read(onboardingStepProvider.notifier)
                  .setStep(OnboardingStep.startJourney),
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            child: Column(
              children: [
                const SizedBox(height: 16),
                Text(
                  texts['login_welcome']!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  texts['login_desc']!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.primary.withValues(alpha: 0.6),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                _buildRecentAccountsRow(texts),
                const SizedBox(height: 16),
                _CustomTextField(
                  label: texts['email_label']!,
                  icon: Icons.email_outlined,
                  placeholder: texts['email_hint']!,
                  controller: _emailController,
                ),
                const SizedBox(height: 20),
                _CustomTextField(
                  label: texts['pass_label']!,
                  icon: Icons.lock_outline,
                  placeholder: "********",
                  isPassword: true,
                  controller: _passwordController,
                ),
              ],
            ),
          ),
        ),
        _buildStickyBottom(texts: texts, isReg: false, onPrimary: _handleLogin),
      ],
    );
  }

  // ==================== REGISTER SCREEN ====================
  Widget _buildRegisterScreen(Map<String, String> texts) {
    return Column(
      children: [
        const StepProgressBar(currentStep: 3, totalSteps: 3),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Align(
            alignment: Alignment.centerLeft,
            child: CustomBackButton(
              onPressed: () => ref
                  .read(onboardingStepProvider.notifier)
                  .setStep(OnboardingStep.startJourney),
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Text(
                  texts['reg_title']!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  texts['reg_desc']!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.primary.withValues(alpha: 0.6),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 32),
                _CustomTextField(
                  label: texts['name_label']!,
                  icon: Icons.person_outline,
                  placeholder: texts['name_hint']!,
                  controller: _nameController,
                ),
                const SizedBox(height: 16),
                _CustomTextField(
                  label: texts['email_label']!,
                  icon: Icons.email_outlined,
                  placeholder: texts['email_hint']!,
                  controller: _emailController,
                ),
                const SizedBox(height: 16),
                _CustomTextField(
                  label: texts['pass_label']!,
                  icon: Icons.lock_outline,
                  placeholder: "********",
                  isPassword: true,
                  controller: _passwordController,
                ),
                const SizedBox(height: 16),
                _CustomTextField(
                  label: texts['conf_pass_label']!,
                  icon: Icons.lock_outline,
                  placeholder: "********",
                  isPassword: true,
                  controller: _confirmController,
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _agreedToTerms,
                      activeColor: AppColors.accent,
                      onChanged: (val) => setState(() => _agreedToTerms = val ?? false),
                    ),
                    Expanded(child: _buildLegalAgreementText()),
                  ],
                ),
              ],
            ),
          ),
        ),
        _buildStickyBottom(
          texts: texts,
          isReg: true,
          onPrimary: _handleRegister,
        ),
      ],
    );
  }

  // Sebelumnya nggak ada link Syarat & Ketentuan / Kebijakan Privasi di
  // manapun di flow pendaftaran.
  Widget _buildLegalAgreementText() {
    final lang = ref.read(selectedLanguageProvider);
    final isId = lang == 'id';
    final linkStyle = TextStyle(
      color: AppColors.primary,
      fontSize: 12,
      fontWeight: FontWeight.bold,
      decoration: TextDecoration.underline,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: TextStyle(color: AppColors.primary.withValues(alpha: 0.6), fontSize: 12),
          children: [
            TextSpan(text: isId ? 'Dengan mendaftar, kamu setuju dengan ' : 'By signing up, you agree to our '),
            TextSpan(
              text: isId ? 'Syarat & Ketentuan' : 'Terms of Service',
              style: linkStyle,
              recognizer: TapGestureRecognizer()
                ..onTap = () => Navigator.of(context, rootNavigator: true).push(
                      appPageRoute(
                        LegalPage(
                          title: isId ? 'Syarat & Ketentuan' : 'Terms of Service',
                          sections: isId ? kTermsOfServiceId : kTermsOfServiceEn,
                        ),
                      ),
                    ),
            ),
            TextSpan(text: isId ? ' dan ' : ' and '),
            TextSpan(
              text: isId ? 'Kebijakan Privasi' : 'Privacy Policy',
              style: linkStyle,
              recognizer: TapGestureRecognizer()
                ..onTap = () => Navigator.of(context, rootNavigator: true).push(
                      appPageRoute(
                        LegalPage(
                          title: isId ? 'Kebijakan Privasi' : 'Privacy Policy',
                          sections: isId ? kPrivacyPolicyId : kPrivacyPolicyEn,
                        ),
                      ),
                    ),
            ),
            const TextSpan(text: '.'),
          ],
        ),
      ),
    );
  }

  Widget _buildStickyBottom({
    required Map<String, String> texts,
    required bool isReg,
    required VoidCallback onPrimary,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            onPressed: onPrimary,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
            ),
            child: Text(
              isReg ? texts['btn_register']! : texts['btn_login']!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Divider(color: AppColors.primary, thickness: 1),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  isReg ? texts['divider_signup']! : texts['divider_login']!,
                  style: TextStyle(
                    color: AppColors.primary.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ),
              Expanded(
                child: Divider(color: AppColors.primary, thickness: 1),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _googleBtn(texts['btn_google']!),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isReg
                    ? "${texts['switch_login']!.split('?')[0]}? "
                    : "${texts['switch_reg']!.split('?')[0]}? ",
                style: TextStyle(color: AppColors.primary, fontSize: 13),
              ),
              GestureDetector(
                onTap: () => ref.read(onboardingStepProvider.notifier).setStep(
                      isReg ? OnboardingStep.login : OnboardingStep.register,
                    ),
                child: Text(
                  isReg ? texts['btn_login']! : texts['btn_register']!,
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _googleBtn(String label) {
    // Belum ada integrasi Google OAuth beneran — dulu tombol ini keliatan
    // aktif tapi diem aja pas dipencet. Sekarang jelas ditandain belum jadi.
    return ComingSoonBadge(
      child: ElevatedButton.icon(
        onPressed: null,
        icon: Image.asset(
          'assets/images/google.png',
          width: 24,
          errorBuilder: (c, e, s) => const SizedBox(width: 24, height: 24),
        ),
        label: Text(
          label,
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.surface,
          disabledBackgroundColor: AppColors.surface,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            side: BorderSide(color: Colors.grey.shade300),
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final bool active;
  const _Dot({required this.active});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? Colors.white : Colors.white.withValues(alpha: 0.25),
      ),
    );
  }
}

class _CustomTextField extends StatefulWidget {
  final String label;
  final IconData icon;
  final String placeholder;
  final bool isPassword;
  final TextEditingController controller;

  const _CustomTextField({
    required this.label,
    required this.icon,
    required this.placeholder,
    required this.controller,
    this.isPassword = false,
  });

  @override
  State<_CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<_CustomTextField> {
  bool _obscureText = true;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Row(
            children: [
              Icon(widget.icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        TextField(
          controller: widget.controller,
          obscureText: widget.isPassword ? _obscureText : false,
          style: TextStyle(color: AppColors.primary),
          decoration: InputDecoration(
            hintText: widget.placeholder,
            hintStyle: TextStyle(
              color: AppColors.primary.withValues(alpha: 0.4),
              fontSize: 14,
            ),
            filled: true,
            fillColor: AppColors.surface.withValues(alpha: 0.5), // 🔥 PERBAIKAN 3
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              borderSide: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              borderSide: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              borderSide: BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(
                      _obscureText
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.primary.withValues(alpha: 0.6),
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscureText = !_obscureText),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
