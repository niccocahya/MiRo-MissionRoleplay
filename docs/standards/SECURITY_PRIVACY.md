# Standar Keamanan dan Privasi

MiRO menyimpan data tentang **anak**: nama panggilan, usia, foto, dan perkembangan. (Rekaman suara tidak ada di v2.) Ini kategori data paling sensitif yang bisa dimiliki aplikasi konsumen. Standar di sini lebih ketat dari aplikasi biasa, dan setiap pengecualian harus ditulis alasannya.

> Catatan hukum: di Indonesia berlaku UU No. 27 Tahun 2022 tentang Pelindungan Data Pribadi (UU PDP). Data anak termasuk data pribadi yang bersifat spesifik, dan pemrosesannya membutuhkan persetujuan orang tua atau wali. Dokumen ini adalah standar teknis, bukan nasihat hukum. Minta orang yang paham hukum memeriksa kebijakan privasi sebelum rilis publik.

## 1. Prinsip

1. **Minimal.** Kumpulkan hanya yang dipakai fitur. Anak: nama panggilan, usia, avatar, kesukaan. Tidak ada nama lengkap, tanggal lahir, sekolah, atau lokasi.
2. **Guru tidak menyimpan data siswa.** Hanya jumlah dan agregat kelas. Statistik baru muncul setelah ≥ 3 sesi (layar 53) supaya angka tidak bisa menunjuk satu anak.
3. **Privat secara default.** Semua foto dan data anak hanya bisa dilihat oleh akun keluarga (pemilik + pendamping) atau akun guru pemilik kelas.
4. **Persetujuan tercatat.** Persetujuan orang tua disimpan dengan waktu dan versi kebijakan (ditampilkan di layar 42).
5. **Bisa dihapus.** Pengguna bisa mengunduh dan menghapus semua data sendiri, tanpa menghubungi admin.

## 2. Autentikasi (Supabase Auth)

- Email + kata sandi dan Google OAuth.
- Kata sandi minimal 8 karakter, ditolak jika ada di daftar kata sandi bocor (aktifkan "Leaked password protection" Supabase).
- Rate limit login dan reset (bawaan Supabase, jangan dimatikan).
- Pesan login gagal dan lupa sandi tidak membedakan "email tidak terdaftar" dan "sandi salah".
- Sesi dikelola `supabase_flutter` (penyimpanan sesi bawaan). Jangan menyalin token ke `shared_preferences` atau log.
- Ganti email dan hapus akun membutuhkan login ulang dalam 10 menit terakhir.

## 3. Otorisasi: Row Level Security

**RLS wajib aktif di semua tabel**, tanpa pengecualian. Pola dasar:

```sql
-- Anggota keluarga/akun. Di MiRO, "akun" = tabel parents (DECISIONS §H9).
create table account_members (
  account_id uuid references parents(id) on delete cascade,
  user_id uuid references auth.users(id) on delete cascade,
  role text check (role in ('owner','companion')),
  primary key (account_id, user_id)
);

create function is_member(acc uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from account_members
                 where account_id = acc and user_id = auth.uid());
$$;

alter table children enable row level security;
create policy "anggota bisa membaca anak" on children
  for select using (is_member(account_id));
create policy "anggota bisa menulis anak" on children
  for insert with check (is_member(account_id));
create policy "anggota bisa mengubah anak" on children
  for update using (is_member(account_id)) with check (is_member(account_id));
create policy "hanya pemilik bisa menghapus anak" on children
  for delete using (exists (select 1 from account_members
    where account_id = children.account_id and user_id = auth.uid() and role = 'owner'));
```

Aturan:
- Setiap tabel punya kebijakan `select`, `insert`, `update`, `delete` yang eksplisit. Tidak ada `using (true)`.
- Perhitungan XP, level, lencana, dan streak dilakukan di **RPC database** (`complete_mission_run`) dengan `security definer`, bukan dari klien. Klien tidak boleh bisa menulis `xp_events` langsung.
- Ikan dan pembeku streak dikurangi di RPC dengan pengecekan saldo dalam transaksi.
- Service role key dan kunci pihak ketiga (Groq) **hanya** di Supabase secrets dan dipakai di Edge Function. Aplikasi hanya membawa `SUPABASE_URL` dan anon key (lewat `--dart-define-from-file`).
- Uji RLS: tes otomatis yang login sebagai akun A dan memastikan tidak bisa membaca atau mengubah data akun B.
- **Perubahan RLS pada tabel lama dibuat aditif** (DECISIONS §H9): kebijakan baru ditambahkan di samping yang lama, dan kebijakan lama dicabut hanya setelah tes lintas akun lulus di project staging `miro-staging`.

## 4. Foto

- Bucket Storage **privat**. Akses lewat signed URL berumur pendek (≤ 1 jam), dibuat di server setelah cek keanggotaan.
- Path file tidak memuat nama anak: `memories/{account_id}/{uuid}.jpg`.
- Sebelum unggah, di perangkat:
  - kompres ke sisi terpanjang 1600px, JPEG kualitas 0,8;
  - **hapus metadata EXIF** (lokasi GPS, model HP) dengan `flutter_image_compress` (`keepExif: false`);
  - batas 15 MB sebelum kompres, tolak format selain JPEG/PNG/HEIC/WebP.
