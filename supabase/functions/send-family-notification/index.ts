// send-family-notification (spec section 48)
//
// Called by the app right after a report is created (spec section 11 step
// 6). Looks up the report/button/reporter/family, then pushes an APNs
// alert to every OTHER family member's registered devices.
//
// Flow (spec section 48):
//   1. report取得
//   2. button取得
//   3. reporter profile取得
//   4. family_members取得
//   5. device_tokens取得
//   6. 報告者本人を除外
//   7. APNsへ通知送信
//
// Required environment variables (Edge Function secrets — see spec
// section 49: never put these in the iOS app):
//   SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, SUPABASE_ANON_KEY — the first
//     two are auto-injected by Supabase; ANON_KEY needs to be set manually
//     since Edge Functions don't get it for free.
//   APNS_TEAM_ID        — Apple Developer Team ID.
//   APNS_KEY_ID         — Key ID of the APNs Auth Key (.p8).
//   APNS_PRIVATE_KEY    — The .p8 file's contents (PEM, including the
//                         BEGIN/END PRIVATE KEY lines).
//   APNS_BUNDLE_ID      — The app's bundle identifier (com.yumita.familytap).
//   APNS_HOST           — Optional. Defaults to production
//                         (api.push.apple.com); set to
//                         api.sandbox.push.apple.com for local/TestFlight
//                         builds signed with a development provisioning
//                         profile.
//
// NOT independently tested end-to-end in this environment — that needs a
// real Apple Developer Program membership, an APNs Auth Key, and a
// physical device (see PROGRESS.md, Phase 13).

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

interface RequestBody {
  reportId: string;
}

Deno.serve(async (req: Request) => {
  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return json({ error: "missing authorization" }, 401);
    }

    const { reportId } = (await req.json()) as RequestBody;
    if (!reportId) {
      return json({ error: "reportId is required" }, 400);
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    // Verify the caller can actually see this report (i.e. is a member of
    // its family) using their own JWT — RLS (reports_select_member) does
    // the real access check here. Without this, anyone with an account
    // could pass an arbitrary reportId and spam a family they're not in.
    const supabaseAsCaller = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: visibleReport } = await supabaseAsCaller
      .from("reports")
      .select("id")
      .eq("id", reportId)
      .maybeSingle();

    if (!visibleReport) {
      return json({ error: "not found or not authorized" }, 403);
    }

    // From here on, use the service role to read across the whole family
    // (other members' device tokens aren't visible to the caller under
    // RLS, and rightly so for normal client requests).
    const supabaseAdmin = createClient(supabaseUrl, serviceRoleKey);

    // 1. report取得
    const { data: report, error: reportError } = await supabaseAdmin
      .from("reports")
      .select("id, family_id, button_id, user_id")
      .eq("id", reportId)
      .single();
    if (reportError || !report) {
      return json({ error: "report not found" }, 404);
    }

    // 2. button取得
    const { data: button } = await supabaseAdmin
      .from("report_buttons")
      .select("label, icon")
      .eq("id", report.button_id)
      .single();

    // 3. reporter profile取得
    const { data: reporterProfile } = await supabaseAdmin
      .from("profiles")
      .select("display_name")
      .eq("id", report.user_id)
      .single();

    // 4. family_members取得（6. 報告者本人を除外、をここで一緒に行う）
    const { data: members } = await supabaseAdmin
      .from("family_members")
      .select("user_id")
      .eq("family_id", report.family_id)
      .neq("user_id", report.user_id);

    const recipientIds = (members ?? []).map((m: { user_id: string }) => m.user_id);
    if (recipientIds.length === 0) {
      return json({ message: "no recipients" }, 200);
    }

    // 5. device_tokens取得
    const { data: tokens } = await supabaseAdmin
      .from("device_tokens")
      .select("token")
      .in("user_id", recipientIds)
      .eq("platform", "ios");

    if (!tokens || tokens.length === 0) {
      return json({ message: "no device tokens" }, 200);
    }

    const reporterName = reporterProfile?.display_name ?? "家族";
    const buttonLabel = button?.label ?? "報告";
    const icon = button?.icon ? ` ${button.icon}` : "";

    // 7. APNsへ通知送信
    const results = await Promise.allSettled(
      tokens.map((t: { token: string }) =>
        sendApnsPush({
          deviceToken: t.token,
          title: "Family Tap",
          body: `${reporterName}が「${buttonLabel}」と報告しました${icon}`,
        })
      ),
    );

    const sent = results.filter((r) => r.status === "fulfilled").length;
    const failed = results.length - sent;
    if (failed > 0) {
      console.error(
        `send-family-notification: ${failed}/${results.length} APNs pushes failed`,
        results.filter((r) => r.status === "rejected"),
      );
    }

    return json({ sent, total: tokens.length }, 200);
  } catch (error) {
    console.error("send-family-notification error:", error);
    return json({ error: String(error) }, 500);
  }
});

