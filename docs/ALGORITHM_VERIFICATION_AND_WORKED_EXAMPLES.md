# EVayLanka: Algorithmic Verification & Reproducible Worked Examples

> **Document Type:** Mathematical Verification & Specification Suite  
> **Version:** 1.0.0  
> **Target Audience:** Algorithm Reviewers, Technical Evaluators, Software Engineers  
> **Repository:** `EVayLanka`  
> **Source Modules:** `evay_app/lib/services/smart_route_service.dart`, `evay_app/lib/services/range_anxiety_service.dart`, `evay_app/lib/services/checkin_service.dart`

---

## Overview

This document provides formal mathematical definitions, algorithmic consistency proofs, and step-by-step reproducible worked numerical examples for five core computational components implemented on the `improvements` branch:

1. **Normalized Routing Cost Function**
2. **Calibrated Range Anxiety Index (RAI)**
3. **LankaScore Station Reliability & Real-Time Outage Penalty**
4. **Battery Reserve Enforcement & Infeasibility Filtering**
5. **Multi-Hop Route Feasibility & Topographical Physics Modeling**

```mermaid
flowchart LR
    A["1. Normalized Cost"] --> B["2. Calibrated RAI"]
    B --> C["3. LankaScore Penalty"]
    C --> D["4. Reserve Enforcement"]
    D --> E["5. Multi-Hop Physics Corridor"]
```

---

## 1. Normalized Routing Cost Function

### Formal Algorithm Definition
To evaluate and rank candidate paths without bias from mismatched physical units, route distance ($D$), electrical energy consumption ($E$), and charging delay ($C$) are mapped onto the unit interval $[0, 1]$ before linear weighting:

$$\text{Cost}(r) = \alpha \left(\frac{D}{D_{\max}}\right) + \beta \left(\frac{E}{E_{\max}}\right) + \gamma \left(\frac{C}{C_{\max}}\right)$$

Subject to the following boundary constraints:
$$\alpha + \beta + \gamma = 1.0, \quad \alpha \ge 0, \, \beta \ge 0, \, \gamma \ge 0$$
$$\frac{D}{D_{\max}} \in [0, 1], \quad \frac{E}{E_{\max}} \in [0, 1], \quad \frac{C}{C_{\max}} \in [0, 1]$$

#### Calibrated Parameter Values
* $\alpha = 0.40$ (Distance weighting factor)
* $\beta = 0.35$ (Energy consumption weighting factor)
* $\gamma = 0.25$ (Charging session delay weighting factor)
* Domain Upper Bounds:
  * $D_{\max} = 500.0\text{ km}$ (Maximum typical interprovincial transit in Sri Lanka)
  * $E_{\max} = 100.0\text{ kWh}$ (Maximum pack capacity / single long-distance demand)
  * $C_{\max} = 90.0\text{ mins}$ (Maximum acceptable session detour charging delay)

### Mathematical Consistency Proof
1. **Dimensionless Formulation:**  
   $$\left[\frac{D}{D_{\max}}\right] = \frac{\text{km}}{\text{km}} = 1, \quad \left[\frac{E}{E_{\max}}\right] = \frac{\text{kWh}}{\text{kWh}} = 1, \quad \left[\frac{C}{C_{\max}}\right] = \frac{\text{min}}{\text{min}} = 1$$
   Every constituent term is dimensionless.
2. **Bounded Output Range:**  
   Because $0 \le \frac{X}{X_{\max}} \le 1$ and $\alpha + \beta + \gamma = 1$, the function image is strictly bounded:
   $$\text{Cost}(r) \in [0.0, 1.0]$$
3. **Strict Monotonicity (Pareto Optimality):**  
   $$\frac{\partial \text{Cost}}{\partial D} = \frac{\alpha}{D_{\max}} > 0, \quad \frac{\partial \text{Cost}}{\partial E} = \frac{\beta}{E_{\max}} > 0, \quad \frac{\partial \text{Cost}}{\partial C} = \frac{\gamma}{C_{\max}} > 0$$
   A lower cost strictly correlates to shorter distance, lower power consumption, and shorter delay.

