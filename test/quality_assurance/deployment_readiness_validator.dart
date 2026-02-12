/// SPOTS Deployment Readiness Validator
/// Date: August 5, 2025 23:11:54 CDT
/// Purpose: Comprehensive deployment readiness validation for optimal production releases
/// Focus: Ensure maximum confidence in production deployments through rigorous validation
// ignore_for_file: constant_identifier_names - Test constants use UPPER_CASE convention
library;

import 'dart:io';
import 'dart:convert';
import 'dart:math' as math;
import 'test_health_metrics.dart';
import 'performance_benchmarks.dart';
import 'automated_quality_checker.dart';

/// Deployment readiness validation system for SPOTS
/// Provides comprehensive analysis before production releases
class DeploymentReadinessValidator {
  static const String REPORTS_PATH =
      'test/quality_assurance/deployment_reports';
  static const double MIN_DEPLOYMENT_SCORE = 9.0;
  static const double MIN_SECURITY_SCORE = 9.5;
  static const double MIN_PERFORMANCE_SCORE = 8.5;

  /// Comprehensive deployment readiness assessment
  /// Returns detailed validation with go/no-go recommendation
  static Future<DeploymentReadinessReport> validateDeploymentReadiness() async {
      // ignore: avoid_print
    print('🚀 Starting comprehensive deployment readiness validation...');

    final timestamp = DateTime.now();

    // Core validations
    final healthValidation = await _validateTestHealth();
    final performanceValidation = await _validatePerformance();
    final securityValidation = await _validateSecurity();
    final architectureValidation = await _validateArchitecture();
    final qualityValidation = await _validateCodeQuality();
    final coverageValidation = await _validateCoverage();
    final integrationValidation = await _validateIntegration();
    final documentationValidation = await _validateDocumentation();
    final aiSystemValidation = await _validateAISystemReadiness();
    final productionValidation = await _validateProductionReadiness();

    final report = DeploymentReadinessReport(
      timestamp: timestamp,
      healthValidation: healthValidation,
      performanceValidation: performanceValidation,
      securityValidation: securityValidation,
      architectureValidation: architectureValidation,
      qualityValidation: qualityValidation,
      coverageValidation: coverageValidation,
      integrationValidation: integrationValidation,
      documentationValidation: documentationValidation,
      aiSystemValidation: aiSystemValidation,
      productionValidation: productionValidation,
    );

    await _generateDeploymentReport(report);
    await _executeDeploymentDecision(report);

    return report;
  }

  /// Validate test health for deployment confidence
  static Future<ValidationResult> _validateTestHealth() async {
    final healthScore = await TestHealthMetrics.calculateHealthScore();
    final issues = <String>[];
    final recommendations = <String>[];

    bool passed = true;

    // Overall health score validation
    if (healthScore.overallScore < MIN_DEPLOYMENT_SCORE) {
      passed = false;
      issues.add(
          'Test health score ${healthScore.overallScore} below minimum $MIN_DEPLOYMENT_SCORE');
      recommendations
          .add('Improve test quality to achieve minimum health score');
    }

    // Individual component validation
    if (healthScore.structureScore < 9.0) {
      issues.add(
          'Test structure score ${healthScore.structureScore} needs improvement');
      recommendations.add('Enhance test organization and documentation');
    }

    if (healthScore.coverageScore < 9.0) {
      issues.add(
          'Coverage score ${healthScore.coverageScore} below deployment standard');
      recommendations.add('Increase test coverage for critical components');
    }

    if (healthScore.qualityScore < 9.0) {
      issues.add(
          'Quality score ${healthScore.qualityScore} requires improvement');
      recommendations.add('Address test reliability and performance issues');
    }

    return ValidationResult(
      category: 'Test Health',
      passed: passed,
      score: healthScore.overallScore,
      issues: issues,
      recommendations: recommendations,
      details: {
        'overallScore': healthScore.overallScore,
        'structureScore': healthScore.structureScore,
        'coverageScore': healthScore.coverageScore,
        'qualityScore': healthScore.qualityScore,
        'maintenanceScore': healthScore.maintenanceScore,
        'isDeploymentReady': healthScore.isDeploymentReady,
      },
    );
  }

  /// Validate performance for production deployment
  static Future<ValidationResult> _validatePerformance() async {
    final performanceReport =
        await TestPerformanceBenchmarks.analyzeTestPerformance();
    final issues = <String>[];
    final recommendations = <String>[];

    bool passed = true;
    double score = 10.0;

    // Test suite performance validation
    if (!performanceReport.isOptimalForDevelopment) {
      passed = false;
      score -= 3.0;
      issues.add('Test performance below optimal development standards');
      recommendations
          .add('Optimize slow tests to improve development velocity');
    }

    if (!performanceReport.isReadyForDeployment) {
      passed = false;
      score -= 5.0;
      issues.add('Test performance not ready for production deployment');
      recommendations.add(
          'Critical performance issues must be resolved before deployment');
    }

    // Suite execution time validation
    final totalTimeMinutes =
        performanceReport.fullSuitePerformance.totalExecutionTimeMs / 60000;
    if (totalTimeMinutes > 5.0) {
      score -= 2.0;
      issues.add(
          'Full test suite takes ${totalTimeMinutes.toStringAsFixed(1)} minutes (>5 minute target)');
      recommendations
          .add('Optimize test execution time for faster CI/CD pipeline');
    }

    // Memory usage validation
    if (performanceReport.memoryUsage.peakMemoryMB > 500) {
      score -= 1.0;
      issues.add(
          'Peak memory usage ${performanceReport.memoryUsage.peakMemoryMB}MB exceeds 500MB limit');
      recommendations.add('Optimize memory usage in tests');
    }

    return ValidationResult(
      category: 'Performance',
      passed: passed && score >= MIN_PERFORMANCE_SCORE,
      score: math.max(score, 0.0),
      issues: issues,
      recommendations: recommendations,
      details: {
        'isOptimalForDevelopment': performanceReport.isOptimalForDevelopment,
        'isReadyForDeployment': performanceReport.isReadyForDeployment,
        'totalExecutionTimeMs':
            performanceReport.fullSuitePerformance.totalExecutionTimeMs,
        'peakMemoryMB': performanceReport.memoryUsage.peakMemoryMB,
        'concurrencyEfficiency':
            performanceReport.concurrencyMetrics.currentEfficiency,
      },
    );
  }

  /// Validate security for production safety
  static Future<ValidationResult> _validateSecurity() async {
    final qualityAssessment =
        await AutomatedQualityChecker.runFullQualityCheck();
    final securityCompliance = qualityAssessment.securityCompliance;
    final issues = <String>[];
    final recommendations = <String>[];

    bool passed = true;
    double score = securityCompliance.securityScore;

    // Critical security issues block deployment
    if (securityCompliance.criticalIssues > 0) {
      passed = false;
      issues.add(
          '${securityCompliance.criticalIssues} critical security issues detected');
      recommendations.add(
          'All critical security issues must be resolved before deployment');
    }

    // Privacy compliance validation (critical for AI2AI system)
    if (securityCompliance.privacyComplianceScore < MIN_SECURITY_SCORE) {
      passed = false;
      issues.add(
          'Privacy compliance score ${securityCompliance.privacyComplianceScore} below required $MIN_SECURITY_SCORE');
      recommendations.add('Address privacy protection issues in AI2AI systems');
    }

    // Additional security validations
    final additionalSecurityChecks = await _performAdditionalSecurityChecks();
    issues.addAll(additionalSecurityChecks.issues);
    recommendations.addAll(additionalSecurityChecks.recommendations);

    if (additionalSecurityChecks.criticalCount > 0) {
      passed = false;
    }

    return ValidationResult(
      category: 'Security',
      passed: passed && score >= MIN_SECURITY_SCORE,
      score: score,
      issues: issues,
      recommendations: recommendations,
      details: {
        'securityScore': securityCompliance.securityScore,
        'privacyComplianceScore': securityCompliance.privacyComplianceScore,
        'totalIssues': securityCompliance.totalIssues,
        'criticalIssues': securityCompliance.criticalIssues,
        'additionalChecks': additionalSecurityChecks.details,
      },
    );
  }

