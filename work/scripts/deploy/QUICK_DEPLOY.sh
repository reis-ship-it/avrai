#!/bin/bash

# Quick Deploy Script for Google Gemini LLM Integration
# Run this script to deploy the LLM function to Supabase

set -e

echo "🚀 Deploying Google Gemini LLM Integration..."
echo ""

# Check if Supabase CLI is installed
if ! command -v supabase &> /dev/null; then
    echo "❌ Supabase CLI not found. Install it with: npm install -g supabase"
    exit 1
fi

# Step 1: Deploy the function
echo "📦 Step 1: Deploying Edge Function..."
supabase functions deploy llm-chat --no-verify-jwt

if [ $? -eq 0 ]; then
    echo "✅ Function deployed successfully!"
else
    echo "❌ Deployment failed. Make sure you're logged in: supabase login"
    exit 1
fi

echo ""
echo "🔑 Step 2: Setting API Key Secret..."
echo "⚠️  You need to set your Gemini API key manually:"
echo ""
echo "   supabase secrets set GEMINI_API_KEY=your_api_key_here"
echo ""
echo "   Get your API key from: https://makersuite.google.com/app/apikey"
echo ""

# Check if API key is already set
if supabase secrets list 2>/dev/null | grep -q "GEMINI_API_KEY"; then
    echo "✅ GEMINI_API_KEY secret already exists"
else
    echo "⚠️  GEMINI_API_KEY secret not found - you need to set it!"
fi

echo ""
echo "✅ Deployment complete!"
echo ""
echo "📝 Next steps:"
echo "   1. Set your API key: supabase secrets set GEMINI_API_KEY=your_key"
echo "   2. Test the function (see DEPLOY_GEMINI.md)"
echo "   3. Use LLMService in your app!"
echo ""

