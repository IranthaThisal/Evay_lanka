# EVay Lanka: Algorithmic Verification & Formal Mathematical Specifications

> **Document Type:** Mathematical Specification & Verification Suite  
> **Target Conference:** ICACT 2026  
> **Source Modules:**  
> - `evay_app/lib/services/smart_route_service.dart`  
> - `evay_app/lib/services/range_anxiety_service.dart`  
> - `evay_app/lib/services/checkin_service.dart`  
> - `evay_app/lib/services/booking_service.dart`  
> - `evay_app/lib/services/simulation_service.dart`  

---

## 1. Normalized Dimensionless Routing Cost Function

### 1.1 Mathematical Formulation
To evaluate and rank candidate paths without dimensional inconsistency, distance ($D$), energy demand ($E$), and charging session delay ($C$) are mapped onto the bounded unit interval $[0, 1]$ before linear weighting:

$$\text{Cost}(r) = \alpha \left(\frac{D}{D_{\max}}\right) + \beta \left(\frac{E}{E_{\max}}\right) + \gamma \left(\frac{C}{C_{\max}}\right)$$

Subject to:
$$\alpha + \beta + \gamma = 1.0, \quad \alpha \ge 0, \, \beta \ge 0, \, \gamma \ge 0$$
$$\frac{D}{D_{\max}} \in [0, 1], \quad \frac{E}{E_{\max}} \in [0, 1], \quad \frac{C}{C_{\max}} \in [0, 1]$$

### 1.2 Implemented Coefficients & Domain Denominators
* $\alpha = 0.35$ (Distance / Detour Weighting Factor) — `smart_route_service.dart#L260`
* $\beta = 0.45$ (Energy Consumption / Power Weighting Factor) — `smart_route_service.dart#L261`
* $\gamma = 0.20$ (Charging Delay / Queue Weighting Factor) — `smart_route_service.dart#L262`
* $D_{\max} = 500.0\text{ km}$ (Maximum typical interprovincial transit in Sri Lanka)
* $E_{\max} = 100.0\text{ kWh}$ (Maximum pack capacity / single long-distance demand)
* $C_{\max} = 90.0\text{ minutes}$ (Maximum acceptable session detour charging delay)

### 1.3 Mathematical Properties
1. **Dimensionless Consistency:**
   $$\left[\frac{D}{D_{\max}}\right] = \frac{\text{km}}{\text{km}} = 1, \quad \left[\frac{E}{E_{\max}}\right] = \frac{\text{kWh}}{\text{kWh}} = 1, \quad \left[\frac{C}{C_{\max}}\right] = \frac{\text{min}}{\text{min}} = 1$$
2. **Strictly Bounded Output:**
   Because each normalized term is clamped to $[0.0, 1.0]$ and $\sum \text{weights} = 1.0$:
   $$\text{Cost}(r) \in [0.0, 1.0]$$
3. **Monotonicity (Pareto Optimality):**
   $$\frac{\partial \text{Cost}}{\partial D} = \frac{\alpha}{D_{\max}} = \frac{0.35}{500} = 0.0007 > 0$$
   $$\frac{\partial \text{Cost}}{\partial E} = \frac{\beta}{E_{\max}} = \frac{0.45}{100} = 0.0045 > 0$$
   $$\frac{\partial \text{Cost}}{\partial C} = \frac{\gamma}{C_{\max}} = \frac{0.20}{90} \approx 0.00222 > 0$$

### 1.4 Step-by-Step Numerical Verification
* **Route A (Direct Expressway, 126 km, 22.8 kWh, 0 min charge):**
  $$\text{Norm}_D(A) = \frac{126.0}{500.0} = 0.2520, \quad \text{Norm}_E(A) = \frac{22.8}{100.0} = 0.2280, \quad \text{Norm}_C(A) = \frac{0.0}{90.0} = 0.0000$$
  $$\text{Cost}(A) = (0.35 \times 0.2520) + (0.45 \times 0.2280) + (0.20 \times 0.0000) = 0.0882 + 0.1026 + 0.0000 = \mathbf{0.1908}$$

* **Route B (Inland Detour, 138 km, 26.1 kWh, 22 min charge):**
  $$\text{Norm}_D(B) = \frac{138.0}{500.0} = 0.2760, \quad \text{Norm}_E(B) = \frac{26.1}{100.0} = 0.2610, \quad \text{Norm}_C(B) = \frac{22.0}{90.0} \approx 0.24444$$
  $$\text{Cost}(B) = (0.35 \times 0.2760) + (0.45 \times 0.2610) + (0.20 \times 0.24444) = 0.09660 + 0.11745 + 0.04889 = \mathbf{0.26294}$$

---

## 2. Topographical Elevation & Gravitational Physics Model

### 2.1 28-Node Gaussian Radial Basis Function (RBF)
Implemented in `SriLankaElevationModel` (`smart_route_service.dart#L12-L102`). Given a geographic coordinate $(lat, lng)$, elevation $z(lat, lng)$ is interpolated from 28 regional anchors:

$$z(lat, lng) = \frac{\sum_{i=1}^{28} w_i(lat, lng) \cdot z_i}{\sum_{i=1}^{28} w_i(lat, lng)}$$

Where the Gaussian weight $w_i$ is computed with radial cutoff $\tau_i = 18.42 \cdot \sigma_i^2$:
$$w_i(lat, lng) = \begin{cases} \exp\left(-\frac{d_i^2}{2\sigma_i^2}\right) & \text{if } d_i^2 < 18.42 \sigma_i^2 \\ 0 & \text{otherwise} \end{cases}$$

