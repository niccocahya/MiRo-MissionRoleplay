import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

// JALUR IMPORT
import '../../../shared/widgets/penguin_chat_bot.dart'; // Pastikan path ini benar!
import '../data/mission_model.dart';
import 'mission_win_screen.dart';
import '../../../core/providers/language_provider.dart';
import '../../../core/router/app_page_transition.dart';
import '../../../core/services/storage_upload_service.dart';
import '../../../core/theme/app_colors.dart';

// ==========================================
// 1. DICTIONARY (KAMUS LENGKAP)
// ==========================================
const Map<String, Map<String, String>> _t = {
  'en': {
    'img_failed': "Failed to load image",
    'photo_saved': "Photo successfully saved",
    'photo_failed': "Failed to upload photo: ",
    'read_instruction': "Reading instructions",
    'how_to_play': "How to play",
    'step': "Step",
    'listen': "Listen",
    'photo_saved_btn': "Photo Saved",
    'add_photo': "Add Photo",
    'uploading': "Uploading...",
    'done': "Done",
    'tips': "Tips for Parents",
    'back': "Back",
    'next': "Next",
  },
  'id': {
    'img_failed': "Gambar gagal dimuat",
    'photo_saved': "Foto berhasil tersimpan",
    'photo_failed': "Gagal mengunggah foto: ",
    'read_instruction': "Membacakan instruksi",
    'how_to_play': "Cara bermain",
    'step': "Langkah",
    'listen': "Dengar",
    'photo_saved_btn': "Foto Tersimpan",
    'add_photo': "Tambah Foto",
    'uploading': "Mengunggah...",
    'done': "Selesai",
    'tips': "Tips untuk Orang Tua",
    'back': "Kembali",
    'next': "Lanjut",
  },
};

// =====================================================================
// 🔥 WIDGET PINTAR: SMART SUPABASE IMAGE
// Otomatis mencari versi .jpg jika .PNG tidak ditemukan (Mencegah 404)
// =====================================================================
class SmartSupabaseImage extends StatefulWidget {
  final String rawPath;
  final double? width;
  final double? height;
  final BoxFit fit;

  const SmartSupabaseImage({
    super.key,
    required this.rawPath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  State<SmartSupabaseImage> createState() => _SmartSupabaseImageState();
}

class _SmartSupabaseImageState extends State<SmartSupabaseImage> {
  bool _tryFallback = false;

  String _getPublicUrl(String path) {
    return Supabase.instance.client.storage
        .from('mission-assets')
        .getPublicUrl(path);
  }

  @override
  Widget build(BuildContext context) {
    // 1. Target utama sesuai database (biasanya .PNG)
    String targetPath = widget.rawPath;

    // 2. Kalau target utama gagal, ubah paksa jadi .jpg
    if (_tryFallback) {
      targetPath = widget.rawPath.replaceAll(
        RegExp(r'\.PNG|\.png', caseSensitive: false),
        '.jpg',
      );
    }

    return CachedNetworkImage(
      imageUrl: _getPublicUrl(targetPath),
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      placeholder: (context, url) => Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            color: Colors.white.withValues(alpha: 0.5),
            strokeWidth: 2,
          ),
        ),
      ),
      errorWidget: (context, url, error) {
        // Jika gagal meload .PNG, perintahkan widget untuk nyoba .jpg di frame berikutnya
        if (!_tryFallback) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _tryFallback = true);
          });
          return Center(
            child: CircularProgressIndicator(
              color: Colors.white.withValues(alpha: 0.5),
            ),
          );
        }
        // Jika .jpg juga gagal (Mungkin typo parah di Supabase), tampilkan icon rusak
        return Container(
          width: widget.width,
          height: widget.height,
          color: Colors.white30,
          child: const Icon(Icons.broken_image, color: Colors.white),
        );
      },
    );
  }
}

// =====================================================================
// HALAMAN UTAMA MISSION PLAY
// =====================================================================
class MissionPlayScreen extends ConsumerStatefulWidget {
  final MissionModel mission;

  const MissionPlayScreen({super.key, required this.mission});

  @override
  ConsumerState<MissionPlayScreen> createState() => _MissionPlayScreenState();
}

class _MissionPlayScreenState extends ConsumerState<MissionPlayScreen> {
  int activeStep = 0;
  int completedSteps = 0;
  int? openTipsIndex;
  bool isUploading = false;

