// Supabase Edge Function: delete-account
// Deletes the calling user's identity from auth.users using the service_role key.
// The service_role key is NEVER shipped in the client app and NEVER committed to repo.
// It is read securely from the function environment secrets.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

serve(async (req: Request) => {
  // Handle CORS preflight requests
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // 1. Verify Authorization header is present
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Missing Authorization header" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 2. Load environment variables
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY");
    // In Supabase Edge Functions, SUPABASE_SERVICE_ROLE_KEY is injected automatically
    // or set via `supabase secrets set SUPABASE_SERVICE_ROLE_KEY=...`
    const supabaseServiceRoleKey =
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? Deno.env.get("SERVICE_ROLE_KEY");

    if (!supabaseUrl || !supabaseServiceRoleKey) {
      return new Response(
        JSON.stringify({
          error: "Edge Function configuration missing: SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY secret is not set.",
        }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 3. Authenticate the caller using their JWT
    const userClient = createClient(
      supabaseUrl,
      supabaseAnonKey ?? supabaseServiceRoleKey,
      {
        global: { headers: { Authorization: authHeader } },
        auth: { persistSession: false },
      }
    );

    const {
      data: { user },
      error: userError,
    } = await userClient.auth.getUser();

    if (userError || !user) {
      return new Response(
        JSON.stringify({
          error: "Unauthorized: Invalid, expired, or missing user token",
          details: userError?.message,
        }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 4. Verify caller authorization: if userId is explicitly supplied, it must match auth.uid
    let targetUserId = user.id;
    try {
      const body = await req.json();
      if (body && body.userId && body.userId !== user.id) {
        return new Response(
          JSON.stringify({
            error: "Forbidden: You are only permitted to delete your own account.",
          }),
          { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }
    } catch (_) {
      // Body may be empty or non-JSON; default to verified user.id
    }

    // 5. Delete identity from auth.users using service_role admin client
    const adminClient = createClient(supabaseUrl, supabaseServiceRoleKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    });

    const { error: deleteError } = await adminClient.auth.admin.deleteUser(targetUserId);

    if (deleteError) {
      return new Response(
        JSON.stringify({
          error: "Failed to delete user identity from auth.users",
          details: deleteError.message,
        }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    return new Response(
      JSON.stringify({
        message: "User identity deleted successfully from auth.users",
        userId: targetUserId,
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err: any) {
    return new Response(
      JSON.stringify({
        error: "Internal Server Error in delete-account function",
        details: err?.message ?? String(err),
      }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
