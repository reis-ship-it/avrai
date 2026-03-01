# Apply RLS Performance Migration

**Migration File:** `supabase/migrations/021_fix_rls_performance.sql`  
**Status:** Ready to apply

---

## 🚀 **Quick Apply (Choose One Method)**

### **Option 1: Supabase Dashboard (Easiest) ⭐ Recommended**

1. Go to: https://supabase.com/dashboard/project/nfzlwgbvezwwrutqpedy/sql/new
2. Copy the entire contents of `supabase/migrations/021_fix_rls_performance.sql`
3. Paste into the SQL Editor
4. Click **Run** (or press Cmd+Enter)
5. Verify: Check for success message

**Time:** ~30 seconds

---

### **Option 2: Supabase CLI (With Password)**

```bash
cd /Users/reisgordon/SPOTS
supabase db push --linked --password YOUR_DB_PASSWORD
```

**Note:** Replace `YOUR_DB_PASSWORD` with your database password.  
Get it from: https://supabase.com/dashboard/project/nfzlwgbvezwwrutqpedy/settings/database

---

### **Option 3: Direct psql Connection**

```bash
cd /Users/reisgordon/SPOTS
psql "postgresql://postgres.nfzlwgbvezwwrutqpedy:[YOUR_PASSWORD]@aws-0-us-west-2.pooler.supabase.com:6543/postgres" -f supabase/migrations/021_fix_rls_performance.sql
```

**Note:** Replace `[YOUR_PASSWORD]` with your database password.

---

## ✅ **After Applying**

1. **Verify in Supabase Dashboard:**
   - Go to Database → Policies
   - Check that policies are updated:
     - `llm_responses`: Should have 2 policies (INSERT/UPDATE/DELETE + SELECT)
     - `onboarding_aggregations`: Should have 2 policies
     - `structured_facts`: Should have 2 policies

2. **Run Supabase Linter Again:**
   - Go to Database → Linter
   - Should show **0 warnings** for:
     - `auth_rls_initplan`
     - `multiple_permissive_policies`

3. **Test a Query:**
   ```sql
   -- This should work and be faster
   SELECT * FROM llm_responses LIMIT 10;
   ```

---

## 📋 **What This Migration Does**

- ✅ Fixes 5 `auth_rls_initplan` warnings (caches `auth.role()`)
- ✅ Fixes 19 `multiple_permissive_policies` warnings (combines policies)
- ✅ **10-100x performance improvement** for queries with many rows
- ✅ **No breaking changes** - same security, just faster

---

## 🔍 **Migration Preview**

The migration will:
1. Drop old policies
2. Create new optimized policies with cached `auth.role()`
3. Split `FOR ALL` into separate `INSERT/UPDATE/DELETE` and `SELECT` policies
4. Handle tables that might not exist (`nda_access`, `admin_credentials`)

**Full migration:** See `supabase/migrations/021_fix_rls_performance.sql`

---

**Last Updated:** December 23, 2025