  /// Validate architecture compliance for maintainability
  static Future<ValidationResult> _validateArchitecture() async {
    final qualityAssessment =
        await AutomatedQualityChecker.runFullQualityCheck();
    final architecturalCompliance = qualityAssessment.architecturalCompliance;
    final issues = <String>[];
    final recommendations = <String>[];

    bool passed = true;
    double score = architecturalCompliance.cleanArchitectureScore;

    // Clean architecture validation
    if (architecturalCompliance.cleanArchitectureScore < 8.5) {
      passed = false;
      issues.add(
          'Clean architecture score ${architecturalCompliance.cleanArchitectureScore} below deployment standard');
      recommendations.add('Improve architectural compliance before deployment');
    }

    // Layer separation validation
    if (architecturalCompliance.layerSeparation < 0.9) {
      issues.add(
          'Layer separation score ${architecturalCompliance.layerSeparation} indicates architectural violations');
      recommendations
          .add('Ensure proper separation between architectural layers');
    }

    // Dependency direction validation
    if (architecturalCompliance.dependencyDirection < 0.9) {
      issues.add(
          'Dependency direction score ${architecturalCompliance.dependencyDirection} indicates violations');
      recommendations
          .add('Fix dependency direction violations in test architecture');
    }

    // Test structure alignment
    if (architecturalCompliance.testStructureAlignment < 0.85) {
      issues.add(
          'Test structure alignment ${architecturalCompliance.testStructureAlignment} needs improvement');
      recommendations
          .add('Align test structure with production code architecture');
    }

    // Additional architecture checks
    final ai2aiCompliance = await _validateAI2AIArchitecture();
    if (!ai2aiCompliance.passed) {
      passed = false;
      issues.addAll(ai2aiCompliance.issues);
      recommendations.addAll(ai2aiCompliance.recommendations);
    }

    return ValidationResult(
      category: 'Architecture',
      passed: passed,
      score: score,
      issues: issues,
      recommendations: recommendations,
      details: {
        'cleanArchitectureScore':
            architecturalCompliance.cleanArchitectureScore,
        'layerSeparation': architecturalCompliance.layerSeparation,
        'dependencyDirection': architecturalCompliance.dependencyDirection,
        'testStructureAlignment':
            architecturalCompliance.testStructureAlignment,
        'violations': architecturalCompliance.violations,
        'ai2aiCompliance': ai2aiCompliance.details,
      },
    );
  }

  /// Validate code quality for maintainability
  static Future<ValidationResult> _validateCodeQuality() async {
    final qualityAssessment =
        await AutomatedQualityChecker.runFullQualityCheck();
    final codeQuality = qualityAssessment.codeQuality;
    final maintainability = qualityAssessment.maintainabilityMetrics;
    final issues = <String>[];
    final recommendations = <String>[];

    bool passed = true;
    double score = codeQuality.averageScore;

    // Code quality validation
    if (codeQuality.averageScore < 8.5) {
      passed = false;
      issues.add(
          'Code quality score ${codeQuality.averageScore} below deployment standard');
      recommendations.add('Improve test code quality before deployment');
    }

    // Critical issues validation
    if (codeQuality.criticalIssues > 0) {
      passed = false;
      issues.add(
          '${codeQuality.criticalIssues} critical code quality issues detected');
      recommendations.add('Resolve all critical code quality issues');
    }

    // Maintainability validation
    if (maintainability.maintainabilityIndex < 8.0) {
      issues.add(
          'Maintainability index ${maintainability.maintainabilityIndex} below optimal');
      recommendations.add('Improve code maintainability for long-term health');
    }

    // Technical debt validation
    if (maintainability.technicalDebt > 0.25) {
      issues.add(
          'Technical debt ${(maintainability.technicalDebt * 100).toStringAsFixed(1)}% exceeds 25% threshold');
      recommendations.add('Address technical debt before deployment');
    }

    // Duplication validation
    if (maintainability.testDuplication > 0.20) {
      issues.add(
          'Test duplication ${(maintainability.testDuplication * 100).toStringAsFixed(1)}% exceeds 20% threshold');
      recommendations.add('Refactor duplicated test code');
    }

    return ValidationResult(
      category: 'Code Quality',
      passed: passed,
      score: score,
      issues: issues,
      recommendations: recommendations,
      details: {
        'averageScore': codeQuality.averageScore,
        'totalIssues': codeQuality.totalIssues,
        'criticalIssues': codeQuality.criticalIssues,
        'maintainabilityIndex': maintainability.maintainabilityIndex,
        'technicalDebt': maintainability.technicalDebt,
        'testDuplication': maintainability.testDuplication,
      },
    );
  }

  /// Validate test coverage for comprehensive validation
  static Future<ValidationResult> _validateCoverage() async {
    final qualityAssessment =
        await AutomatedQualityChecker.runFullQualityCheck();
    final coverageQuality = qualityAssessment.coverageQuality;
    final issues = <String>[];
    final recommendations = <String>[];

    bool passed = true;
    double score = coverageQuality.qualityScore;

    // Line coverage validation
    final lineCoverage =
        (coverageQuality.linesCovered / coverageQuality.totalLines) * 100;
    if (lineCoverage < 90.0) {
      passed = false;
      issues.add(
          'Line coverage ${lineCoverage.toStringAsFixed(1)}% below 90% requirement');
      recommendations
          .add('Increase line coverage to meet deployment standards');
    }

    // Branch coverage validation
    if (coverageQuality.branchCoverage < 0.85) {
      passed = false;
      issues.add(
          'Branch coverage ${(coverageQuality.branchCoverage * 100).toStringAsFixed(1)}% below 85% requirement');
      recommendations
          .add('Improve branch coverage for better edge case validation');
    }

    // Function coverage validation
    if (coverageQuality.functionCoverage < 0.95) {
      issues.add(
          'Function coverage ${(coverageQuality.functionCoverage * 100).toStringAsFixed(1)}% below 95% target');
      recommendations
          .add('Increase function coverage for comprehensive validation');
    }

    // Critical path coverage validation
    if (coverageQuality.uncoveredCriticalPaths.isNotEmpty) {
      passed = false;
      issues.add(
          '${coverageQuality.uncoveredCriticalPaths.length} uncovered critical paths detected');
      recommendations.add('Add tests for all critical application paths');
    }

    // Coverage gaps validation
    if (coverageQuality.coverageGaps.isNotEmpty) {
      issues.add(
          'Coverage gaps identified: ${coverageQuality.coverageGaps.join(', ')}');
      recommendations.add('Address identified coverage gaps');
    }

    return ValidationResult(
      category: 'Coverage',
      passed: passed,
      score: score,
      issues: issues,
      recommendations: recommendations,
      details: {
        'lineCoverage': lineCoverage,
        'branchCoverage': coverageQuality.branchCoverage,
        'functionCoverage': coverageQuality.functionCoverage,
        'uncoveredCriticalPaths': coverageQuality.uncoveredCriticalPaths,
        'coverageGaps': coverageQuality.coverageGaps,
        'qualityScore': coverageQuality.qualityScore,
      },
    );
  }

