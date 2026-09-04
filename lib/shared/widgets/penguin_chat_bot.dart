import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ⚠️ PASTIKAN IMPORT PROVIDER ANAK INI BENAR SESUAI FOLDERMU
import '../../core/providers/child_provider.dart';
import '../../core/providers/language_provider.dart';
import '../../core/providers/child_stats_provider.dart';
import '../../core/utils/level_utils.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/responsive.dart';

/// Seluruh teks Mink, dua bahasa.
///
/// Dulu file ini SATU-SATUNYA bagian app yang nggak nyentuh
/// `languageProvider` sama sekali -- 879 baris tanpa satu pun rujukan ke
/// bahasa. Efeknya buat orang tua yang milih English: tombol, sapaan,
/// dialog, chip saran, sampai balasan AI-nya sendiri semua tetap Bahasa
/// Indonesia, karena prompt sistemnya pun ditulis dalam Indonesia.
const Map<String, Map<String, String>> _t = {
  'en': {
    'status_online': "Online • Ready to help",
    'typing': "Mink is typing... 🐧💭",
    'hint': "Ask Mink here...",
    'clear_tooltip': "Clear chat history",
    'clear_title': "Clear chat history?",
    'clear_body': "Every conversation with Mink will be deleted. This can't be undone.",
    'clear_cancel': "Cancel",
    'clear_confirm': "Delete",
    'err_busy': "Oops, Mink's head is spinning. Try asking again! 🐧💦",
    'err_offline': "Sorry, Mink seems to have lost the connection. 📶🐧",
    'no_badges': "No new badges yet.",
    'greet_morning': "Good Morning",
    'greet_noon': "Good Afternoon",
    'greet_evening': "Good Evening",
    'greet_night': "Good Night",
    'chip_first_step': "What's the first step?",
    'chip_materials': "What do we need to prepare?",
    'chip_why': "Why does this mission matter?",
    'chip_recommend': "Recommend a mission for today",
    'chip_xp': "How do XP & levels work?",
    'chip_progress': "Tell me about my child's progress",
    'child_fallback': "Champ",
    // {g} = sapaan waktu, {n} = nama anak.
    'close_chat': "Close chat",
    'greet_mission': "{g}! Stuck anywhere in this mission? Just ask Mink! 🐧",
    'greet_home': "{g}! Need a mission suggestion, or want to talk about how {n} is doing today? Ask Mink! 🐧✨",
  },
  'id': {
    'status_online': "Online • Siap membantu",
    'typing': "Mink sedang mengetik... 🐧💭",
    'hint': "Tanya Mink di sini...",
    'clear_tooltip': "Hapus histori chat",
    'clear_title': "Hapus histori chat?",
    'clear_body': "Semua percakapan sama Mink bakal dihapus. Nggak bisa dibatalin.",
    'clear_cancel': "Batal",
    'clear_confirm': "Hapus",
    'err_busy': "Waduh, Mink lagi pusing nih. Coba tanya lagi ya, Bunda! 🐧💦",
    'err_offline': "Maaf, koneksi internet Mink sepertinya terputus. 📶🐧",
    'no_badges': "Belum ada lencana baru.",
    'greet_morning': "Selamat Pagi",
    'greet_noon': "Selamat Siang",
    'greet_evening': "Selamat Sore",
    'greet_night': "Selamat Malam",
    'chip_first_step': "Apa langkah pertamanya?",
    'chip_materials': "Bahan apa aja yang perlu disiapkan?",
    'chip_why': "Kenapa misi ini penting?",
    'chip_recommend': "Rekomendasi misi hari ini",
    'chip_xp': "Gimana cara kerja XP & level?",
    'chip_progress': "Ceritain progres anakku",
    'greet_mission': "{g} Bunda! Ada yang bingung pas ngerjain misi ini? Tanya Mink aja! 🐧",
    'child_fallback': "Anak Hebat",
    'greet_home': "{g} Bunda! Butuh rekomendasi misi atau mau bahas perkembangan {n} hari ini? Tanya Mink ya! 🐧✨",
    'close_chat': "Tutup chat",
  },
};