Planar squared distance is computed via equirectangular projection at mean Sri Lankan latitude ($7.87^\circ\text{ N}$):
$$d_i^2 = \big((lat - lat_i) \cdot 110.574\text{ km/deg}\big)^2 + \big((lng - lng_i) \cdot 110.250\text{ km/deg}\big)^2$$

### 2.2 Gravitational Energy Delta & Regenerative Braking
Implemented in `computeElevationEnergyDelta` (`smart_route_service.dart#L149-L170`):
$$\Delta E_{\text{elev}} = \begin{cases} 
\frac{m \cdot g \cdot |\Delta h|}{\eta_{\text{drive}} \cdot 3.6 \times 10^6} & \text{if } \Delta h > 0 \text{ (Ascent penalty, } \eta_{\text{drive}} = 0.88\text{)} \\
-\frac{m \cdot g \cdot |\Delta h| \cdot \eta_{\text{regen}}}{3.6 \times 10^6} & \text{if } \Delta h < 0 \text{ (Descent recovery, } \eta_{\text{regen}} = 0.65\text{)} 
\end{cases}$$

* $m$: Total vehicle mass ($1800.0\text{ kg}$ curb $+ m_{\text{payload}}$)
* $g = 9.80665\text{ m/s}^2$
* $\Delta h = \text{Gain} - (0.70 \times \text{Loss})$ (Effective net topographic gradient)

---

## 3. Range Anxiety Index (RAI) Formulation

Implemented in `RangeAnxietyService` (`range_anxiety_service.dart#L10-L140`):
$$RAI = \text{round}\Big(\big(w_b \cdot m_b + w_r \cdot m_r + w_c \cdot m_c\big) \times 100\Big) \in [0, 100]$$

### 3.1 Sub-score Components
* $w_b = 0.50$ (Battery Margin Sub-score):
  $$m_b = \max\left(0, \frac{\text{SoC}_{\text{effective}} - E_{\text{route}}}{\text{SoC}_{\text{effective}}}\right)$$
* $w_r = 0.30$ (Route Feasibility Sub-score):
  $$m_r = \min\left(1, \frac{R_{\text{effective}}}{D_{\text{route}}}\right)$$
* $w_c = 0.20$ (Station Accessibility Sub-score):
  $$m_c = \min\left(1, \frac{n_{\text{stations}}}{n_{\text{required}}}\right) \times \text{ChargerFactor}$$

### 3.2 Operational Classification Tiers
* $RAI \ge 70$: **Safe Trip** (Full confidence buffer, navigation permitted)
* $40 \le RAI < 70$: **Charge Recommended** (Tight buffer, intermediate stop advised)
* $RAI < 40$: **High Risk** (Severe energy deficit, navigation rejected)

### 3.3 Dynamic Environmental Safety Margin
Implemented in `computeDynamicSafetyMargin` (`range_anxiety_service.dart#L144-L183`):
$$\text{Margin}_{\text{dyn}} = 1.06 + \Delta_{\text{chargers}} + \Delta_{\text{weather}} + \Delta_{\text{mode}} + \Delta_{\text{payload}} + \Delta_{\text{climb}}$$
* $\Delta_{\text{chargers}} = +0.04$ (if corridor chargers present) or $+0.12$ (if absent)
* $\Delta_{\text{weather}} = +0.00$ (Dry), $+0.03$ (Light Rain), $+0.08$ (Heavy Monsoon)
* $\Delta_{\text{mode}} = +0.00$ (Eco), $+0.02$ (Normal), $+0.05$ (Sport)
* $\Delta_{\text{payload}} = +0.03$ (if added payload $> 150\text{ kg}$)
* $\Delta_{\text{climb}} = +0.04$ (if elevation gain $> 400\text{ m}$)
* Spans dynamically from $1.10\times$ up to $1.38\times$.

---

## 4. LankaScore Station Reliability & Stepwise Recency Penalty

Implemented in `CheckInService` (`checkin_service.dart#L50-L103`):
$$S_{\text{raw}} = \left(\frac{n_{\text{success}}}{n_{\text{success}} + n_{\text{failure}}}\right) \times 10.0$$

### 4.1 Stepwise Recency Penalty
If an unresolved issue (grid outage, breaker trip, ICE-ing) was logged within 4 hours:
$$S_{\text{final}} = \text{clamp}\big(S_{\text{raw}} \times 0.6, \, 1.0, \, 6.0\big)$$

### 4.2 Candidate Selection Utility Function
In `SmartRouteService._scoreCandidateCharger` (`smart_route_service.dart#L578-L610`):
$$\text{Utility} = \big(0.35 \cdot S_{\text{close}} + 0.30 \cdot S_{\text{power}} + 0.20 \cdot S_{\text{slot}} + 0.15 \cdot S_{\text{progress}}\big) \times \text{clamp}\left(\frac{S_{\text{final}}}{10.0}, 0.2, 1.0\right)$$

---

## 5. Smart Reservation & Concurrency Management

Implemented in `BookingService` (`booking_service.dart`):

### 5.1 SoC-Based Duration Auto-Calculation
$$T_{\text{charge}} = \text{clamp}\left(\text{round}\left(\frac{(80\% - \text{SoC}_{\text{current}}) \times \text{Capacity}_{\text{kWh}}}{P_{\text{station}} \times \eta_c} \times 60\right), \, 15, \, 180\right)\text{ minutes}$$
Where $\eta_c = 0.90$ (AC/DC onboard conversion efficiency).

### 5.2 Optimistic Concurrency Control (OCC)
- Atomic slot reservation enforces physical capacity ($k$ bays) using Firestore transactional primitives (`runTransaction`).
- Zero double-booking tolerance: conflicts throw `BookingConflictException`.
- Expired slot recycling automatically frees unreleased capacity when $T > T_{\text{end}}$.