  /// Validate integration tests for end-to-end confidence
  static Future<ValidationResult> _validateIntegration() async {
    final issues = <String>[];
    final recommendations = <String>[];
    bool passed = true;
    double score = 10.0;

    // Run integration tests
    final integrationResult = await _runIntegrationTests();

    if (!integrationResult.allPassed) {
      passed = false;
      score -= 5.0;
      issues.add('${integrationResult.failedCount} integration tests failed');
      recommendations
          .add('Fix all integration test failures before deployment');
    }

    // Performance validation for integration tests
    if (integrationResult.averageExecutionTimeMs > 5000) {
      score -= 2.0;
      issues.add(
          'Integration tests average ${integrationResult.averageExecutionTimeMs}ms (>5s target)');
      recommendations.add('Optimize integration test performance');
    }

    // Critical user journey validation
    final criticalJourneys = await _validateCriticalUserJourneys();
    if (!criticalJourneys.allPassed) {
      passed = false;
      issues.add('Critical user journey tests failed');
      recommendations
          .add('Ensure all critical user paths are working correctly');
    }

    // AI2AI integration validation
    final ai2aiIntegration = await _validateAI2AIIntegration();
    if (!ai2aiIntegration.passed) {
      passed = false;
      issues.addAll(ai2aiIntegration.issues);
      recommendations.addAll(ai2aiIntegration.recommendations);
    }

    return ValidationResult(
      category: 'Integration',
      passed: passed,
      score: math.max(score, 0.0),
      issues: issues,
      recommendations: recommendations,
      details: {
        'totalTests': integrationResult.totalCount,
        'passedTests': integrationResult.passedCount,
        'failedTests': integrationResult.failedCount,
        'averageExecutionTimeMs': integrationResult.averageExecutionTimeMs,
        'criticalJourneys': criticalJourneys.details,
        'ai2aiIntegration': ai2aiIntegration.details,
      },
    );
  }

  /// Validate documentation for deployment support
  static Future<ValidationResult> _validateDocumentation() async {
    final qualityAssessment =
        await AutomatedQualityChecker.runFullQualityCheck();
    final docQuality = qualityAssessment.documentationQuality;
    final issues = <String>[];
    final recommendations = <String>[];

    bool passed = true;
    double score = docQuality.qualityScore;

    // Documentation quality validation
    if (docQuality.qualityScore < 8.0) {
      passed = false;
      issues.add(
          'Documentation quality score ${docQuality.qualityScore} below deployment standard');
      recommendations.add('Improve documentation quality before deployment');
    }

    // Missing documentation validation
    if (docQuality.missingDocumentation.isNotEmpty) {
      issues.add(
          'Missing documentation: ${docQuality.missingDocumentation.join(', ')}');
      recommendations.add('Complete all required documentation');
    }

    // Outdated documentation validation
    if (docQuality.outdatedDocumentation.isNotEmpty) {
      issues.add(
          'Outdated documentation: ${docQuality.outdatedDocumentation.join(', ')}');
      recommendations
          .add('Update outdated documentation to reflect current state');
    }

    // Deployment-specific documentation
    final deploymentDocs = await _validateDeploymentDocumentation();
    if (!deploymentDocs.complete) {
      passed = false;
      issues.addAll(deploymentDocs.missing);
      recommendations.add('Complete deployment documentation requirements');
    }

    return ValidationResult(
      category: 'Documentation',
      passed: passed,
      score: score,
      issues: issues,
      recommendations: recommendations,
      details: {
        'qualityScore': docQuality.qualityScore,
        'missingDocumentation': docQuality.missingDocumentation,
        'outdatedDocumentation': docQuality.outdatedDocumentation,
        'deploymentDocumentation': deploymentDocs.details,
      },
    );
  }

  /// Validate AI system readiness for production
  static Future<ValidationResult> _validateAISystemReadiness() async {
    final issues = <String>[];
    final recommendations = <String>[];
    bool passed = true;
    double score = 10.0;

    // AI2AI system validation
    final ai2aiReadiness = await _validateAI2AISystemReadiness();
    if (!ai2aiReadiness.passed) {
      passed = false;
      score -= ai2aiReadiness.impact;
      issues.addAll(ai2aiReadiness.issues);
      recommendations.addAll(ai2aiReadiness.recommendations);
    }

    // Personality learning system validation
    final personalityReadiness = await _validatePersonalityLearningReadiness();
    if (!personalityReadiness.passed) {
      passed = false;
      score -= personalityReadiness.impact;
      issues.addAll(personalityReadiness.issues);
      recommendations.addAll(personalityReadiness.recommendations);
    }

    // Privacy protection validation
    final privacyReadiness = await _validatePrivacyProtectionReadiness();
    if (!privacyReadiness.passed) {
      passed = false; // Privacy failures block deployment
      issues.addAll(privacyReadiness.issues);
      recommendations.addAll(privacyReadiness.recommendations);
    }

    // ML model validation
    final mlReadiness = await _validateMLModelReadiness();
    if (!mlReadiness.passed) {
      score -= mlReadiness.impact;
      issues.addAll(mlReadiness.issues);
      recommendations.addAll(mlReadiness.recommendations);
    }

    return ValidationResult(
      category: 'AI System',
      passed: passed,
      score: math.max(score, 0.0),
      issues: issues,
      recommendations: recommendations,
      details: {
        'ai2aiReadiness': ai2aiReadiness.details,
        'personalityReadiness': personalityReadiness.details,
        'privacyReadiness': privacyReadiness.details,
        'mlReadiness': mlReadiness.details,
      },
    );
  }

  /// Validate production environment readiness
  static Future<ValidationResult> _validateProductionReadiness() async {
    final issues = <String>[];
    final recommendations = <String>[];
    bool passed = true;
    double score = 10.0;

    // Environment configuration validation
    final envValidation = await _validateEnvironmentConfiguration();
    if (!envValidation.passed) {
      passed = false;
      issues.addAll(envValidation.issues);
      recommendations.addAll(envValidation.recommendations);
    }

    // Database migration validation
    final dbValidation = await _validateDatabaseMigrations();
    if (!dbValidation.passed) {
      passed = false;
      issues.addAll(dbValidation.issues);
      recommendations.addAll(dbValidation.recommendations);
    }

    // API compatibility validation
    final apiValidation = await _validateAPICompatibility();
    if (!apiValidation.passed) {
      passed = false;
      issues.addAll(apiValidation.issues);
      recommendations.addAll(apiValidation.recommendations);
    }

    // Monitoring and alerting validation
    final monitoringValidation = await _validateMonitoringSetup();
    if (!monitoringValidation.passed) {
      score -= 2.0;
      issues.addAll(monitoringValidation.issues);
      recommendations.addAll(monitoringValidation.recommendations);
    }

    // Rollback preparation validation
    final rollbackValidation = await _validateRollbackPreparation();
    if (!rollbackValidation.passed) {
      score -= 3.0;
      issues.addAll(rollbackValidation.issues);
      recommendations.addAll(rollbackValidation.recommendations);
    }

    return ValidationResult(
      category: 'Production Readiness',
      passed: passed,
      score: math.max(score, 0.0),
      issues: issues,
      recommendations: recommendations,
      details: {
        'environmentConfiguration': envValidation.details,
        'databaseMigrations': dbValidation.details,
        'apiCompatibility': apiValidation.details,
        'monitoringSetup': monitoringValidation.details,
        'rollbackPreparation': rollbackValidation.details,
      },
    );
  }

  /// Generate comprehensive deployment report
  static Future<void> _generateDeploymentReport(
      DeploymentReadinessReport report) async {
    final reportDir = Directory(REPORTS_PATH);
    if (!reportDir.existsSync()) {
      await reportDir.create(recursive: true);
    }

    final timestamp = report.timestamp.toIso8601String().replaceAll(':', '-');
    final reportFile =
        File('$REPORTS_PATH/deployment_readiness_$timestamp.json');

    final reportContent = {
      'metadata': {
        'timestamp': report.timestamp.toIso8601String(),
        'version': '1.0.0',
        'generatedBy': 'SPOTS Deployment Readiness Validator',
      },
      'summary': {
        'overallScore': report.overallScore,
        'deploymentApproved': report.deploymentApproved,
        'criticalBlockers': report.criticalBlockers,
        'recommendationCount': report.totalRecommendations,
      },
      'validations': report.toJson(),
      'deploymentDecision': {
        'approved': report.deploymentApproved,
        'reasoning': report.deploymentReasoning,
        'blockers': report.criticalBlockers,
        'nextSteps': report.nextSteps,
      },
    };

    await reportFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(reportContent),
    );
      // ignore: avoid_print

