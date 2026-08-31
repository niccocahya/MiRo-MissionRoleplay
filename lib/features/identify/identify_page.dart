import 'dart:io'; // Untuk menangani file gambar
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p; // Tambahan untuk deteksi ekstensi file

import '../../shared/widgets/step_progress_bar.dart';
import '../../shared/widgets/back_button.dart';
import '../../data/repositories/supabase_repository.dart';
import '../../core/providers/language_provider.dart';
import '../../core/providers/child_provider.dart';

// 🔥 IMPORT SAKLAR UTAMA DARI FILE CHATBOT (Biar gak beda alam)
import '../../shared/widgets/penguin_chat_bot.dart';

// ==========================================
// 1. DICTIONARY (KAMUS LENGKAP)
// ==========================================
const Map<String, Map<String, String>> _t = {
  'en': {
    'step1_title': "What's your little\nhero's name?",
    'step1_hint': "Child's name",
    'step1_age': "How old are they?",
    'step2_title': "What are your child's favorite activities?",
    'step3_title': "How is their learning style?",
    'step3_v': "Visual",
    'step3_v_sub': "(images, graphics)",
    'step3_a': "Auditory",
    'step3_a_sub': "(hearing, reading)",
    'step3_k': "Kinesthetic",
    'step3_k_sub': "(physical, moving)",
    'step4_title': "What skills do you want to develop? (max 3)",
    'step5_title': "How much play time together?",
    'btn_back': "Back",
    'btn_next': "Next",
    'btn_finish': "Finish",
    'err_step1': "Please complete name and age",
    'err_step2': "Please select at least 1 activity",
    'err_step3': "Please select a learning style",
    'err_step4': "Please select at least 1 skill",
    'err_image': "Failed to capture image: ",
    'err_submit': "Error: ",
    // STEP 2
    'act_draw': "Drawing",
    'act_read': "Reading",
    'act_speak': "Speaking",
    'act_music': "Music",
    'act_sport': "Sport",
    // STEP 4
    'skill_motor': "Motor skills",
    'skill_creat': "Creativity",
    'skill_emp': "Empathy",
    'skill_lit': "Literacy",
    'skill_think': "Thinking skills",
    // STEP 5 (Dinamis)
    'time_15m': "15 min",
    'time_30m': "30 min",
    'time_1h': "1 hour",
    'time_1_5h': "1.5 hours",
    'time_2h': "2 hours",
  },
  'id': {
    'step1_title': "Siapa nama pahlawan\nkecilmu?",
    'step1_hint': "Nama anak",
    'step1_age': "Berapa usianya?",
    'step2_title': "Apa kegiatan kesukaan anakmu?",
    'step3_title': "Bagaimana gaya belajar mereka?",
    'step3_v': "Visual",
    'step3_v_sub': "(gambar, grafik)",
    'step3_a': "Auditori",
    'step3_a_sub': "(mendengar, membaca)",
    'step3_k': "Kinestetik",
    'step3_k_sub': "(fisik, bergerak)",
    'step4_title': "Keahlian apa yang ingin dikembangkan? (maks 3)",
    'step5_title': "Berapa lama waktu bermain bersama?",
    'btn_back': "Kembali",
    'btn_next': "Lanjut",
    'btn_finish': "Selesai",
    'err_step1': "Mohon lengkapi nama dan umur anak",
    'err_step2': "Pilih setidaknya 1 kegiatan",
    'err_step3': "Pilih gaya belajar anak",
    'err_step4': "Pilih setidaknya 1 keahlian",
    'err_image': "Gagal mengambil gambar: ",
    'err_submit': "Terjadi kesalahan: ",
    // STEP 2
    'act_draw': "Menggambar",
    'act_read': "Membaca",
    'act_speak': "Berbicara",
    'act_music': "Musik",
    'act_sport': "Olahraga",
    // STEP 4
    'skill_motor': "Keahlian motorik",
    'skill_creat': "Kreativitas",
    'skill_emp': "Empati",
    'skill_lit': "Literasi",
    'skill_think': "Keahlian berpikir",
    // STEP 5 (Dinamis)
    'time_15m': "15 mnt",
    'time_30m': "30 mnt",
    'time_1h': "1 jam",
    'time_1_5h': "1,5 jam",
    'time_2h': "2 jam",
  },
};