- **Akun Guru:** buram wajah otomatis aktif default (layar 51), diproses di perangkat sebelum unggah. Foto tidak bisa diberi nama murid. Tampilkan peringatan izin sekolah.
- Mematikan "Simpan foto momen" di Privasi menyembunyikan langkah Abadikan dan tidak mengunggah apa pun.
- Kolase dan sertifikat yang "dibagikan" dibuat sebagai gambar di perangkat dan dibagikan lewat share sheet OS. Tidak ada tautan publik ke foto anak.

## 5. Undangan pendamping dan kode kelas

- Kode 6 karakter dari alfabet tanpa karakter mirip (tanpa O/0, I/1), dibuat di server dengan generator acak kriptografis.
- Berlaku 48 jam, sekali pakai, bisa dicabut.
- Percobaan kode salah dibatasi (mis. 5 kali per 15 menit per pengguna).
- Pendamping tidak bisa menghapus anak, akun, atau mengubah paket.

## 6. Validasi input dan keamanan web

- Validasi input di aplikasi (untuk UX, `input_limits.dart`) **dan** di database lewat `CHECK` constraint atau RPC (untuk keamanan). Batas panjang: nama panggilan 20, catatan refleksi 280, nama kelas 30.
- Konten pengguna selalu dirender sebagai teks biasa (tidak ada HTML/markdown dari pengguna).
- Android: `android:allowBackup="false"` atau aturan backup yang mengecualikan cache foto; `usesCleartextTraffic` mati. iOS: hanya izin yang dipakai (kamera, galeri) dengan teks alasan dalam Bahasa Indonesia.
- Build rilis memakai `--obfuscate --split-debug-info`.
- (Bagian di bawah berlaku hanya jika nanti ada versi web.) Header keamanan:
  - `Content-Security-Policy` (default-src 'self'; img-src 'self' blob: data: domain Storage; connect-src 'self' domain Supabase)
  - `Strict-Transport-Security`, `X-Content-Type-Options: nosniff`, `Referrer-Policy: strict-origin-when-cross-origin`, `Permissions-Policy` (kamera hanya self, tanpa geolokasi)
- Edge Function dan RPC selalu memeriksa `auth.uid()` dan keanggotaan, tidak percaya `account_id`/`child_id` dari aplikasi.
- Tidak ada ID berurutan di URL. Pakai UUID.

## 7. Log, analytics, dan error

- Tidak ada data anak (nama, foto, catatan) di log, analytics, pesan error, atau URL.
- Analytics hanya event agregat (mis. `mission_completed` dengan `role` dan `duration`), tanpa ID anak. Tidak ada SDK iklan.
- Error reporting (jika dipakai) dengan scrubbing field `nickname`, `note`, `email`.

## 8. Pembayaran

- Memakai Google Play Billing / App Store (langganan dalam aplikasi), diverifikasi di server lewat Edge Function. MiRO tidak pernah menyimpan nomor kartu atau rekening.
- Status langganan hanya diubah oleh webhook penyedia yang diverifikasi tanda tangannya, bukan oleh klien.
- Uji coba 7 hari: kirim pengingat H-2 (sesuai layar 38), batalkan dengan satu ketukan dari Pengaturan.

## 9. Penghapusan dan ekspor data

- **Hapus anak** (40): menghapus profil, event, peserta run, dan semua foto yang hanya berisi anak itu. Foto bersama anak lain tetap ada untuk anak lain. Proses permanen, termasuk file di Storage, dalam 30 hari dari cadangan.
- **Hapus akun keluarga** (42): menghapus semua di atas untuk semua anak + akun. Konfirmasi ulang dengan login.
- **Unduh semua data** (42): ZIP berisi JSON progres + foto, dibuat di server, tautan berlaku 24 jam.

## 10. Dependensi dan rilis

- `flutter pub outdated` dan advisori paket dicek sebelum rilis; tidak ada paket dengan kerentanan yang diketahui.
- Kunci versi dengan `pubspec.lock`; perbarui dependensi lewat PR terpisah.
- Jangan commit `env.json` (hanya `env.example.json`). Aktifkan secret scanning GitHub.

## 11. Checklist sebelum rilis

- [ ] RLS aktif di semua tabel dan tes lintas-akun lulus
- [ ] Bucket Storage privat, signed URL ≤ 1 jam
- [ ] EXIF terhapus (cek file hasil unggah)
- [ ] Buram wajah aktif default untuk Guru
- [ ] Tidak ada data anak di log dan analytics (cari `nickname` di log)
- [ ] APK rilis diperiksa: tidak ada kunci rahasia di dalamnya (cari string `gsk_`, `service_role`)
- [ ] Alur hapus anak, hapus akun, dan unduh data diuji ujung ke ujung
- [ ] Kebijakan privasi versi singkat untuk orang tua tersedia dan diperiksa
