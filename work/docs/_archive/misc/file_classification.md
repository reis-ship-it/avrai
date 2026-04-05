Relocations performed:

- lib/main_supabase_example.dart → examples/supabase/main_supabase_example.dart
- lib/supabase_initializer.dart → examples/supabase/supabase_initializer.dart (lib file left as legacy stub)
- lib/supabase_integration_example.dart → examples/supabase/supabase_integration_example.dart
- lib/supabase_config.dart → examples/supabase/supabase_config.dart (runtime config now via DI/spots_network)

Notes:
- CLI utilities remain at repo root (e.g., check_*.dart, debug_*.dart, verify_*.dart). Consider moving them under scripts/ if desired.
# SPOTS File Classification System
**Date:** July 30, 2025  
**Status:** 📋 **ACTIVE CLASSIFICATION SYSTEM**

---

## 🎯 **Purpose**

This document defines the classification system for all files in the SPOTS project. The goal is to **preserve valuable development artifacts** while **cleaning only truly temporary files**.

**Core Principle:** Auto-generated ≠ Disposable. Auto-generated files are often valuable development artifacts.

---

## 📋 **File Categories**

### **Category 1: Development Artifacts (KEEP)**
**Auto-generated but VALUABLE for development**

#### **Analysis & Testing:**
- `analysis_*.log` - Development insights and debugging data
- `session_report_*.md` - Progress tracking and development history
- `test_results/` - Quality metrics and test outcomes
- `coverage/` - Testing insights and coverage reports
- `performance_*.log` - Optimization data and performance metrics
- `memory_*.log` - Memory usage analysis
- `cpu_*.log` - CPU performance tracking

#### **Automation Tools:**
- `background_agent/` - Automation scripts and tools
- `auto_*.sh` - Automated fix scripts
- `fix_*.sh` - Code quality improvement scripts
- `sync_*.sh` - Synchronization scripts
- `*_analysis.sh` - Analysis automation scripts
- `*_compare.sh` - Comparison tools
- `*_monitor.sh` - Monitoring scripts

#### **Reports & Documentation:**
- `*_GUIDE.md` - Generated guides and tutorials
- `*_REPORT.md` - Analysis reports and findings
- `*_ROADMAP.md` - Generated planning documents
- `*_FEATURE*.md` - Feature documentation
- `*_ISSUE*.md` - Issue tracking documentation
- `*_DEVELOPMENT*.md` - Development process docs
- `*_BUSINESS*.md` - Business analysis docs
- `*_COMPETITOR*.md` - Competitor research
- `*_GUTS*.md` - Core philosophy and values

#### **Configuration & Data:**
- `analysis_options.yaml` - Analysis configuration
- `analysis_options_*.yaml` - Analysis configuration variants
- `spots_data_export/` - Data exports for analysis
- `*.db` - Development databases
- `*.sqlite` - SQLite databases
- `*.sqlite3` - SQLite3 databases

---

### **Category 2: Temporary Files (CLEAN)**
**Truly disposable files that can be safely removed**

#### **OS Generated:**
- `.DS_Store` - macOS system files
- `.DS_Store?` - macOS system file variants
- `._*` - macOS hidden files
- `.Spotlight-V100` - macOS Spotlight
- `.Trashes` - macOS Trashes
- `ehthumbs.db` - Windows thumbnails
- `Thumbs.db` - Windows thumbnails
- `Desktop.ini` - Windows desktop ini

#### **Linux Generated:**
- `*~` - Linux backup files
- `.fuse_hidden*` - Linux FUSE hidden files
- `.directory` - Linux directory files
- `.Trash-*` - Linux trash files
- `.nfs*` - Linux NFS files

#### **Cache & Temporary:**
- `*.tmp` - Temporary files
- `*.temp` - Temporary files
- `temp/` - Temp directory
- `tmp/` - Tmp directory
- `.tmp/` - Hidden tmp directory
- `.cache/` - Cache directory
- `cache/` - Cache directory
- `*.cache` - Cache files

#### **Build Artifacts:**
- `build/` - Build directory (can be rebuilt)
- `*.g.dart` - Generated Dart files (can be regenerated)
- `*.freezed.dart` - Freezed generated files
- `*.mocks.dart` - Mock generated files
- `*.config.dart` - Config generated files

---

### **Category 3: Sensitive Files (PROTECT)**
**Never commit - contains secrets and sensitive data**

#### **Environment & Secrets:**
- `.env` - Environment variables
- `.env.local` - Local environment file
- `.env.development` - Development environment file
- `.env.production` - Production environment file
- `.env.staging` - Staging environment file
- `secrets.dart` - Secrets file
- `api_keys.dart` - API keys file
- `config/secrets.dart` - Config secrets
- `lib/config/secrets.dart` - Lib config secrets
- `lib/core/config/secrets.dart` - Core config secrets
- `lib/core/constants/api_keys.dart` - API keys constants
- `lib/core/constants/secrets.dart` - Secrets constants

