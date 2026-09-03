import 'dart:io'; // Untuk menangani file gambar
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../../shared/widgets/step_progress_bar.dart';
import '../../shared/widgets/back_button.dart';
import '../../data/repositories/supabase_repository.dart';
import '../../core/providers/language_provider.dart';
import '../../core/providers/child_provider.dart';
import '../../core/services/storage_upload_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/input_limits.dart';
import '../../shared/widgets/fun_background_decorations.dart';
import '../../core/theme/app_spacing.dart';

// 🔥 IMPORT SAKLAR UTAMA DARI FILE CHATBOT (Biar gak beda alam)
import '../../shared/widgets/penguin_chat_bot.dart';

// Warna TETAP, BUKAN AppColors.x -- layar identify (nama/usia/minat/foto
// anak) ini, sama kayak onboarding_page.dart, sengaja SELALU terang nggak
// peduli tema app-nya. Sama alasannya: dulu _kIdentifyNavy/.primaryLighter/
// .surface di sini reaktif ke dark mode, jadi pas dark mode aktif teksnya
// bisa nabrak kontras sama background yang beberapa step-nya tetep putih
// polos (Colors.white, nggak ikut tema).
const Color _kIdentifyNavy = Color(0xFF0A264F);
const Color _kIdentifyLightBlue = Color(0xFFA5CBEB);
const Color _kIdentifySurface = Colors.white;

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
    'err_max_reached': "You can only pick up to 3. Unpick one first.",
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
    'err_max_reached': "Maksimal cuma boleh pilih 3. Batalin salah satu dulu.",
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
  const IdentifyPage({super.key, this.isAddingChild = false});

  /// True kalau parent SENGAJA nambah anak lagi dari Profile (bukan
  /// alur onboarding pertama kali) — kalau true, jangan auto-redirect
  /// ke /home walau parent ini udah punya anak lain.
  final bool isAddingChild;

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
    // Parent yang sengaja mau nambah anak lagi TIDAK boleh diredirect
    // balik ke /home walau dia udah punya anak lain.
    if (widget.isAddingChild) return;

    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      // List + limit(1), BUKAN `.maybeSingle()` — `.maybeSingle()` error
      // kalau baris yang cocok lebih dari 1, dan itu bakal kejadian begitu
      // parent ini punya lebih dari 1 anak.
      final data = await supabase
          .from('children')
          .select()
          .eq('parent_id', user.id)
          .order('created_at', ascending: false)
          .limit(1);
      if (data.isNotEmpty && mounted) {
        ref.read(selectedChildIdProvider.notifier).setId(data.first['id']);
        context.go('/home');
      }
    } catch (e) {
      // Beda sama _pickImage/_handleSubmit di file ini yang udah dijaga
      // try/catch, cek ini sebelumnya nggak — kalau lagi offline pas app
      // baru dibuka, biarin aja lanjut ke alur identify normal daripada
      // nge-throw Future error yang nggak ketangkep.
      debugPrint("Gagal cek anak yang udah ada: $e");
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
      // Pemilih gambar itu layar milik SISTEM -- halaman ini bisa aja
      // udah dilepas pas galatnya balik (orang tuanya keluar dari app,
      // atau Android ngebunuh activity-nya buat hemat memori). Tanpa
      // penjaga ini, ScaffoldMessenger dipanggil pakai context yang udah
      // mati dan app-nya crash, persis di saat yang udah bermasalah.
      if (!mounted) return;
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
    Map<String, String>? texts,
  }) {
    List<String> newList = List.from(currentList);
    if (newList.contains(item)) {
      newList.remove(item);
    } else if (newList.length < max) {
      newList.add(item);
    } else {
      // Dulu di sini nggak ngapa-ngapain sama sekali kalau udah kena
      // batas maksimal — kesannya kartu itemnya rusak/nggak responsif,
      // padahal emang sengaja dibatasi.
      if (texts != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(texts['err_max_reached'] ?? 'Max $max')),
        );
      }
      return;
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
        backgroundColor: AppColors.accent,
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
      String? uploadedPhotoUrl;

      // 1. Cek apakah Bunda milih foto. Kalau iya, upload ke bucket 'user_photo'
      if (_imageFile != null) {
        uploadedPhotoUrl = await StorageUploadService.uploadProfilePhoto(
          _imageFile!,
        );
      }

      // 2. Setor semua data (termasuk link foto) ke Repository
      final String childId =
          await ref.read(supabaseRepositoryProvider).submitOnboardingData(
                // Dipangkas SEBELUM disimpan. Validasi di atas emang udah
                // pakai trim(), tapi yang dikirim ke database dulu nilai
                // mentahnya -- jadi nama berspasi di ujung tetap lolos dan
                // kebawa ke mana-mana: sapaan di Home ("Halo, Jasmine !"),
                // sertifikat, sampai laporan PDF. Di database sekarang masih
                // ada satu baris peninggalan ini.
                name: childName.trim(),
                age: childAge!,
                interests: childEnjoys,
                learningStyles: childLearns,
                parentGoals: childDevelops,
                timePreference: bondTime ?? "15_min",
                avatarUrl: uploadedPhotoUrl,
              );

      ref.read(selectedChildIdProvider.notifier).setId(childId);
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
    final Color mainBgColor = isWhiteBg ? Colors.white : _kIdentifyLightBlue;

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
          // Sentuhan ringan -- layar ini udah punya ilustrasi & gradasi
          // per-langkahnya sendiri, jadi dekorasinya sengaja dikit.
          const Sparkle(top: 90, right: 20, size: 16, color: AppColors.accent),
          const Sparkle(top: 160, left: 16, size: 12, color: AppColors.gold),
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
              child: Center(
                child: CircularProgressIndicator(color: _kIdentifyNavy),
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
                  backgroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.xl),
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
                backgroundColor: _kIdentifyNavy,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
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
            style: TextStyle(
              color: _kIdentifyNavy,
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
            // Dulu nggak ada batas panjang sama sekali di seluruh app --
            // nama sepanjang apa pun keterima, lalu kebawa ke sapaan
            // Home, kartu sertifikat, dan laporan PDF yang lebarnya
            // tetap. buildCounter dimatiin biar teks "0/30" bawaan
            // Flutter nggak nongol dan ngerusak tata letaknya.
            maxLength: kMaxChildNameLength,
            buildCounter: (_,
                    {required currentLength, required isFocused, maxLength}) =>
                null,
            decoration: InputDecoration(
              hintText: texts['step1_hint']!,
              filled: true,
              fillColor: _kIdentifySurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
            ),
          ),
          const SizedBox(height: 40),
          Text(
            texts['step1_age']!,
            style: TextStyle(
              color: _kIdentifyNavy,
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
                color: _kIdentifyNavy.withValues(alpha: 0.1),
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
              decoration: BoxDecoration(
                color: AppColors.accent,
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
                color: isSel ? _kIdentifyNavy : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSel
                      ? _kIdentifyNavy
                      : _kIdentifyNavy.withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                age.toString(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSel ? Colors.white : _kIdentifyNavy,
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
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _kIdentifyNavy,
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
                    color: isSel ? AppColors.gold : const Color(0xFFF4F7FA),
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSel ? Colors.white : _kIdentifyNavy,
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
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _kIdentifyNavy,
            ),
          ),
          const SizedBox(height: 32),
          ...options.map((item) {
            final String label = texts[item['key']]!;
            final String? subLabel =
                item['sub'] != null ? texts[item['sub']] : null;
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
                  () => toggleSelection(
                    dbId,
                    current,
                    onUpdate,
                    max: max,
                    texts: texts,
                  ),
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
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: isSelected ? AppColors.accent : Colors.transparent,
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
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected ? AppColors.accent : _kIdentifyNavy,
                    ),
                  ),
                  if (subLabel != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subLabel!,
                      style: TextStyle(
                        fontSize: 13,
                        color: isSelected
                            ? AppColors.accent.withValues(alpha: 0.8)
                            : _kIdentifyNavy.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: AppColors.accent),
          ],
        ),
      ),
    );
  }
}
