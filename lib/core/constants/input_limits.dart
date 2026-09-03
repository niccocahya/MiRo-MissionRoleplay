/// Batas panjang isian yang dipakai orang tua.
///
/// Sebelum ini nggak ada satu pun `maxLength` di seluruh app -- nama anak
/// atau nama orang tua sepanjang apa pun keterima apa adanya, lalu kebawa
/// ke tempat-tempat yang lebarnya TETAP dan nggak bisa ngalir: sapaan di
/// Home, kartu sertifikat, dan laporan PDF.
///
/// Angkanya sengaja longgar -- cukup buat nama panjang yang wajar
/// (termasuk nama Indonesia yang beruntun), tapi tetap nutup isian yang
/// jelas bukan nama.
library;

/// Nama anak. Dipakai di sapaan Home, sertifikat, dan konteks Mink.
const int kMaxChildNameLength = 30;

/// Nama orang tua. Muncul di sapaan Home dan laporan PDF.
const int kMaxParentNameLength = 50;

/// Umur anak -- 2 digit sudah cukup, app ini buat anak-anak.
const int kMaxChildAgeLength = 2;
