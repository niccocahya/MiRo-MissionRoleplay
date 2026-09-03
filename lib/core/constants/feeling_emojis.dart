/// Skala 5 emoji perasaan (indeks 0..4) yang dipakai di refleksi misi.
///
/// Dulu daftar ini ditulis ulang di 2 file: mission_reflection_screen.dart
/// (buat NGISI perasaan) dan mission_journal_screen.dart (buat NAMPILIN
/// balik perasaan yang udah diisi). Karena angka yang kesimpen di database
/// (`reflections.parent_feeling`/`child_feeling`) itu INDEKS ke daftar ini,
/// dua daftar yang kepisah = bom waktu: begitu salah satunya diubah
/// urutannya, emoji yang ditampilin nggak nyambung lagi sama yang dipilih.
const List<String> kFeelingEmojis = ["😞", "😐", "🙂", "😀", "🤩"];

/// Emoji buat satu nilai perasaan, aman dari indeks di luar jangkauan
/// (mis. data lama/rusak).
String feelingEmoji(int? index) {
  if (index == null || index < 0 || index >= kFeelingEmojis.length) return '❓';
  return kFeelingEmojis[index];
}
