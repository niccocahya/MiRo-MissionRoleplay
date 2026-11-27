# Standar Kenyamanan Pengguna (UX dan Aksesibilitas)

Pengguna MiRO adalah orang tua atau guru yang memegang HP dengan satu tangan sambil mengawasi anak. Mereka sering terganggu, sering lelah, dan tidak punya waktu membaca. Setiap keputusan UX diuji dengan satu pertanyaan: **apakah ini bisa dipakai dengan satu tangan, dalam 3 detik, sambil melirik?**

## 1. Prinsip

1. **Layar adalah pemandu, bukan tujuan.** Waktu di layar per misi (di luar membaca langkah) ≤ 2 menit. Tidak ada feed, scroll tanpa akhir, atau notifikasi yang memancing.
2. **Satu aksi utama per layar**, selalu di bawah, di zona jempol.
3. **Tidak ada hukuman.** Tidak ada nyawa, tidak ada "gagal". Streak putus disampaikan dengan nada tenang (layar 45).
4. **Jelas lebih penting dari pintar.** Label tombol kata kerja ≤ 3 kata. Tidak ada istilah teknis.
5. **Hormati perhatian.** Maksimal satu notifikasi push per hari, tidak ada pop-up promosi, paket berbayar hanya muncul saat pengguna menyentuh fitur terkunci atau membukanya sendiri.

## 2. Tata letak dan jangkauan

- Lebar desain 390px; harus rapi di 320, 375, 390, dan 430px.
- Margin samping 20px. Jarak antar blok 12 sampai 16px.
- Tombol utama di `MiroStickyFooter` (padding bawah 24 + safe area bawah).
- Aksi destruktif tidak pernah di posisi tombol utama dan tidak berwarna coral.
- Tombol kembali kiri atas 44px; di layar alur misi tombol keluar (X) memicu konfirmasi (33).
- Konten penting tidak boleh tertutup bottom nav: tambahkan padding bawah setinggi nav.

## 3. Target sentuh dan ketikan

- Target sentuh minimal 44×44px, jarak antar target minimal 8px.
- Field memakai `keyboardType`, `textInputAction`, dan `autofillHints` yang tepat (`AutofillHints.email`, `password`, `newPassword`, `nickname`), dibungkus `AutofillGroup`.
- Keyboard tidak menutupi field aktif atau tombol kirim: layar form memakai `SingleChildScrollView` + `MiroStickyFooter` yang ikut `MediaQuery.viewInsets`.
- Stepper (−/+) untuk angka kecil (usia, jumlah siswa), bukan field ketik.

## 4. Form dan validasi

- Validasi saat blur dan saat kirim, bukan setiap ketikan.
- Pesan error di bawah field, warna `red-700`, dengan ikon, menjelaskan cara memperbaiki: "Emailnya belum lengkap. Contoh: nama@gmail.com".
- Tombol kirim nonaktif sampai field wajib terisi, tapi tetap jelaskan apa yang kurang jika diketuk.
- Jangan pernah menghapus isi form saat error.
- Lupa kata sandi (43) memberi pesan yang sama untuk email terdaftar atau tidak (keamanan).

## 5. State wajib di setiap layar

| State | Aturan |
|---|---|
| Memuat | Skeleton berbentuk konten asli, muncul setelah 300 ms (hindari kedip) |
| Kosong | `MiroEmptyState`: Maro, judul, satu kalimat alasan, langkah singkat, satu CTA (48, 49, 53) |
| Error | Pesan manusiawi + "Coba lagi". Data yang sudah diisi tidak hilang |
| Offline | Banner navy (50). Aksi yang bisa ditunda tetap jalan dan masuk antrean |
| Sukses | Umpan balik langsung (animasi, toast, atau layar perayaan), tidak diam |
| Terkunci (paket) | Tampilkan isi yang terkunci + jalan untuk membuka (46), jangan sembunyikan |

## 6. Konfirmasi dan pembatalan

