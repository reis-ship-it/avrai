# Set Your Gemini API Key

## ✅ Function Deployed!

Your LLM function is now deployed to:
- Project: `nfzlwgbvezwwrutqpedy`
- Function: `llm-chat`
- Dashboard: https://supabase.com/dashboard/project/nfzlwgbvezwwrutqpedy/functions

---

## 🔑 Next Step: Set Your Gemini API Key

### **1. Get Your API Key**

If you haven't already:
1. Go to: https://makersuite.google.com/app/apikey
2. Click "Create API Key"
3. Copy your key (starts with `AIza...`)

### **2. Set the Secret**

Run this command (replace with your actual key):

```bash
supabase secrets set GEMINI_API_KEY=your_api_key_here
```

**Example:**
```bash
supabase secrets set GEMINI_API_KEY=AIzaSyAbCdEfGhIjKlMnOpQrStUvWxYz1234567
```

### **3. Verify It's Set**

```bash
supabase secrets list
```

You should see `GEMINI_API_KEY` in the list.

---

## 🧪 Test It

Once the key is set, test the function:

```bash
# Get your anon key from Supabase dashboard
curl -X POST https://nfzlwgbvezwwrutqpedy.supabase.co/functions/v1/llm-chat \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [
      {"role": "user", "content": "Hello! Can you help me find coffee shops?"}
    ]
  }'
```

---

## ✅ You're Almost Done!

After setting the API key, your LLM integration will be fully functional! 🎉

