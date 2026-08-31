import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Import router dan provider bahasa
import 'core/router/app_router.dart';
import 'core/providers/language_provider.dart';

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
    final String lang = ref.watch(languageProvider);

    return MaterialApp.router(
      title: 'MiRO',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0A264F),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Poppins',
      ),
      routerConfig: router,

      // ========================================================
      // 🔥 PINGUIN THE MASTER OVERLAY
      // ========================================================
      builder: (context, child) {
        return Stack(
          children: [
            // 1. Seluruh layar aplikasi ditaruh di paling dasar
            if (child != null) child,

            // 2. Pinguin dibiarkan lepas menguasai Stack!
            const PenguinChatButton(),
          ],
        );
      },
    );
  }
}
