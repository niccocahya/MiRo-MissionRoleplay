import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Import router dan provider bahasa
import 'core/router/app_router.dart';
import 'core/providers/language_provider.dart';

// IMPORT WIDGET PINGUIN GLOBAL
import 'shared/widgets/penguin_chat_bot.dart'; // Sesuaikan path ini!

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://kbfitbaxifwzhonmcsnx.supabase.co',
    anonKey: 'sb_publishable_bH8q8P2_jZbQTFVtJMB9LQ_TEIioVYM',
  );

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