---

### Reproducible Worked Example 1: Route Selection
* **Candidate Route A (Southern Expressway):**  
  $D_A = 126.0\text{ km}$, $E_A = 22.8\text{ kWh}$, $C_A = 0.0\text{ min}$ (Direct, no charging needed).
* **Candidate Route B (Galle Road Inland + DC Charger Detour):**  
  $D_B = 138.0\text{ km}$, $E_B = 26.1\text{ kWh}$, $C_B = 22.0\text{ min}$.

#### Step-by-Step Numerical Computation:

**Route A:**
$$\text{Norm}_D(A) = \frac{126.0}{500.0} = 0.2520$$
$$\text{Norm}_E(A) = \frac{22.8}{100.0} = 0.2280$$
$$\text{Norm}_C(A) = \frac{0.0}{90.0} = 0.0000$$
$$\text{Cost}(A) = (0.40 \times 0.2520) + (0.35 \times 0.2280) + (0.25 \times 0.0000)$$
$$\text{Cost}(A) = 0.1008 + 0.0798 + 0.0000 = \mathbf{0.1806}$$

**Route B:**
$$\text{Norm}_D(B) = \frac{138.0}{500.0} = 0.2760$$
$$\text{Norm}_E(B) = \frac{26.1}{100.0} = 0.2610$$
$$\text{Norm}_C(B) = \frac{22.0}{90.0} = 0.2444$$
$$\text{Cost}(B) = (0.40 \times 0.2760) + (0.35 \times 0.2610) + (0.25 \times 0.2444)$$
$$\text{Cost}(B) = 0.1104 + 0.09135 + 0.06110 = \mathbf{0.2629}$$

**Result:**  
$\text{Cost}(A) = 0.1806 < \text{Cost}(B) = 0.2629 \implies$ **Route A is optimal and selected.**

---

## 2. Calibrated Range Anxiety Index (RAI)

### Formal Algorithm Definition
The RAI quantifies trip risk on an integer scale $[0, 100]$:

$$RAI = \text{round}\Big(\big(w_b \cdot m_b + w_r \cdot m_r + w_c \cdot m_c\big) \times 100\Big)$$

Subject to:
$$w_b + w_r + w_c = 1.0 \quad (w_b = 0.50, \, w_r = 0.30, \, w_c = 0.20)$$

#### Sub-Score Formulations:
1. **Battery Margin Sub-Score ($m_b$):**
   $$m_b = \max\left(0.0, \, \frac{\text{SoC}_{\text{effective}} - E_{\text{demand}}}{\text{SoC}_{\text{effective}}}\right)$$
   Where $\text{SoC}_{\text{effective}} = \text{SoC}_{\text{available}} + \sum E_{\text{injected}}$.
2. **Route Feasibility Sub-Score ($m_r$):**
   $$m_r = \min\left(1.0, \, \frac{R_{\text{effective}}}{D_{\text{route}}}\right) \quad \text{where } R_{\text{effective}} = \frac{\text{SoC}_{\text{effective}}}{\eta_{\text{effective}}}$$
3. **Station Accessibility Sub-Score ($m_c$):**
   $$m_c = \text{clamp}_{0}^{1}\left(\min\left(1.0, \, \frac{n_{\text{stations}}}{n_{\text{required}}}\right) \times F_{\text{charger}}\right)$$
   Where $n_{\text{required}} = \max\left(0, \left\lceil \frac{E_{\text{demand}}}{0.75 \times \text{SoC}_{\text{avail}}} \right\rceil - 1\right)$ ($n_{\text{required}} = 0 \implies \text{ratio} = 1.0$), and $F_{\text{charger}} \in [0.55, 1.0]$.