#### **Firebase Configuration:**
- `google-services.json` - Google services config
- `GoogleService-Info.plist` - iOS Firebase config
- `firebase_options.dart` - Firebase options
- `lib/firebase_options.dart` - Lib Firebase options

#### **Certificates & Keys:**
- `*.p12` - Certificate files
- `*.pem` - PEM files
- `*.key` - Key files
- `*.crt` - Certificate files
- `*.cer` - Certificate files
- `*.der` - DER files

#### **Network Configuration:**
- `.netrc` - Network config
- `.npmrc` - NPM config
- `.yarnrc` - Yarn config

---

### **Category 4: Core Documentation (PRESERVE)**
**Always keep - essential project documentation**

#### **Core Philosophy:**
- `OUR_GUTS.md` - Core philosophy and values
- `README.md` - Project overview and documentation

#### **Business Planning:**
- `MVP_ROADMAP.md` - Project milestones and goals
- `POST_MVP_ROADMAP.md` - Post-MVP planning
- `BUSINESS_ROADMAP.md` - Business strategy
- `FEATURE_LIST.md` - Feature planning
- `ISSUE_TRACKER.md` - Issue tracking
- `DEVELOPMENT_LOG.md` - Development history
- `competitor_research.md` - Competitor analysis

#### **Technical Planning:**
- `TECHNICAL_ROADMAP.md` - Technical architecture
- `project.json` - Project configuration
- `SPOTS_README.md` - Detailed project overview

#### **Development Documentation:**
- `docs/` - All documentation directory
- `test/testing/comprehensive_testing_plan.md` - Testing strategy
- `docs/architecture_ai_federated_p2p.md` - System architecture
- `docs/ui_ux_notes.md` - UI/UX guidelines
- `docs/background_agent_optimization_plan.md` - Optimization plans

---

## 🔧 **Implementation Rules**

### **KEEP Rules:**
- **Development artifacts** are valuable for debugging and optimization
- **Auto-generated files** often contain important insights
- **Analysis logs** help track progress and identify issues
- **Reports** provide historical context and decision-making data

### **CLEAN Rules:**
- **Only remove truly temporary files** that can be safely deleted
- **OS-generated files** that don't add value
- **Cache files** that can be regenerated
- **Build artifacts** that can be rebuilt

### **PROTECT Rules:**
- **Never commit sensitive files** to version control
- **Environment variables** should be kept secure
- **API keys and secrets** must be protected
- **Certificates** should never be shared

### **PRESERVE Rules:**
- **Core philosophy** defines the project's soul
- **Business planning** guides development decisions
- **Technical documentation** ensures maintainability
- **Development history** provides context for decisions

---

## 📊 **Classification Matrix**

| File Type | Category | Action | Reason |
|-----------|----------|--------|---------|
| `analysis_*.log` | Development Artifacts | KEEP | Valuable debugging data |
| `session_report_*.md` | Development Artifacts | KEEP | Progress tracking |
| `background_agent/` | Development Artifacts | KEEP | Automation tools |
| `*.tmp` | Temporary Files | CLEAN | Truly disposable |
| `.DS_Store` | Temporary Files | CLEAN | OS-generated |
| `.env` | Sensitive Files | PROTECT | Contains secrets |
| `OUR_GUTS.md` | Core Documentation | PRESERVE | Core philosophy |
| `MVP_ROADMAP.md` | Core Documentation | PRESERVE | Business planning |

---

## 🚀 **Usage Guidelines**

### **For Developers:**
1. **Check classification** before deleting any files
2. **Preserve development artifacts** - they're valuable
3. **Only clean truly temporary files**
4. **Protect sensitive information**
5. **Maintain core documentation**

### **For Automation:**
1. **Use this classification** in cleanup scripts
2. **Preserve valuable artifacts** even if auto-generated
3. **Only remove temporary files**
4. **Never touch sensitive or core files**

### **For Git Management:**
1. **Ignore only temporary and sensitive files**
2. **Track valuable development artifacts**
3. **Preserve core documentation**
4. **Use proper .gitignore patterns**

---

## 📋 **Next Steps**

1. **Implement classification script** based on this documentation
2. **Update .gitignore** to reflect proper categorization
3. **Create smart cleanup script** that preserves valuable artifacts
4. **Train team** on proper file classification
5. **Monitor effectiveness** of classification system

---

**This classification system ensures we preserve valuable development artifacts while maintaining a clean workspace.** 🎯 