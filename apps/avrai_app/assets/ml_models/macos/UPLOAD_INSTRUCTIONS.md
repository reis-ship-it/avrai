# Upload CoreML Model to Supabase

## File Details
- **File:** `llama-3.1-8b-instruct-coreml.zip`
- **Size:** 3.7 GB (3,936,400,726 bytes)
- **SHA-256:** `843c1773f2335dbd1ede45fb21684499641648b7e04c3a76989d9eb0a54672f8`

---

## Step 1: Ensure Bucket Exists

1. Go to: https://supabase.com/dashboard/project/nfzlwgbvezwwrutqpedy/storage/buckets
2. Check if `local-llm-models` bucket exists
3. **If it doesn't exist:**
   - Go to **SQL Editor**: https://supabase.com/dashboard/project/nfzlwgbvezwwrutqpedy/editor
   - Run the SQL from: `supabase/migrations/064_local_llm_models_bucket_v1.sql`
   - Or click **New Bucket** → Name: `local-llm-models` → Public: **Yes**

---

## Step 2: Upload via Dashboard

1. **Open the bucket:**
   ```
   https://supabase.com/dashboard/project/nfzlwgbvezwwrutqpedy/storage/buckets/local-llm-models
   ```

2. **Click "Upload" button** (top right)

3. **Select file:**
   - Navigate to: `/Users/reisgordon/AVRAI/models/macos/llama-3.1-8b-instruct-coreml.zip`
   - Or drag and drop the file
   - **Note:** Upload may take 5-15 minutes for 3.7GB

4. **Wait for upload to complete** (you'll see progress bar)

5. **After upload, click on the filename** to view details

6. **Copy the public URL:**
   - Should be: `https://nfzlwgbvezwwrutqpedy.supabase.co/storage/v1/object/public/local-llm-models/llama-3.1-8b-instruct-coreml.zip`
   - Save this URL for Step 3

---

## Step 3: Set Supabase Secrets

Run these commands in your terminal:

```bash
cd /Users/reisgordon/AVRAI

# Set the three secrets (replace URL if different from above)
supabase secrets set LOCAL_LLM_MACOS_COREML_ZIP_URL="https://nfzlwgbvezwwrutqpedy.supabase.co/storage/v1/object/public/local-llm-models/llama-3.1-8b-instruct-coreml.zip"

supabase secrets set LOCAL_LLM_MACOS_COREML_ZIP_SHA256="843c1773f2335dbd1ede45fb21684499641648b7e04c3a76989d9eb0a54672f8"

supabase secrets set LOCAL_LLM_MACOS_COREML_ZIP_SIZE_BYTES="3936400726"
```

---

## Step 4: Verify

Test the manifest endpoint:

```bash
curl https://nfzlwgbvezwwrutqpedy.supabase.co/functions/v1/local-llm-manifest
```

You should see a JSON response with your model details.

---

## Alternative: Upload via CLI

If you prefer CLI (may be slower for large files):

```bash
cd /Users/reisgordon/AVRAI

# Upload
supabase storage upload local-llm-models \
  llama-3.1-8b-instruct-coreml.zip \
  --file models/macos/llama-3.1-8b-instruct-coreml.zip
```

Then proceed to Step 3 to set secrets.