#### Score Classification Bands:
* $RAI \ge 70$: **Safe Trip** (Comfortable reserve margin)
* $40 \le RAI < 70$: **Charge Recommended** (Tight buffer; corridor stop advised)
* $RAI < 40$: **High Risk** (Battery exhaustion projected before destination)

---

### Reproducible Worked Example 2: Monsoon Highway Trip
* **Vehicle State:** Battery Capacity $= 50.3\text{ kWh}$, Initial SoC $= 52\%$  
  $$\text{SoC}_{\text{avail}} = 50.3 \times 0.52 = \mathbf{26.156\text{ kWh}}$$
* **Vehicle Base Efficiency:** Rated $= 6.0\text{ km/kWh}$ ($\eta_{\text{rated}} = 1 / 6.0 = 0.1667\text{ kWh/km}$).
* **Environmental Factor Calibration:**
  * Tropical ambient HVAC: $k_{\text{climate}} = 1.05$
  * Driving Mode: Normal ($k_{\text{mode}} = 1.00$)
  * Heavy Monsoon Rain: $k_{\text{weather}} = 1.10$ (+10% hydrodynamic drag)
  * Payload Mass: Driver + 2 passengers ($150\text{ kg}$ additional):
    $$k_{\text{payload}} = 1.0 + \left(\frac{150}{1800}\right) \times 0.45 = 1.0375$$
  * Composite Environmental Factor:
    $$k_{\text{env}} = 1.05 \times 1.00 \times 1.10 \times 1.0375 = \mathbf{1.1983}$$
  * Effective Consumption Rate:
    $$\eta_{\text{effective}} = 0.1667 \times 1.1983 = \mathbf{0.1998\text{ kWh/km}}$$
* **Route Profile:** $D_{\text{route}} = 125.0\text{ km}$, Coastal flat ($\Delta E_{\text{elev}} = 0$).
  $$E_{\text{demand}} = 125.0 \times 0.1998 = \mathbf{24.975\text{ kWh}}$$
  $$\text{Stops} = 0 \implies \text{SoC}_{\text{effective}} = 26.156\text{ kWh}$$
  $$R_{\text{effective}} = \frac{26.156}{0.1998} = \mathbf{130.91\text{ km}}$$

#### Sub-Score Computation:
1. $$m_b = \frac{26.156 - 24.975}{26.156} = \frac{1.181}{26.156} = \mathbf{0.04515}$$
2. $$m_r = \min\left(1.0, \, \frac{130.91}{125.0}\right) = \mathbf{1.0000}$$
3. $$n_{\text{required}} = 0 \implies m_c = 1.0 \times 0.55 = \mathbf{0.5500}$$

#### Composite Calculation:
$$RAI = \big((0.50 \times 0.04515) + (0.30 \times 1.0000) + (0.20 \times 0.5500)\big) \times 100$$
$$RAI = (0.02257 + 0.30000 + 0.11000) \times 100 = 0.43257 \times 100 = \mathbf{43}$$

**Classification Output:**  
$RAI = 43 \in [40, 69] \implies$ **"Charge recommended"**  
*(Accurately identifies that while the vehicle can technically arrive, it would arrive with only $1.18\text{ kWh}$ or $\approx 5.9\text{ km}$ remaining).*

---

## 3. "LankaScore" Reliability & Real-Time Outage Penalty

### Formal Algorithm Definition
Reliability is evaluated from a rolling window of driver check-ins:

$$\text{RawScore} = \begin{cases} 9.0 & \text{if } N_{\text{eval}} = 0 \\ \left(\frac{N_{\text{success}}}{N_{\text{eval}}}\right) \times 10.0 & \text{if } N_{\text{eval}} > 0 \end{cases}$$

#### Outage Recency Penalty Rule:
If any failure (grid blackout, tripped breaker, broken plug, bay ICE-ing) occurred within $\Delta t < 4.0\text{ hours}$:

$$\text{LankaScore} = \text{clamp}_{1.0}^{6.0}\big(\text{RawScore} \times 0.60\big)$$

