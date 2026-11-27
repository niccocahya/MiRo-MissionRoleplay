# Standar Desain (ringkasan untuk implementasi)

Sumber lengkap: [`../DESIGN_SYSTEM.md`](../DESIGN_SYSTEM.md). Dokumen ini adalah daftar periksa singkat yang dipakai setiap kali membuat atau meninjau layar.

## 1. Identitas

- **Rasa:** hangat, tebal, bermain, seperti mainan yang bisa ditekan. Bukan dashboard korporat.
- **Maro** muncul di momen yang butuh emosi (sapaan, perayaan, kosong, error), tidak di setiap kartu.
- **Logo:** siluet navy di kotak krem (`assets/brand/miro-logo.svg`). Aturan di DESIGN_SYSTEM §10.1b.

## 2. Warna

| Aturan | Detail |
|---|---|
| Proporsi | 60% latar terang, 30% navy, 10% coral/amber |
| Coral = aksi | Tombol utama `coral-600` dengan lip `coral-700` |
| Amber = hadiah | XP, ikan, peti, lencana, CTA perayaan. Teks di atas amber selalu navy |
| Hijau = berhasil | Tombol "Sudah!", centang, toggle aktif. Bukan dekorasi |
| Warna peran | Hanya untuk tab peran, kartu misi, latar ilustrasi. Tidak untuk tombol berteks |
| Gradien | Hanya `bg-mood` (onboarding, perayaan) |

## 3. Tipografi

Nunito 600 sampai 900. Skala: 40 / 32 / 24 / 20 / 17 / 15 / 13 / 12 px. Judul layar maksimal 2 baris di 375px. Label tombol uppercase 0.04em. Label kecil di atas judul memakai huruf kalimat 13px tebal, **bukan** huruf kapital renggang.

## 4. Bentuk dan kedalaman

- Grid 4pt, margin layar 20px.
- Radius: tombol 16, kartu 20, sheet 28, chip penuh.
- **Lip** (bayangan padat di bawah) pada semua elemen yang bisa ditekan: 4px tombol, 3px kartu, 2px tombol ikon. Tidak ada bayangan blur.
- Border 2px `navy-200` untuk kartu putih.

## 5. Komposisi layar

- Urutan: header (kembali + judul) → konten → `StickyFooter` dengan satu tombol utama.
- Satu elemen "bintang" per layar (angka streak, lencana, foto). Sisanya mendukung.
- Hindari tiga kotak statistik berjajar kecuali di perayaan dan statistik kelas; pakai satu kalimat utama + angka pendukung.
- Kosong bukan kesalahan: setiap daftar punya state kosong yang mengajak bertindak.

## 6. Larangan "AI slop"

- `·` atau `—` sebagai pemisah teks
- Eyebrow huruf kapital renggang
- Kartu harga gaya SaaS (kartu gelap + centang + pill "Paling populer")
- Daftar fitur bercentang di kartu pilihan
- Lingkaran buram dekoratif, gradien acak, garis tepi kiri berwarna di kartu
- Emoji atau ikon bergaya emoji (bola lampu kuning, bintang berkilau)
- Ornamen yang terlihat seperti tanda centang atau jarum jam
- Elemen yang menumpuk tanpa sengaja
- Copy pemasaran kosong ("Tingkatkan pengalaman Anda")

## 7. Daftar periksa per layar

- [ ] Sama dengan `design/screens/NN-*.png`
- [ ] Satu tombol utama, di bawah
- [ ] Warna mengikuti peran warna (§2)
- [ ] Teks lolos kontras, tidak ada teks putih di amber
- [ ] Tidak ada pelanggaran §6
- [ ] State kosong, memuat, error dirancang
- [ ] Copy hangat, pendek, dalam Bahasa Indonesia, berganti untuk akun Guru
