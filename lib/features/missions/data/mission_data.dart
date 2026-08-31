import 'package:flutter/material.dart';

// ==============================================================
// DATA MISI LOKAL (Langkah, Tips, Bahan)
// Catatan CTO: Ke depannya, data "steps" dan "materials" ini
// juga akan ditarik langsung dari Supabase (tabel missions_master).
// ==============================================================
final Map<String, dynamic> missionData = {
  "doctor": {
    "roleName": "DOKTER KECIL",
    "missionTitle": "Kuman Takut Sabun",
    "description":
        "Menjadi dokter kecil yang mempelajari tubuh, kesehatan, dan cara menjaga diri tetap bersih.",
    "duration": "10 mnt",
    "skills": [
      {"name": "Kognitif", "icon": "🧠"},
      {"name": "Motorik", "icon": "🧩"},
      {"name": "Empati", "icon": "💗"},
    ],
    "materials": [
      "Piring putih",
      "Spidol",
      "Air",
      "Lada hitam / Bedak",
      "Sabun cuci piring",
    ],
    "bgImage": "assets/images/doctor_trans.png",
    "introImage": "assets/images/doctor_trans.png",
    "winImage": "assets/images/doctor_trans.png",
    "steps": [
      {
        "title": "Siapkan Kuman",
        "details": [
          {
            "text": "Gambar cetakan tangan pada piring putih dengan spidol.",
            "image": "assets/images/hand_plate.png",
          },
          {
            "text": "Tuangkan sedikit air ke dalam piring tersebut.",
            "image": "assets/images/pour_water.png",
          },
          {
            "text": "Taburkan lada hitam seolah menjadi kuman-kuman nakal.",
            "image": "assets/images/pepper_germs.png",
          },
        ],
        "gradient": const [Color(0xFF0A264F), Color(0xFF1e467a)],
      },
      {
        "title": "Keajaiban Sabun",
        "details": [
          {
            "text":
                "Oleskan sedikit sabun cuci piring pada ujung jari telunjuk anak.",
            "image": "assets/images/soap_finger.png",
          },
          {
            "text": "Bersiap-siap untuk melihat keajaiban yang terjadi!",
            "image": "assets/images/ready_magic.png",
          },
        ],
        "tips": [
          "Gunakan bahasa sederhana: 'Ini titik hitam namanya kuman.'",
          "Ajak menebak: 'Kalau jari kena sabun, apa yang terjadi?'",
        ],
        "gradient": const [Color(0xFFF1A22F), Color(0xFFf4b65d)],
      },
      {
        "title": "Lihat Mereka Lari!",
        "details": [
          {
            "text": "Celupkan jari ke dalam air yang berisi lada tadi.",
            "image": "assets/images/dip_finger.png",
          },
          {
            "text":
                "Amati bagaimana 'kuman' lada berlarian menjauh dari sabun!",
            "image": "assets/images/germs_run.png",
          },
        ],
        "gradient": const [Color(0xFF8bbce6), Color(0xFFA5CBEB)],
      },
    ],
  },
  "chef": {
    "roleName": "KOKI KECIL",
    "missionTitle": "Membuat Bola Biskuit",
    "description":
        "Belajar membuat makanan sederhana sambil mengenal tekstur, rasa, dan proses memasak.",
    "duration": "15 mnt",
    "skills": [
      {"name": "Kognitif", "icon": "🧠"},
      {"name": "Motorik", "icon": "🧩"},
      {"name": "Kreativitas", "icon": "🎨"},
    ],
    "materials": [
      "Biskuit kering",
      "Susu kental manis",
      "Plastik bersih",
      "Topping (meses/keju)",
    ],
    "bgImage": "assets/images/chef_trans.png",
    "introImage": "assets/images/chef_trans.png",
    "winImage": "assets/images/chef_trans.png",
    "steps": [
      {
        "title": "Hancurkan!",
        "details": [
          {
            "text": "Cuci tangan sampai bersih.",
            "image": "assets/images/wash_hands.png",
          },
          {
            "text": "Siapkan biskuit kering di dalam plastik bersih.",
            "image": "assets/images/biscuit_plastic.png",
          },
          {
            "text": "Hancurkan biskuit dengan memukul plastik hingga halus.",
            "image": "assets/images/smash_biscuit.png",
          },
        ],
        "gradient": const [Color(0xFF0A264F), Color(0xFF1e467a)],
      },
      {
        "title": "Campur dan Bentuk",
        "details": [
          {
            "text": "Tuangkan susu kental manis ke dalam remahan, aduk rata.",
            "image": "assets/images/mix_milk.png",
          },
          {
            "text":
                "Ambil sedikit adonan, kemudian bentuk bulat menggunakan tangan.",
            "image": "assets/images/shape_ball.png",
          },
        ],
        "tips": [
          "Fokus pada proses, bukan kerapihan: tekankan bahwa tidak apa-apa berantakan.",
        ],
        "gradient": const [Color(0xFFF1A22F), Color(0xFFf4b65d)],
      },
      {
        "title": "Waktunya Topping!",
        "details": [
          {
            "text":
                "Tambahkan topping apa pun yang ada di rumah (meses, keju, gula halus).",
            "image": "assets/images/topping.png",
          },
          {
            "text": "Cicipi bersama dan minta anak menjelaskan rasanya.",
            "image": "assets/images/tasting.png",
          },
        ],
        "gradient": const [Color(0xFF8bbce6), Color(0xFFA5CBEB)],
      },
    ],
  },
};
