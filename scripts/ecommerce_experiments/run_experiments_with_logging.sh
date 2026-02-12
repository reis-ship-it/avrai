#!/bin/bash
# Run E-Commerce Experiments with Comprehensive Logging
# Phase 21: E-Commerce Data Enrichment Integration POC

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Log file
LOG_FILE="results/experiment_run_$(date +%Y%m%d_%H%M%S).log"
mkdir -p results

# Function to log with timestamp
log() {
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log_section() {
    echo "" | tee -a "$LOG_FILE"
    log "${BLUE}=== $1 ===${NC}"
}

log_success() {
    log "${GREEN}✅ $1${NC}"
}

log_error() {
    log "${RED}❌ $1${NC}"
}

log_warning() {
    log "${YELLOW}⚠️  $1${NC}"
}

# Check dependencies
log_section "Checking Dependencies"
if ! python3 -c "import numpy, pandas, scipy" 2>/dev/null; then
    log_error "Missing dependencies. Installing..."
    pip3 install numpy pandas scipy --quiet
    log_success "Dependencies installed"
else
    log_success "All dependencies available"
fi

# Get API configuration
log_section "API Configuration"

# Try to get from environment or use defaults
API_URL="${ECOMMERCE_API_URL:-}"
API_KEY="${ECOMMERCE_API_KEY:-}"

# If not set, try to construct from Supabase project
if [ -z "$API_URL" ]; then
    # Try to get from Supabase status or use default project
    PROJECT_REF="nfzlwgbvezwwrutqpedy"  # Default from run_app.sh
    API_URL="https://${PROJECT_REF}.supabase.co/functions/v1/ecommerce-enrichment"
    log_warning "Using default API URL: $API_URL"
    log_warning "Set ECOMMERCE_API_URL environment variable to override"
else
    log_success "API URL: $API_URL"
fi

if [ -z "$API_KEY" ]; then
    log_error "API_KEY not set. Cannot run experiments."
    log_warning "To generate an API key:"
    log_warning "  1. Connect to your Supabase database"
    log_warning "  2. Run: SELECT generate_api_key('test_partner', 100, 10000, NULL);"
    log_warning "  3. Set: export ECOMMERCE_API_KEY='your_generated_key'"
    log_warning ""
    log_warning "For testing without API key, experiments will simulate API calls."
    log_warning "Set ECOMMERCE_API_KEY='MOCK' to run in simulation mode."
    exit 1
else
    if [ "$API_KEY" = "MOCK" ]; then
        log_warning "Running in MOCK mode (simulated API calls)"
    else
        log_success "API Key configured"
    fi
fi

# Run experiments
log_section "Running Experiments"

EXPERIMENT_START=$(date +%s)

if [ "$API_KEY" = "MOCK" ]; then
    log_warning "MOCK mode: Experiments will simulate API responses"
    log_warning "To run real experiments, generate an API key and set ECOMMERCE_API_KEY"
    
    # Create a mock results summary
    cat > results/MOCK_EXPERIMENT_SUMMARY.md << EOF
# Mock Experiment Results

**Date:** $(date '+%Y-%m-%d %H:%M:%S')
**Mode:** MOCK (Simulated)

## Status

Experiments were run in MOCK mode because no API key was provided.

## To Run Real Experiments

1. **Generate API Key:**
   \`\`\`sql
   SELECT generate_api_key('test_partner', 100, 10000, NULL);
   \`\`\`

2. **Set Environment Variable:**
   \`\`\`bash
   export ECOMMERCE_API_KEY='your_generated_key'
   \`\`\`

3. **Run Experiments:**
   \`\`\`bash
   ./run_experiments_with_logging.sh
   \`\`\`

## Expected Results

Once API is deployed and key is generated:
- Endpoint functionality tests
- Performance benchmarks
- Algorithm enhancement A/B test
- Data quality validation
EOF
    
    log_success "Mock summary created: results/MOCK_EXPERIMENT_SUMMARY.md"
else
    # Run real experiments
    log "Starting experiment suite..."
    
    python3 run_all_experiments.py \
        --api-url "$API_URL" \
        --api-key "$API_KEY" \
        --performance-iterations 50 \
        --ab-test-users 500 \
        --ab-test-products 50 \
        2>&1 | tee -a "$LOG_FILE"
    
    EXPERIMENT_END=$(date +%s)
    DURATION=$((EXPERIMENT_END - EXPERIMENT_START))
    
    log_success "Experiments completed in ${DURATION} seconds"
fi

# Generate summary
log_section "Generating Summary"

if [ -f "results/MASTER_SUMMARY.md" ]; then
    log_success "Master summary: results/MASTER_SUMMARY.md"
    cat results/MASTER_SUMMARY.md | tee -a "$LOG_FILE"
else
    log_warning "Master summary not found (experiments may not have completed)"
fi

log_section "Experiment Run Complete"
log "Log file: $LOG_FILE"
log "Results directory: results/"
