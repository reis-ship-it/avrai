# How to Run E-Commerce Enrichment Experiments

**Quick Reference Guide**

---

## 🚀 **Quick Start**

### **1. Setup (One-Time)**

```bash
cd scripts/ecommerce_experiments

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install numpy pandas scipy
```

### **2. Deploy API (If Not Already Deployed)**

```bash
cd /Users/reisgordon/SPOTS

# Link to Supabase
supabase link --project-ref nfzlwgbvezwwrutqpedy

# Apply migrations
supabase db push

# Deploy function
supabase functions deploy ecommerce-enrichment --no-verify-jwt
```

### **3. Generate API Key**

```sql
-- In Supabase SQL Editor
SELECT generate_api_key('test_partner', 100, 10000, NULL);
-- Save the returned key!
```

### **4. Run Experiments**

```bash
cd scripts/ecommerce_experiments
source venv/bin/activate

export ECOMMERCE_API_URL="https://nfzlwgbvezwwrutqpedy.supabase.co/functions/v1/ecommerce-enrichment"
export ECOMMERCE_API_KEY="your_generated_key"

./run_experiments_with_logging.sh
```

---

## 📊 **Individual Experiments**

### **Functionality Tests**
```bash
python3 test_endpoint_functionality.py \
  --api-url "$ECOMMERCE_API_URL" \
  --api-key "$ECOMMERCE_API_KEY"
```

### **Performance Benchmarks**
```bash
python3 test_performance.py \
  --api-url "$ECOMMERCE_API_URL" \
  --api-key "$ECOMMERCE_API_KEY" \
  --iterations 100
```

### **A/B Test**
```bash
python3 test_algorithm_enhancement.py \
  --api-url "$ECOMMERCE_API_URL" \
  --api-key "$ECOMMERCE_API_KEY" \
  --users 1000 \
  --products 100
```

### **Data Quality**
```bash
python3 test_data_quality.py \
  --api-url "$ECOMMERCE_API_URL" \
  --api-key "$ECOMMERCE_API_KEY"
```

---

## 📁 **Results Location**

All results saved to: `scripts/ecommerce_experiments/results/`

- CSV files: Detailed data
- JSON files: Structured results
- Markdown reports: Human-readable summaries
- Log files: Complete execution logs

---

## 🔍 **Check Results**

```bash
# View latest log
tail -f results/experiment_run_*.log

# View master summary
cat results/MASTER_SUMMARY.md

# View specific report
cat results/performance/PERFORMANCE_REPORT.md
```

---

**Status:** Framework ready, waiting for API deployment and API key generation.
