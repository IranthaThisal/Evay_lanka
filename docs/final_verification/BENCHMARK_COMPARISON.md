# EVay Lanka: Benchmark Comparison & Methodological Analysis

> **Document Type:** Comparative Benchmark Reproduction & Synthesis  
> **Target Conference:** ICACT 2026  
> **Source Testbed:** `evay_app/test/comparative_benchmark_45_scenarios_test.dart`, `evay_app/tool/recalculate_manuscript_metrics.dart`  
> **Evaluation Dataset:** 45 Method-Scenario Evaluations across 5 Sri Lankan corridors (C1–C5) $\times$ 3 Initial SoCs ($30\%, 50\%, 80\%$)  

---

## 1. Primary Benchmark Metrics Comparison

The table below contrasts the expected values reported in the research manuscript against the independently reproduced values:

| Evaluation Parameter | Evaluated Domain | Reported Stated Value | Independently Recomputed Value | Absolute Difference | Relative Deviation | Verification Status |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: |
| **OSRM Reserve Violations** | All 15 Scenarios | $86.7\%$ ($13/15$) | $86.67\%$ ($13/15$) | $0.03\%$ | $0.03\%$ | **VERIFIED** |
| **Nearest Charger Violations** | All 15 Scenarios | $33.3\%$ ($5/15$) | $33.33\%$ ($5/15$) | $0.03\%$ | $0.09\%$ | **VERIFIED** |
| **EVayLanka Violations** | All 15 Scenarios | $6.7\%$ ($1/15$) | $6.67\%$ ($1/15$) | $0.03\%$ | $0.45\%$ | **VERIFIED** |
| **Hazard Detection Rate** | All 15 Scenarios | $100.0\%$ ($13/13$ unsafe) | $100.00\%$ ($13/13$) | $0.00\%$ | $0.00\%$ | **VERIFIED** |
| **Nearest Avg Detour Distance** | All 15 Scenarios | $+69.9\text{ km}$ | $+69.9400\text{ km}$ | $0.04\text{ km}$ | $0.06\%$ | **VERIFIED** |
| **EVayLanka Avg Detour Distance**| All 15 Scenarios | $+9.9\text{ km}$ | $+9.9400\text{ km}$ | $0.04\text{ km}$ | $0.40\%$ | **VERIFIED** |
| **Detour Overhead Reduction** | All 15 Scenarios | $85.8\%$ | $85.79\%$ | $0.01\%$ | $0.01\%$ | **VERIFIED** |
| **Worst Single Detour (Nearest)**| C4 @ 50% SoC | $+211.9\text{ km}$ | $+211.90\text{ km}$ | $0.00\text{ km}$ | $0.00\%$ | **VERIFIED** |
| **Worst Single Detour (EVay)** | C4 @ All SoCs | $+26.5\text{ km}$ | $+26.50\text{ km}$ | $0.00\text{ km}$ | $0.00\%$ | **VERIFIED** |
| **Worst Detour Reduction** | C4 Corridor | $87.5\%$ | $87.49\%$ | $0.01\%$ | $0.01\%$ | **VERIFIED** |
| **Nearest Feasible Avg Charge Time**| 8 Feasible Charging Runs | $68.4\text{ min}$ | $68.4125\text{ min}$ | $0.01\text{ min}$ | $0.02\%$ | **VERIFIED** |
| **EVayLanka Feasible Avg Charge Time**| 12 Active Charging Runs | $56.1\text{ min}$ | $56.0667\text{ min}$ | $0.03\text{ min}$ | $0.06\%$ | **VERIFIED** |
| **Feasible Charging Time Reduction**| Active Charging Runs | $18.0\%$ | $18.04\%$ | $0.04\%$ | $0.22\%$ | **VERIFIED** |
| **Global Peak Charging Delay** | Global Max across 45 Runs | $51.1\%$ ($171.3\text{m} \to 83.7\text{m}$) | $51.14\%$ ($171.3\text{m} \to 83.7\text{m}$) | $0.04\%$ | $0.08\%$ | **VERIFIED** |
| **Single-Scenario Peak Delay** | C4 @ 50% SoC | $57.0\%$ ($171.3\text{m} \to 73.7\text{m}$) | $56.98\%$ ($171.3\text{m} \to 73.7\text{m}$) | $0.02\%$ | $0.04\%$ | **VERIFIED** |
| **Model D Energy MAE Reduction**| 8 Drive Cycles | $67.6\%$ ($4.38 \to 1.42\text{ kWh}$) | $67.64\%$ ($4.380 \to 1.4175\text{ kWh}$) | $0.04\%$ | $0.06\%$ | **VERIFIED** |
| **Model D Energy RMSE Reduction**| 8 Drive Cycles | $65.2\%$ ($5.78 \to 2.01\text{ kWh}$) | $65.18\%$ ($5.782 \to 2.0134\text{ kWh}$) | $0.02\%$ | $0.03\%$ | **VERIFIED** |
| **Model D Energy MAPE Reduction**| 8 Drive Cycles | $47.9\%$ ($22.6\% \to 11.7\%$) | $47.98\%$ ($22.56\% \to 11.74\%$) | $0.08\%$ | $0.17\%$ | **VERIFIED** |

