#!/bin/bash

# Deploy Edge Functions for Phase 11 Section 4
# Deploys: onboarding-aggregation, social-enrichment, llm-generation

set -e

echo "🚀 Deploying Phase 11 Edge Functions..."
echo ""

# Check if Supabase CLI is installed
if ! command -v supabase &> /dev/null; then
    echo "❌ Supabase CLI not found. Install it with: npm install -g supabase"
    exit 1
fi

# Functions to deploy
FUNCTIONS=("onboarding-aggregation" "social-enrichment" "llm-generation")

# Deploy each function
for func in "${FUNCTIONS[@]}"; do
    echo "📦 Deploying $func..."
    supabase functions deploy "$func" --no-verify-jwt
    
    if [ $? -eq 0 ]; then
        echo "✅ $func deployed successfully!"
    else
        echo "❌ Failed to deploy $func"
        exit 1
    fi
    echo ""
done

echo "✅ All edge functions deployed successfully!"
echo ""
echo "📝 Next steps:"
echo "   1. Ensure GEMINI_API_KEY is set (for llm-generation):"
echo "      supabase secrets set GEMINI_API_KEY=your_key"
echo "   2. Test the functions using the services:"
echo "      - OnboardingAggregationService"
echo "      - SocialEnrichmentService"
echo "      - LLMService (llm-generation)"
echo ""