- Aksi yang bisa dibatalkan: lakukan langsung, beri toast dengan "Urungkan" 5 detik (mis. mengeluarkan foto dari kolase).
- Aksi permanen (hapus anak, hapus akun): `MiroAlertSheet` dua langkah, sebutkan apa yang hilang dengan angka, tawarkan unduh data dulu, minta ketik nama untuk konfirmasi (40).
- Keluar dari misi: konfirmasi yang menyebutkan progres yang hilang (33). Tombol aman ("Lanjut main") yang paling menonjol.

## 7. Aksesibilitas (WCAG 2.2 AA)

- **Kontras:** teks biasa ≥ 4,5:1, teks besar (≥ 18,66px tebal) dan elemen UI ≥ 3:1. Token di DESIGN_SYSTEM §1.3 sudah lolos. Teks putih di atas amber dan `coral-500` dilarang.
- **Ukuran teks:** hormati `textScaler` sistem dan pengaturan ukuran teks aplikasi. Layout harus tahan sampai 1.3× tanpa terpotong (hindari tinggi tetap pada wadah teks; pakai `Flexible`, `Wrap`, `FittedBox` hanya untuk angka besar).
- **Fokus:** ring fokus terlihat saat navigasi keyboard/switch access. Urutan fokus mengikuti urutan visual. Sheet mengunci fokus dan mengembalikannya ke pemicu saat ditutup.
- **Screen reader:**
  - Gambar dekoratif `alt=""`, ilustrasi bermakna diberi alt.
  - Ikon tanpa teks dibungkus `Semantics(label: …)` atau diberi `tooltip`.
  - Perubahan penting diumumkan lewat `SemanticsService.announce` (XP didapat, streak naik, foto gagal).
  - Grafik (`WeekBars`, `SkillRadar`) dibungkus `Semantics(label: ringkasan angka)` dan `ExcludeSemantics` untuk isi grafiknya.
- **Warna bukan satu-satunya penanda:** status selesai/terkunci/gagal selalu disertai ikon atau teks.
- **Gerak:** lihat ANIMATION §7.
- **Bahasa:** `locale` MaterialApp mengikuti pilihan (id/en), agar TalkBack membaca dengan pelafalan yang benar.

## 8. Copy

- Bahasa Indonesia sehari-hari yang hangat, kalimat pendek, kata "kamu" untuk orang dewasa, nama anak sesering mungkin di momen positif.
- Maro boleh bersemangat (tanda seru), tapi teks sistem dan error tidak.
- Angka ditulis sebagai angka ("3 misi", "15 menit"). Rentang ditulis "4 sampai 8 tahun" atau "4+ tahun", bukan tanda pisah.
- Tidak ada `·` atau `—` sebagai pemisah. Tidak ada emoji.
- Teks berbayar jujur: harga setelah uji coba, tanggal tagihan pertama, cara membatalkan (38).

## 9. Notifikasi

- Minta izin hanya di layar 28, setelah pengguna paham manfaatnya, tidak di awal aplikasi.
- Maksimal 1 push per hari, hanya jika target hari ini belum tercapai, pada jam pilihan pengguna.
- Jam tenang 20.30 sampai 07.00 (tidak ada push).
- Isi push tidak pernah membuat merasa bersalah ("Kamu mengecewakan Rafi" dilarang).
- Push tidak memuat nama lengkap anak atau foto.

## 10. Ramah anak (walaupun pengguna utamanya dewasa)

- Layar yang mungkin dilihat anak (Perayaan, Lencana baru, Level naik, Sertifikat) memakai teks besar, Maro, dan bahasa sederhana.
- Tidak ada iklan, tautan keluar, atau pembelian dari layar yang dilihat anak.
- Paket berbayar dan pengaturan hanya dari tab Profil.

## 11. Cara menguji

- [ ] Selesaikan alur utama (buka app → mulai misi → selesai → abadikan → perayaan) hanya dengan jempol kanan, HP di satu tangan.
- [ ] Ulangi dengan jempol kiri.
- [ ] Ulangi dengan VoiceOver/TalkBack: semua tombol terbaca dengan benar.
- [ ] Perbesar teks sistem ke maksimum: tidak ada teks terpotong atau tumpang tindih.
- [ ] Mode pesawat: aplikasi tidak macet, pesan offline jelas.
- [ ] Accessibility Scanner (Android) tanpa temuan kontras dan ukuran target di layar utama.
