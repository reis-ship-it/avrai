# E-Commerce Enrichment API - Experiment Suite

**Phase 21:** E-Commerce Data Enrichment Integration POC  
**Purpose:** Validate API functionality, performance, and algorithm enhancement

---

## Overview

This experiment suite validates the e-commerce enrichment API through:

1. **Endpoint Functionality Tests** - Verify all endpoints work correctly
2. **Performance Benchmarks** - Measure response times and throughput
3. **Algorithm Enhancement A/B Test** - Compare baseline vs SPOTS-enhanced algorithms
4. **Data Quality Validation** - Verify privacy, aggregation, and data quality

---

## Setup

### Prerequisites

```bash
# Install Python dependencies
pip install numpy pandas scipy

# Or use virtual environment
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install numpy pandas scipy
```

### Configuration

Set your API credentials:

```bash
export ECOMMERCE_API_URL="https://[project-ref].supabase.co/functions/v1/ecommerce-enrichment"
export ECOMMERCE_API_KEY="your_api_key_here"
```

---

## Running Experiments

### Run All Experiments

```bash
cd scripts/ecommerce_experiments
python3 run_all_experiments.py \
  --api-url "$ECOMMERCE_API_URL" \
  --api-key "$ECOMMERCE_API_KEY"
```

### Run Individual Experiments

#### 1. Endpoint Functionality Tests

```bash
python3 test_endpoint_functionality.py \
  --api-url "$ECOMMERCE_API_URL" \
  --api-key "$ECOMMERCE_API_KEY"
```

**Tests:**
- Real-world behavior endpoint
- Quantum personality endpoint
- Community influence endpoint
- Response structure validation

#### 2. Performance Benchmarks

```bash
python3 test_performance.py \
  --api-url "$ECOMMERCE_API_URL" \
  --api-key "$ECOMMERCE_API_KEY" \
  --iterations 100
```

**Metrics:**
- Average response time
- P50, P95, P99 response times
- Success rate
- Throughput

#### 3. Algorithm Enhancement A/B Test

```bash
python3 test_algorithm_enhancement.py \
  --api-url "$ECOMMERCE_API_URL" \
  --api-key "$ECOMMERCE_API_KEY" \
  --users 1000 \
  --products 100
```

**Compares:**
- Baseline algorithm (collaborative filtering + content-based)
- SPOTS-enhanced algorithm (70% baseline + 30% SPOTS data)

**Metrics:**
- Conversion rate improvement
- Recommendation accuracy
- Statistical significance (p-value, Cohen's d)

#### 4. Data Quality Validation

```bash
python3 test_data_quality.py \
  --api-url "$ECOMMERCE_API_URL" \
  --api-key "$ECOMMERCE_API_KEY"
```

**Validates:**
- Privacy (no personal data)
- Aggregation (properly aggregated)
- Confidence scores (≥ 0.75 average)
- Data freshness (< 24 hours)

---

## Experiment Options

### Run All with Custom Options

```bash
python3 run_all_experiments.py \
  --api-url "$ECOMMERCE_API_URL" \
  --api-key "$ECOMMERCE_API_KEY" \
  --performance-iterations 200 \
  --ab-test-users 2000 \
  --ab-test-products 200 \
  --skip-validation  # Skip data quality validation
```

### Run Specific Experiments Only

```bash
# Only functionality and performance
python3 run_all_experiments.py \
  --api-url "$ECOMMERCE_API_URL" \
  --api-key "$ECOMMERCE_API_KEY" \
  --skip-ab-test \
  --skip-validation
```

---

## Results Structure

```
results/
├── endpoint_functionality/
│   ├── endpoint_functionality_test_*.csv
│   ├── endpoint_functionality_test_*.json
│   └── SUMMARY.md
├── performance/
│   ├── performance_benchmark_*.csv
│   ├── performance_benchmark_*.json
│   └── PERFORMANCE_REPORT.md
├── algorithm_enhancement/
│   ├── algorithm_enhancement_ab_test_*.csv
│   ├── algorithm_enhancement_ab_test_*.json
│   └── AB_TEST_REPORT.md
├── data_quality/
│   ├── data_quality_validation_*.csv
│   ├── data_quality_validation_*.json
│   └── VALIDATION_REPORT.md
└── MASTER_SUMMARY.md
```

---

## Expected Results

### Performance Targets

- **P95 Response Time:** < 500ms ✅
- **Success Rate:** > 99% ✅
- **P99 Response Time:** < 1000ms ✅

### Algorithm Enhancement Targets

- **Conversion Rate Improvement:** ≥ 10% ✅
- **Statistical Significance:** p < 0.01 ✅
- **Effect Size:** Cohen's d > 1.0 (large effect) ✅

### Data Quality Targets

- **Privacy:** No personal data fields ✅
- **Aggregation:** Properly aggregated ✅
- **Confidence:** Average ≥ 0.75 ✅
- **Freshness:** < 24 hours ✅

---

## Experiment Framework

All experiments use the `ECommerceExperimentBase` class which provides:

- **API Client** - Standardized endpoint calls
- **Statistical Analysis** - T-tests, Cohen's d, confidence intervals
- **Result Storage** - CSV and JSON output
- **Report Generation** - Markdown summaries

---

## Troubleshooting

### API Key Issues

```bash
# Test API key
curl -X POST "$ECOMMERCE_API_URL/real-world-behavior" \
  -H "Authorization: Bearer $ECOMMERCE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"user_segment": {"segment_id": "test"}}'
```

### Rate Limiting

If you hit rate limits:
- Reduce `--iterations` for performance tests
- Reduce `--users` for A/B tests
- Wait between test runs

### Missing Dependencies

```bash
pip install --upgrade numpy pandas scipy
```

---

## Next Steps

After running experiments:

1. **Review Results** - Check all reports in `results/` directory
2. **Validate Targets** - Ensure all targets are met
3. **Fix Issues** - Address any failures
4. **Optimize** - Improve performance if needed
5. **Document** - Update API documentation with findings

---

**Status:** Ready to Run  
**Last Updated:** December 23, 2025
