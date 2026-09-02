import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

// ⚠️ PASTIKAN IMPORT PROVIDER ANAK INI BENAR SESUAI FOLDERMU
import '../../core/providers/child_provider.dart';
import '../../core/providers/child_stats_provider.dart';
import '../../core/utils/level_utils.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/responsive.dart';

/// Sapaan berdasarkan jam saat ini. Sebelumnya if/else-chain ini ditulis
/// ulang persis sama 2x di file ini (pas kirim pesan ke AI & pas buka
/// jendela chat).
String _timeGreeting() {
  final hour = DateTime.now().hour;
  if (hour >= 5 && hour < 11) return "Selamat Pagi";
  if (hour >= 11 && hour < 15) return "Selamat Siang";
  if (hour >= 15 && hour < 18) return "Selamat Sore";
  return "Selamat Malam";
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
  // Diisi lewat --dart-define-from-file=env.json (lihat env.example.json).
  // Key lama yang sempat hardcode di sini sudah HARUS di-revoke di
  // console.groq.com/keys karena sempat ada di source code.
  static const String _apiKey = String.fromEnvironment('GROQ_API_KEY');
  static const String _endpoint =
      'https://api.groq.com/openai/v1/chat/completions';

  static Future<String> sendMessage({
    required List<Map<String, String>> chatHistory,
    required String systemPrompt,
  }) async {
    try {
      final List<Map<String, String>> messages = [
        {'role': 'system', 'content': systemPrompt},
        ...chatHistory,
      ];

      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "model": "llama-3.1-8b-instant",
          "messages": messages,
          "temperature": 0.7,
          "max_tokens": 1024,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        debugPrint("❌ GROQ ERROR: ${response.statusCode} - ${response.body}");
        return "Waduh, Mink lagi pusing nih. Coba tanya lagi ya, Bunda! 🐧💦";
      }
    } catch (e) {
      debugPrint("❌ GROQ EXCEPTION: $e");
      return "Maaf, koneksi internet Mink sepertinya terputus. 📶🐧";
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
  }) async {
    state = state.copyWith(
      messages: [
        ...state.messages,
        {'role': 'user', 'content': userMessage},
      ],
      isLoading: true,
    );
    unawaited(_saveMessage('user', userMessage));

    final String timeGreeting = _timeGreeting();

    final int xp = childFullData['total_xp'] ?? 0;
    // Bukan `childFullData['current_level']` — kolom itu di DB nggak
    // pernah ditulis balik, selalu nyangkut di angka default (biasanya 1).
    final int level = calculateLevel(xp);
    final double cog = (childFullData['cognitive_score'] ?? 0).toDouble();
    final double emp = (childFullData['empathy_score'] ?? 0).toDouble();
    final double cre = (childFullData['creativity_score'] ?? 0).toDouble();
    final double lit = (childFullData['literacy_score'] ?? 0).toDouble();
    final double mot = (childFullData['motoric_score'] ?? 0).toDouble();

    String badgesString = recentAchievements.isEmpty
        ? "Belum ada lencana baru."
        : recentAchievements.map((b) => "- ${b['title_id']}").join("\n");

    final String systemPrompt =
        """
Kamu adalah Mink, Pinguin asisten parenting virtual yang ceria. Sapa dengan "$timeGreeting Bunda/Ayah!".
Aplikasi MiRO punya 5 peran misi offline (Koki, Dokter, Pelukis, Atlet, Guru) untuk melatih 5 skill tanpa layar HP.

[DATA ANAK SAAT INI]
- Nama: $childName (Level $level, XP $xp)
- Radar Skill: Kognitif ($cog), Empati ($emp), Kreativitas ($cre), Literasi ($lit), Motorik ($mot).
- Lencana: $badgesString

[KONTEKS HALAMAN SAAT INI]
${missionContext != null ? "INFORMASI MISI YANG SEDANG DIKERJAKAN:\n$missionContext\n\nJika pengguna bertanya tentang misi, pandu mereka berdasarkan informasi di atas." : "Bunda sedang berada di menu utama."}

[ATURAN]
- Jawab singkat, pakai bullet points (-), tebalkan teks penting.
- Dilarang bahas di luar parenting/MiRO. Dilarang diagnosa medis.
- Gunakan emoji 🐧✨.
""";

    final aiResponse = await GroqService.sendMessage(
      chatHistory: state.messages,
      systemPrompt: systemPrompt,
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
  bool _isChatOpen = false;

  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

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

  Future<void> _confirmClearHistory(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus histori chat?'),
        content: const Text(
          'Semua percakapan sama Mink bakal dihapus. Nggak bisa dibatalin.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Hapus', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await ref.read(chatbotProvider.notifier).clearHistory();
    }
  }

  Future<void> _handleSend(
    Map<String, dynamic> childFullData,
    String? activeContext,
  ) async {
    if (_chatController.text.trim().isEmpty) return;
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
          childName: childFullData['name'] ?? 'Anak Hebat',
          missionContext: activeContext,
          childFullData: childFullData,
          recentAchievements: recentAchievements,
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
    final String childName = childData['name'] ?? 'Anak Hebat';

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

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        if (_isChatOpen)
          Positioned.fill(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              resizeToAvoidBottomInset: true,
              body: Stack(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _isChatOpen = false),
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

        if (!_isChatOpen)
          Positioned(
            top: _top,
            left: 6,
            child: SafeArea(
              child: Material(
                type: MaterialType.transparency,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    setState(() => _isChatOpen = true);
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
      ],
    );
  }

  Widget _buildChatWindow(
    ChatbotState chatState,
    String childName,
    Map<String, dynamic> childData,
    String? activeContext,
  ) {
    final String timeGreeting = _timeGreeting();

    final String botGreeting = activeContext != null
        ? "$timeGreeting Bunda! Ada yang bingung pas ngerjain misi ini? Tanya Mink aja! 🐧"
        : "$timeGreeting Bunda! Butuh rekomendasi misi atau mau bahas perkembangan $childName hari ini? Tanya Mink ya! 🐧✨";

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
              color: Colors.grey.shade300,
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
                      "Online • Siap membantu",
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
                    tooltip: 'Hapus histori chat',
                    onPressed: () => _confirmClearHistory(context),
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                IconButton(
                  onPressed: () => setState(() => _isChatOpen = false),
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
                        "Mink sedang mengetik... 🐧💭",
                        style: TextStyle(
                          color: Colors.grey.shade500,
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
                          ? const [
                              "Apa langkah pertamanya?",
                              "Bahan apa aja yang perlu disiapkan?",
                              "Kenapa misi ini penting?",
                            ]
                          : const [
                              "Rekomendasi misi hari ini",
                              "Gimana cara kerja XP & level?",
                              "Ceritain progres anakku",
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
                hintText: "Tanya Mink di sini...",
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                filled: true,
                fillColor: AppColors.background,
                suffixIcon: GestureDetector(
                  onTap: () => _handleSend(childData, activeContext),
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
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
