Deployment notes

Set the following secrets for both functions:

- SUPABASE_URL
- SUPABASE_SERVICE_ROLE_KEY
- SERVICE_CALL_SECRET

Deploy:

```
supabase functions deploy coordinator --no-verify-jwt
supabase functions deploy rooms-agent --no-verify-jwt
```

Call (backend-only) with header `x-service-key: $SERVICE_CALL_SECRET`.

Endpoints:

- coordinator
  - GET /
  - POST /profile-summary { recipient_id, summary }
  - POST /dm { recipient_id, payload }
- rooms-agent
  - GET /
  - POST /create { metadata }
  - POST /join { room_id, user_id }
  - POST /post { room_id, sender_id, payload }


