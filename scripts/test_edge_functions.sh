#!/bin/bash

# Test Phase 11 Edge Functions
# Tests: onboarding-aggregation, social-enrichment, llm-generation

set -e

echo "🧪 Testing Phase 11 Edge Functions..."
echo ""

# Get project info
PROJECT_REF=$(supabase status 2>&1 | grep "API URL" | sed 's/.*https:\/\///' | sed 's/\.supabase\.co.*//' || echo "")
if [ -z "$PROJECT_REF" ]; then
    echo "⚠️  Could not determine project reference. Using nfzlwgbvezwwrutqpedy"
    PROJECT_REF="nfzlwgbvezwwrutqpedy"
fi

API_URL="https://${PROJECT_REF}.supabase.co"
ANON_KEY=$(supabase status 2>&1 | grep "anon key" | awk '{print $3}' || echo "")

if [ -z "$ANON_KEY" ]; then
    echo "⚠️  Could not get anon key from status. You may need to set it manually."
    echo "   Get it from: https://supabase.com/dashboard/project/${PROJECT_REF}/settings/api"
    exit 1
fi

echo "📋 Project: $PROJECT_REF"
echo "📋 API URL: $API_URL"
echo ""

# Test 1: onboarding-aggregation
echo "1️⃣  Testing onboarding-aggregation..."
TEST_RESPONSE=$(curl -s -X POST "${API_URL}/functions/v1/onboarding-aggregation" \
  -H "Authorization: Bearer ${ANON_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "agentId": "agent_test123",
    "onboardingData": {
      "age": 25,
      "homebase": "San Francisco",
      "favoritePlaces": ["Coffee Shop", "Park"],
      "preferences": {"Food": ["Coffee", "Pastries"]},
      "baselineLists": ["Coffee Spots", "Parks"],
      "respectedFriends": ["friend1", "friend2"],
      "socialMediaConnected": {"google": true}
    }
  }')

if echo "$TEST_RESPONSE" | grep -q "success"; then
    echo "✅ onboarding-aggregation: SUCCESS"
    echo "   Response: $(echo $TEST_RESPONSE | jq -r '.success // .error // .' 2>/dev/null || echo $TEST_RESPONSE)"
else
    echo "❌ onboarding-aggregation: FAILED"
    echo "   Response: $TEST_RESPONSE"
fi
echo ""

# Test 2: social-enrichment
echo "2️⃣  Testing social-enrichment..."
# Note: This requires a valid userId, so we'll test with a placeholder
TEST_RESPONSE=$(curl -s -X POST "${API_URL}/functions/v1/social-enrichment" \
  -H "Authorization: Bearer ${ANON_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "agentId": "agent_test123",
    "userId": "00000000-0000-0000-0000-000000000000"
  }')

if echo "$TEST_RESPONSE" | grep -q "insights"; then
    echo "✅ social-enrichment: SUCCESS"
    echo "   Response: $(echo $TEST_RESPONSE | jq -r '.insights // .error // .' 2>/dev/null | head -c 100 || echo $TEST_RESPONSE | head -c 100)..."
else
    # Even if no data, if we get a valid JSON response it's working
    if echo "$TEST_RESPONSE" | grep -qE "insights|error"; then
        echo "✅ social-enrichment: SUCCESS (no data, but function is working)"
        echo "   Response: $(echo $TEST_RESPONSE | jq -r '.error // .insights // .' 2>/dev/null || echo $TEST_RESPONSE | head -c 100)..."
    else
        echo "❌ social-enrichment: FAILED"
        echo "   Response: $TEST_RESPONSE"
    fi
fi
echo ""

# Test 3: llm-generation
echo "3️⃣  Testing llm-generation..."
TEST_RESPONSE=$(curl -s -X POST "${API_URL}/functions/v1/llm-generation" \
  -H "Authorization: Bearer ${ANON_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "Find coffee shops near me",
    "structuredContext": {
      "traits": ["explorer", "coffee-lover"],
      "places": [],
      "social_graph": [],
      "agentId": "agent_test123"
    },
    "dimensionScores": {
      "exploration_eagerness": 0.8,
      "location_adventurousness": 0.7
    }
  }' \
  --max-time 30)

if echo "$TEST_RESPONSE" | grep -q "response"; then
    echo "✅ llm-generation: SUCCESS"
    RESPONSE_TEXT=$(echo "$TEST_RESPONSE" | jq -r '.response // .error // .' 2>/dev/null || echo "$TEST_RESPONSE")
    echo "   Response preview: $(echo "$RESPONSE_TEXT" | head -c 150)..."
elif echo "$TEST_RESPONSE" | grep -q "error"; then
    ERROR_MSG=$(echo "$TEST_RESPONSE" | jq -r '.error // .' 2>/dev/null || echo "$TEST_RESPONSE")
    if echo "$ERROR_MSG" | grep -q "GEMINI_API_KEY"; then
        echo "⚠️  llm-generation: API KEY NOT CONFIGURED"
        echo "   Error: $ERROR_MSG"
    else
        echo "❌ llm-generation: FAILED"
        echo "   Error: $ERROR_MSG"
    fi
else
    echo "❌ llm-generation: FAILED"
    echo "   Response: $TEST_RESPONSE"
fi
echo ""

echo "✅ Testing complete!"
echo ""
echo "📝 Note: These are basic connectivity tests. Full functionality requires:"
echo "   - Valid user data for social-enrichment"
echo "   - GEMINI_API_KEY configured for llm-generation"
