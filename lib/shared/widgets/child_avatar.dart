import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Emoji yang dipakai kalau anak belum punya foto profil. Di data beneran,
/// foto profil hampir SELALU kosong (langkahnya gampang dilewatin pas
/// onboarding), jadi ini yang paling sering keliatan.
const String kChildAvatarFallbackEmoji = "👦🏻";

/// Foto profil anak berbentuk lingkaran, dengan fallback emoji kalau
/// fotonya belum ada / gagal dimuat.
///
/// Blok ini sebelumnya ditulis ulang di beberapa tempat (header Profil,
/// tiap baris di switcher ganti-anak, dll) dengan struktur sama persis --
/// cuma beda ukuran lingkaran & ukuran emoji-nya, yang tiap kali dihitung
/// manual (72/36, 48/24, ...). Sekarang tinggal kasih [size], ukuran
/// emoji-nya ngikut otomatis.
class ChildAvatar extends StatelessWidget {
  const ChildAvatar({
    super.key,
    required this.avatarUrl,
    this.size = 48,
    this.borderColor,
    this.showShadow = false,
  });

  final String? avatarUrl;
  final double size;

  /// Default: putih (kayak semua pemakaian sebelumnya).
  final Color? borderColor;

  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    final bool hasPhoto = avatarUrl != null && avatarUrl!.isNotEmpty;
    // Perbandingan yang dipakai di semua pemakaian sebelumnya: emoji
    // kira-kira setengah dari diameter lingkarannya.
    final double emojiSize = size / 2;

    final Widget fallback = Text(
      kChildAvatarFallbackEmoji,
      style: TextStyle(fontSize: emojiSize),
    );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.accentTint,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor ?? Colors.white, width: 2),
        boxShadow: showShadow
            ? const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      child: hasPhoto
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: avatarUrl!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => fallback,
              ),
            )
          : fallback,
    );
  }
}
