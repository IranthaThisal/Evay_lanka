# EVay Lanka — Formal IEEE Peer Review Response & Rebuttal Document

> **Manuscript Title:** Topography-Aware EV Routing, Dynamic Range Anxiety Modeling, and Crowdsourced Grid Reliability in Sri Lanka  
> **Target Venue:** IEEE Transactions on Intelligent Transportation Systems / IEEE Access  
> **Date:** November 8, 2026  
> **Authors' Formal Response to Reviewers #1 and #4**  

---

## 1. Response to Reviewer #1

### Comment 1.1: Range Anxiety Index Weights and Calibration
> *"The weights for the Range Anxiety Index ($w_b=0.50, w_r=0.30, w_c=0.20$) appear to be assigned heuristically without independent empirical calibration or psychological user studies."*

**Authors' Response:**  
We thank the reviewer for this insightful critique. We completely agree that in the absence of empirical human-subject psychometric studies, the composite index cannot legitimately claim to measure human emotional or psychological anxiety. 

In response, we have revised the manuscript and terminology throughout:
1. **Terminology Reclassification:** The index is now explicitly designated as an **engineering heuristic trip-feasibility indicator** (formulated in the software architecture as the Range Anxiety Index, RAI).
2. **Mathematical Scope:** The paper now clarifies that the index quantifies remaining physical battery energy buffers ($m_b$), route range feasibility ratios ($m_r$), and corridor charger accessibility ($m_c$), rather than psychometric anxiety.
3. **Threshold Definition:** The operational tiers ($\ge 70$, $40\text{--}69$, $<40$) are defined strictly as engineering safety margins for automated pre-departure route rejection, rather than psychological diagnostic categories.
4. **Documentation Location:** Revised in Abstract (line 17), Section I.2, Section X.2, and in [`research/stage5_verification/stage5_independent_verification_report.md`](file:///t:/project/EVayLanka/research/stage5_verification/stage5_independent_verification_report.md).

---

### Comment 1.2: Apparent Textual Discrepancy (Camera Reliability, Fire Detection, F1 = 0.9999)
> *"On page 2, the review refers to a camera-reliability term, fire detection, and an F1 score of 0.9999."*

**Authors' Response:**  
The authors respectfully note that the submitted manuscript focuses exclusively on electric vehicle energy routing, topographical potential energy modeling, and charger booking concurrency in Sri Lanka. It contains no computer vision modules, optical camera sensors, or fire-detection algorithms. 

These specific observations appear to reflect an unintentional cross-review transcription mismatch with an unrelated computer vision or fire safety manuscript. 

Rather than setting aside Reviewer #1's evaluation, we have carefully extracted and fully addressed all valid and constructive methodological concerns raised by Reviewer #1—specifically:
* Clarifying the heuristic nature of routing weights ($\alpha=0.35, \beta=0.45, \gamma=0.20$);
* Disclosing that the 8 telemetry trace files are physics-calibrated synthetic reference benchmarks rather than on-road physical hardware captures;
* Guaranteeing identical 26-station baseline infrastructure across all tested routing methods; and
* Ensuring end-to-end reproducibility of all 45 scenario evaluations.

---

## 2. Response to Reviewer #4

### Comment 2.1: Distinguishing Feasible Selection from Global Optimality
> *"Reviewer #4 correctly distinguishes between choosing a feasible charging stop from evaluated candidates and claiming mathematical global optimality across the entire road network."*

**Authors' Response:**  
We thank Reviewer #4 for this critical distinction. We fully concur that selecting high-utility charging stops along a corridor does not constitute a mathematical proof of global optimality across an infinite search space of all possible route paths and stop combinations.

We have revised all routing claims throughout the manuscript:
1. **Replaced All "Optimal" Assertions:** Systematically eliminated claims of "global optimality." EVayLanka is now described as providing **multi-criteria cost-ranked charging stop selection optimized among evaluated corridor candidate stations**.
2. **Defensible Benchmark Scope:** The revised manuscript clearly states that EVayLanka demonstrates significant, verified comparative improvements over tested baseline heuristics (OSRM shortest path and greedy Nearest Charger) across 15 Sri Lankan interprovincial scenarios (reducing average detour overhead by $85.8\%$ and peak charging delay by $51.1\%$), while disclaiming mathematical global optimality across the unconstrained road network.
3. **Documentation Location:** Revised in Section I.2, Section V.3, and Section X.3 of [`docs/IEEE_RESEARCH_MANUSCRIPT_VALIDATION.md`](file:///t:/project/EVayLanka/docs/IEEE_RESEARCH_MANUSCRIPT_VALIDATION.md).

---

### Comment 2.2: Threshold Boundaries and Psychological Interpretation
> *"Reviewer #4 questions the thresholds (e.g., 70, 40) and psychological interpretation of the Range Anxiety Index."*

**Authors' Response:**  
We agree completely. In the revised manuscript:
* The score thresholds ($\ge 70$: Compliant Buffer, $40\text{--}69$: Recharge Advised, $<40$: Infeasible Buffer / Departure Veto) are defined strictly as operational safety gates for the automated pre-departure navigation engine (`validateNavigationReadiness` and `canInitiateNavigation`).
* We explicitly note that interpreting these thresholds as boundaries of psychological stress would require controlled driver behavioral studies, which are highlighted as important future empirical work.

---

## 3. Summary of Revisions Table

| Reviewer Point | Manuscript Location | Modification Description | Status |
| :--- | :--- | :--- | :---: |
| **RAI Psychological vs Feasibility** | Abstract, Sec. I.2, Sec. X.2 | Reclassified as an engineering heuristic trip-feasibility indicator. | **RESOLVED** |
| **Route Optimality Claims** | Sec. I.2, Sec. V.3, Sec. X.3 | Replaced "global optimality" with "cost-ranked candidate optimization". | **RESOLVED** |
| **Reviewer #1 Mix-Up (Fire/Camera)** | Sec. X.1 | Polite clarification of cross-paper transcription mismatch; valid concerns addressed. | **RESOLVED** |
| **Synthetic Provenance Disclosure** | Sec. VII.1, Data README | Explicitly disclosed as physics-calibrated synthetic reference traces. | **RESOLVED** |
| **LankaScore Formula Accuracy** | Abstract, Sec. VIII.1 | Corrected "exponential decay" to "4-hour stepwise recency penalty ($0.6\times$)". | **RESOLVED** |
| **Concurrency Testbed Scope** | Abstract, Sec. I.2, Sec. VIII.2 | Strictly identified as an in-memory OCC transaction simulation (`InMemoryReservationEngine`). | **RESOLVED** |