Map<String, String> _texts(String lang) => _t[lang] ?? _t['id']!;

/// Sapaan berdasarkan jam saat ini. Sebelumnya if/else-chain ini ditulis
/// ulang persis sama 2x di file ini (pas kirim pesan ke AI & pas buka
/// jendela chat).
String _timeGreeting(String lang) {
  final t = _texts(lang);
  final hour = DateTime.now().hour;
  if (hour >= 5 && hour < 11) return t['greet_morning']!;
  if (hour >= 11 && hour < 15) return t['greet_noon']!;
  if (hour >= 15 && hour < 18) return t['greet_evening']!;
  return t['greet_night']!;
}

// ============================================================================
// 👁️ GLOBAL VISIBILITY PROVIDER (Kontrol Mink sembunyi/muncul)
// ============================================================================
class ChatbotVisibilityNotifier extends Notifier<bool> {
  @override
  bool build() => true; // Default awalnya true (Mink Muncul)

  // Fungsi saklar sembunyi/muncul
  void hide() => state = false;
  void show() => state = true;
}

final showChatbotGlobalProvider =
    NotifierProvider<ChatbotVisibilityNotifier, bool>(() {
      return ChatbotVisibilityNotifier();
    });

/// Kebuka/nggaknya JENDELA chat Mink (beda dari showChatbotGlobalProvider,
/// yang cuma ngatur BOLA/tombol Mink-nya keliatan atau nggak). Dulu ini
/// state lokal di dalam _PenguinChatButtonState, jadi nggak ada cara buka
/// jendela chat dari layar LAIN (mis. tombol "Chat Mink" di Help Center) --
/// paling jauh cuma bisa manggil showChatbotGlobalProvider buat munculin
/// bola-nya, tapi jendelanya tetep ketutup sampai bola itu di-tap manual.
class ChatWindowOpenNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void open() => state = true;
  void close() => state = false;
}

final chatWindowOpenProvider =
    NotifierProvider<ChatWindowOpenNotifier, bool>(() {
      return ChatWindowOpenNotifier();
    });

// ============================================================================
// 🌐 GLOBAL CONTEXT PROVIDER (Mata Mink untuk membaca halaman)
// ============================================================================
class MissionContextNotifier extends Notifier<String?> {
  @override
  String? build() => null; // Default awalnya null (tidak ada misi aktif)

  // Fungsi untuk update konteks dari halaman misi
  void setContext(String? newContext) {
    state = newContext;
  }
}

final currentMissionContextProvider =
    NotifierProvider<MissionContextNotifier, String?>(() {
      return MissionContextNotifier();
    });

// ============================================================================
// 🧠 BAGIAN 1: SERVICE GROQ (Tukang Antar Surat ke Server AI)
// ============================================================================
class GroqService {
  /// Nama Edge Function yang megang kunci Groq (lihat
  /// `supabase/functions/mink-chat/index.ts`).
  ///
  /// Dulu file ini manggil api.groq.com LANGSUNG pakai kunci dari
  /// `String.fromEnvironment('GROQ_API_KEY')`. Nilai --dart-define itu
  /// disisipin ke HASIL BUILD, bukan dibaca pas runtime -- jadi di build
  /// web kuncinya nangkring di bundel JavaScript dan kebaca lewat
  /// DevTools, dan di Android/iOS bisa dicungkil dari APK/IPA. Siapa pun
  /// yang ngambil bisa makai kuota Groq atas tagihan pemilik akun.
  ///
  /// Mindahin kunci dari hardcode ke --dart-define (yang sempat
  /// dilakukan sebelumnya) cuma nutup kebocoran di SOURCE CODE, bukan di
  /// hasil build. Sekarang kuncinya nggak pernah nyampe ke perangkat
  /// sama sekali.
  ///
  /// Bedain sama SUPABASE_ANON_KEY yang tetap di klien: itu emang kunci
  /// publik dan RLS yang jagain datanya.
  static const String _functionName = 'mink-chat';