class IdentifyPage extends ConsumerStatefulWidget {
  const IdentifyPage({super.key});
  @override
  ConsumerState<IdentifyPage> createState() => _IdentifyPageState();
}

class _IdentifyPageState extends ConsumerState<IdentifyPage> {
  int step = 1;
  bool isLoading = false;

  // Form State
  File? _imageFile;
  String childName = "";
  int? childAge;
  List<String> childEnjoys = [];
  List<String> childLearns = [];
  List<String> childDevelops = [];
  String? bondTime;

  @override
  void initState() {
    super.initState();
    _checkExistingChild();

    // 🔥 PERINTAH MUTLAK: Sembunyikan Mink saat masuk halaman Identify!
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(showChatbotGlobalProvider.notifier).hide();
    });
  }

  @override
  void dispose() {
    // ⚠️ FUNGSI show() DIHAPUS TOTAL DARI SINI BIAR GAK BIKIN MINK NONGOL PREMATUR!
    super.dispose();
  }

  Future<void> _checkExistingChild() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return;
    final data = await supabase
        .from('children')
        .select()
        .eq('parent_id', user.id)
        .maybeSingle();
    if (data != null && mounted) {
      ref.read(selectedChildIdProvider.notifier).state = data['id'];
      context.go('/home');
    }
  }

  Future<void> _pickImage(Map<String, String> texts) async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 75, // Kompres sedikit biar uploadnya cepet
      );
      if (pickedFile != null) {
        setState(() => _imageFile = File(pickedFile.path));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${texts['err_image']}$e')));
    }
  }

  void toggleSelection(
    String item,
    List<String> currentList,
    Function(List<String>) updateList, {
    int max = 3,
  }) {
    List<String> newList = List.from(currentList);
    if (newList.contains(item)) {
      newList.remove(item);
    } else {
      if (newList.length < max) newList.add(item);
    }
    updateList(newList);
  }

  void _handleNext(Map<String, String> texts) {
    if (step == 1 && (childName.trim().isEmpty || childAge == null)) {
      _showError(texts['err_step1']!);
      return;
    }
    if (step == 2 && childEnjoys.isEmpty) {
      _showError(texts['err_step2']!);
      return;
    }
    if (step == 3 && childLearns.isEmpty) {
      _showError(texts['err_step3']!);
      return;
    }
    if (step == 4 && childDevelops.isEmpty) {
      _showError(texts['err_step4']!);
      return;
    }
    setState(() => step++);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFE57B65),
      ),
    );
  }

  // =====================================================================
  // 🔥 FUNGSI UPLOAD FOTO & SUBMIT DATA
  // =====================================================================
  Future<void> _handleSubmit(Map<String, String> texts) async {
    if (childName.trim().isEmpty || childAge == null) return;

    setState(() => isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      String? uploadedPhotoUrl;

      // 1. Cek apakah Bunda milih foto. Kalau iya, upload ke bucket 'user_photo'
      if (_imageFile != null) {
        final user = supabase.auth.currentUser;
        final fileExt = p.extension(_imageFile!.path);
        // Bikin nama file unik: IDParent_Timestamp.jpg
        final fileName =
            "${user?.id ?? 'child'}_${DateTime.now().millisecondsSinceEpoch}$fileExt";

        // Upload ke bucket baru Bos!
        await supabase.storage.from('user_photo').upload(fileName, _imageFile!);

        // Ambil Public URL-nya
        uploadedPhotoUrl = supabase.storage
            .from('user_photo')
            .getPublicUrl(fileName);
      }

      // 2. Setor semua data (termasuk link foto) ke Repository
      final String childId = await ref
          .read(supabaseRepositoryProvider)
          .submitOnboardingData(
            name: childName,
            age: childAge!,
            interests: childEnjoys,
            learningStyles: childLearns,
            parentGoals: childDevelops,
            timePreference: bondTime ?? "15_min",
            avatarUrl: uploadedPhotoUrl,
          );

      ref.read(selectedChildIdProvider.notifier).state = childId;
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) _showError('${texts['err_submit']}${e.toString()}');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final texts = _t[lang] ?? _t['en']!;
    final bool isWhiteBg = step % 2 != 0;
    final Color mainBgColor = isWhiteBg
        ? Colors.white
        : const Color(0xFFA5CBEB);

    // 🔥 PENGAMANAN EKSTRA: Paksa hide terus-terusan selama halaman ini di-build!
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(showChatbotGlobalProvider)) {
        ref.read(showChatbotGlobalProvider.notifier).hide();
      }
    });

    return Scaffold(
      backgroundColor: mainBgColor,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Opacity(
              opacity: 0.95,
              child: Image.asset(
                'assets/images/penguin_identify1.png',
                fit: BoxFit.cover,
                height: 330,
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 330,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [mainBgColor, mainBgColor.withValues(alpha: 0.0)],
                  stops: const [0.0, 0.4],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 140,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.white, Colors.white.withValues(alpha: 0.0)],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                StepProgressBar(currentStep: step, totalSteps: 5),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: CustomBackButton(
                      onPressed: () => step == 1
                          ? context.go('/onboarding')
                          : setState(() => step--),
                    ),
                  ),
                ),
                Expanded(child: _buildCurrentStepContent(texts)),
                _buildBottomButtons(texts),
              ],
            ),
          ),
          if (isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFF0A264F)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCurrentStepContent(Map<String, String> texts) {
    switch (step) {
      case 1:
        return _buildStep1(texts);
      case 2:
        return _buildStep2(texts);
      case 3:
        return _buildStep3(texts);
      case 4:
        return _buildStep4(texts);
      case 5:
        return _buildStep5(texts);
      default:
        return const SizedBox();
    }
  }

  Widget _buildBottomButtons(Map<String, String> texts) {
    final bool isLastStep = step == 5;
    final bool showBack = step > 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 32),
      child: Row(
        children: [
          if (showBack) ...[
            Expanded(
              flex: 1,
              child: ElevatedButton(
                onPressed: isLoading ? null : () => setState(() => step--),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE57B65),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  texts['btn_back']!,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            flex: showBack ? 2 : 1,
            child: ElevatedButton(
              onPressed: isLoading
                  ? null
                  : (isLastStep
                        ? () => _handleSubmit(texts)
                        : () => _handleNext(texts)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A264F),
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                isLastStep ? texts['btn_finish']! : texts['btn_next']!,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1(Map<String, String> texts) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const SizedBox(height: 16),
          _avatarPicker(texts),
          const SizedBox(height: 24),
          Text(
            texts['step1_title']!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF0A264F),
              fontSize: 24,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            textAlign: TextAlign.center,
            controller: TextEditingController.fromValue(
              TextEditingValue(
                text: childName,
                selection: TextSelection.collapsed(offset: childName.length),
              ),
            ),
            onChanged: (val) => childName = val,
            decoration: InputDecoration(
              hintText: texts['step1_hint']!,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
          const SizedBox(height: 40),
          Text(
            texts['step1_age']!,
            style: const TextStyle(
              color: Color(0xFF0A264F),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          _ageSelector(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _avatarPicker(Map<String, String> texts) {
    return GestureDetector(
      onTap: () => _pickImage(texts),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4F8),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF0A264F).withValues(alpha: 0.1),
                width: 4,
              ),
            ),
            child: Center(
              child: _imageFile != null
                  ? ClipOval(
                      child: Image.file(
                        _imageFile!,
                        width: 96,
                        height: 96,
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Text("👦🏻", style: TextStyle(fontSize: 40)),
            ),
          ),
          Positioned(
            bottom: -4,
            right: -8,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFE57B65),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ageSelector() {
    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 9,
        separatorBuilder: (c, i) => const SizedBox(width: 12),
        itemBuilder: (c, i) {
          final age = i + 2;
          final isSel = childAge == age;
          return GestureDetector(
            onTap: () => setState(() => childAge = age),
            child: Container(
              width: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSel ? const Color(0xFF0A264F) : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSel
                      ? const Color(0xFF0A264F)
                      : const Color(0xFF0A264F).withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                age.toString(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSel ? Colors.white : const Color(0xFF0A264F),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStep2(Map<String, String> texts) {
    final enjoyOptions = [
      {
        "key": "act_draw",
        "img": "assets/images/drawing.png",
        "dbId": "Drawing",
      },
      {
        "key": "act_read",
        "img": "assets/images/reading.png",
        "dbId": "Reading",
      },
      {
        "key": "act_speak",
        "img": "assets/images/speaking.png",
        "dbId": "Speaking",
      },
      {"key": "act_music", "img": "assets/images/music.png", "dbId": "Music"},
      {"key": "act_sport", "img": "assets/images/sport.png", "dbId": "Sport"},
    ];
    return _buildListStep(
      texts['step2_title']!,
      enjoyOptions,
      childEnjoys,
      (l) => childEnjoys = l,
      texts,
    );
  }

  Widget _buildStep3(Map<String, String> texts) {
    final options = [
      {
        "key": "step3_v",
        "sub": "step3_v_sub",
        "img": "assets/images/visual.png",
        "dbId": "Visual",
      },
      {
        "key": "step3_a",
        "sub": "step3_a_sub",
        "img": "assets/images/auditory.png",
        "dbId": "Auditori",
      },
      {
        "key": "step3_k",
        "sub": "step3_k_sub",
        "img": "assets/images/kinesthetic.png",
        "dbId": "Kinestetik",
      },
    ];
    return _buildListStep(
      texts['step3_title']!,
      options,
      childLearns,
      (l) => childLearns = l,
      texts,
      max: 1,
    );
  }

  Widget _buildStep4(Map<String, String> texts) {
    final options = [
      {
        "key": "skill_motor",
        "img": "assets/images/motor.png",
        "dbId": "Motor skills",
      },
      {
        "key": "skill_creat",
        "img": "assets/images/creativity.png",
        "dbId": "Creativity",
      },
      {
        "key": "skill_emp",
        "img": "assets/images/empathy.png",
        "dbId": "Empathy",
      },
      {
        "key": "skill_lit",
        "img": "assets/images/literacy.png",
        "dbId": "Literacy",
      },
      {
        "key": "skill_think",
        "img": "assets/images/thinking.png",
        "dbId": "Thinking skills",
      },
    ];
    return _buildListStep(
      texts['step4_title']!,
      options,
      childDevelops,
      (l) => childDevelops = l,
      texts,
    );
  }

  Widget _buildStep5(Map<String, String> texts) {
    final times = [
      {"dbId": "15_min", "key": "time_15m"},
      {"dbId": "30_min", "key": "time_30m"},
      {"dbId": "1_hour", "key": "time_1h"},
      {"dbId": "1_5_hours", "key": "time_1_5h"},
      {"dbId": "2_hours", "key": "time_2h"},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            texts['step5_title']!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0A264F),
            ),
          ),
          const SizedBox(height: 40),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: times.map((t) {
              final String dbId = t['dbId']!;
              final String label = texts[t['key']]!;
              final isSel = bondTime == dbId;

              return GestureDetector(
                onTap: () => setState(() => bondTime = dbId),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSel
                        ? const Color(0xFFF1A22F)
                        : const Color(0xFFF4F7FA),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSel ? Colors.white : const Color(0xFF0A264F),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildListStep(
    String title,
    List<Map<String, String>> options,
    List<String> current,
    Function(List<String>) onUpdate,
    Map<String, String> texts, {
    int max = 3,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0A264F),
            ),
          ),
          const SizedBox(height: 32),
          ...options.map((item) {
            final String label = texts[item['key']]!;
            final String? subLabel = item['sub'] != null
                ? texts[item['sub']]
                : null;
            final String dbId = item['dbId']!;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _OptionCard(
                label: label,
                subLabel: subLabel,
                iconPath: item['img']!,
                isSelected: current.contains(dbId),
                bgColor: current.contains(dbId)
                    ? const Color(0xFFFFE8B6)
                    : const Color(0xFFF0F4F8),
                onTap: () => setState(
                  () => toggleSelection(dbId, current, onUpdate, max: max),
                ),
              ),
            );
          }),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final String label;
  final String? subLabel;
  final String iconPath;
  final bool isSelected;
  final Color bgColor;
  final VoidCallback onTap;

  const _OptionCard({
    required this.label,
    this.subLabel,
    required this.iconPath,
    required this.isSelected,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? const Color(0xFFE57B65) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Image.asset(
              iconPath,
              width: 44,
              height: 44,
              errorBuilder: (c, e, s) => const Icon(Icons.broken_image),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w600,
                      color: isSelected
                          ? const Color(0xFFE57B65)
                          : const Color(0xFF0A264F),
                    ),
                  ),
                  if (subLabel != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subLabel!,
                      style: TextStyle(
                        fontSize: 13,
                        color: isSelected
                            ? const Color(0xFFE57B65).withValues(alpha: 0.8)
                            : const Color(0xFF0A264F).withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFFE57B65)),
          ],
        ),
      ),
    );
  }
}
