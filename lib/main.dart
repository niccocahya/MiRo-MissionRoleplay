import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Import router dan provider bahasa
import 'core/router/app_router.dart';
import 'core/providers/language_provider.dart';
import 'core/providers/text_size_provider.dart';
import 'core/theme/app_theme.dart';

// IMPORT WIDGET PINGUIN GLOBAL
import 'shared/widgets/penguin_chat_bot.dart'; // Sesuaikan path ini!

// Diisi lewat --dart-define-from-file=env.json (lihat env.example.json).
// Jangan taruh key beneran langsung di source lagi ya.
const String _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const String _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  assert(
    _supabaseUrl.isNotEmpty && _supabaseAnonKey.isNotEmpty,
    'SUPABASE_URL / SUPABASE_ANON_KEY belum di-set. '
    'Jalankan dengan --dart-define-from-file=env.json (copy dari env.example.json).',
  );

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

              // 2. Pinguin dibiarkan lepas menguasai Stack!
              // BUKAN const — widget const dikanonikalisasi (objek yang
              // sama persis tiap kali), jadi Flutter skip rebuild-nya
              // walau MyApp rebuild pas bahasa diganti, dan Mink bakal
              // "nyangkut" bahasa lama.
              //
              // Dibungkus Overlay SENDIRI di sini. `child` di atas isinya
              // Navigator (yang punya Overlay bawaannya sendiri), tapi
              // PenguinChatButton ini SAUDARA-nya `child` di Stack, bukan
              // turunan Navigator itu -- jadi dia nggak pernah kebagian
              // Overlay dari mana pun. Nggak kelihatan selama chatbot cuma
              // pakai Container/Stack/Positioned biasa, tapi begitu ada
              // widget yang BUTUH Overlay ancestor (Tooltip di tombol
              // tutup chat), app-nya crash "No Overlay widget found" pas
              // jendela chat dibuka. Overlay bisa disarangkan -- yang di
              // sini nyediain satu khusus buat subtree ini aja.
              Overlay(
                initialEntries: [
                  OverlayEntry(builder: (context) => const PenguinChatButton()),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