  static Future<String> sendMessage({
    required List<Map<String, String>> chatHistory,
    required String systemPrompt,
    required String lang,
  }) async {
    try {
      // invoke() otomatis nyertain JWT sesi yang lagi login, dan fungsinya
      // di sisi server emang minta itu -- jadi cuma orang tua yang udah
      // masuk yang bisa mancing balasan.
      final response = await Supabase.instance.client.functions.invoke(
        _functionName,
        body: {
          'systemPrompt': systemPrompt,
          'chatHistory': chatHistory,
        },
      );

      final data = response.data;
      if (response.status == 200 && data is Map && data['reply'] is String) {
        return data['reply'] as String;
      }

      debugPrint("❌ MINK-CHAT ERROR: ${response.status} - $data");
      return _texts(lang)['err_busy']!;
    } catch (e) {
      debugPrint("❌ MINK-CHAT EXCEPTION: $e");
      return _texts(lang)['err_offline']!;
    }
  }
}

// ============================================================================
// 💾 BAGIAN 2: STATE & PROVIDER (Otak Memori Mink)
// ============================================================================
class ChatbotState {
  final List<Map<String, String>> messages;
  final bool isLoading;

  ChatbotState({this.messages = const [], this.isLoading = false});

  ChatbotState copyWith({
    List<Map<String, String>>? messages,
    bool? isLoading,
  }) {
    return ChatbotState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ChatbotNotifier extends Notifier<ChatbotState> {
  String? _childId;

  @override
  ChatbotState build() {
    // Muat histori chat dari tabel `ai_chats` — sebelumnya tabel ini ada di
    // database tapi nggak pernah dipakai sama sekali, jadi histori chat
    // Mink selalu hilang tiap app ditutup/dibuka lagi.
    //
    // Percakapan Mink di-scope per ANAK (bukan cuma per parent) — konteks
    // yang dikasih ke Mink tiap giliran chat (level/XP/skill radar) emang
    // udah spesifik 1 anak, jadi histori-nya juga harus ngikutin anak yang
    // lagi aktif dipilih, bukan numpuk campur kalau ada >1 anak.
    ref.listen(selectedChildIdProvider, (prev, next) {
      if (next != prev) {
        _childId = next;
        _loadHistory();
      }
    });
    _childId = ref.read(selectedChildIdProvider);
    _loadHistory();
    return ChatbotState(messages: []);
  }

  Future<void> _loadHistory() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || _childId == null) {
      state = ChatbotState(messages: []);
      return;
    }

    // Kosongin dulu biar nggak sekilas nampilin histori anak sebelumnya
    // pas lagi ganti anak.
    state = ChatbotState(messages: []);

    try {
      final rows = await Supabase.instance.client
          .from('ai_chats')
          .select('role, message')
          .eq('parent_id', user.id)
          .eq('child_id', _childId!)
          .order('created_at', ascending: true)
          .limit(50);

      final history = rows
          .map<Map<String, String>>(
            (r) => {
              'role': r['role']?.toString() ?? 'assistant',
              'content': r['message']?.toString() ?? '',
            },
          )
          .toList();

      if (history.isNotEmpty) {
        state = state.copyWith(messages: history);
      }
    } catch (e) {
      debugPrint("Gagal memuat histori chat Mink: $e");
    }
  }