---

## 2. In-Depth Methodological Clarifications

### 2.1 Detour Distance Denominators & Averages
* **Methodology:** The total direct base distance across all 15 corridor trips is $3,459.0\text{ km}$ ($125\times 3 + 115\times 3 + 168\times 3 + 395\times 3 + 350\times 3$), yielding a mean corridor length of $230.6\text{ km}$.
* **Nearest Charger:** Traversed a total of $4,508.1\text{ km}$, representing $+1,049.1\text{ km}$ of total detour overhead (mean $+69.94\text{ km}$ per trip, or $+30.3\%$).
* **EVayLanka:** Traversed a total of $3,608.1\text{ km}$, representing $+149.1\text{ km}$ of total detour overhead (mean $+9.94\text{ km}$ per trip, or $+4.3\%$).
* **Reduction:**
  $$\frac{69.94\text{ km} - 9.94\text{ km}}{69.94\text{ km}} = \mathbf{85.79\%} \approx 85.8\%$$

### 2.2 Charging Delay Comparison Scope (Global Max vs. Paired Scenario)
The presentation references a $51.1\%$ reduction in charging delay:
* **Calculation Basis:** This metric is derived from a **comparison of separate global maximums** across the entire 45-evaluation matrix:
  - Worst observed delay for Nearest Charger: $171.3\text{ minutes}$ (on C4 Colombo–Jaffna at $50\%$ SoC).
  - Worst observed delay for EVayLanka: $83.7\text{ minutes}$ (on C5 Hambantota–Trincomalee at $30\%$ SoC).
  - Global peak delay reduction: $\frac{171.3 - 83.7}{171.3} = \mathbf{51.14\%} \approx 51.1\%$.
* **Paired Single-Scenario Peak Reduction (C4 @ 50% SoC):**
  - Nearest Charger delay on C4 @ 50% SoC: $171.3\text{ minutes}$.
  - EVayLanka delay on C4 @ 50% SoC: $73.7\text{ minutes}$.
  - Paired reduction on this bottleneck: $\frac{171.3 - 73.7}{171.3} = \mathbf{56.98\%} \approx 57.0\%$.
* **Conclusion for Presenter:** Both figures are mathematically valid, but the speaker must specify whether they are citing the global-peak ceiling comparison ($51.1\%$) or the direct scenario-paired reduction on C4 ($57.0\%$).

### 2.3 Reserve Violations vs. Physical Roadside Strandings
* **Reserve Violation Definition:** Arrival at destination with final SoC $<10.0\%$ ($5.03\text{ kWh}$) or arrival with an energy deficit ($<0\text{ kWh}$).
* **EVayLanka 1/15 Violation:** The single violation ($6.7\%$) occurs on **Corridor C3 (Colombo to Nuwara Eliya) at 80% initial SoC**, arriving at $6.5\%$ SoC.
* **Pre-Departure Safety Gate:** EVayLanka flags this journey before departure (`isFeasible == false`, `canInitiateNavigation == false`), alerting the driver to plan a charging stop at Ramboda Falls, which restores arrival SoC to $38.3\%$ and approves navigation. In contrast, OSRM fails in 13/15 scenarios with zero pre-departure awareness.

---

## 3. CSV Reproduction Artifact
The raw scenario-by-scenario results table containing all 45 evaluations is exported and saved at:
[`docs/final_verification/BENCHMARK_REPRODUCTION.csv`](file:///d:/Projects/Evay_lanka/docs/final_verification/BENCHMARK_REPRODUCTION.csv).
