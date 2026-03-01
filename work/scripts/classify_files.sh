#!/bin/bash

# SPOTS File Classification and Management Script
# Based on docs/file_classification.md
# Date: July 30, 2025

echo "🔍 SPOTS File Classification System"
echo "=================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Function to safely remove files/directories
safe_remove() {
    local path="$1"
    local description="$2"
    
    if [ -e "$path" ]; then
        echo -e "${YELLOW}🗑️  Removing $description: $path${NC}"
        rm -rf "$path"
    else
        echo -e "${BLUE}✅ $description already clean: $path${NC}"
    fi
}

# Function to safely keep files/directories
safe_keep() {
    local path="$1"
    local description="$2"
    
    if [ -e "$path" ]; then
        echo -e "${GREEN}✅ Keeping $description: $path${NC}"
    else
        echo -e "${BLUE}ℹ️  $description not found: $path${NC}"
    fi
}

# Function to check if file should be preserved
should_preserve() {
    local file="$1"
    
    # Core documentation - ALWAYS preserve
    if [[ "$file" == "OUR_GUTS.md" ]] || \
       [[ "$file" == "README.md" ]] || \
       [[ "$file" == "MVP_ROADMAP.md" ]] || \
       [[ "$file" == "TECHNICAL_ROADMAP.md" ]] || \
       [[ "$file" == "BUSINESS_ROADMAP.md" ]] || \
       [[ "$file" == "FEATURE_LIST.md" ]] || \
       [[ "$file" == "ISSUE_TRACKER.md" ]] || \
       [[ "$file" == "DEVELOPMENT_LOG.md" ]] || \
       [[ "$file" == "competitor_research.md" ]] || \
       [[ "$file" == "project.json" ]] || \
       [[ "$file" == "SPOTS_README.md" ]]; then
        return 0  # true - preserve
    fi
    
    # Development artifacts - KEEP
    if [[ "$file" == analysis_*.log ]] || \
       [[ "$file" == session_report_*.md ]] || \
       [[ "$file" == background_agent/* ]] || \
       [[ "$file" == test_results/* ]] || \
       [[ "$file" == coverage/* ]] || \
       [[ "$file" == performance_*.log ]] || \
       [[ "$file" == memory_*.log ]] || \
       [[ "$file" == cpu_*.log ]] || \
       [[ "$file" == auto_*.sh ]] || \
       [[ "$file" == fix_*.sh ]] || \
       [[ "$file" == sync_*.sh ]] || \
       [[ "$file" == *_analysis.sh ]] || \
       [[ "$file" == *_compare.sh ]] || \
       [[ "$file" == *_monitor.sh ]] || \
       [[ "$file" == *_GUIDE.md ]] || \
       [[ "$file" == *_REPORT.md ]] || \
       [[ "$file" == *_ROADMAP.md ]] || \
       [[ "$file" == *_FEATURE*.md ]] || \
       [[ "$file" == *_ISSUE*.md ]] || \
       [[ "$file" == *_DEVELOPMENT*.md ]] || \
       [[ "$file" == *_BUSINESS*.md ]] || \
       [[ "$file" == *_COMPETITOR*.md ]] || \
       [[ "$file" == *_GUTS*.md ]] || \
       [[ "$file" == analysis_options.yaml ]] || \
       [[ "$file" == analysis_options_*.yaml ]] || \
       [[ "$file" == spots_data_export/* ]] || \
       [[ "$file" == *.db ]] || \
       [[ "$file" == *.sqlite ]] || \
       [[ "$file" == *.sqlite3 ]]; then
        return 0  # true - keep
    fi
    
    # Sensitive files - PROTECT (don't remove, but don't track)
    if [[ "$file" == .env* ]] || \
       [[ "$file" == secrets.dart ]] || \
       [[ "$file" == api_keys.dart ]] || \
       [[ "$file" == config/secrets.dart ]] || \
       [[ "$file" == lib/config/secrets.dart ]] || \
       [[ "$file" == lib/core/config/secrets.dart ]] || \
       [[ "$file" == lib/core/constants/api_keys.dart ]] || \
       [[ "$file" == lib/core/constants/secrets.dart ]] || \
       [[ "$file" == google-services.json ]] || \
       [[ "$file" == GoogleService-Info.plist ]] || \
       [[ "$file" == firebase_options.dart ]] || \
       [[ "$file" == lib/firebase_options.dart ]] || \
       [[ "$file" == *.p12 ]] || \
       [[ "$file" == *.pem ]] || \
       [[ "$file" == *.key ]] || \
       [[ "$file" == *.crt ]] || \
       [[ "$file" == *.cer ]] || \
       [[ "$file" == *.der ]] || \
       [[ "$file" == .netrc ]] || \
       [[ "$file" == .npmrc ]] || \
       [[ "$file" == .yarnrc ]]; then
        return 2  # special - protect
    fi
    
    return 1  # false - can be cleaned
}

# Function to classify and act on files
classify_and_act() {
    local file="$1"
    
    if should_preserve "$file"; then
        safe_keep "$file" "Development artifact or core documentation"
    else
        # Check if it's a temporary file that should be cleaned
        if [[ "$file" == *.tmp ]] || \
           [[ "$file" == *.temp ]] || \
           [[ "$file" == .DS_Store* ]] || \
           [[ "$file" == ._* ]] || \
           [[ "$file" == .Spotlight-V100 ]] || \
           [[ "$file" == .Trashes ]] || \
           [[ "$file" == ehthumbs.db ]] || \
           [[ "$file" == Thumbs.db ]] || \
           [[ "$file" == Desktop.ini ]] || \
           [[ "$file" == *~ ]] || \
           [[ "$file" == .fuse_hidden* ]] || \
           [[ "$file" == .directory ]] || \
           [[ "$file" == .Trash-* ]] || \
           [[ "$file" == .nfs* ]] || \
           [[ "$file" == temp/* ]] || \
           [[ "$file" == tmp/* ]] || \
           [[ "$file" == .tmp/* ]] || \
           [[ "$file" == .cache/* ]] || \
           [[ "$file" == cache/* ]] || \
           [[ "$file" == *.cache ]] || \
           [[ "$file" == build/* ]] || \
           [[ "$file" == *.g.dart ]] || \
           [[ "$file" == *.freezed.dart ]] || \
           [[ "$file" == *.mocks.dart ]] || \
           [[ "$file" == *.config.dart ]]; then
            safe_remove "$file" "Temporary file"
        else
            echo -e "${CYAN}ℹ️  Unknown file type: $file${NC}"
        fi
    fi
}

# Main classification function
classify_workspace() {
    echo -e "${CYAN}🔍 Starting file classification...${NC}"
    echo ""
    
    # Find all files and classify them
    find . -type f -not -path "./.git/*" -not -path "./node_modules/*" -not -path "./Pods/*" | while read -r file; do
        # Remove leading ./
        file="${file#./}"
        classify_and_act "$file"
    done
    
    echo ""
    echo -e "${GREEN}✅ File classification complete!${NC}"
}

# Function to show classification summary
show_summary() {
    echo ""
    echo -e "${CYAN}📊 Classification Summary:${NC}"
    echo ""
    
    echo -e "${GREEN}✅ Development Artifacts (KEEP):${NC}"
    find . -name "analysis_*.log" -o -name "session_report_*.md" -o -name "background_agent" -o -name "test_results" -o -name "coverage" | head -5
    echo "..."
    
    echo ""
    echo -e "${YELLOW}🗑️  Temporary Files (CLEAN):${NC}"
    find . -name "*.tmp" -o -name ".DS_Store" -o -name "*.cache" -o -name "build" | head -5
    echo "..."
    
    echo ""
    echo -e "${RED}🔒 Sensitive Files (PROTECT):${NC}"
    find . -name ".env*" -o -name "secrets.dart" -o -name "*.p12" -o -name "google-services.json" | head -5
    echo "..."
    
    echo ""
    echo -e "${BLUE}📚 Core Documentation (PRESERVE):${NC}"
    find . -name "OUR_GUTS.md" -o -name "README.md" -o -name "*_ROADMAP.md" -o -name "project.json" | head -5
    echo "..."
}

# Function to create smart .gitignore
create_smart_gitignore() {
    echo -e "${CYAN}📝 Creating smart .gitignore...${NC}"
    
    cat > .gitignore.smart << 'EOF'
# SPOTS Smart .gitignore
# Based on file_classification.md

# ===== TEMPORARY FILES (CLEAN) =====
*.tmp
*.temp
temp/
tmp/
.tmp/
.cache/
cache/
*.cache

# OS Generated Files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db
Desktop.ini
*~
.fuse_hidden*
.directory
.Trash-*
.nfs*

# Build Artifacts (can be rebuilt)
build/
*.g.dart
*.freezed.dart
*.mocks.dart
*.config.dart

# ===== SENSITIVE FILES (PROTECT) =====
.env
.env.local
.env.development
.env.production
.env.staging
secrets.dart
api_keys.dart
config/secrets.dart
lib/config/secrets.dart
lib/core/config/secrets.dart
lib/core/constants/api_keys.dart
lib/core/constants/secrets.dart
google-services.json
GoogleService-Info.plist
firebase_options.dart
lib/firebase_options.dart
*.p12
*.pem
*.key
*.crt
*.cer
*.der
.netrc
.npmrc
.yarnrc

# ===== DEVELOPMENT ARTIFACTS (KEEP) =====
# Note: These are NOT ignored - they're valuable for development
# analysis_*.log
# session_report_*.md
# background_agent/
# test_results/
# coverage/
# performance_*.log
# memory_*.log
# cpu_*.log
# auto_*.sh
# fix_*.sh
# sync_*.sh
# *_analysis.sh
# *_compare.sh
# *_monitor.sh
# *_GUIDE.md
# *_REPORT.md
# *_ROADMAP.md
# *_FEATURE*.md
# *_ISSUE*.md
# *_DEVELOPMENT*.md
# *_BUSINESS*.md
# *_COMPETITOR*.md
# *_GUTS*.md
# analysis_options.yaml
# analysis_options_*.yaml
# spots_data_export/
# *.db
# *.sqlite
# *.sqlite3

# ===== CORE DOCUMENTATION (PRESERVE) =====
# Note: These are NOT ignored - they're essential
# OUR_GUTS.md
# README.md
# MVP_ROADMAP.md
# TECHNICAL_ROADMAP.md
# BUSINESS_ROADMAP.md
# FEATURE_LIST.md
# ISSUE_TRACKER.md
# DEVELOPMENT_LOG.md
# competitor_research.md
# project.json
# SPOTS_README.md
EOF

    echo -e "${GREEN}✅ Smart .gitignore created: .gitignore.smart${NC}"
    echo -e "${YELLOW}💡 Review and replace existing .gitignore if desired${NC}"
}

# Main execution
case "${1:-classify}" in
    "classify")
        classify_workspace
        show_summary
        ;;
    "summary")
        show_summary
        ;;
    "gitignore")
        create_smart_gitignore
        ;;
    "help")
        echo "Usage: $0 [classify|summary|gitignore|help]"
        echo ""
        echo "Commands:"
        echo "  classify  - Classify all files and show summary (default)"
        echo "  summary   - Show classification summary only"
        echo "  gitignore - Create smart .gitignore based on classification"
        echo "  help      - Show this help message"
        ;;
    *)
        echo "Unknown command: $1"
        echo "Use 'help' for usage information"
        exit 1
        ;;
esac

echo ""
echo -e "${CYAN}📋 For detailed classification rules, see: docs/file_classification.md${NC}" 