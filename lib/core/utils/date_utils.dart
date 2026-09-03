/// Parsing tanggal yang aman dari berbagai format yang dikirim Supabase,
/// HASILNYA SELALU WAKTU LOKAL.
///
/// Sebelumnya fungsi ini (byte demi byte identik) ditulis ulang terpisah di
/// `home_page.dart` dan `progress_page.dart`.
///
/// Soal `.toLocal()`-nya: kolom `timestamptz` dikirim PostgREST dengan
/// offset (mis. "2026-05-05T17:21:05.267+00:00"), jadi `DateTime.parse`
/// balikin objek ber-flag UTC. Yang manggil fungsi ini rata-rata langsung
/// ngambil komponen tanggalnya (`DateTime(d.year, d.month, d.day)`) buat
/// dibandingin sama `DateTime.now()` yang LOKAL -- campur UTC vs lokal.
///
/// Buat Indonesia (UTC+7) itu meleset sehari penuh tiap misi diselesaikan
/// antara 00:00-06:59 WIB: contoh nyata dari database ini,
/// "2026-05-05T17:21:05+00:00" itu 6 Mei 00:21 WIB, tapi kebaca sebagai
/// 5 Mei. Efeknya streak ngira "kemarin" padahal barusan, kalender streak
/// nandain kotak hari yang salah, dan peringatan "streak-mu mau putus"
/// muncul padahal misinya udah dikerjain pagi tadi.
DateTime? parseDateSafely(String dateStr) {
  if (dateStr.isEmpty) return null;

  String s = dateStr.trim();

  // Normalize ke ISO8601
  if (!s.contains('T') && s.contains(' ')) {
    s = s.replaceFirst(' ', 'T');
  }

  try {
    return DateTime.parse(s).toLocal();
  } catch (_) {
    return null;
  }
}
