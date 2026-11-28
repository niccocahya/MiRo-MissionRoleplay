# Standar Responsif

Desain dibuat di 390×844, tetapi MiRO dipakai di HP dari yang sempit dan pendek sampai yang lebar dan panjang, dengan teks sistem yang sering diperbesar. Standar ini memastikan setiap layar tetap utuh dan bisa dipakai di semua ukuran itu.

Berlaku mulai Fase 1. Layar dari fase sebelumnya diperbaiki di Fase 9.

## 1. Matriks ukuran wajib

| Lebar | Tinggi | Keterangan |
|---|---|---|
| 320 | 640 | HP sempit dan pendek (batas bawah) |
| 360 | 640 | Android kelas bawah |
| **390** | **844** | **Layar dasar desain** |
| 412 | 915 | Android umum |
| 430 | 932 | HP lebar dan panjang |

Tinggi pendek yang diuji: **640**. Tinggi panjang yang diuji: **932**.

## 2. Prinsip tata letak

- **Jangan menskalakan seluruh UI.** Dilarang memakai `flutter_screenutil` atau paket sejenis yang mengalikan semua ukuran dengan rasio layar. Ukuran dari mockup dipakai apa adanya (1 px = 1 logical pixel).
- Pakai tata letak fleksibel: `Expanded`/`Flexible`, `Wrap`, dan `LayoutBuilder` untuk keputusan berdasarkan ruang yang tersedia.
- **Padding samping** 20 (`MiroSpace.x5`); di lebar **< 360** menjadi 16 (`MiroSpace.x4`).
- **Grid 3 kolom** (peserta, lencana, kolase) menjadi **2 kolom** di lebar **< 340**.
- **Tab peran** bisa digeser horizontal; tidak pernah dipaksa muat dengan mengecilkan isi.

## 3. Layar pendek (tinggi < 700)

- Konten utama bisa di-scroll; `MiroStickyFooter` tetap terlihat di bawah.
- Gambar maskot dan ilustrasi dibatasi maksimal **±22% tinggi layar** lewat `LayoutBuilder`.
- Layar perayaan (05, 21, 31, 45) mengecilkan visual, **bukan** memotong teks atau tombol.

## 4. Ukuran teks

- Layout wajib **rapi sampai 1.3×** (pengaturan ukuran teks di app).
- Layout wajib **tetap bisa dipakai sampai 2.0×** (teks sistem): teks membungkus dan layar bisa di-scroll, tidak ada yang terpotong.
- Angka besar (streak, level, odometer) boleh dibatasi dengan `MediaQuery.withClampedTextScaling(maxScaleFactor: 1.5)`.
- **Teks isi tidak boleh di-clamp.**

## 5. Safe area

App memakai mode edge-to-edge (`main.dart`), jadi konten bisa tergambar di balik status bar dan gesture bar.

- Semua layar memakai `SafeArea` atau padding dari `MediaQuery` (notch, Dynamic Island, gesture bar).
- Bottom nav dan footer menambah padding bawah sistem (`MediaQuery.paddingOf(context).bottom`).

## 6. Keyboard

- Layar form memakai `SingleChildScrollView` dan footer yang naik di atas keyboard (`MediaQuery.viewInsetsOf(context)`).
- Field yang sedang aktif tidak boleh tertutup keyboard.

## 7. Bottom sheet

Tinggi maksimal **90% layar**; isinya bisa di-scroll.

## 8. Orientasi dan tablet

- HP dikunci **portrait**.
- Tablet (lebar **≥ 600**): konten dibatasi lebar maksimal **480** dan diletakkan di tengah.

## 9. Gambar

Pakai `AspectRatio`, atau ukuran tetap + `BoxFit.contain`. Gambar tidak pernah melar.

## 10. Tes

- **Golden setiap layar di 3 ukuran** (360×640, 390×844, 430×932), ditambah **390×844 dengan teks 1.3×**.
- Di semua widget test dan golden, **error overflow (`RenderFlex overflowed`) membuat tes GAGAL**. Helper test memasang `FlutterError.onError` untuk ini (`test/helpers/golden.dart`).