#### Router Candidate Weighting:
$$\text{ReliabilityFactor} = \text{clamp}_{0.2}^{1.0}\left(\frac{\text{LankaScore}}{10.0}\right)$$
$$\text{Score}_{\text{final}} = \text{Score}_{\text{candidate}} \times \text{ReliabilityFactor}$$

---

### Reproducible Worked Example 3: Rerouting Around a Tripped Breaker
* **Station 1 (Kadugannawa DC Fast):**  
  Power: $60\text{ kW}$, Detour: $0.5\text{ km}$.  
  Base Router Score: $\text{Score}_{\text{cand}} = \mathbf{0.840}$.  
  History: 18 successful charges, 2 failures ($N_{\text{eval}} = 20$).  
  $\text{RawScore} = (18 / 20) \times 10.0 = 9.0$.  
  **Real-Time Incident:** Driver reports "Tripped Breaker" 35 minutes ago ($\Delta t = 0.58\text{ hr} < 4.0\text{ hr}$).
* **Station 2 (Ambepussa DC):**  
  Power: $30\text{ kW}$, Detour: $2.0\text{ km}$.  
  Base Router Score: $\text{Score}_{\text{cand}} = \mathbf{0.680}$.  
  History: 8 successful charges, 1 failure. No issues in the last 24 hours. $\text{RawScore} = \mathbf{8.9}$.

#### Step-by-Step Computation:

**Station 1 (Recent Outage Penalty):**
$$\text{LankaScore}_1 = \text{clamp}_{1.0}^{6.0}(9.0 \times 0.60) = \text{clamp}_{1.0}^{6.0}(5.40) = \mathbf{5.40}$$
$$\text{ReliabilityFactor}_1 = \frac{5.40}{10.0} = \mathbf{0.540}$$
$$\text{Score}_{\text{final}}(1) = 0.840 \times 0.540 = \mathbf{0.4536}$$

**Station 2 (Normal Operation):**
$$\text{LankaScore}_2 = \mathbf{8.90}$$
$$\text{ReliabilityFactor}_2 = \frac{8.90}{10.0} = \mathbf{0.890}$$
$$\text{Score}_{\text{final}}(2) = 0.680 \times 0.890 = \mathbf{0.6052}$$

**Result:**  
$$\text{Score}_{\text{final}}(2) = 0.6052 > \text{Score}_{\text{final}}(1) = 0.4536$$
**Station 2 is selected.** The system automatically avoids routing the user to the disabled station.

---

## 4. Battery Reserve Enforcement (Feasibility Boundary)

### Formal Algorithm Definition
To guarantee against stranding, any candidate station $c_i$ must satisfy:

$$E_{\text{segment}}(p_{\text{origin}} \to c_i) \le \text{SoC}_{\text{available}} - \text{SoC}_{\text{reserve}}$$

Where:
* $E_{\text{segment}} = (D_{\text{origin} \to c_i} + 2 \times D_{\text{detour}}) \times \eta_{\text{effective}}$
* $\text{SoC}_{\text{reserve}} = \text{Capacity}_{\text{battery}} \times R_{\text{threshold}}$  
  ($R_{\text{threshold}} = 0.10$ for single stops; $0.18$ for multi-hop corridors).

Any station violating this inequality is dropped before multi-criteria ranking.

---

### Reproducible Worked Example 4: Infeasible Candidate Elimination
* **Vehicle State:** Battery Capacity $= 50.3\text{ kWh}$, Current SoC $= 20\%$ ($\text{SoC}_{\text{avail}} = 10.06\text{ kWh}$).
* **Reserve Threshold:** $10\% \implies \text{SoC}_{\text{reserve}} = 50.3 \times 0.10 = \mathbf{5.03\text{ kWh}}$.
* **Maximum Allowable Reach Energy:**
  $$E_{\text{allowable}} = 10.06 - 5.03 = \mathbf{5.03\text{ kWh}}$$