function json(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json" },
  });
}

// ---------------------------------------------------------------------
// APNs (HTTP/2 provider API, token-based auth — see Apple's docs at
// developer.apple.com/documentation/usernotifications/sending-notification-requests-to-apns).
// Implemented directly against `fetch`/`crypto.subtle` rather than a
// third-party library, to keep this function's dependencies minimal.
// ---------------------------------------------------------------------

async function sendApnsPush(
  { deviceToken, title, body }: { deviceToken: string; title: string; body: string },
): Promise<void> {
  const teamId = Deno.env.get("APNS_TEAM_ID")!;
  const keyId = Deno.env.get("APNS_KEY_ID")!;
  const privateKey = Deno.env.get("APNS_PRIVATE_KEY")!;
  const bundleId = Deno.env.get("APNS_BUNDLE_ID")!;
  const apnsHost = Deno.env.get("APNS_HOST") ?? "https://api.push.apple.com";

  const jwt = await createApnsJwt(teamId, keyId, privateKey);

  const payload = {
    aps: {
      alert: { title, body },
      sound: "default",
    },
  };

  const response = await fetch(`${apnsHost}/3/device/${deviceToken}`, {
    method: "POST",
    headers: {
      authorization: `bearer ${jwt}`,
      "apns-topic": bundleId,
      "apns-push-type": "alert",
      "content-type": "application/json",
    },
    body: JSON.stringify(payload),
  });

  if (!response.ok) {
    const text = await response.text();
    throw new Error(`APNs error ${response.status}: ${text}`);
  }
}

async function createApnsJwt(teamId: string, keyId: string, privateKeyPem: string): Promise<string> {
  const header = { alg: "ES256", kid: keyId };
  const payload = { iss: teamId, iat: Math.floor(Date.now() / 1000) };

  const headerB64 = base64url(JSON.stringify(header));
  const payloadB64 = base64url(JSON.stringify(payload));
  const signingInput = `${headerB64}.${payloadB64}`;

  const key = await importApnsPrivateKey(privateKeyPem);
  const signature = await crypto.subtle.sign(
    { name: "ECDSA", hash: "SHA-256" },
    key,
    new TextEncoder().encode(signingInput),
  );

  return `${signingInput}.${base64url(new Uint8Array(signature))}`;
}

function importApnsPrivateKey(pem: string): Promise<CryptoKey> {
  const pemBody = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\s+/g, "");
  const binary = Uint8Array.from(atob(pemBody), (c) => c.charCodeAt(0));

  return crypto.subtle.importKey(
    "pkcs8",
    binary,
    { name: "ECDSA", namedCurve: "P-256" },
    false,
    ["sign"],
  );
}

function base64url(input: Uint8Array | string): string {
  const bytes = typeof input === "string" ? new TextEncoder().encode(input) : input;
  let binary = "";
  for (const byte of bytes) {
    binary += String.fromCharCode(byte);
  }
  return btoa(binary)
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");
}