  late List<int> _currentSubSteps;
  late List<PageController> _pageControllers;
  final Map<int, String> _stepPhotos = {};
  late FlutterTts flutterTts;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final int stepCount = widget.mission.stepsId.length;
    _currentSubSteps = List.filled(stepCount, 0);
    _pageControllers = List.generate(stepCount, (_) => PageController());
    flutterTts = FlutterTts();
    _setupTts();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setMissionContextForMink();
    });
  }

  void _setMissionContextForMink() {
    final lang = ref.read(languageProvider);
    final title = lang == 'id'
        ? widget.mission.titleId
        : widget.mission.titleEn;
    final desc = lang == 'id'
        ? widget.mission.descriptionId
        : widget.mission.descriptionEn;

    final contextString =
        "JUDUL MISI: '$title'.\nDESKRIPSI: '$desc'.\n(Pandu Bunda dengan tips praktis untuk melakukan misi offline ini jika mereka bertanya).";
    ref.read(currentMissionContextProvider.notifier).setContext(contextString);
  }

  Future<void> _setupTts() async {
    final lang = ref.read(languageProvider);
    final targetLang = lang == 'id' ? "id-ID" : "en-US";

    bool isTargetAvailable = await flutterTts.isLanguageAvailable(targetLang);
    if (isTargetAvailable) {
      await flutterTts.setLanguage(targetLang);
    } else {
      await flutterTts.setLanguage(lang);
    }

    await flutterTts.setSpeechRate(1.0);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(2.0);
  }

  @override
  void dispose() {
    ref.read(currentMissionContextProvider.notifier).setContext(null);
    flutterTts.stop();
    for (var controller in _pageControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _showImageDialog(String rawPath) {
    if (rawPath.isEmpty) return;

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            InteractiveViewer(
              clipBehavior: Clip.none,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                // 🔥 Memanggil Smart Widget untuk Dialog
                child: SmartSupabaseImage(
                  rawPath: rawPath,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: -16,
              right: -16,
              child: IconButton(
                icon: const Icon(Icons.cancel, color: Colors.white, size: 36),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _takeAndUploadPhoto(int stepIndex) async {
    if (isUploading) return;

    final lang = ref.read(languageProvider);
    final texts = _t[lang] ?? _t['en']!;

    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );

    if (photo == null) return;

    setState(() => isUploading = true);

    try {
      final file = File(photo.path);
      final publicUrl = await StorageUploadService.uploadMissionStepPhoto(
        missionId: widget.mission.id,
        stepIndex: stepIndex,
        file: file,
      );

      setState(() {
        _stepPhotos[stepIndex] = publicUrl;
        isUploading = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(texts['photo_saved']!)));
    } catch (e) {
      setState(() => isUploading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("${texts['photo_failed']!}$e")));
    }
  }

  Future<void> _playVoice(String text) async {
    final lang = ref.read(languageProvider);
    final texts = _t[lang] ?? _t['en']!;

    await flutterTts.stop();
    await flutterTts.speak(text);
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.volume_up, color: Colors.white),
            const SizedBox(width: 8),
            Text(texts['read_instruction']!),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final texts = _t[lang] ?? _t['en']!;

    final List steps = lang == 'id'
        ? widget.mission.stepsId
        : widget.mission.stepsEn;
    final bool allStepsDone = completedSteps >= steps.length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SizedBox.expand(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.background, Color(0xFFE2EAF4)],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // PROGRESS BAR
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        texts['how_to_play']!,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: List.generate(steps.length, (index) {
                          bool isCompleted = index < completedSteps;
                          bool isActive = index == activeStep;
                          return Expanded(
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              height: 8,
                              decoration: BoxDecoration(
                                color: isCompleted || isActive
                                    ? AppColors.primary
                                    : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: isActive
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primary.withValues(alpha: 0.3),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),

                // DAFTAR LANGKAH
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    physics: const BouncingScrollPhysics(),
                    itemCount: steps.length,
                    separatorBuilder: (c, i) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final step = steps[index];
                      final List instructions = step['instructions'] ?? [];
                      final List tips = step['step_tips'] ?? step['tips'] ?? [];
                      final bool isCurrent = index == completedSteps;
                      final bool isFinished = index < completedSteps;
                      final bool isOpen = activeStep == index;
                      final bool isTipsOpen = openTipsIndex == index;
                      final bool isLastSubStep =
                          instructions.isEmpty ||
                          _currentSubSteps[index] == instructions.length - 1;

                      return GestureDetector(
                        onTap: () {
                          if (isFinished || isCurrent) {
                            setState(() => activeStep = index);
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                          decoration: BoxDecoration(
                            gradient: isOpen
                                ? const LinearGradient(
                                    colors: [
                                      AppColors.primary,
                                      AppColors.primaryLight,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color: isOpen
                                ? null
                                : AppColors.gold.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: isOpen
                                ? const [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 15,
                                      offset: Offset(0, 5),
                                    ),
                                  ]
                                : null,
                          ),
                          child: AnimatedSize(
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeInOut,
                            alignment: Alignment.topCenter,
                            child: Padding(
                              padding: EdgeInsets.all(isOpen ? 28 : 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // HEADER KARTU
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          if (isFinished) ...[
                                            Container(
                                              width: 24,
                                              height: 24,
                                              decoration: const BoxDecoration(
                                                color: Colors.green,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.check,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                          ],
                                          Text(
                                            "${texts['step']} ${index + 1}",
                                            style: TextStyle(
                                              color: isOpen
                                                  ? Colors.white
                                                  : AppColors.primary,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (!isOpen)
                                        Icon(
                                          Icons.keyboard_arrow_down,
                                          color: AppColors.primary.withValues(alpha: 0.4),
                                        ),
                                    ],
                                  ),

                                  // KONTEN DALAM KARTU
                                  if (isOpen) ...[
                                    const SizedBox(height: 24),
                                    if (instructions.isNotEmpty) ...[
                                      SizedBox(
                                        height: 160,
                                        child: PageView.builder(
                                          controller: _pageControllers[index],
                                          onPageChanged: (idx) => setState(
                                            () => _currentSubSteps[index] = idx,
                                          ),
                                          itemCount: instructions.length,
                                          itemBuilder: (ctx, subIdx) {
                                            return Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  width: 28,
                                                  height: 28,
                                                  decoration:
                                                      const BoxDecoration(
                                                        color: Colors.white,
                                                        shape: BoxShape.circle,
                                                      ),
                                                  alignment: Alignment.center,
                                                  child: Text(
                                                    '${subIdx + 1}',
                                                    style: const TextStyle(
                                                      color: AppColors.primary,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        instructions[subIdx],
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 15,
                                                          height: 1.4,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        height: 12,
                                                      ),
                                                      GestureDetector(
                                                        onTap: () => _playVoice(
                                                          instructions[subIdx],
                                                        ),
                                                        child: Container(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 12,
                                                                vertical: 8,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color: Colors.white
                                                                .withValues(
                                                                  alpha: 0.2,
                                                                ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  20,
                                                                ),
                                                          ),
                                                          child: Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              Icon(
                                                                Icons
                                                                    .volume_up_rounded,
                                                                color: Colors
                                                                    .white
                                                                    .withValues(
                                                                      alpha:
                                                                          0.7,
                                                                    ),
                                                                size: 16,
                                                              ),
                                                              const SizedBox(
                                                                width: 6,
                                                              ),
                                                              Text(
                                                                texts['listen']!,
                                                                style: TextStyle(
                                                                  color: Colors
                                                                      .white
                                                                      .withValues(
                                                                        alpha:
                                                                            0.7,
                                                                      ),
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                // 🔥 PANGGIL SMART WIDGET DI SINI
                                                if (step['image_url'] != null &&
                                                    step['image_url']
                                                        .toString()
                                                        .isNotEmpty) ...[
                                                  const SizedBox(width: 12),
                                                  GestureDetector(
                                                    onTap: () =>
                                                        _showImageDialog(
                                                          step['image_url'],
                                                        ),
                                                    child: ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                      child: SmartSupabaseImage(
                                                        rawPath:
                                                            step['image_url'],
                                                        width: 70,
                                                        height: 70,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            );
                                          },
                                        ),
                                      ),

                                      // DOTS SUBSTEP
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: List.generate(
                                          instructions.length,
                                          (dotIdx) => Container(
                                            margin: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                            ),
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color:
                                                  _currentSubSteps[index] ==
                                                      dotIdx
                                                  ? Colors.white
                                                  : Colors.white.withValues(
                                                      alpha: 0.3,
                                                    ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ] else
                                      const SizedBox(width: double.infinity),

                                    // BAGIAN TIPS
                                    if (tips.isNotEmpty) ...[
                                      const SizedBox(height: 20),
                                      const Divider(color: Colors.white24),
                                      GestureDetector(
                                        onTap: () => setState(
                                          () => openTipsIndex = isTipsOpen
                                              ? null
                                              : index,
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                          color: Colors.transparent,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                texts['tips']!,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Icon(
                                                isTipsOpen
                                                    ? Icons.keyboard_arrow_up
                                                    : Icons.keyboard_arrow_down,
                                                color: Colors.white,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      AnimatedSize(
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        child: isTipsOpen
                                            ? Padding(
                                                padding: const EdgeInsets.only(
                                                  bottom: 16,
                                                  left: 16,
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: tips
                                                      .map(
                                                        (t) => Padding(
                                                          padding:
                                                              const EdgeInsets.only(
                                                                bottom: 16,
                                                              ),
                                                          child: Row(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              const Text(
                                                                "• ",
                                                                style: TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                ),
                                                              ),
                                                              Expanded(
                                                                child: Column(
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .start,
                                                                  children: [
                                                                    Text(
                                                                      t.toString(),
                                                                      style: TextStyle(
                                                                        color: Colors
                                                                            .white
                                                                            .withValues(
                                                                              alpha: 0.9,
                                                                            ),
                                                                        fontSize:
                                                                            14,
                                                                        height:
                                                                            1.4,
                                                                      ),
                                                                    ),
                                                                    const SizedBox(
                                                                      height: 8,
                                                                    ),
                                                                    GestureDetector(
                                                                      onTap: () =>
                                                                          _playVoice(
                                                                            t.toString(),
                                                                          ),
                                                                      child: Row(
                                                                        mainAxisSize:
                                                                            MainAxisSize.min,
                                                                        children: [
                                                                          Icon(
                                                                            Icons.volume_up_rounded,
                                                                            color: Colors.white.withValues(
                                                                              alpha: 0.7,
                                                                            ),
                                                                            size:
                                                                                16,
                                                                          ),
                                                                          const SizedBox(
                                                                            width:
                                                                                6,
                                                                          ),
                                                                          Text(
                                                                            texts['listen']!,
                                                                            style: TextStyle(
                                                                              color: Colors.white.withValues(
                                                                                alpha: 0.7,
                                                                              ),
                                                                              fontSize: 12,
                                                                              fontWeight: FontWeight.w600,
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      )
                                                      .toList(),
                                                ),
                                              )
                                            : const SizedBox(
                                                width: double.infinity,
                                              ),
                                      ),
                                    ],

                                    // TOMBOL AKSI: AMBIL FOTO / LANJUT
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        if (isCurrent && isLastSubStep)
                                          GestureDetector(
                                            onTap: () =>
                                                _takeAndUploadPhoto(index),
                                            child: Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(
                                                    10,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        _stepPhotos.containsKey(
                                                          index,
                                                        )
                                                        ? Colors.green
                                                        : Colors.white
                                                              .withValues(
                                                                alpha: 0.2,
                                                              ),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child:
                                                      isUploading &&
                                                          activeStep == index
                                                      ? const SizedBox(
                                                          width: 20,
                                                          height: 20,
                                                          child:
                                                              CircularProgressIndicator(
                                                                color: Colors
                                                                    .white,
                                                                strokeWidth:
                                                                    2.5,
                                                              ),
                                                        )
                                                      : Icon(
                                                          _stepPhotos
                                                                  .containsKey(
                                                                    index,
                                                                  )
                                                              ? Icons.check
                                                              : Icons
                                                                    .camera_alt_rounded,
                                                          color: Colors.white,
                                                          size: 20,
                                                        ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  isUploading &&
                                                          activeStep == index
                                                      ? texts['uploading']!
                                                      : _stepPhotos.containsKey(
                                                          index,
                                                        )
                                                      ? texts['photo_saved_btn']!
                                                      : texts['add_photo']!,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        else
                                          const SizedBox(),

                                        ElevatedButton(
                                          onPressed:
                                              (isCurrent &&
                                                  isLastSubStep &&
                                                  !isUploading)
                                              ? () {
                                                  flutterTts.stop();
                                                  setState(() {
                                                    completedSteps = index + 1;
                                                    openTipsIndex = null;
                                                    if (completedSteps <
                                                        steps.length) {
                                                      activeStep =
                                                          completedSteps;
                                                    }
                                                  });
                                                }
                                              : null,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                (isCurrent &&
                                                    isLastSubStep &&
                                                    !isUploading)
                                                ? AppColors.accent
                                                : Colors.white.withValues(
                                                    alpha: 0.2,
                                                  ),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 40,
                                              vertical: 16,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(30),
                                            ),
                                            elevation:
                                                (isCurrent &&
                                                    isLastSubStep &&
                                                    !isUploading)
                                                ? 5
                                                : 0,
                                          ),
                                          child: Text(
                                            texts['done']!,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // TOMBOL NAVIGASI BAWAH
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            flutterTts.stop();
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Text(
                            texts['back']!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: allStepsDone
                              ? () {
                                  flutterTts.stop();
                                  Navigator.pushReplacement(
                                    context,
                                    appPageRoute(
                                      MissionWinScreen(
                                        mission: widget.mission,
                                        capturedPhotos: _stepPhotos.values
                                            .toList(),
                                      ),
                                    ),
                                  );
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: allStepsDone
                                ? AppColors.primary
                                : Colors.grey.shade300,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Text(
                            texts['next']!,
                            style: TextStyle(
                              color: allStepsDone
                                  ? Colors.white
                                  : Colors.grey.shade500,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