* **Effective Consumption:** $\eta = 0.18\text{ kWh/km}$.
* **Candidate Station A:** Located at $D_{\text{origin}} = 26.0\text{ km}$, Detour $= 2.5\text{ km}$.
  $$D_{\text{segment}} = 26.0 + (2 \times 2.5) = 31.0\text{ km}$$
  $$E_{\text{segment}} = 31.0\text{ km} \times 0.18\text{ kWh/km} = \mathbf{5.58\text{ kWh}}$$

#### Boundary Check:
$$E_{\text{segment}} = 5.58\text{ kWh} > E_{\text{allowable}} = 5.03\text{ kWh}$$
$$\text{Projected Arrival SoC} = 10.06 - 5.58 = 4.48\text{ kWh} \quad (8.9\% < 10.0\%)$$

**Result:**  
Candidate Station A is **rejected as mathematically infeasible**.

---

## 5. Multi-Hop Route Feasibility & Topographical Physics Modeling

### Formal Algorithm Definition
Elevations are sampled using 28 Gaussian Radial Basis Function (RBF) anchors:

$$\text{Elev}(p) = \frac{\sum_i w_i \cdot \text{Elev}_i}{\sum_i w_i}, \quad w_i = \exp\left(-\frac{d_i^2}{2\sigma_i^2}\right)$$

Gravitational potential energy adjustments are calculated per segment:
1. **Ascent Penalty:**
   $$\Delta E_{\text{climb}} = \frac{m \cdot g \cdot \Delta h_{\text{gain}}}{3.6 \times 10^6 \times \eta_{\text{drive}}} \quad (\text{kWh})$$
2. **Descent Regenerative Recovery:**
   $$E_{\text{regen}} = \frac{m \cdot g \cdot |\Delta h_{\text{loss}}| \times \eta_{\text{regen}}}{3.6 \times 10^6} \quad (\text{kWh})$$
   *(Physical constants: $m = 1800\text{ kg}$, $g = 9.81\text{ m/s}^2$, $\eta_{\text{drive}} = 0.88$, $\eta_{\text{regen}} = 0.65$)*.

#### Sequential Waypoint Simulation:
$$\text{SoC}_k = \text{SoC}_{k-1} - (\Delta d_k \times \eta_{\text{rolling}}) - \Delta E_{\text{climb}, k} + E_{\text{regen}, k}$$
When $\text{SoC}_k \le \text{Capacity} \times 0.18$, a charging stop is inserted:
$$\Delta t_{\text{charge}} = \left(\frac{(0.80 - \text{SoC}_{\text{arrival}}) \times \text{Capacity}}{P_{\text{charger}} \times 0.90}\right) \times 60 \quad (\text{mins})$$

---

### Reproducible Worked Example 5: Colombo to Nuwara Eliya Corridor
* **Trip Distance:** $168.0\text{ km}$.
* **Topography Profile:** Elevation rises from $10\text{m}$ (Colombo) to $1,950\text{m}$ (Nuwara Eliya).  
  Gross Cumulative Climb: $\Delta h_{\text{gain}} = +2,150\text{m}$; Gross Descent: $\Delta h_{\text{loss}} = -210\text{m}$.
* **Vehicle Spec:** Battery Capacity $= 50.3\text{ kWh}$, Initial Battery $= 65\%$ ($32.695\text{ kWh}$).  
  Base rolling consumption $= 0.16\text{ kWh/km}$.

#### Physics-Based Topographical Energy Demands:
$$\Delta E_{\text{climb}} = \frac{1800 \times 9.81 \times 2150}{3.6 \times 10^6 \times 0.88} = \frac{37,964,700}{3,168,000} = \mathbf{11.98\text{ kWh}}$$
$$E_{\text{regen}} = \frac{1800 \times 9.81 \times 210 \times 0.65}{3.6 \times 10^6} = \frac{2,410,317}{3,600,000} = \mathbf{0.67\text{ kWh}}$$
$$\Delta E_{\text{net\_elevation}} = 11.98 - 0.67 = \mathbf{+11.31\text{ kWh}}$$
$$\text{Total Trip Energy Needed} = (168\text{ km} \times 0.16) + 11.31 = 26.88 + 11.31 = \mathbf{38.19\text{ kWh}}$$

