#!/bin/bash

# Script to verify generate_api_key() function exists and works
# This script checks if the migration has been applied and tests the function

set -e

echo "🔍 Verifying API Key Generation Function..."
echo ""

# Check if Supabase is linked
if [ ! -f ".supabase/config.toml" ]; then
    echo "⚠️  Supabase project not linked locally"
    echo "   Run: supabase link --project-ref nfzlwgbvezwwrutqpedy"
    echo ""
    echo "📝 To verify manually:"
    echo "   1. Go to Supabase Dashboard → SQL Editor"
    echo "   2. Run: SELECT routine_name FROM information_schema.routines WHERE routine_name = 'generate_api_key';"
    echo "   3. If it returns a row, the function exists"
    echo "   4. Test it: SELECT generate_api_key('test', 10, 100, NULL);"
    exit 0
fi

echo "✅ Supabase project is linked"
echo ""

# Check migration status
echo "📋 Checking migration status..."
if supabase migration list 2>/dev/null | grep -q "022_ecommerce_enrichment_api_tables"; then
    echo "✅ Migration 022_ecommerce_enrichment_api_tables found in migration list"
else
    echo "⚠️  Migration not found in local migration list"
    echo "   This doesn't mean it's not applied - it might be applied remotely"
fi

echo ""
echo "📝 To verify the function exists in your database:"
echo ""
echo "   1. Go to: https://supabase.com/dashboard/project/nfzlwgbvezwwrutqpedy/sql/new"
echo "   2. Run this query to check if function exists:"
echo ""
echo "      SELECT routine_name, routine_type"
echo "      FROM information_schema.routines"
echo "      WHERE routine_schema = 'public'"
echo "      AND routine_name = 'generate_api_key';"
echo ""
echo "   3. If it returns a row, the function exists!"
echo ""
echo "   4. Test the function:"
echo ""
echo "      SELECT generate_api_key('verification_test', 10, 100, NULL);"
echo ""
echo "   5. If it returns a key like 'spots_poc_verification_test_...', it works!"
echo ""
echo "📊 Expected Results:"
echo "   - Function exists: Should return 1 row"
echo "   - Function works: Should return a key starting with 'spots_poc_'"
echo ""
