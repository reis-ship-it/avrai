# Fix: Project Not Linked Error

## 🔴 **Error**
```
Cannot find project ref. Have you run supabase link?
```

## ✅ **Solution**

You need to link your local project to your remote Supabase project.

### **Option 1: Link with Project Reference (Recommended)**

1. **Get your project reference:**
   - Go to your Supabase dashboard: https://app.supabase.com
   - Select your project
   - Go to Settings → General
   - Copy your **Project Reference** (looks like: `abcdefghijklmnop`)

2. **Link the project:**
   ```bash
   cd /Users/reisgordon/SPOTS
   supabase link --project-ref your-project-ref-here
   ```
   
   Replace `your-project-ref-here` with your actual project reference.

3. **You'll be prompted to enter:**
   - Database password (if you have one set)
   - Or just press Enter if no password

### **Option 2: Link Interactively**

```bash
cd /Users/reisgordon/SPOTS
supabase link
```

This will:
1. Ask you to log in (if not already logged in)
2. Show you a list of your projects
3. Let you select which project to link

### **Option 3: Link with Database Password**

If you have a database password set:

```bash
cd /Users/reisgordon/SPOTS
supabase link --project-ref your-project-ref --password your-db-password
```

---

## 🔍 **Find Your Project Reference**

**Method 1: From Supabase Dashboard**
1. Go to https://app.supabase.com
2. Select your project
3. Settings → General
4. Copy "Reference ID"

**Method 2: From Project URL**
Your Supabase project URL looks like:
```
https://abcdefghijklmnop.supabase.co
```
The `abcdefghijklmnop` part is your project reference.

**Method 3: From Your Code**
Check `lib/supabase_config.dart` or `.env` files for your project URL.

---

## ✅ **After Linking**

Once linked, you can deploy:

```bash
# Deploy the function
supabase functions deploy llm-chat --no-verify-jwt

# Set your API key
supabase secrets set GEMINI_API_KEY=your_api_key_here
```

---

## 🐛 **Still Having Issues?**

**If you're not logged in:**
```bash
supabase login
```

**If you need to check your link status:**
```bash
supabase status
```

**If you need to unlink and relink:**
```bash
supabase unlink
supabase link --project-ref your-project-ref
```

---

**Once linked, try deploying again!**

