#!/bin/bash

# BACKGROUND AGENT CLEANUP TRIGGER
# Date: January 30, 2025
# Purpose: Simple trigger for background agent to initiate cleanup
# Usage: ./scripts/background_agent_trigger_cleanup.sh

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🚀 Triggering SPOTS cleanup via background agent...${NC}"

# Execute the background agent cleanup integration
if ./scripts/background_agent_cleanup_integration.sh; then
    echo -e "${GREEN}✅ Cleanup completed successfully!${NC}"
    exit 0
else
    echo -e "${RED}❌ Cleanup failed - check logs above${NC}"
    exit 1
fi 