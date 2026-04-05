import http from 'k6/http';
import { check, sleep } from 'k6';
import { Trend, Counter } from 'k6/metrics';

// Custom metrics
const createRoomMs = new Trend('rooms_agent_create_ms');
const joinRoomMs = new Trend('rooms_agent_join_ms');
const postRoomMs = new Trend('rooms_agent_post_ms');
const httpErrors = new Counter('http_errors');

export const options = {
  vus: Number(__ENV.VUS || 1),
  iterations: Number(__ENV.ITERATIONS || 1),
  thresholds: {
    rooms_agent_create_ms: ['p(95)<400'],
    rooms_agent_join_ms: ['p(95)<400'],
    rooms_agent_post_ms: ['p(95)<400'],
    http_req_failed: ['rate<0.01'],
  },
};

function buildBase() {
  const url = __ENV.BASE || (__ENV.SUPABASE_URL ? `${__ENV.SUPABASE_URL}/functions/v1` : '');
  if (!url) {
    throw new Error('Set BASE or SUPABASE_URL env var. E.g., BASE=https://xxx.supabase.co/functions/v1');
  }
  return url.replace(/\/$/, '');
}

function authHeaders() {
  const token = __ENV.SERVICE_ROLE || __ENV.ANON_KEY || '';
  const headers = { 'Content-Type': 'application/json' };
  if (token) headers['Authorization'] = `Bearer ${token}`;
  return headers;
}

function uuid() {
  // RFC4122 v4 (simple)
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, c => {
    const r = (Math.random() * 16) | 0, v = c === 'x' ? r : (r & 0x3) | 0x8;
    return v.toString(16);
  });
}

export default function () {
  const BASE = buildBase();
  const headers = authHeaders();

  // 1) Create room
  const createPayload = JSON.stringify({
    metadata: {
      niche: __ENV.ROOM_NICHE || 'ai2ai-learning',
      topic: __ENV.ROOM_TOPIC || 'vibe-signals',
      source: 'k6',
    },
  });
  const t0 = Date.now();
  const createRes = http.post(`${BASE}/rooms-agent/create`, createPayload, { headers });
  const t1 = Date.now();
  createRoomMs.add(t1 - t0);
  const createOk = check(createRes, {
    'create status is 200': r => r.status === 200,
    'create returns room_id': r => {
      try {
        const j = r.json();
        return j && j.room_id;
      } catch (_) {
        return false;
      }
    },
  });
  if (!createOk) httpErrors.add(1);
  const roomId = (createOk && createRes.json('room_id')) || '';

  // 2) Join room
  const userId = __ENV.USER_ID || uuid();
  const joinPayload = JSON.stringify({ room_id: roomId, user_id: userId });
  const t2 = Date.now();
  const joinRes = http.post(`${BASE}/rooms-agent/join`, joinPayload, { headers });
  const t3 = Date.now();
  joinRoomMs.add(t3 - t2);
  const joinOk = check(joinRes, { 'join status is 200': r => r.status === 200 });
  if (!joinOk) httpErrors.add(1);

  // 3) Post message
  const payloadSize = Number(__ENV.PAYLOAD_BYTES || 128);
  const msg = 'x'.repeat(Math.min(payloadSize, 4096));
  const postPayload = JSON.stringify({
    room_id: roomId,
    sender_id: userId,
    payload: { msg, ts: new Date().toISOString(), trace_id: uuid() },
  });
  const t4 = Date.now();
  const postRes = http.post(`${BASE}/rooms-agent/post`, postPayload, { headers });
  const t5 = Date.now();
  postRoomMs.add(t5 - t4);
  const postOk = check(postRes, { 'post status is 200': r => r.status === 200 });
  if (!postOk) httpErrors.add(1);

  // Small pause between iterations if any
  sleep(Number(__ENV.SLEEP || 0.2));
}