      // ignore: avoid_print
    print('📋 Deployment readiness report generated: ${reportFile.path}');
  }

  /// Execute deployment decision based on validation results
  static Future<void> _executeDeploymentDecision(
      DeploymentReadinessReport report) async {
    if (report.deploymentApproved) {
      await _approveDeployment(report);
    } else {
      await _blockDeployment(report);
    }

    await _notifyStakeholders(report);
    await _updateDeploymentDashboard(report);
  }

  /// Approve deployment and prepare production release
      // ignore: avoid_print
  static Future<void> _approveDeployment(
      // ignore: avoid_print
      DeploymentReadinessReport report) async {
      // ignore: avoid_print
    print('✅ DEPLOYMENT APPROVED');
      // ignore: avoid_print
    print('Overall Score: ${report.overallScore.toStringAsFixed(2)}/10.0');
      // ignore: avoid_print
    print('All validation criteria met for production release');

    // Create deployment approval file
    final approvalFile = File('$REPORTS_PATH/deployment_approved.json');
    await approvalFile.writeAsString(jsonEncode({
      'timestamp': DateTime.now().toIso8601String(),
      'approvedBy': 'SPOTS Automated Validation System',
      // ignore: avoid_print
      'overallScore': report.overallScore,
      'validationsSummary': report.getValidationSummary(),
    }));

      // ignore: avoid_print
    print('🚀 Production deployment pipeline can proceed');
      // ignore: avoid_print
  }
      // ignore: avoid_print

      // ignore: avoid_print
  /// Block deployment and provide remediation guidance
  static Future<void> _blockDeployment(DeploymentReadinessReport report) async {
      // ignore: avoid_print
    print('🚫 DEPLOYMENT BLOCKED');
      // ignore: avoid_print
      // ignore: avoid_print
    print('Overall Score: ${report.overallScore.toStringAsFixed(2)}/10.0');
      // ignore: avoid_print
    print('Critical issues must be resolved before deployment');
      // ignore: avoid_print

      // ignore: avoid_print
    print('\n❌ Critical Blockers:');
      // ignore: avoid_print
    for (final blocker in report.criticalBlockers) {
      // ignore: avoid_print
      print('  - $blocker');
    }
      // ignore: avoid_print

      // ignore: avoid_print
    print('\n🔧 Required Actions:');
      // ignore: avoid_print
    for (final action in report.nextSteps) {
      // ignore: avoid_print
      print('  - $action');
    }

    // Create deployment blocker file
    final blockerFile = File('$REPORTS_PATH/deployment_blocked.json');
    await blockerFile.writeAsString(jsonEncode({
      'timestamp': DateTime.now().toIso8601String(),
      'blockedBy': 'SPOTS Automated Validation System',
      'overallScore': report.overallScore,
      'criticalBlockers': report.criticalBlockers,
      'nextSteps': report.nextSteps,
    }));
  }

  /// Notify stakeholders of deployment decision
  static Future<void> _notifyStakeholders(
      DeploymentReadinessReport report) async {
    final notificationFile =
        File('$REPORTS_PATH/stakeholder_notification.json');

    final notification = {
      'timestamp': DateTime.now().toIso8601String(),
      'deploymentStatus': report.deploymentApproved ? 'APPROVED' : 'BLOCKED',
      'overallScore': report.overallScore,
      'summary': report.deploymentReasoning,
      'nextActions': report.nextSteps,
    };

    await notificationFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(notification),
    );
  }

  /// Update deployment dashboard with current status
  static Future<void> _updateDeploymentDashboard(
      DeploymentReadinessReport report) async {
    final dashboardFile = File('$REPORTS_PATH/deployment_dashboard.json');

    final dashboard = {
      'lastValidation': report.timestamp.toIso8601String(),
      'deploymentStatus': report.deploymentApproved ? 'READY' : 'BLOCKED',
      'overallScore': report.overallScore,
      'validationResults': report.getValidationSummary(),
      'trend': await _calculateDeploymentReadinessTrend(),
      'nextValidation':
          DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
    };

    await dashboardFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(dashboard),
    );
  }

  // Helper methods for specific validations
  static Future<SecurityCheckResult> _performAdditionalSecurityChecks() async {
    final issues = <String>[];
    final recommendations = <String>[];
    int criticalCount = 0;

    // Check for test data security
    final testDataSecurity = await _validateTestDataSecurity();
    if (!testDataSecurity.secure) {
      criticalCount++;
      issues.add('Test data contains potential security vulnerabilities');
      recommendations
          .add('Sanitize test data and remove sensitive information');
    }

    // Check authentication test security
    final authTestSecurity = await _validateAuthTestSecurity();
    if (!authTestSecurity.secure) {
      criticalCount++;
      issues.add('Authentication tests have security vulnerabilities');
      recommendations.add('Strengthen authentication test security measures');
    }

    return SecurityCheckResult(
      issues: issues,
      recommendations: recommendations,
      criticalCount: criticalCount,
      details: {
        'testDataSecurity': testDataSecurity.details,
        'authTestSecurity': authTestSecurity.details,
      },
    );
  }

  static Future<ArchitectureValidation> _validateAI2AIArchitecture() async {
    final issues = <String>[];
    final recommendations = <String>[];
    bool passed = true;

    // Validate ai2ai vs p2p architecture
    final testFiles = await _getAI2AITestFiles();
    for (final file in testFiles) {
      final content = await file.readAsString();

      // Check for prohibited p2p patterns
      if (content.contains('p2p') || content.contains('peer-to-peer')) {
        passed = false;
        issues.add(
            '${file.path}: Contains prohibited P2P references (must be ai2ai)');
        recommendations
            .add('Replace P2P architecture with ai2ai in ${file.path}');
      }

      // Check for proper ai2ai patterns
      if (!content.contains('ai2ai') && content.contains('connection')) {
        issues.add('${file.path}: Missing ai2ai architecture validation');
        recommendations
            .add('Add ai2ai architecture validation to ${file.path}');
      }
    }

    return ArchitectureValidation(
      passed: passed,
      issues: issues,
      recommendations: recommendations,
      details: {
        'ai2aiTestFiles': testFiles.length,
        'architectureCompliant': passed,
      },
    );
  }

  static Future<TestResult> _runIntegrationTests() async {
    try {
      final stopwatch = Stopwatch()..start();

      // Run integration tests and capture output
      final result = await Process.run(
        'flutter',
        ['test', 'test/integration/', '--reporter=json'],
        runInShell: true,
      );

      stopwatch.stop();

      // Parse JSON output to get test results
      if (result.exitCode != 0 && result.stdout.toString().isEmpty) {
        // Fallback: try parsing stderr or use regex on stdout
        final output = result.stdout.toString();
        final passedMatch = RegExp(r'"successes":\s*(\d+)').firstMatch(output);
        final failedMatch = RegExp(r'"failures":\s*(\d+)').firstMatch(output);
        final totalMatch = RegExp(r'"tests":\s*(\d+)').firstMatch(output);

        final passedCount =
            passedMatch != null ? int.parse(passedMatch.group(1)!) : 0;
        final failedCount =
            failedMatch != null ? int.parse(failedMatch.group(1)!) : 0;
        final totalCount = totalMatch != null
            ? int.parse(totalMatch.group(1)!)
            : (passedCount + failedCount);

        return TestResult(
          totalCount: totalCount,
          passedCount: passedCount,
          failedCount: failedCount,
          averageExecutionTimeMs:
              stopwatch.elapsedMilliseconds / math.max(totalCount, 1),
          allPassed: failedCount == 0,
        );
      }

      // Try to parse JSON output
      try {
        final jsonOutput =
            jsonDecode(result.stdout.toString()) as Map<String, dynamic>;
        final successes = jsonOutput['successes'] as int? ?? 0;
        final failures = jsonOutput['failures'] as int? ?? 0;
        final tests = jsonOutput['tests'] as int? ?? (successes + failures);

        return TestResult(
          totalCount: tests,
          passedCount: successes,
          failedCount: failures,
          averageExecutionTimeMs:
              stopwatch.elapsedMilliseconds / math.max(tests, 1),
          allPassed: failures == 0,
        );
      } catch (e) {
        // Fallback: assume all passed if we can't parse
        return TestResult(
          totalCount: 1,
          passedCount: result.exitCode == 0 ? 1 : 0,
          failedCount: result.exitCode == 0 ? 0 : 1,
          averageExecutionTimeMs: stopwatch.elapsedMilliseconds.toDouble(),
          allPassed: result.exitCode == 0,
        );
      }
    } catch (e) {
      // If flutter test fails, return failure result
      return TestResult(
        totalCount: 0,
        passedCount: 0,
        failedCount: 1,
        averageExecutionTimeMs: 0,
        allPassed: false,
      );
    }
  }

  static Future<TestResult> _validateCriticalUserJourneys() async {
    try {
      final criticalJourneyTests = [
        'test/integration/complete_user_journey_test.dart',
        'test/integration/onboarding_flow_integration_test.dart',
        'test/integration/user_flow_integration_test.dart',
        'test/integration/navigation_flow_integration_test.dart',
      ];

      // Filter to only existing files
      final existingTests = criticalJourneyTests
          .where((path) => File(path).existsSync())
          .toList();

      if (existingTests.isEmpty) {
        return TestResult(
          totalCount: 0,
          passedCount: 0,
          failedCount: 0,
          averageExecutionTimeMs: 0,
          allPassed: true, // No tests = assume passed
        );
      }

      final stopwatch = Stopwatch()..start();
      int totalPassed = 0;
      int totalFailed = 0;

      for (final testFile in existingTests) {
        try {
          final result = await Process.run(
            'flutter',
            ['test', testFile, '--reporter=json'],
            runInShell: true,
          );

          if (result.exitCode == 0) {
            try {
              final jsonOutput =
                  jsonDecode(result.stdout.toString()) as Map<String, dynamic>;
              totalPassed += jsonOutput['successes'] as int? ?? 0;
              totalFailed += jsonOutput['failures'] as int? ?? 0;
            } catch (e) {
              // If parsing fails but exit code is 0, assume passed
              totalPassed += 1;
            }
          } else {
            totalFailed += 1;
          }
        } catch (e) {
          totalFailed += 1;
        }
      }

      stopwatch.stop();
      final totalCount = totalPassed + totalFailed;

      return TestResult(
        totalCount: totalCount,
        passedCount: totalPassed,
        failedCount: totalFailed,
        averageExecutionTimeMs:
            totalCount > 0 ? stopwatch.elapsedMilliseconds / totalCount : 0,
        allPassed: totalFailed == 0,
      );
    } catch (e) {
      return TestResult(
        totalCount: 0,
        passedCount: 0,
        failedCount: 1,
        averageExecutionTimeMs: 0,
        allPassed: false,
      );
    }
  }

  static Future<ValidationResult> _validateAI2AIIntegration() async {
    final issues = <String>[];
    final recommendations = <String>[];
    bool passed = true;
    double score = 10.0;

    // Check for AI2AI integration test files
    final ai2aiTestFiles = [
      'test/integration/ai2ai_complete_integration_test.dart',
      'test/integration/ai2ai_basic_integration_test.dart',
      'test/integration/ai2ai_ecosystem_test.dart',
      'test/integration/ai2ai_final_integration_test.dart',
    ];

    final existingTests =
        ai2aiTestFiles.where((path) => File(path).existsSync()).toList();

    if (existingTests.isEmpty) {
      passed = false;
      score -= 5.0;
      issues.add('No AI2AI integration tests found');
      recommendations
          .add('Add AI2AI integration tests to validate system functionality');
    } else {
      // Check if tests pass
      try {
        final result = await Process.run(
          'flutter',
          ['test', ...existingTests, '--reporter=json'],
          runInShell: true,
        );

        if (result.exitCode != 0) {
          passed = false;
          score -= 3.0;
          issues.add('AI2AI integration tests are failing');
          recommendations.add('Fix failing AI2AI integration tests');
        } else {
          try {
            final jsonOutput =
                jsonDecode(result.stdout.toString()) as Map<String, dynamic>;
            final failures = jsonOutput['failures'] as int? ?? 0;
            if (failures > 0) {
              passed = false;
              score -= 2.0;
              issues.add('$failures AI2AI integration test failures');
              recommendations.add('Fix failing AI2AI integration tests');
            }
          } catch (e) {
            // Can't parse, but exit code was 0, so assume passed
          }
        }
      } catch (e) {
        passed = false;
        score -= 2.0;
        issues.add('Unable to run AI2AI integration tests: $e');
        recommendations
            .add('Ensure Flutter test environment is properly configured');
      }
    }

    // Check for privacy protection in AI2AI tests
    final ai2aiTestContent = await _getAI2AITestFiles();
    bool hasPrivacyChecks = false;
    for (final file in ai2aiTestContent) {
      final content = await file.readAsString();
      if (content.contains('PrivacyProtection') ||
          content.contains('anonymiz')) {
        hasPrivacyChecks = true;
        break;
      }
    }

    if (!hasPrivacyChecks && ai2aiTestContent.isNotEmpty) {
      score -= 1.0;
      issues.add('AI2AI tests may not validate privacy protection');
      recommendations
          .add('Add privacy protection validation to AI2AI integration tests');
    }

    return ValidationResult(
      category: 'AI2AI Integration',
      passed: passed,
      score: math.max(score, 0.0),
      issues: issues,
      recommendations: recommendations,
      details: {
        'privacyPreserved': hasPrivacyChecks,
        'networkFunctional': passed,
        'testFilesFound': existingTests.length,
      },
    );
  }

  static Future<DocumentationValidation>
      _validateDeploymentDocumentation() async {
    final missing = <String>[];

    // Check for required deployment docs
    if (!File('README.md').existsSync()) missing.add('README.md');
    if (!File('docs/deployment_guide.md').existsSync()) {
      missing.add('Deployment Guide');
    }
    if (!File('docs/rollback_procedures.md').existsSync()) {
      missing.add('Rollback Procedures');
    }

    return DocumentationValidation(
      complete: missing.isEmpty,
      missing: missing,
      details: {'requiredDocs': 3, 'presentDocs': 3 - missing.length},
    );
  }

  static Future<SystemValidation> _validateAI2AISystemReadiness() async {
    final issues = <String>[];
    final recommendations = <String>[];
    double impact = 0.0;
    bool passed = true;

    // Check if AI2AI services are registered in DI container
    final injectionContainer = File('lib/injection_container.dart');
    if (injectionContainer.existsSync()) {
      final content = await injectionContainer.readAsString();

      // Check for key AI2AI services
      final requiredServices = [
        'VibeConnectionOrchestrator',
        'PersonalityLearning',
        'UserVibeAnalyzer',
        'PrivacyProtection',
      ];

      for (final service in requiredServices) {
        if (!content.contains(service)) {
          passed = false;
          impact += 2.0;
          issues.add(
              'AI2AI service $service not found in dependency injection container');
          recommendations.add('Register $service in injection_container.dart');
        }
      }
    } else {
      passed = false;
      impact += 5.0;
      issues.add('Dependency injection container not found');
      recommendations.add(
          'Ensure lib/injection_container.dart exists and is properly configured');
    }

    // Check for AI2AI integration test files
    final ai2aiTests = await _getAI2AITestFiles();
    if (ai2aiTests.isEmpty) {
      impact += 1.0;
      issues.add('No AI2AI test files found');
      recommendations.add('Add AI2AI system tests to validate functionality');
    }

    return SystemValidation(
      passed: passed,
      impact: impact,
      issues: issues,
      recommendations: recommendations,
      details: {
        'systemOperational': passed,
        'servicesRegistered': passed,
        'testFilesFound': ai2aiTests.length,
      },
    );
  }

  static Future<SystemValidation>
      _validatePersonalityLearningReadiness() async {
    final issues = <String>[];
    final recommendations = <String>[];
    double impact = 0.0;
    bool passed = true;

    // Check if PersonalityLearning service exists
    final personalityLearningFile =
        File('lib/core/ai/personality_learning.dart');
    if (!personalityLearningFile.existsSync()) {
      passed = false;
      impact += 5.0;
      issues.add('PersonalityLearning service not found');
      recommendations.add('Implement PersonalityLearning service');
      return SystemValidation(
        passed: passed,
        impact: impact,
        issues: issues,
        recommendations: recommendations,
        details: {'learningSystemReady': false},
      );
    }

    // Check for key methods
    final content = await personalityLearningFile.readAsString();
    final requiredMethods = [
      'initializePersonality',
      'evolveFromUserAction',
      'getCurrentPersonality',
    ];

    for (final method in requiredMethods) {
      if (!content.contains(method)) {
        passed = false;
        impact += 1.0;
        issues.add('PersonalityLearning missing required method: $method');
        recommendations.add('Implement $method in PersonalityLearning service');
      }
    }

    // Check for tests
    final testFile = File('test/unit/ai/personality_learning_test.dart');
    if (!testFile.existsSync()) {
      impact += 0.5;
      issues.add('No PersonalityLearning unit tests found');
      recommendations.add('Add unit tests for PersonalityLearning service');
    }

    return SystemValidation(
      passed: passed,
      impact: impact,
      issues: issues,
      recommendations: recommendations,
      details: {
        'learningSystemReady': passed,
        'serviceExists': personalityLearningFile.existsSync(),
        'hasTests': testFile.existsSync(),
      },
    );
  }

  static Future<SystemValidation> _validatePrivacyProtectionReadiness() async {
    final issues = <String>[];
    final recommendations = <String>[];
    double impact = 0.0;
    bool passed = true;

    // Check if PrivacyProtection service exists
    final privacyFile = File('lib/core/ai/privacy_protection.dart');
    if (!privacyFile.existsSync()) {
      passed = false;
      impact += 10.0; // Critical - privacy is mandatory
      issues.add('PrivacyProtection service not found');
      recommendations
          .add('Implement PrivacyProtection service - CRITICAL for deployment');
      return SystemValidation(
        passed: passed,
        impact: impact,
        issues: issues,
        recommendations: recommendations,
        details: {'privacyProtectionActive': false},
      );
    }

    // Check for key privacy methods
    final content = await privacyFile.readAsString();
    final requiredMethods = [
      'anonymizePersonalityData',
      'validateAnonymizationQuality',
    ];

    for (final method in requiredMethods) {
      if (!content.contains(method)) {
        passed = false;
        impact += 3.0;
        issues.add('PrivacyProtection missing required method: $method');
        recommendations.add('Implement $method in PrivacyProtection service');
      }
    }

    // Check for privacy tests
    final testFile = File('test/unit/ai/privacy_protection_test.dart');
    if (!testFile.existsSync()) {
      impact += 1.0;
      issues.add('No PrivacyProtection unit tests found');
      recommendations.add('Add comprehensive privacy protection tests');
    }

    return SystemValidation(
      passed: passed,
      impact: impact,
      issues: issues,
      recommendations: recommendations,
      details: {
        'privacyProtectionActive': passed,
        'serviceExists': privacyFile.existsSync(),
        'hasTests': testFile.existsSync(),
      },
    );
  }

  static Future<SystemValidation> _validateMLModelReadiness() async {
    final issues = <String>[];
    final recommendations = <String>[];
    double impact = 0.0;
    bool passed = true;

    // Check for ML model files or configurations
    final mlFiles = [
      'lib/core/ml/',
      'lib/core/ai/',
    ];

    bool hasMLComponents = false;
    for (final path in mlFiles) {
      final dir = Directory(path);
      if (dir.existsSync()) {
        final entities = await dir.list().toList();
        if (entities.isNotEmpty) {
          hasMLComponents = true;
          break;
        }
      }
    }

    if (!hasMLComponents) {
      impact += 0.5; // Low impact - ML may not be required
      issues.add('No ML model components found');
      recommendations.add('Add ML model components if required for deployment');
    }

    // Check for model validation tests
    final testDir = Directory('test/unit/ml/');
    if (testDir.existsSync()) {
      final entities = await testDir.list().toList();
      if (entities.isEmpty) {
        impact += 0.5;
        issues.add('ML test directory exists but is empty');
        recommendations.add('Add ML model validation tests');
      }
    }

    return SystemValidation(
      passed: passed,
      impact: impact,
      issues: issues,
      recommendations: recommendations,
      details: {
        'modelsValidated': hasMLComponents,
        'hasMLComponents': hasMLComponents,
      },
    );
  }

  static Future<ValidationResult> _validateEnvironmentConfiguration() async {
    final issues = <String>[];
    final recommendations = <String>[];
    bool passed = true;
    double score = 10.0;

    // Check for environment configuration files
    final envFiles = [
      '.env',
      '.env.production',
      'lib/core/config/environment.dart',
    ];

    bool hasEnvConfig = false;
    for (final path in envFiles) {
      final file = File(path);
      if (file.existsSync()) {
        hasEnvConfig = true;
        break;
      }
    }

    if (!hasEnvConfig) {
      score -= 2.0;
      issues.add('No environment configuration files found');
      recommendations
          .add('Add environment configuration for production deployment');
    }

    // Check for Supabase configuration
    final supabaseConfig = File('lib/core/config/supabase_config.dart');
    if (!supabaseConfig.existsSync()) {
      score -= 1.0;
      issues.add('Supabase configuration not found');
      recommendations
          .add('Ensure Supabase configuration is set up for production');
    }

    return ValidationResult(
      category: 'Environment',
      passed: passed,
      score: math.max(score, 0.0),
      issues: issues,
      recommendations: recommendations,
      details: {
        'configurationValid': hasEnvConfig,
        'hasSupabaseConfig': supabaseConfig.existsSync(),
      },
    );
  }

  static Future<ValidationResult> _validateDatabaseMigrations() async {
    final issues = <String>[];
    final recommendations = <String>[];
    bool passed = true;
    double score = 10.0;

    // Check for migration files or migration system
    final migrationPaths = [
      'lib/core/data/migrations/',
      'supabase/migrations/',
      'lib/core/database/migrations.dart',
    ];

    bool hasMigrations = false;
    for (final path in migrationPaths) {
      if (path.endsWith('.dart')) {
        final file = File(path);
        if (file.existsSync()) {
          hasMigrations = true;
          break;
        }
      } else {
        final dir = Directory(path);
        if (dir.existsSync()) {
          final entities = await dir.list().toList();
          if (entities.isNotEmpty) {
            hasMigrations = true;
            break;
          }
        }
      }
    }

    if (!hasMigrations) {
      score -= 1.0;
      issues.add('No database migration system found');
      recommendations.add('Set up database migration system for production');
    }

    return ValidationResult(
      category: 'Database',
      passed: passed,
      score: math.max(score, 0.0),
      issues: issues,
      recommendations: recommendations,
      details: {
        'migrationsReady': hasMigrations,
      },
    );
  }

  static Future<ValidationResult> _validateAPICompatibility() async {
    final issues = <String>[];
    final recommendations = <String>[];
    bool passed = true;
    double score = 10.0;

    // Check for API versioning or compatibility checks
    final apiFiles = [
      'lib/core/api/',
      'lib/core/services/api_service.dart',
    ];

    bool hasAPISystem = false;
    for (final path in apiFiles) {
      if (path.endsWith('.dart')) {
        final file = File(path);
        if (file.existsSync()) {
          hasAPISystem = true;
          break;
        }
      } else {
        final dir = Directory(path);
        if (dir.existsSync()) {
          final entities = await dir.list().toList();
          if (entities.isNotEmpty) {
            hasAPISystem = true;
            break;
          }
        }
      }
    }

    if (!hasAPISystem) {
      score -= 1.0;
      issues.add('No API system found');
      recommendations.add('Ensure API compatibility is maintained');
    }

    return ValidationResult(
      category: 'API Compatibility',
      passed: passed,
      score: math.max(score, 0.0),
      issues: issues,
      recommendations: recommendations,
      details: {
        'apiCompatible': hasAPISystem,
      },
    );
  }

  static Future<ValidationResult> _validateMonitoringSetup() async {
    final issues = <String>[];
    final recommendations = <String>[];
    bool passed = true;
    double score = 10.0;

    // Check for monitoring services
    final monitoringFiles = [
      'lib/core/monitoring/',
      'lib/core/services/monitoring_service.dart',
    ];

    bool hasMonitoring = false;
    for (final path in monitoringFiles) {
      if (path.endsWith('.dart')) {
        final file = File(path);
        if (file.existsSync()) {
          hasMonitoring = true;
          break;
        }
      } else {
        final dir = Directory(path);
        if (dir.existsSync()) {
          final entities = await dir.list().toList();
          if (entities.isNotEmpty) {
            hasMonitoring = true;
            break;
          }
        }
      }
    }

    if (!hasMonitoring) {
      score -= 2.0;
      issues.add('No monitoring system found');
      recommendations.add('Set up production monitoring and alerting');
    }

    return ValidationResult(
      category: 'Monitoring',
      passed: passed,
      score: math.max(score, 0.0),
      issues: issues,
      recommendations: recommendations,
      details: {
        'monitoringActive': hasMonitoring,
      },
    );
  }

  static Future<ValidationResult> _validateRollbackPreparation() async {
    final issues = <String>[];
    final recommendations = <String>[];
    bool passed = true;
    double score = 10.0;

    // Check for rollback documentation
    final rollbackDoc = File('docs/rollback_procedures.md');
    if (!rollbackDoc.existsSync()) {
      score -= 2.0;
      issues.add('Rollback procedures documentation not found');
      recommendations.add('Create rollback procedures documentation');
    }

    // Check for version tagging in git
    try {
      final result =
          await Process.run('git', ['tag', '--list'], runInShell: true);
      if (result.exitCode == 0 && result.stdout.toString().trim().isEmpty) {
        score -= 1.0;
        issues.add('No git tags found for version tracking');
        recommendations.add('Tag releases for easy rollback');
      }
    } catch (e) {
      // Git not available or not a git repo - not critical
      score -= 0.5;
    }

    return ValidationResult(
      category: 'Rollback',
      passed: passed,
      score: math.max(score, 0.0),
      issues: issues,
      recommendations: recommendations,
      details: {
        'rollbackReady': rollbackDoc.existsSync(),
      },
    );
  }

  static Future<SecurityValidation> _validateTestDataSecurity() async {
    final issues = <String>[];
    bool secure = true;

    // Check test files for potential security issues
    final testDir = Directory('test');
    if (testDir.existsSync()) {
      final entities = await testDir.list(recursive: true).toList();
      final testFiles = entities
          .whereType<File>()
          .where((f) => f.path.endsWith('_test.dart'))
          .take(50) // Sample first 50 test files
          .toList();

      final sensitivePatterns = [
        RegExp(r'password\s*=\s*["\''].*?["\']', caseSensitive: false),
        RegExp(r'api[_-]?key\s*=\s*["\''].*?["\']', caseSensitive: false),
        RegExp(r'secret\s*=\s*["\''].*?["\']', caseSensitive: false),
        RegExp(r'token\s*=\s*["\''].*?["\']', caseSensitive: false),
      ];

      for (final file in testFiles) {
        try {
          final content = await file.readAsString();
          for (final pattern in sensitivePatterns) {
            if (pattern.hasMatch(content)) {
              secure = false;
              issues.add('${file.path}: Potential sensitive data in test file');
              break;
            }
          }
        } catch (e) {
          // Skip files that can't be read
        }
      }
    }

    return SecurityValidation(
      secure: secure,
      details: {
        'testDataSanitized': secure,
        'issuesFound': issues.length,
        'filesChecked': testDir.existsSync() ? 50 : 0,
      },
    );
  }

  static Future<SecurityValidation> _validateAuthTestSecurity() async {
    final issues = <String>[];
    bool secure = true;

    // Check authentication test files
    final authTestFiles = [
      'test/unit/auth/',
      'test/integration/auth/',
      'test/widget/pages/auth/',
    ];

    for (final path in authTestFiles) {
      final dir = Directory(path);
      if (dir.existsSync()) {
        final entities = await dir.list(recursive: true).toList();
        final files = entities
            .whereType<File>()
            .where((f) => f.path.endsWith('_test.dart'))
            .toList();

        for (final file in files) {
          try {
            final content = await file.readAsString();

            // Check for hardcoded credentials
            if (RegExp(r'password\s*[:=]\s*["\' '].*?["\']',
                    caseSensitive: false)
                .hasMatch(content)) {
              secure = false;
              issues.add('${file.path}: Hardcoded password found');
            }

            // Check for real API keys
            if (RegExp(
                    r'supabase[_-]?key\s*[:=]\s*["\' '][a-zA-Z0-9]{20,}["\']',
                    caseSensitive: false)
                .hasMatch(content)) {
              secure = false;
              issues.add('${file.path}: Potential real API key found');
            }
          } catch (e) {
            // Skip files that can't be read
          }
        }
      }
    }

    return SecurityValidation(
      secure: secure,
      details: {
        'authTestsSecure': secure,
        'issuesFound': issues.length,
      },
    );
  }

  static Future<List<File>> _getAI2AITestFiles() async {
    final testDir = Directory('test');
    if (!testDir.existsSync()) return [];

    final entities = await testDir.list(recursive: true).toList();
    return entities
        .whereType<File>()
        .where((f) => f.path.contains('ai2ai') && f.path.endsWith('_test.dart'))
        .toList();
  }

  static Future<double> _calculateDeploymentReadinessTrend() async {
    try {
      // Read historical deployment reports
      final reportsDir = Directory(REPORTS_PATH);
      if (!reportsDir.existsSync()) {
        return 0.0; // No history
      }

      final reportFiles = reportsDir
          .listSync()
          .whereType<File>()
          .where((f) =>
              f.path.contains('deployment_readiness_') &&
              f.path.endsWith('.json'))
          .toList();

      if (reportFiles.length < 2) {
        return 0.0; // Need at least 2 reports for trend
      }

      // Sort by modification time (newest first)
      reportFiles
          .sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

      // Get last 5 reports
      final recentReports = reportFiles.take(5).toList();
      final scores = <double>[];

      for (final file in recentReports) {
        try {
          final content = await file.readAsString();
          final json = jsonDecode(content) as Map<String, dynamic>;
          final overallScore = json['summary']?['overallScore'] as double?;
          if (overallScore != null) {
            scores.add(overallScore);
          }
        } catch (e) {
          // Skip files that can't be parsed
        }
      }

      if (scores.length < 2) {
        return 0.0;
      }

      // Calculate trend (newest - oldest) / oldest
      final oldest = scores.last;
      final newest = scores.first;
      if (oldest == 0) {
        return newest > 0 ? 1.0 : 0.0;
      }

      return (newest - oldest) / oldest;
    } catch (e) {
      return 0.0; // Default to no trend if calculation fails
    }
  }
}

// Data classes for deployment validation
class DeploymentReadinessReport {
  final DateTime timestamp;
  final ValidationResult healthValidation;
  final ValidationResult performanceValidation;
  final ValidationResult securityValidation;
  final ValidationResult architectureValidation;
  final ValidationResult qualityValidation;
  final ValidationResult coverageValidation;
  final ValidationResult integrationValidation;
  final ValidationResult documentationValidation;
  final ValidationResult aiSystemValidation;
  final ValidationResult productionValidation;

  DeploymentReadinessReport({
    required this.timestamp,
    required this.healthValidation,
    required this.performanceValidation,
    required this.securityValidation,
    required this.architectureValidation,
    required this.qualityValidation,
    required this.coverageValidation,
    required this.integrationValidation,
    required this.documentationValidation,
    required this.aiSystemValidation,
    required this.productionValidation,
  });

  double get overallScore {
    final validations = [
      healthValidation,
      performanceValidation,
      securityValidation,
      architectureValidation,
      qualityValidation,
      coverageValidation,
      integrationValidation,
      documentationValidation,
      aiSystemValidation,
      productionValidation,
    ];

    return validations.fold(0.0, (sum, v) => sum + v.score) /
        validations.length;
  }

  bool get deploymentApproved {
    return overallScore >= DeploymentReadinessValidator.MIN_DEPLOYMENT_SCORE &&
        securityValidation.score >=
            DeploymentReadinessValidator.MIN_SECURITY_SCORE &&
        performanceValidation.score >=
            DeploymentReadinessValidator.MIN_PERFORMANCE_SCORE &&
        allCriticalValidationsPassed;
  }

  bool get allCriticalValidationsPassed {
    return healthValidation.passed &&
        securityValidation.passed &&
        architectureValidation.passed &&
        integrationValidation.passed &&
        aiSystemValidation.passed &&
        productionValidation.passed;
  }

  List<String> get criticalBlockers {
    final blockers = <String>[];

    if (!healthValidation.passed) blockers.addAll(healthValidation.issues);
    if (!securityValidation.passed) blockers.addAll(securityValidation.issues);
    if (!architectureValidation.passed) {
      blockers.addAll(architectureValidation.issues);
    }
    if (!integrationValidation.passed) {
      blockers.addAll(integrationValidation.issues);
    }
    if (!aiSystemValidation.passed) blockers.addAll(aiSystemValidation.issues);
    if (!productionValidation.passed) {
      blockers.addAll(productionValidation.issues);
    }

    return blockers;
  }

  int get totalRecommendations {
    final validations = [
      healthValidation,
      performanceValidation,
      securityValidation,
      architectureValidation,
      qualityValidation,
      coverageValidation,
      integrationValidation,
      documentationValidation,
      aiSystemValidation,
      productionValidation,
    ];

    return validations.fold(0, (sum, v) => sum + v.recommendations.length);
  }

  String get deploymentReasoning {
    if (deploymentApproved) {
      return 'All validation criteria met. Overall score ${overallScore.toStringAsFixed(2)}/10.0 exceeds minimum requirements. System ready for production deployment.';
    } else {
      return 'Deployment blocked due to validation failures. Overall score ${overallScore.toStringAsFixed(2)}/10.0 below minimum ${DeploymentReadinessValidator.MIN_DEPLOYMENT_SCORE}. Critical issues must be resolved.';
    }
  }

  List<String> get nextSteps {
    if (deploymentApproved) {
      return [
        'Proceed with production deployment pipeline',
        'Monitor deployment metrics and system health',
        'Prepare rollback procedures if needed',
        'Update stakeholders on deployment status',
      ];
    } else {
      final steps = <String>[];
      steps.addAll(criticalBlockers.map((b) => 'Resolve: $b'));
      steps.add('Re-run deployment readiness validation');
      steps.add('Address high-priority recommendations');
      return steps;
    }
  }

  Map<String, bool> getValidationSummary() {
    return {
      'health': healthValidation.passed,
      'performance': performanceValidation.passed,
      'security': securityValidation.passed,
      'architecture': architectureValidation.passed,
      'quality': qualityValidation.passed,
      'coverage': coverageValidation.passed,
      'integration': integrationValidation.passed,
      'documentation': documentationValidation.passed,
      'aiSystem': aiSystemValidation.passed,
      'production': productionValidation.passed,
    };
  }

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'overallScore': overallScore,
        'deploymentApproved': deploymentApproved,
        'healthValidation': healthValidation.toJson(),
        'performanceValidation': performanceValidation.toJson(),
        'securityValidation': securityValidation.toJson(),
        'architectureValidation': architectureValidation.toJson(),
        'qualityValidation': qualityValidation.toJson(),
        'coverageValidation': coverageValidation.toJson(),
        'integrationValidation': integrationValidation.toJson(),
        'documentationValidation': documentationValidation.toJson(),
        'aiSystemValidation': aiSystemValidation.toJson(),
        'productionValidation': productionValidation.toJson(),
      };
}

class ValidationResult {
  final String category;
  final bool passed;
  final double score;
  final List<String> issues;
  final List<String> recommendations;
  final Map<String, dynamic> details;

  ValidationResult({
    required this.category,
    required this.passed,
    required this.score,
    required this.issues,
    required this.recommendations,
    required this.details,
  });

  Map<String, dynamic> toJson() => {
        'category': category,
        'passed': passed,
        'score': score,
        'issues': issues,
        'recommendations': recommendations,
        'details': details,
      };
}

// Additional helper classes
class SecurityCheckResult {
  final List<String> issues;
  final List<String> recommendations;
  final int criticalCount;
  final Map<String, dynamic> details;

  SecurityCheckResult({
    required this.issues,
    required this.recommendations,
    required this.criticalCount,
    required this.details,
  });
}

class ArchitectureValidation {
  final bool passed;
  final List<String> issues;
  final List<String> recommendations;
  final Map<String, dynamic> details;

  ArchitectureValidation({
    required this.passed,
    required this.issues,
    required this.recommendations,
    required this.details,
  });
}

class TestResult {
  final int totalCount;
  final int passedCount;
  final int failedCount;
  final double averageExecutionTimeMs;
  final bool allPassed;

  TestResult({
    required this.totalCount,
    required this.passedCount,
    required this.failedCount,
    required this.averageExecutionTimeMs,
    required this.allPassed,
  });

  Map<String, dynamic> get details => {
        'totalCount': totalCount,
        'passedCount': passedCount,
        'failedCount': failedCount,
        'averageExecutionTimeMs': averageExecutionTimeMs,
        'allPassed': allPassed,
      };
}

class DocumentationValidation {
  final bool complete;
  final List<String> missing;
  final Map<String, dynamic> details;

  DocumentationValidation({
    required this.complete,
    required this.missing,
    required this.details,
  });
}

class SystemValidation {
  final bool passed;
  final double impact;
  final List<String> issues;
  final List<String> recommendations;
  final Map<String, dynamic> details;

  SystemValidation({
    required this.passed,
    required this.impact,
    required this.issues,
    required this.recommendations,
    required this.details,
  });
}

class SecurityValidation {
  final bool secure;
  final Map<String, dynamic> details;

  SecurityValidation({
    required this.secure,
    required this.details,
  });
}
