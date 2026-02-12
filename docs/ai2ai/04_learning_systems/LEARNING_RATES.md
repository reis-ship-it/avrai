# Learning Rates

**Created:** December 8, 2025, 5:25 PM CST  
**Purpose:** Documentation for learning rates and algorithms

---

## 🎯 **Overview**

Learning rates determine how quickly and how much the AI personality evolves from different learning sources.

---

## 📊 **Learning Rate Constants**

### **Personal Learning Rate**

**Default:** 0.1 (10% per learning event)

**Code Reference:**
- `lib/core/constants/vibe_constants.dart` - `personalLearningRate`

---

### **AI2AI Learning Rate**

**Default:** 0.05 (5% per learning event)

**Code Reference:**
- `lib/core/constants/vibe_constants.dart` - `ai2aiLearningRate`

---

### **Cloud Learning Rate**

**Default:** 0.02 (2% per learning event)

**Code Reference:**
- `lib/core/constants/vibe_constants.dart` - `cloudLearningRate`

---

## 🧠 **Learning Algorithms**

### **Personality Evolution**

Personality dimensions evolve based on:
- Learning source (personal/AI2AI/cloud)
- Learning rate for that source
- Confidence in the learning
- Authenticity of the learning

**Code Reference:**
- `lib/core/ai/personality_learning.dart` - Evolution algorithms

---

## 🔗 **Related Documentation**

- **Personal Learning:** [`PERSONAL_LEARNING.md`](./PERSONAL_LEARNING.md)
- **AI2AI Learning:** [`AI2AI_LEARNING.md`](./AI2AI_LEARNING.md)
- **Cloud Learning:** [`CLOUD_LEARNING.md`](./CLOUD_LEARNING.md)

---

**Last Updated:** December 8, 2025, 5:25 PM CST  
**Status:** Learning Rates Documentation Complete

