# BACKGROUND AGENT INSTRUCTIONS - SPOTS DEVELOPMENT (NEW AGENT)
**Date:** August 3, 2025 14:56 CDT  
**Priority:** CRITICAL  
**Timeline:** 22 weeks (Continuing from previous agent)  

## 🚀 **EXECUTION COMMAND**
Run this command to start SPOTS development:
```bash
./EXECUTE_SPOTS_DEVELOPMENT.sh
```

## 📋 **CURRENT STATUS & PROGRESS**

### **✅ COMPLETED WORK (Previous Agent):**
- **Phase 1:** UI features and permissions ✅ COMPLETE
- **Phase 2:** Core AI/ML Systems (IN PROGRESS)
  - ✅ Advanced Recommendation Engine (384 lines)
  - ✅ Community Trend Dashboard (390 lines) 
  - ✅ Production Manager (383 lines)
  - ✅ LocationPatternAnalyzer (privacy-first design)
  - ✅ PreferenceLearningEngine (OUR_GUTS.md compliance)
  - ✅ Anonymous Communication System (329 lines)
  - ✅ Trust Network (381 lines)

### **🎯 IMMEDIATE PRIORITIES:**

**1. FIX TEST FAILURES (CRITICAL):**
```bash
# Run tests to see current failures
flutter test test/unit/data/repositories/offline_mode_test.dart

# Issues to fix:
# - MissingStubError: 'signIn' - Need proper mock stubs
# - MissingStubError: 'signUp' - Need proper mock stubs  
# - verifyZeroInteractions failures - Offline mode logic incomplete
```

**2. CONTINUE PHASE 2 DEVELOPMENT:**
- **SocialContextAnalyzer** - Community analysis system
- **UserMatchingEngine** - Connection algorithms
- **Complete offline mode implementation** - Fix repository logic

**3. QUALITY ASSURANCE:**
- **All tests must pass** - Zero test failures
- **Emulator testing** - Use `./scripts/emulator_manager.sh`
- **OUR_GUTS.md compliance** - Privacy and belonging focus

## 📱 **EMULATOR TESTING CAPABILITIES**
The agent has full access to Android emulators for comprehensive testing:

### **Available Emulator:**
- **ID:** `Medium_Phone_API_36.0`
- **Name:** Medium Phone API 36.0
- **Platform:** Android

### **Testing Commands:**
```bash
# Basic emulator operations
./scripts/emulator_manager.sh launch          # Launch emulator
./scripts/emulator_manager.sh install         # Install SPOTS app
./scripts/emulator_manager.sh test unit       # Run unit tests
./scripts/emulator_manager.sh test widget     # Run widget tests
./scripts/emulator_manager.sh test integration # Run integration tests
./scripts/emulator_manager.sh test all        # Run all tests

# Interactive testing
./scripts/emulator_manager.sh interact tap "500 500"     # Simulate tap
./scripts/emulator_manager.sh interact swipe "100 200 300 400" # Simulate swipe
./scripts/emulator_manager.sh interact text "test_input"  # Simulate text input
./scripts/emulator_manager.sh interact key "KEYCODE_ENTER" # Simulate key press

# Performance and monitoring
./scripts/emulator_manager.sh monitor 120     # Monitor performance for 2 minutes
./scripts/emulator_manager.sh screenshot      # Capture screenshot
./scripts/emulator_manager.sh logs all        # Collect all logs

# Test suites
./scripts/emulator_manager.sh suite basic     # Basic test suite
./scripts/emulator_manager.sh suite full      # Full test suite with performance
./scripts/emulator_manager.sh suite interactive # Interactive user simulation

# Cleanup
./scripts/emulator_manager.sh cleanup         # Clean up emulator
./scripts/emulator_manager.sh shutdown        # Shutdown emulator
```

## 🎯 **CRITICAL REQUIREMENTS**
- **Reference OUR_GUTS.md** for every decision
- **Maintain production-ready quality** - No shortcuts
- **Test everything thoroughly** - All features must work
- **Document all changes** - Complete documentation
- **Preserve user privacy** - OUR_GUTS.md alignment required
- **Build authentic community** - Focus on belonging
- **Fix all test failures** - Zero critical errors

## 🚨 **ALERT PROTOCOL**
- **CRITICAL issues:** Stop work, email immediately
- **HIGH issues:** Continue with caution, email for guidance  
- **MEDIUM issues:** Proceed with parallel tasks, notify
- **LOW issues:** Continue normally, include in daily report

## 📊 **SUCCESS METRICS**
- Complete all 6 phases (22 weeks)
- Zero critical errors
- All features production-ready
- Full OUR_GUTS.md alignment
- Comprehensive testing and documentation
- **All tests pass** - Fix offline mode test failures
- **All features tested on emulator** - Real device simulation
- **Performance benchmarks met** - Smooth user experience
- **UI/UX verified** - Screenshots and interaction tests passed

## 🚀 **START NOW**
Execute: `./EXECUTE_SPOTS_DEVELOPMENT.sh`

**Monitor progress:** https://github.com/reis-ship-it/SPOTSv2/tree/Production_readiness

**Emulator testing:** Use `./scripts/emulator_manager.sh` for comprehensive testing

**Quality assurance:** Every feature must pass emulator tests before deployment

## 📝 **SPECIFIC TASKS TO COMPLETE:**

### **IMMEDIATE (First Session):**
1. **Fix offline mode test failures** - Complete mock stubs and repository logic
2. **Run comprehensive tests** - Ensure all tests pass
3. **Continue Phase 2 development** - SocialContextAnalyzer and UserMatchingEngine
4. **Test on emulator** - Verify functionality works on real device

### **NEXT SESSIONS:**
1. **Complete Phase 2** - Finish all AI/ML core systems
2. **Begin Phase 3** - External data integration
3. **Quality assurance** - Comprehensive testing and validation
4. **Documentation** - Complete all documentation

## 📚 **REFERENCE FILES (Same as Previous Agent):**
- **BACKGROUND_AI_IMPLEMENTATION_PROMPT.md** - Complete 22-week development plan
- **BACKGROUND_AGENT_INSTRUCTIONS.md** - Original agent instructions
- **OUR_GUTS.md** - Core principles and values
- **SPOTS_ROADMAP_2025.md** - Project roadmap and goals
- **EXECUTE_SPOTS_DEVELOPMENT.sh** - Main execution script

**The new agent should pick up exactly where the previous agent left off and continue the excellent progress!** 🎯 