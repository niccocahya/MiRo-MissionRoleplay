// Proxy panggilan chat Mink ke Groq, supaya kunci API-nya TIDAK ikut
// terbungkus di aplikasi.
//
// Kenapa fungsi ini ada
// ---------------------
// Sebelumnya klien Flutter memanggil api.groq.com langsung, dengan kunci
// dari `String.fromEnvironment('GROQ_API_KEY')`. Nilai itu disisipkan ke
// hasil build, bukan dibaca saat runtime -- jadi:
//   * di build WEB, kuncinya ada di dalam bundel JavaScript dan bisa
//     dibaca siapa pun lewat DevTools;
//   * di Android/iOS bisa diekstrak dari APK/IPA.
// Siapa pun yang mengambilnya bisa memakai kuota Groq atas tagihan
// pemilik akun.
//
// Memindahkan kunci dari hardcode ke --dart-define dulu cuma menutup
// kebocoran di source code, bukan di hasil build. Yang benar adalah
// kuncinya nggak pernah sampai ke perangkat sama sekali -- itu yang
// dikerjakan file ini.
//
// Catatan: SUPABASE_ANON_KEY di klien beda urusan dan memang aman -- itu
// kunci publik, dan RLS yang jaga datanya.
//
// Cara deploy
// -----------
//   1. Simpan kuncinya sebagai secret (JANGAN di env.json app):
//        supabase secrets set GROQ_API_KEY=gsk_xxx
//   2. Deploy:
//        supabase functions deploy mink-chat
//   3. Cabut kunci lama di console.groq.com/keys kalau kunci yang sama
//      pernah ikut ke build yang sudah tersebar, lalu terbitkan yang
//      baru untuk langkah 1.
//
// JWT-nya diverifikasi Supabase secara default (jangan pakai
// --no-verify-jwt), jadi cuma orang tua yang sudah login yang bisa
// memanggil ini.

import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const GROQ_ENDPOINT = "https://api.groq.com/openai/v1/chat/completions";

// Dikunci di server, bukan diterima dari klien -- kalau model dan batas
// token boleh ditentukan pemanggil, fungsi ini berubah jadi proxy LLM
// serba bisa atas tagihan kita.
const MODEL = "llama-3.1-8b-instant";
const MAX_TOKENS = 1024;
const TEMPERATURE = 0.7;

// Pagar ukuran. Pengguna sudah terautentikasi, tapi akun yang sah pun
// bisa dipakai berlebihan -- entah sengaja atau karena bug di klien yang
// mengirim histori tanpa henti.
const MAX_MESSAGES = 40;
const MAX_TOTAL_CHARS = 24000;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

Deno.serve(async (req) => {
  // App ini juga jalan di browser (build web), jadi preflight-nya wajib
  // dilayani -- tanpa ini panggilannya diblokir CORS sebelum sempat
  // sampai ke logika di bawah.
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  const apiKey = Deno.env.get("GROQ_API_KEY");
  if (!apiKey) {
    console.error("GROQ_API_KEY belum di-set. Jalankan: supabase secrets set GROQ_API_KEY=...");
    return json({ error: "Server belum dikonfigurasi" }, 500);
  }

  let payload: { chatHistory?: unknown; systemPrompt?: unknown };
  try {
    payload = await req.json();
  } catch {
    return json({ error: "Body bukan JSON yang valid" }, 400);
  }

  const systemPrompt = payload.systemPrompt;
  const chatHistory = payload.chatHistory;

  if (typeof systemPrompt !== "string" || systemPrompt.length === 0) {
    return json({ error: "systemPrompt wajib diisi" }, 400);
  }
  if (!Array.isArray(chatHistory)) {
    return json({ error: "chatHistory harus berupa array" }, 400);
  }
  if (chatHistory.length > MAX_MESSAGES) {
    return json({ error: "Percakapannya kepanjangan" }, 413);
  }

  // Cuma ambil bentuk yang kita harapkan. Tanpa ini, field asing dari
  // klien ikut diteruskan mentah-mentah ke Groq.
  const messages: { role: string; content: string }[] = [
    { role: "system", content: systemPrompt },
  ];
  for (const m of chatHistory) {
    if (typeof m !== "object" || m === null) continue;
    const role = (m as Record<string, unknown>).role;
    const content = (m as Record<string, unknown>).content;
    if (role !== "user" && role !== "assistant") continue;
    if (typeof content !== "string") continue;
    messages.push({ role, content });
  }

  const totalChars = messages.reduce((n, m) => n + m.content.length, 0);
  if (totalChars > MAX_TOTAL_CHARS) {
    return json({ error: "Percakapannya kepanjangan" }, 413);
  }

  try {
    const groqRes = await fetch(GROQ_ENDPOINT, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: MODEL,
        messages,
        temperature: TEMPERATURE,
        max_tokens: MAX_TOKENS,
      }),
    });

    if (!groqRes.ok) {
      // Isi error dari Groq sengaja NGGAK diteruskan ke klien -- itu bisa
      // memuat detail akun/kuota. Cukup dicatat di log server.
      console.error(`Groq error ${groqRes.status}: ${await groqRes.text()}`);
      return json({ error: "upstream" }, 502);
    }

    const data = await groqRes.json();
    const reply = data?.choices?.[0]?.message?.content;
    if (typeof reply !== "string") {
      console.error("Bentuk balasan Groq nggak seperti yang diharapkan");
      return json({ error: "upstream" }, 502);
    }

    return json({ reply });
  } catch (e) {
    console.error("Gagal menghubungi Groq:", e);
    return json({ error: "upstream" }, 502);
  }
});