  /// Hapus histori chat — lokal & di database. Sebelumnya nggak ada cara
  /// ngosongin chat sama sekali, numpuk terus. Cuma hapus punya anak yang
  /// lagi aktif, bukan punya semua anak.
  Future<void> clearHistory() async {
    state = ChatbotState(messages: []);
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      var query = Supabase.instance.client
          .from('ai_chats')
          .delete()
          .eq('parent_id', user.id);
      if (_childId != null) query = query.eq('child_id', _childId!);
      await query;
    } catch (e) {
      debugPrint("Gagal hapus histori chat Mink: $e");
    }
  }

  Future<void> _saveMessage(String role, String content) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      await Supabase.instance.client.from('ai_chats').insert({
        'parent_id': user.id,
        'child_id': _childId,
        'role': role,
        'message': content,
      });
    } catch (e) {
      debugPrint("Gagal simpan chat Mink: $e");
    }
  }

  Future<void> sendMessage(
    String userMessage, {
    required String childName,
    required String? missionContext,
    required Map<String, dynamic> childFullData,
    required List<Map<String, dynamic>> recentAchievements,
    required String lang,
  }) async {
    // Dulu nggak ada penjaga apa pun di sini -- ngetuk kirim 2x cepat
    // (atau nekan Enter sambil nge-tap tombol) nembak 2 panggilan Groq
    // yang overlap, balesannya bisa numpuk/keluar nggak sesuai urutan.
    if (state.isLoading) return;

    state = state.copyWith(
      messages: [
        ...state.messages,
        {'role': 'user', 'content': userMessage},
      ],
      isLoading: true,
    );
    unawaited(_saveMessage('user', userMessage));

    final String timeGreeting = _timeGreeting(lang);

    final int xp = childFullData['total_xp'] ?? 0;
    // Bukan `childFullData['current_level']` — kolom itu di DB nggak
    // pernah ditulis balik, selalu nyangkut di angka default (biasanya 1).
    final int level = calculateLevel(xp);
    final double cog = (childFullData['cognitive_score'] ?? 0).toDouble();
    final double emp = (childFullData['empathy_score'] ?? 0).toDouble();
    final double cre = (childFullData['creativity_score'] ?? 0).toDouble();
    final double lit = (childFullData['literacy_score'] ?? 0).toDouble();
    final double mot = (childFullData['motoric_score'] ?? 0).toDouble();

    // Judul lencana ikut bahasa yang dipilih. Dulu selalu `title_id`,
    // jadi walau nanti Mink jawab pakai Inggris, nama-nama lencananya
    // tetap kebaca Indonesia di tengah kalimat.
    final String badgeTitleKey = lang == 'en' ? 'title_en' : 'title_id';
    String badgesString = recentAchievements.isEmpty
        ? _texts(lang)['no_badges']!
        : recentAchievements
            .map((b) => "- ${b[badgeTitleKey] ?? b['title_id']}")
            .join("\n");

    // Prompt sistemnya sendiri yang nentuin Mink jawab pakai bahasa apa.
    // Selama ini cuma ada versi Indonesia, jadi orang tua yang milih
    // English tetap dibalas Indonesia -- setelan bahasanya nggak pernah
    // nyampe ke sini sama sekali.
    final String systemPrompt = lang == 'en'
        ? """
You are Mink, a cheerful virtual parenting-assistant penguin. Greet with "$timeGreeting!".
The MiRO app has 5 offline mission roles (Chef, Doctor, Painter, Athlete, Teacher) that train 5 skills without screen time.

[CURRENT CHILD DATA]
- Name: $childName (Level $level, XP $xp)
- Skill radar: Cognitive ($cog), Empathy ($emp), Creativity ($cre), Literacy ($lit), Motoric ($mot).
- Badges: $badgesString

[CURRENT PAGE CONTEXT]
${missionContext != null ? "MISSION CURRENTLY IN PROGRESS:\n$missionContext\n\nIf the parent asks about the mission, guide them using the information above." : "The parent is on the main menu."}

[RULES]
- Answer in English. Keep it short, use bullet points (-), bold the important parts.
- Stay strictly on parenting/MiRO topics. Never give medical diagnoses.
- Use emoji 🐧✨.
"""
        : """
Kamu adalah Mink, Pinguin asisten parenting virtual yang ceria. Sapa dengan "$timeGreeting Bunda/Ayah!".
Aplikasi MiRO punya 5 peran misi offline (Koki, Dokter, Pelukis, Atlet, Guru) untuk melatih 5 skill tanpa layar HP.

[DATA ANAK SAAT INI]
- Nama: $childName (Level $level, XP $xp)
- Radar Skill: Kognitif ($cog), Empati ($emp), Kreativitas ($cre), Literasi ($lit), Motorik ($mot).
- Lencana: $badgesString

[KONTEKS HALAMAN SAAT INI]
${missionContext != null ? "INFORMASI MISI YANG SEDANG DIKERJAKAN:\n$missionContext\n\nJika pengguna bertanya tentang misi, pandu mereka berdasarkan informasi di atas." : "Bunda sedang berada di menu utama."}

[ATURAN]
- Jawab dalam Bahasa Indonesia. Jawab singkat, pakai bullet points (-), tebalkan teks penting.
- Dilarang bahas di luar parenting/MiRO. Dilarang diagnosa medis.
- Gunakan emoji 🐧✨.
""";

    final aiResponse = await GroqService.sendMessage(
      chatHistory: state.messages,
      systemPrompt: systemPrompt,
      lang: lang,
    );

    state = state.copyWith(
      messages: [
        ...state.messages,
        {'role': 'assistant', 'content': aiResponse},
      ],
      isLoading: false,
    );
    unawaited(_saveMessage('assistant', aiResponse));
  }
}

