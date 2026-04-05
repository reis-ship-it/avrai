import ws from 'k6/ws';
import { check, sleep } from 'k6';
import { Trend, Counter } from 'k6/metrics';

// Metrics
const wsConnectMs = new Trend('realtime_ws_connect_ms');
const wsPingRttMs = new Trend('realtime_ws_ping_rtt_ms');
const wsErrors = new Counter('realtime_ws_errors');

export const options = {
  vus: Number(__ENV.VUS || 1),
  iterations: Number(__ENV.ITERATIONS || 1),
  thresholds: {
    realtime_ws_connect_ms: ['p(95)<400'],
    realtime_ws_ping_rtt_ms: ['p(95)<250'],
    checks: ['rate>0.95'],
  },
};

function buildRealtimeWsUrl() {
  const base = __ENV.SUPABASE_REALTIME_URL || __ENV.SUPABASE_URL;
  if (!base) throw new Error('Set SUPABASE_REALTIME_URL or SUPABASE_URL');
  const url = base.replace(/^http/, 'ws').replace(/\/$/, '');
  const path = __ENV.REALTIME_PATH || '/realtime/v1/websocket';
  const apikey = __ENV.ANON_KEY || __ENV.SUPABASE_ANON_KEY || __ENV.SERVICE_ROLE || '';
  const qs = new URLSearchParams({ vsn: '1.0.0', apikey }).toString();
  return `${url}${path}?${qs}`;
}

export default function () {
  const fullUrl = buildRealtimeWsUrl();
  const params = { tags: { name: 'realtime' } };

  const t0 = Date.now();
  const res = ws.connect(fullUrl, params, function (socket) {
    socket.on('open', function () {
      const t1 = Date.now();
      wsConnectMs.add(t1 - t0);

      // Join a broadcast topic/channel
      const chan = `realtime:${__ENV.REALTIME_CHANNEL || 'ai2ai-network'}`;
      const ref = Math.floor(Math.random() * 100000).toString();
      socket.send(JSON.stringify({ topic: chan, event: 'phx_join', payload: {}, ref }));

      // After join ack, send a broadcast ping that should be received back by this client
      const traceId = Math.random().toString(36).slice(2);
      const sendTs = new Date().toISOString();
      const pingMsg = {
        topic: chan,
        event: 'broadcast',
        payload: { event: 'latency_ping', payload: { trace_id: traceId, send_ts: sendTs } },
        ref: (Number(ref) + 1).toString(),
      };
      // Wait briefly for join ack before ping
      setTimeout(() => socket.send(JSON.stringify(pingMsg)), 200);

      // Close after a short window
      setTimeout(() => socket.close(), Number(__ENV.DURATION_MS || 3000));
    });

    socket.on('message', function (msg) {
      try {
        const data = JSON.parse(msg);
        if (data && data.event === 'broadcast' && data.payload && data.payload.event === 'latency_ping') {
          const send = Date.parse(data.payload.payload && data.payload.payload.send_ts);
          const recv = Date.now();
          if (!isNaN(send)) wsPingRttMs.add(recv - send);
        }
      } catch (_) {}
    });

    socket.on('error', function (e) {
      wsErrors.add(1);
    });
  });

  check(res, { 'ws connected': r => r && r.status === 101 || r && r.status === 0 });

  // small sleep between iterations
  sleep(0.2);
}