#### Direct Drive Feasibility:
$$\text{Net Balance} = 32.695\text{ kWh} - 38.19\text{ kWh} = \mathbf{-5.495\text{ kWh}} \implies \textbf{Stranding without charging!}$$

#### Multi-Hop Corridor Execution:
1. **Segment 1: Colombo to Peradeniya Foothills ($105.0\text{ km}$, $+620\text{m}$ climb):**
   * Energy used: $(105 \times 0.16) + \frac{1800 \times 9.81 \times 620}{3,168,000} = 16.80 + 3.46 = \mathbf{20.26\text{ kWh}}$.
   * Battery at Peradeniya: $32.695 - 20.26 = \mathbf{12.435\text{ kWh}}$ ($\mathbf{24.7\%}$).
   * Projected next leg needs $\approx 18.0\text{ kWh}$, which exceeds available energy before reserve ($12.435 - 9.05 = 3.385\text{ kWh}$).
   * **Stop 1 Scheduled:** Peradeniya DC Fast Charger ($50\text{ kW}$).
2. **Stop 1 Charging Session Simulation:**
   * Target: $80\% = 40.24\text{ kWh}$. Energy added: $40.24 - 12.435 = \mathbf{27.805\text{ kWh}}$.
   * Charging time:
     $$\Delta t = \frac{27.805\text{ kWh}}{50\text{ kW} \times 0.90} \times 60 = 0.6179 \times 60 = \mathbf{37.1\text{ mins}}$$
   * Battery departs at: $40.24\text{ kWh}$ ($80\%$).
3. **Segment 2: Peradeniya to Nuwara Eliya ($63.0\text{ km}$, $+1,530\text{m}$ mountain climb):**
   * Energy used: $(63 \times 0.16) + \frac{1800 \times 9.81 \times 1530}{3,168,000} = 10.08 + 8.53 = \mathbf{18.61\text{ kWh}}$.
   * Arrival battery at Nuwara Eliya:
     $$\text{SoC}_{\text{dest}} = 40.24 - 18.61 = \mathbf{21.63\text{ kWh}} \quad \left(\frac{21.63}{50.3} = \mathbf{43.0\%}\right)$$

**Result:**  
The corridor algorithm successfully schedules 1 charging stop ($37.1\text{ mins}$), arriving with $43.0\%$ battery remaining, preventing battery exhaustion.

---

## Synthesis & Verification Summary

| Component | Governing Equation | Physical Bounds | Key Verification Property |
| :--- | :--- | :--- | :--- |
| **Normalized Routing Cost** | $\alpha \frac{D}{D_{\max}} + \beta \frac{E}{E_{\max}} + \gamma \frac{C}{C_{\max}}$ | $[0.0, 1.0]$ | Dimensionless, scale-invariant, monotonic Pareto preference |
| **Calibrated RAI** | $(0.50 m_b + 0.30 m_r + 0.20 m_c) \times 100$ | $[0, 100]$ | Bounded risk index integrating battery, route, and stations |
| **LankaScore Outage Penalty** | $\text{clamp}_{1.0}^{6.0}(\text{RawScore} \times 0.60)$ | $[1.0, 10.0]$ | Dynamic 40% penalty for outages within 4 hours |
| **Battery Reserve Enforcement** | $E_{\text{reach}} \le \text{SoC}_{\text{avail}} - \text{SoC}_{\text{reserve}}$ | Boolean | Strictly prevents stranding before reaching candidate stops |
| **Multi-Hop Corridor Physics** | $\text{SoC}_k = \text{SoC}_{k-1} - \Delta E_{\text{roll}} - \Delta E_{\text{climb}} + E_{\text{regen}}$ | $[0, \text{Capacity}]$ | Gravitational climb penalties & regen braking recovery |
