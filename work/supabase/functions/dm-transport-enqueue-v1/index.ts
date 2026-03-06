import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

type EnqueueBody = {
  message_id?: string;
  from_user_id?: string;
  to_user_id?: string;
  sender_agent_id?: string;
  recipient_agent_id?: string;
  encryption_type?: string;
  ciphertext_base64?: string;
  sent_at?: string;
  recipient_device_id?: string;
};

// Canonical API endpoint; storage writes use base tables for deterministic
// insert/update semantics across PostgREST schema-cache refresh windows.
const DM_BLOBS_BASE_TABLE = 'dm_message_blobs';
const DM_NOTIFICATIONS_BASE_TABLE = 'dm_notifications';

function adminClient() {
  const url = Deno.env.get('SUPABASE_URL');
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (!url || !serviceKey) {
    throw new Error('Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY');
  }
  return createClient(url, serviceKey, {
    auth: { persistSession: false },
    db: { schema: 'public' },
  });
}

serve(async (req) => {
  if (req.method !== 'POST') {
    return Response.json({ ok: false, error: 'Method not allowed' }, { status: 405 });
  }

  try {
    const authHeader = req.headers.get('Authorization') ?? '';
    const token = authHeader.startsWith('Bearer ')
      ? authHeader.slice('Bearer '.length).trim()
      : '';
    if (!token) {
      return Response.json({ ok: false, error: 'Missing bearer token' }, { status: 401 });
    }

    const body = (await req.json()) as EnqueueBody;
    const messageId = body.message_id?.trim() ?? '';
    const fromUserId = body.from_user_id?.trim() ?? '';
    const toUserId = body.to_user_id?.trim() ?? '';
    const senderAgentId = body.sender_agent_id?.trim() ?? '';
    const recipientAgentId = body.recipient_agent_id?.trim() ?? '';
    const encryptionType = body.encryption_type?.trim() ?? '';
    const ciphertextBase64 = body.ciphertext_base64?.trim() ?? '';
    const sentAt = body.sent_at?.trim() ?? new Date().toISOString();
    const recipientDeviceId = body.recipient_device_id?.trim() || 'legacy';

    if (
      !messageId ||
      !fromUserId ||
      !toUserId ||
      !senderAgentId ||
      !recipientAgentId ||
      !encryptionType ||
      !ciphertextBase64
    ) {
      return Response.json({ ok: false, error: 'Missing required fields' }, { status: 400 });
    }

    const admin = adminClient();
    const { data: userData, error: userErr } = await admin.auth.getUser(token);
    if (userErr || !userData.user) {
      return Response.json({ ok: false, error: 'Unauthorized' }, { status: 401 });
    }
    if (userData.user.id !== fromUserId) {
      return Response.json({ ok: false, error: 'Sender mismatch' }, { status: 403 });
    }

    // Prefer the recipient_device_id-aware insert path.
    const withDevice = await admin.from(DM_BLOBS_BASE_TABLE).insert({
      message_id: messageId,
      from_user_id: fromUserId,
      to_user_id: toUserId,
      sender_agent_id: senderAgentId,
      recipient_agent_id: recipientAgentId,
      encryption_type: encryptionType,
      ciphertext_base64: ciphertextBase64,
      sent_at: sentAt,
      recipient_device_id: recipientDeviceId,
    });
    if (withDevice.error) {
      const errorMessage = withDevice.error.message;
      if (errorMessage && errorMessage.toLowerCase().includes('recipient_device_id')) {
        // Compatibility path for environments where the column has not landed yet.
        const legacyShape = await admin.from(DM_BLOBS_BASE_TABLE).insert({
          message_id: messageId,
          from_user_id: fromUserId,
          to_user_id: toUserId,
          sender_agent_id: senderAgentId,
          recipient_agent_id: recipientAgentId,
          encryption_type: encryptionType,
          ciphertext_base64: ciphertextBase64,
          sent_at: sentAt,
        });
        if (legacyShape.error) {
          return Response.json(
            { ok: false, error: `Blob insert failed: ${legacyShape.error.message}` },
            { status: 400 },
          );
        }
      } else {
        return Response.json(
          { ok: false, error: `Blob insert failed: ${withDevice.error.message}` },
          { status: 400 },
        );
      }
    }

    const notify = await admin.from(DM_NOTIFICATIONS_BASE_TABLE).insert({
      to_user_id: toUserId,
      message_id: messageId,
    });
    if (notify.error) {
      // Best effort cleanup to avoid orphan blobs.
      await admin.from(DM_BLOBS_BASE_TABLE).delete().eq('message_id', messageId);
      return Response.json(
        { ok: false, error: `Notification insert failed: ${notify.error.message}` },
        { status: 400 },
      );
    }

    return Response.json({ ok: true, message_id: messageId }, { status: 200 });
  } catch (e) {
    return Response.json(
      { ok: false, error: e instanceof Error ? e.message : String(e) },
      { status: 500 },
    );
  }
});
