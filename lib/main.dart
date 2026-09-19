import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Import router dan provider bahasa
import 'core/router/app_router.dart';
import 'core/providers/language_provider.dart';
import 'core/providers/text_size_provider.dart';
import 'core/theme/app_scroll_behavior.dart';
import 'core/theme/app_theme.dart';

// IMPORT WIDGET PINGUIN GLOBAL
// Mink (PenguinChatButton) DISEMBUNYIKAN SEMENTARA atas permintaan --
// import-nya dikomentari bareng pemasangannya di bawah (lihat blok
// "PINGUIN THE MASTER OVERLAY" di builder MaterialApp.router). Fitur &
// kodenya nggak dihapus sama sekali, tinggal buka comment 2 bagian ini
// lagi buat nyalain balik.
// import 'shared/widgets/penguin_chat_bot.dart';

// Diisi lewat --dart-define-from-file=env.json (lihat env.example.json).
// Jangan taruh key beneran langsung di source lagi ya.
const String _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const String _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // BUKAN assert() -- assert DIBUANG TOTAL di build --release (no-op),
  // jadi kalau APK release ke-build TANPA --dart-define-from-file=env.json,
  // _supabaseUrl/_supabaseAnonKey diam-diam kompilasi jadi STRING KOSONG,
  // assert-nya nggak pernah sempat bunyi (udah dibuang duluan), dan
  // Supabase.initialize() jalan dengan url kosong -- app kebuka normal,
  // tapi SETIAP panggilan ke Supabase (login, daftar, apa pun) gagal
  // total tanpa jejak DI SERVER SAMA SEKALI (nggak ada tempat yang
  // dituju), keliatan persis kayak "nggak bisa reach server" padahal
  // penyebabnya bukan jaringan ATAU server -- APK-nya sendiri yang
  // ke-build salah. Ini KEJADIAN NYATA (baru ketauan setelah bongkar
  // APK & nyari string URL-nya di binary -- nggak ketemu sama sekali).
  // Sekarang ini nyata-nyata BERHENTI app-nya (di build APAPUN, release
  // termasuk) dengan pesan yang jelas, bukan diam-diam lanjut jalan
  // dengan client yang nggak akan pernah bisa connect ke mana pun.
  if (_supabaseUrl.isEmpty || _supabaseAnonKey.isEmpty) {
    throw StateError(
      'SUPABASE_URL / SUPABASE_ANON_KEY belum ke-set (kosong). '
      'Build ulang pakai --dart-define-from-file=env.json (copy dari '
      'env.example.json) -- tanpa ini APK-nya kebuka normal tapi SETIAP '
      'panggilan ke Supabase bakal gagal total, keliatan kayak masalah '
      'jaringan padahal bukan.',
    );
  }

  await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Di-watch (bukan cuma dibaca) supaya seluruh tree rebuild pas bahasa
    // diganti — banyak widget anak pilih field *_id / *_en berdasarkan ini.
    ref.watch(languageProvider);
    final textSize = ref.watch(textSizeProvider);

    // App ini SENGAJA satu mode aja (terang) -- dark mode sempat dibangun
    // penuh lalu diminta dicabut total karena nggak cocok sama identitas
    // visual MiRO yang colorful/playful. `theme` doang, nggak ada
    // `darkTheme`/`themeMode` sama sekali, jadi nggak ada jalan buat OS
    // "memaksa" app ini ke gelap.
    return MaterialApp.router(
      title: 'MiRO',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      scrollBehavior: const AppScrollBehavior(),
      routerConfig: router,

      // ========================================================
      // 🔥 PINGUIN THE MASTER OVERLAY
      // ========================================================
      builder: (context, child) {
        // Terapkan preferensi ukuran teks (Settings > Tampilan) ke SELURUH
        // app dari satu tempat.
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textSize.scaleFactor),
          ),
          child: Stack(
            children: [
              // 1. Seluruh layar aplikasi ditaruh di paling dasar
              if (child != null) child,

              // 2. Pinguin (Mink) DISEMBUNYIKAN SEMENTARA atas permintaan.
              // Kode aslinya (Overlay tersarang + PenguinChatButton)
              // dikomentari di bawah, bukan dihapus -- tinggal buka
              // comment blok ini + import-nya di atas buat nyalain balik.
              // Alasan Overlay tersarang itu ada (jangan dihapus infonya
              // pas nyalain lagi): `child` di atas isinya Navigator (yang
              // punya Overlay bawaannya sendiri), tapi PenguinChatButton
              // itu SAUDARA-nya `child` di Stack, bukan turunan Navigator
              // itu -- jadi dia nggak pernah kebagian Overlay dari mana
              // pun secara alami, dan bakal crash "No Overlay widget
              // found" begitu ada widget yang BUTUH Overlay ancestor
              // (Tooltip di tombol tutup chat) direndernya.
              //
              // Overlay(
              //   initialEntries: [
              //     OverlayEntry(builder: (context) => const PenguinChatButton()),
              //   ],
              // ),
            ],
          ),
        );
      },
    );
  }
}
