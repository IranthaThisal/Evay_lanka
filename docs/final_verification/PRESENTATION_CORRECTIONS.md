# EVay Lanka: ICACT 2026 Presentation Corrections & Talking Points

> **Document Type:** Speaker Guide & Presentation Slide Revisions  
> **Target Event:** ICACT 2026 Research Presentation  
> **Source Repository:** `https://github.com/IranthaThisal/EVay_lanka`  

---

## 1. Slide-by-Slide Audit & Recommended Revisions

### Slide: Mathematical Cost Function & Calibration
* **Current Presentation Content:** Distance: 35%, Energy: 45%, Charging Delay: 20%.
* **Audit Finding:** **CONFIRMED & VERIFIED ACCURATE.**
  - Implemented in `smart_route_service.dart#L260-L262`: $\alpha=0.35, \beta=0.45, \gamma=0.20$.
  - Unit test assertion in `algorithm_verification_test.dart#L22-L24`: `equals(0.35), equals(0.45), equals(0.20)`.
  - Research Manuscript (`IEEE_RESEARCH_MANUSCRIPT_VALIDATION.md#L16`): $\alpha=0.35, \beta=0.45, \gamma=0.20$.
* **Speaker Action:** No change required. Maintain 35% / 45% / 20%. Emphasize that physical calibration elevated the energy consumption weight ($\beta=0.45$) above distance ($\alpha=0.35$) due to severe gravitational potential swings in Sri Lanka's central highlands.

---

### Slide: Benchmark Results & Detour Reduction
* **Current Presentation Content:** Average detour reduction of $85.8\%$; worst-case single detour reduction of $87.5\%$.
* **Audit Finding:** **CONFIRMED & VERIFIED ACCURATE.**
  - Base corridor distance sum $= 3,459.0\text{ km}$ across 15 scenarios.
  - Nearest Charger mean detour $= +69.94\text{ km}$ ($+30.3\%$).
  - EVayLanka mean detour $= +9.94\text{ km}$ ($+4.3\%$).
  - Reduction $= (69.94 - 9.94) / 69.94 = \mathbf{85.79\%} \approx 85.8\%$.
  - Worst detour on C4 @ 50% SoC reduced from $+211.9\text{ km}$ to $+26.5\text{ km}$ ($\mathbf{87.49\%} \approx 87.5\%$).
* **Speaker Action:** Highlight that greedy nearest-charger routing routinely causes catastrophic detours into remote dead-ends, whereas EVayLanka searches within an $O(1)$ spatial bounding corridor along the planned vector.

---

### Slide: Charging Delay Efficiency
* **Current Presentation Content:** 51.1% peak charging delay reduction.
* **Audit Finding:** **METHODOLOGICAL CLARIFICATION REQUIRED.**
  - The $51.1\%$ metric represents a **comparison between two separate global peaks** across all 45 evaluations:
    - Nearest Charger worst delay: $171.3\text{ minutes}$ (on C4 Colombo–Jaffna at $50\%$ initial SoC).
    - EVayLanka worst delay: $83.7\text{ minutes}$ (on C5 Hambantota–Trincomalee at $30\%$ initial SoC).
    - Global ceiling comparison: $(171.3 - 83.7) / 171.3 = \mathbf{51.14\%} \approx 51.1\%$.
  - In a direct **scenario-paired comparison on C4 @ 50% SoC**:
    - Nearest Charger delay: $171.3\text{ minutes}$.
    - EVayLanka delay: $73.7\text{ minutes}$.
    - Paired scenario reduction: $(171.3 - 73.7) / 171.3 = \mathbf{56.98\%} \approx 57.0\%$.
* **Speaker Action:** Update slide note or clarify verbally: *"EVayLanka cuts peak corridor charging delay across the entire benchmark matrix from 171.3 minutes down to 83.7 minutes (a 51.1% reduction in worst-case delay ceiling), achieving up to 57.0% delay reduction on the critical Colombo–Jaffna corridor."*

---

### Slide: Safety Enforcement & Reserve Violations
* **Current Presentation Content:** Reserve violation rate: OSRM $86.7\%$, Nearest Charger $33.3\%$, EVayLanka $6.7\%$.
* **Audit Finding:** **CONFIRMED & VERIFIED ACCURATE.**
  - OSRM violates the $10\%$ reserve floor in $13/15$ scenarios ($86.67\%$).
  - Nearest Charger violates reserve in $5/15$ scenarios ($33.33\%$) due to excessive detour depletion.
  - EVayLanka incurs only $1/15$ violation ($6.67\%$), strictly confined to unassisted C3 (Colombo to Nuwara Eliya) at $80\%$ SoC arriving at $6.5\%$ SoC.
* **Speaker Action:** Emphasize the distinction between **Reserve Violation Rate** ($6.7\%$) and **Pre-Departure Hazard Detection Rate** ($100.0\%$). Explain that on C3 @ 80%, the system flags the reserve violation before departure and refuses to start navigation until a charging stop at Ramboda Falls is inserted, which brings arrival SoC to $38.3\%$.

---

### Slide: Crowdsourced Station Reliability ("LankaScore")
* **Current Presentation Content:** Dynamic reliability scoring with outage penalty.
* **Audit Finding:** **TERMINOLOGY CLARIFICATION REQUIRED.**
  - Ensure the penalty is described as a **"4-hour stepwise recency penalty ($0.6\times$ multiplier clamped to $[1.0, 6.0]$)"**, rather than an "exponential continuous decay".
  - Clarify that availability data is **crowdsourced driver check-ins**, not direct hardware IoT/OCPP telemetry from charging network operators.
* **Speaker Action:** State clearly: *"LankaScore uses a 4-hour stepwise recency penalty that immediately discounts reported stations by 40% upon community check-in reporting a grid outage or breaker trip, steering active EV drivers to reliable alternates."*

---

### Slide: Multi-User Booking Concurrency
* **Current Presentation Content:** Concurrency evaluation with 50 competing users, 2 accepted, 48 rejected, 0 double bookings.
* **Audit Finding:** **SCOPING CLARIFICATION REQUIRED.**
  - Clarify that this benchmark evaluates an **in-memory Optimistic Concurrency Control (OCC) testbed (`InMemoryReservationEngine`)** measuring application concurrency algorithms and atomic isolation, rather than measuring live Google Cloud Firestore network latency over wide-area cellular networks.
* **Speaker Action:** State clearly: *"The reservation contention engine was validated under in-memory OCC simulation, demonstrating 100% atomic integrity and zero double-bookings under severe multi-driver contention."*

---

### Slide: Empirical Telemetry & Validation
* **Current Presentation Content:** CAN bus telemetry evaluation across 8 Sri Lankan drive cycles.
* **Audit Finding:** **SCIENTIFIC INTEGRITY DISCLOSURE REQUIRED.**
  - Confirm that the 8 OBD-II datasets are **physics-calibrated synthetic reference benchmarks** generated via `tool/export_obd_traces.dart`.
  - Disclose that physical on-road vehicle instrumentation with hardware CAN dataloggers represents planned future work.
* **Speaker Action:** Emphasize: *"The energy model was benchmarked against standardized, physics-calibrated synthetic reference drive cycles modeling an MG ZS EV across Sri Lanka's terrain. Full instrumented on-road fleet trials form our next phase of research."*