final chatbotProvider = NotifierProvider<ChatbotNotifier, ChatbotState>(
  () => ChatbotNotifier(),
);

// ============================================================================
// 🎨 BAGIAN 3: WIDGET UI (Wujud Fisik Mink)
// ============================================================================
class PenguinChatButton extends ConsumerStatefulWidget {
  final String? missionContext;

  const PenguinChatButton({super.key, this.missionContext});

  @override
  ConsumerState<PenguinChatButton> createState() => _PenguinChatButtonState();
}

class _PenguinChatButtonState extends ConsumerState<PenguinChatButton> {
  double _top = 240.0;

  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Dialog konfirmasi "hapus histori" digambar SENDIRI di sini (bukan
  // lewat showDialog) -- lihat catatan panjang di _confirmClearHistory
  // buat alasannya.
  bool _showClearConfirm = false;

  @override
  void dispose() {
    // Dulu nggak ada dispose() sama sekali di sini -- nggak kerasa
    // sekarang karena PenguinChatButton dipasang sekali di level
    // MaterialApp.builder dan hidup seumur app, tapi tetep leak beneran
    // kalau widget ini pernah di-unmount (hot restart pas dev, atau
    // refactor nanti yang bikin ini conditional).
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Dulu ini nge-showDialog lewat rootNavigatorKey.currentContext -- itu
  // benerin CRASH-nya (PenguinChatButton nggak punya Navigator ancestor
  // sendiri), tapi ninggalin bug VISUAL baru: dialognya emang kebuka
  // tanpa error, tapi kegambar ke Overlay APLIKASI UTAMA punya
  // rootNavigatorKey -- yang di main.dart posisinya PERTAMA (paling
  // BAWAH) di antara 2 layer Stack-nya MyApp, sedangkan seluruh
  // PenguinChatButton (termasuk jendela chat yang lagi kebuka) hidup di
  // Overlay TERPISAH yang ditaruh SETELAHNYA (paling ATAS). Jadi dialog
  // konfirmasinya kegambar, tapi ketutupan sama jendela chat sendiri --
  // "kebuka" tapi nggak kelihatan.
  //
  // Sekarang dialognya nggak lewat showDialog/Navigator sama sekali --
  // digambar sebagai state lokal widget ini sendiri (`_showClearConfirm`),
  // jadi otomatis satu Overlay/Stack yang SAMA persis sama jendela chat,
  // dan tinggal ditaruh sebagai children TERAKHIR di Stack utama biar
  // pasti di atas.
  void _confirmClearHistory(BuildContext context) {
    setState(() => _showClearConfirm = true);
  }

  Future<void> _handleClearConfirmed() async {
    setState(() => _showClearConfirm = false);
    await ref.read(chatbotProvider.notifier).clearHistory();
  }

  Future<void> _handleSend(
    Map<String, dynamic> childFullData,
    String? activeContext,
  ) async {
    if (_chatController.text.trim().isEmpty) return;
    // Dulu nggak ada penjaga ini -- kirim pesan baru sementara Mink masih
    // mikirin balasan sebelumnya (mis. ngetik cepet terus nekan kirim 2x)
    // nembak 2 request Groq yang overlap. Beda dari penjaga di
    // sendMessage(): ini dicek SEBELUM textnya kehapus, jadi pesan yang
    // lagi diketik nggak ilang -- tetap ada di kolom teks, tinggal kirim
    // lagi begitu balasan sebelumnya kelar.
    if (ref.read(chatbotProvider).isLoading) return;
    final text = _chatController.text;
    _chatController.clear();

    final String childId = childFullData['id'] ?? '';
    List<Map<String, dynamic>> recentAchievements = [];

    if (childId.isNotEmpty) {
      try {
        final supabase = Supabase.instance.client;
        final achRes = await supabase
            .from('child_achievements')
            .select('achievements_master(title_id, role_id)')
            .eq('child_id', childId)
            // Dulu nggak ada .order() sama sekali -- "3 lencana terbaru"
            // sebenernya cuma 3 baris dalam urutan apa pun yang Postgres
            // kebetulan balikin, bukan beneran yang paling baru dibuka.
            .order('unlocked_at', ascending: false)
            .limit(3);

        for (var item in achRes) {
          if (item['achievements_master'] != null) {
            recentAchievements.add(item['achievements_master']);
          }
        }
      } catch (e) {
        debugPrint("Gagal narik lencana: $e");
      }
    }

    ref
        .read(chatbotProvider.notifier)
        .sendMessage(
          text,
          childName: () {
            final n = (childFullData['name'] as String? ?? '').trim();
            return n.isEmpty
                ? _texts(ref.read(languageProvider))['child_fallback']!
                : n;
          }(),
          missionContext: activeContext,
          childFullData: childFullData,
          recentAchievements: recentAchievements,
          lang: ref.read(languageProvider),
        );

    _scrollToBottom();
  }

  Future<void> _handleQuickReply(
    String text,
    Map<String, dynamic> childFullData,
    String? activeContext,
  ) async {
    _chatController.text = text;
    await _handleSend(childFullData, activeContext);
  }

  @override
  Widget build(BuildContext context) {
    // 🔥 SAKLAR GAIB MINK! BACA PERINTAH DARI PROVIDER
    final isVisible = ref.watch(showChatbotGlobalProvider);

    // Kalau disuruh sembunyi (misal: di Onboarding/Identify), render nol besar (SizedBox.shrink)
    if (!isVisible) {
      return const SizedBox.shrink();
    }

    // --- Kalau isVisible == true, baru Mink boleh eksis ---
    final screenHeight = context.screenHeight;
    final chatState = ref.watch(chatbotProvider);
    final childData = ref.watch(childDataProvider).value ?? {};
    final String rawName = (childData['name'] as String? ?? '').trim();
    final String childName = rawName.isEmpty
        ? _texts(ref.watch(languageProvider))['child_fallback']!
        : rawName;

    // Skor 5 skill (buat konteks yang dikasih ke Mink) ada di tabel
    // `child_stats`, BUKAN di `children` — `childData` doang nggak
    // punya field cognitive_score/dst, jadi sebelumnya field itu SELALU
    // kebaca 0 di system prompt Mink walau anaknya punya skor beneran.
    final childStats =
        ref.watch(childStatsProvider(childData['id'] ?? '')).value ?? {};
    final childFullDataForChat = <String, dynamic>{...childData, ...childStats};

    // MEMBACA KONTEKS DINAMIS DARI PROVIDER
    final globalMissionContext = ref.watch(currentMissionContextProvider);
    final activeContext = widget.missionContext ?? globalMissionContext;

    // Dipindah dari state lokal ke provider (chatWindowOpenProvider) biar
    // layar lain (mis. tombol "Chat Mink" di Help Center) bisa buka
    // jendela ini juga, bukan cuma dari tap bola Mink sendiri.
    final isChatOpen = ref.watch(chatWindowOpenProvider);

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        if (isChatOpen)
          Positioned.fill(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              resizeToAvoidBottomInset: true,
              body: Stack(
                children: [
                  GestureDetector(
                    onTap: () => ref.read(chatWindowOpenProvider.notifier).close(),
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.5),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: GestureDetector(
                      onTap: () {},
                      child: _buildChatWindow(
                        chatState,
                        childName,
                        childFullDataForChat,
                        activeContext,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        if (!isChatOpen)
          Positioned(
            top: _top,
            left: 6,
            child: SafeArea(
              child: Material(
                type: MaterialType.transparency,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    ref.read(chatWindowOpenProvider.notifier).open();
                    _scrollToBottom();
                  },
                  onVerticalDragUpdate: (details) {
                    setState(() {
                      _top += details.delta.dy;
                      _top = _top.clamp(50.0, screenHeight - 120.0);
                    });
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.6),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        left: -15,
                        child: Image.asset(
                          'assets/images/penguin_peek.png',
                          width: 65,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // Sengaja jadi children TERAKHIR di Stack ini -- lihat catatan
        // panjang di _confirmClearHistory. Dijamin di atas jendela chat
        // (dan bola Mink) karena satu Stack yang sama, bukan Navigator/
        // Overlay lain yang urutan tumpukannya nggak bisa dipastikan.
        if (_showClearConfirm) _buildClearConfirmOverlay(),
      ],
    );
  }

  Widget _buildClearConfirmOverlay() {
    final t = _texts(ref.watch(languageProvider));
    return Positioned.fill(
      child: Material(
        color: Colors.black.withValues(alpha: 0.5),
        child: GestureDetector(
          onTap: () => setState(() => _showClearConfirm = false),
          child: Center(
            child: GestureDetector(
              // Nyerap tap di dalam kartu-nya sendiri biar nggak ke-anggep
              // "tap di luar" (yang nutup dialog) sama GestureDetector scrim
              // di atas.
              onTap: () {},
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(color: Colors.black38, blurRadius: 20, offset: Offset(0, 8)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t['clear_title']!,
                      style: AppTextStyles.h3(color: AppColors.primary),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      t['clear_body']!,
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => setState(() => _showClearConfirm = false),
                          child: Text(t['clear_cancel']!),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        TextButton(
                          onPressed: _handleClearConfirmed,
                          child: Text(
                            t['clear_confirm']!,
                            style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatWindow(
    ChatbotState chatState,
    String childName,
    Map<String, dynamic> childData,
    String? activeContext,
  ) {
    final String lang = ref.watch(languageProvider);
    final t = _texts(lang);
    final String timeGreeting = _timeGreeting(lang);

    final String botGreeting = (activeContext != null
            ? t['greet_mission']!
            : t['greet_home']!)
        .replaceAll('{g}', timeGreeting)
        .replaceAll('{n}', childName);

    return Container(
      constraints: BoxConstraints(
        maxHeight: context.screenHeight * 0.75,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Image.asset(
                  'assets/images/penguin_head.png',
                  width: 40,
                  fit: BoxFit.contain,
                  errorBuilder: (c, e, s) =>
                      const Text("🐧", style: TextStyle(fontSize: 30)),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Mink",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      t['status_online']!,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                if (chatState.messages.isNotEmpty)
                  IconButton(
                    tooltip: t['clear_tooltip']!,
                    onPressed: () => _confirmClearHistory(context),
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                IconButton(
                  tooltip: t['close_chat']!,
                  onPressed: () => ref.read(chatWindowOpenProvider.notifier).close(),
                  icon: Icon(
                    Icons.close_rounded,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.border),
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(),
              children: [
                _buildChatBubble(botGreeting, isUser: false),
                ...chatState.messages.map(
                  (msg) => _buildChatBubble(
                    msg['content']!,
                    isUser: msg['role'] == 'user',
                  ),
                ),
                if (chatState.isLoading)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        t['typing']!,
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Chip balasan cepat — sebelumnya orang tua selalu harus ngetik
          // sendiri dari nol tiap buka chat, padahal pertanyaan pertama
          // hampir selalu salah satu dari beberapa hal yang sama.
          // Cuma muncul di percakapan yang masih kosong biar nggak ganggu
          // pas udah lagi ngobrol.
          if (chatState.messages.isEmpty && !chatState.isLoading)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: SizedBox(
                height: 34,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  children: (activeContext != null
                          ? [
                              t['chip_first_step']!,
                              t['chip_materials']!,
                              t['chip_why']!,
                            ]
                          : [
                              t['chip_recommend']!,
                              t['chip_xp']!,
                              t['chip_progress']!,
                            ])
                      .map(
                        (q) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () =>
                                _handleQuickReply(q, childData, activeContext),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.primaryTint,
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: AppColors.primary.withValues(alpha: 0.15),
                                ),
                              ),
                              child: Text(
                                q,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: TextField(
              controller: _chatController,
              onSubmitted: (_) => _handleSend(childData, activeContext),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
              decoration: InputDecoration(
                hintText: t['hint']!,
                hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                filled: true,
                fillColor: AppColors.background,
                suffixIcon: GestureDetector(
                  onTap: chatState.isLoading
                      ? null
                      : () => _handleSend(childData, activeContext),
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: chatState.isLoading
                          ? AppColors.primary.withValues(alpha: 0.4)
                          : AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  /// Pecah `**teks tebal**` markdown sederhana dari balasan AI jadi span
  /// bold beneran. Sebelumnya tanda `**`-nya cuma dihapus mentah-mentah,
  /// jadi instruksi "tebalkan teks penting" di system prompt nggak pernah
  /// benar-benar kelihatan di layar.
  List<TextSpan> _parseBoldSpans(String text, TextStyle baseStyle) {
    final pattern = RegExp(r'\*\*(.+?)\*\*');
    final spans = <TextSpan>[];
    int cursor = 0;
    for (final match in pattern.allMatches(text)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, match.start)));
      }
      spans.add(
        TextSpan(
          text: match.group(1),
          style: baseStyle.copyWith(fontWeight: FontWeight.bold),
        ),
      );
      cursor = match.end;
    }
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }
    return spans;
  }

  Widget _buildChatBubble(String text, {required bool isUser}) {
    final baseStyle = TextStyle(
      fontSize: 14,
      height: 1.4,
      fontWeight: isUser ? FontWeight.bold : FontWeight.w500,
      color: isUser ? Colors.white : AppColors.primary,
    );

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 4,
        ),
        margin: EdgeInsets.only(
          bottom: AppSpacing.sm + 4,
          left: isUser ? 40 : 0,
          right: isUser ? 0 : 40,
        ),
        decoration: BoxDecoration(
          color: isUser ? AppColors.accent : AppColors.background,
          borderRadius: BorderRadius.circular(AppRadius.lg).copyWith(
            topLeft: Radius.circular(isUser ? AppRadius.lg : 0),
            topRight: Radius.circular(isUser ? 0 : AppRadius.lg),
          ),
          border: isUser ? null : Border.all(color: AppColors.border),
        ),
        child: RichText(
          text: TextSpan(
            style: baseStyle,
            children: _parseBoldSpans(text, baseStyle),
          ),
        ),
      ),
    );
  }
}
