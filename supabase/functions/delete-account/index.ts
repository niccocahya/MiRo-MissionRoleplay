import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

// Hapus akun orang tua (dan semua data anak yang menempel) atas permintaan
// sendiri -- dulu ini cuma bisa lewat email manual ke CS, padahal Privacy
// Policy udah janji ini bisa dilakukan kapan saja. Client biasa (anon/
// authenticated key) nggak boleh & nggak bisa hapus baris auth.users milik
// sendiri, jadi ini butuh service role key yang cuma ada di edge function.
//
// Urutan hapus:
// 1. Verifikasi JWT pemanggil -> tau siapa user-nya.
// 2. Hapus file-file storage milik user ini (nggak ke-cover FK cascade DB).
// 3. Hapus baris auth.users -- otomatis cascade ke parents -> children ->
//    child_stats/mission_logs/journals/dst (lihat FK ON DELETE CASCADE).
Deno.serve(async (req: Request) => {
  const corsHeaders = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  };

  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Missing authorization" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    // Client dengan JWT si pemanggil -- cuma buat identifikasi, bukan buat
    // operasi hapusnya (biar nggak bisa dipakai buat hapus akun orang lain).
    const callerClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: { user }, error: userErr } = await callerClient.auth.getUser();
    if (userErr || !user) {
      return new Response(JSON.stringify({ error: "Invalid session" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const adminClient = createClient(supabaseUrl, serviceRoleKey);

    // Bersihkan file di kedua bucket yang dipakai app ini (path-nya selalu
    // `{uid}/namafile`, lihat storage_upload_service.dart).
    for (const bucket of ["user_photo", "mission-assets"]) {
      const { data: files } = await adminClient.storage.from(bucket).list(user.id);
      if (files && files.length > 0) {
        const paths = files.map((f) => `${user.id}/${f.name}`);
        await adminClient.storage.from(bucket).remove(paths);
      }
    }

    const { error: deleteErr } = await adminClient.auth.admin.deleteUser(user.id);
    if (deleteErr) {
      return new Response(JSON.stringify({ error: deleteErr.message }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    return new Response(JSON.stringify({ success: true }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
