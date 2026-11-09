# Sri Lanka EV Telemetry Benchmark Dataset (Physics-Calibrated Synthetic Reference Traces)

> **Dataset Classification:** Standardized Reference Drive Cycle Benchmark  
> **Generation Testbed:** `tool/export_obd_traces.dart`  
> **Target Homologation:** MG ZS EV (Standard Range, 2024 Model Year)  
> **Geographic Domain:** Sri Lanka Interprovincial Highways, Midland Passes, and Mountain Corridors  

---

## 1. Provenance & Nature of the Benchmark

This repository directory contains calibrated time-series reference diagnostic traces modeling eight canonical driving cycles across Sri Lanka.

**Transparency & Scientific Integrity Notice:**
* These traces are **physics-calibrated synthetic reference benchmarks** generated via `tool/export_obd_traces.dart` to simulate standard on-board diagnostic CAN telemetry.
* They provide a transparent, deterministic, and open reference testbed to validate EV battery-energy consumption models against Newtonian mechanical equations (aerodynamic drag, rolling resistance, HVAC thermal loads, and gravitational elevation potential).
* They model the exact signal schema and sampling characteristics of physical diagnostic logging without claiming unverified physical on-road hardware acquisition.

---

## 2. Vehicle Platform Specifications (Simulated Homologation)

- **Model:** MG ZS EV (Standard Range, 2024 Model Year)
- **Battery Pack:** $50.3\text{ kWh}$ Lithium Iron Phosphate (CATL LFP)
- **Nominal Pack Voltage:** $384\text{ V}$ ($340\text{ V}$ depleted to $410\text{ V}$ fully charged)
- **Curb Mass:** $1,800\text{ kg}$
- **Tire Specifications:** 215/55 R17 ($2.5\text{ bar}$ cold pressure)
- **Rated Efficiency:** $6.0\text{ km/kWh}$ ($16.67\text{ kWh/100km}$)

---

## 3. Emulated Sensor Instrumentation & Signal Schema

The synthetic generator replicates the exact diagnostic PIDs and sampling frequencies typical of an **OBDLink MX+ Bluetooth Interface** operating on **ISO 15765-4 (CAN bus 500 kbps, 11-bit ID)**:

- **Sampling Frequency:** $0.5\text{ Hz}$ ($2.0\text{-second}$ time step)
- **Modeled Diagnostic Parameters:**
  - `0x221154`: High-Voltage Traction Battery Current ($I_{\text{pack}}$, Amperes)
  - `0x221155`: High-Voltage Traction Battery Voltage ($V_{\text{pack}}$, Volts)
  - `0x221156`: Battery Management System State-of-Charge ($SoC_{\text{BMS}}$, $\%$)
  - `0x221101`: Vehicle Ground Speed ($v$, $\text{km/h}$)

---

## 4. Trip Directory

1. `OBD-2026-0312-C1.csv` — Colombo to Galle (E01 Southern Expressway, $125.0\text{ km}$, $24.20\text{ kWh}$)
2. `OBD-2026-0312-C2.csv` — Galle to Colombo (E01 Southern Expressway Return, $125.0\text{ km}$, $23.90\text{ kWh}$)
3. `OBD-2026-0318-K1.csv` — Colombo to Kandy (A1 Kadugannawa Pass Ascent, $115.0\text{ km}$, $25.10\text{ kWh}$)
4. `OBD-2026-0318-K2.csv` — Kandy to Colombo (A1 Kadugannawa Pass Descent, $115.0\text{ km}$, $18.40\text{ kWh}$)
5. `OBD-2026-0325-N1.csv` — Colombo to Nuwara Eliya (A7/A5 Central Massif Ascent, $168.0\text{ km}$, $41.20\text{ kWh}$)
6. `OBD-2026-0326-N2.csv` — Nuwara Eliya to Kandy (A5 Ramboda Pass Steep Descent, $75.0\text{ km}$, $7.10\text{ kWh}$)
7. `OBD-2026-0402-D1.csv` — Colombo to Dambulla (A1/A6 Midland Plains, $155.0\text{ km}$, $28.60\text{ kWh}$)
8. `OBD-2026-0405-A1.csv` — Colombo to Katunayake (Airport Expressway, $38.0\text{ km}$, $6.90\text{ kWh}$)

---

## 5. Discrete Time Integration

Instantaneous electrical power and cumulative discharge energy across sampled steps $k = 1, \dots, N$ are calculated as:

$$P_k = V_k \times I_k \quad [\text{W}]$$

$$E_{\text{actual}} = \sum_{k=1}^{N} \frac{V_k \cdot I_k \cdot \Delta t_k}{3.6 \times 10^6} \quad [\text{kWh}]$$
