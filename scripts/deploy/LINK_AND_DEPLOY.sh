#!/bin/bash

# Link Supabase Project and Deploy Gemini Function
# This script will help you link your project and deploy

set -e

echo "🔗 Linking Supabase Project..."
echo ""

# Check if already linked
if supabase status 2>&1 | grep -q "project_ref"; then
    echo "✅ Project already linked!"
    PROJECT_REF=$(supabase status 2>&1 | grep "project_ref" | awk '{print $2}')
    echo "   Project Reference: $PROJECT_REF"
else
    echo "⚠️  Project not linked. Let's link it now..."
    echo ""
    echo "You have two options:"
    echo ""
    echo "Option 1: Interactive linking (recommended)"
    echo "   Run: supabase link"
    echo "   This will show you a list of projects to choose from"
    echo ""
    echo "Option 2: Link with project reference"
    echo "   Run: supabase link --project-ref YOUR_PROJECT_REF"
    echo "   Get your project ref from: https://app.supabase.com → Settings → General"
    echo ""
    echo "Press Enter to start interactive linking, or Ctrl+C to cancel..."
    read
    
    supabase link
fi

echo ""
echo "📦 Deploying LLM Function..."
supabase functions deploy llm-chat --no-verify-jwt

if [ $? -eq 0 ]; then
    echo "✅ Function deployed successfully!"
    echo ""
    echo "🔑 Next: Set your Gemini API key"
    echo "   supabase secrets set GEMINI_API_KEY=your_api_key_here"
    echo ""
    echo "   Get your API key from: https://makersuite.google.com/app/apikey"
else
    echo "❌ Deployment failed"
    exit 1
fi

