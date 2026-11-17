# EVay Lanka 🚗⚡
### Intelligent, Physics-Aware Electric Vehicle Ecosystem for Sri Lanka

[![Flutter](https://img.shields.io/badge/Flutter-3.29.2-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.7.2-0175C2?logo=dart)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Auth%20%7C%20Firestore-FFCA28?logo=firebase)](https://firebase.google.com)
[![Conference Target](https://img.shields.io/badge/Conference-ICACT%202026-blueviolet)](https://icact.org)
[![Status](https://img.shields.io/badge/Status-Production%20Ready%20%28PASS%29-brightgreen)](#conference-verification--benchmark-reproducibility)

**EVay Lanka** is an autonomous, mobile-first EV ecosystem and route navigation platform engineered specifically for the distinct geographical, electrical, and infrastructure landscape of **Sri Lanka**. 

It addresses range anxiety through physics-informed highland elevation modeling, hybrid charging station discovery (315+ stations across ChargeNET and CEB networks), pre-departure safety reserve validation, Ceylon Electricity Board (CEB) Time-Of-Use (TOU) tariff optimization, and conflict-free charging slot reservations.

---

## 📌 Core Innovations & Architectural Pillars

### 1. 🏔️ Sri Lanka Topography & Elevation Physics Engine
* **Gaussian RBF Elevation Model**: High-precision relief modeling of the Central Highlands massif (Nuwara Eliya, Kandy, Hatton, Ella, Ramboda Pass) transitioning to coastal plains.
* **Gravitational Potential Energy & Regen**: Real-time energy penalty ($\Delta E = m \cdot g \cdot \Delta h$) and regenerative braking recovery ($\eta_{\text{regen}} \approx 70\%$) computation.
* **Point of No Return (PNR) Detection**: Real-time calculation of the physical point beyond which an EV can no longer turn back to the nearest charging depot without battery exhaustion.
* **Round-Trip Simulation**: Toggle to model both the steep mountain ascent and energy-recovering descent back to origin.

### 2. 🛣️ Multi-Hop Corridor Route Optimization & Reserve Floor
* **Normalized Pareto Cost Function**:
  $$\text{Cost}(r) = \alpha \frac{D}{D_{\max}} + \beta \frac{E}{E_{\max}} + \gamma \frac{C}{C_{\max}}$$
  Calibrated with conference-verified weights: $\alpha = 0.35$ (Detour), $\beta = 0.45$ (Power/Energy), $\gamma = 0.20$ (Queue Delay).
* **Strict 10% Reserve Floor Enforcement**: Mandatory pre-departure veto if projected arrival SoC drops below the 10.0% safety threshold.
* **Sequential Multi-Stop Insertion**: Proactively schedules charging stops when SoC approaches the critical 15–20% buffer.
* **Alternative Charger Comparison**: Evaluates and allows swapping with runner-up corridor chargers (e.g., swapping an L2 stop for a 50 kW DC Fast Charger).

### 3. 🔌 Sri Lanka EV Presets & Connector-Aware Routing
* **Local Vehicle Profiles**: Built-in specifications for popular Sri Lankan EVs:
  * **MG ZS EV** (50.3 kWh • CCS2 / Type 2)
  * **BYD Atto 3** Standard (49.9 kWh) & Extended (60.5 kWh • CCS2)
  * **BYD Dolphin** (44.9 kWh • CCS2)
  * **Nissan Leaf** ZE1 (40 kWh • CHAdeMO / Type 2) & AZE0 (24 kWh • CHAdeMO / Type 1)
  * **Hyundai Kona Electric** (39.2 kWh • CCS2)
* **Automatic Compatibility Filtering**: Filters corridor charging stops by the vehicle's connector type (`CCS2`, `CHAdeMO`, `Type 2`).

### 4. ⚡ Hybrid 315+ Charging Station Provider
* **Zero-Latency Offline Seed**: 315 verified Sri Lankan charging points embedded locally for instant startup.
* **Live ChargeNET API Polling**: Periodic background query (`api.chargenet.lk:13100`) updating real-time slot availability (`AVAILABLE` vs `OCCUPIED`).
* **LankaScore Crowdsourcing**: Community-driven check-in reliability score with immediate 4-hour penalties for reported power cuts or broken ports.

### 5. 📅 Smart Slot Booking & One-Tap ETA Reservation
* **Intelligent Duration Auto-Calculation**: Computes exact minutes to reach 80% SoC:
  $$\text{Duration (mins)} = \left[ \frac{(80\% - \text{Current\%}) \times \text{Capacity (kWh)}}{\text{Power (kW)} \times 0.90} \right] \times 60$$
* **One-Tap "Book ETA"**: Books an arrival slot directly from planned route stops, pre-selecting projected arrival time and charging duration.
* **Smart Waitlist & Queue Alerting**: Instant notification when occupied slots are freed or expired bookings are recycled.

### 6. 💰 CEB Time-Of-Use (TOU) Tariff Optimizer
* **Live CEB Tariff Ticker**: Displays active tariff windows:
  * **Off-Peak** (22:30 – 05:30): `LKR 25.00 / kWh` (Up to 61% cheaper)
  * **Day Rate** (05:30 – 18:30): `LKR 40.00 / kWh`
  * **Peak Hours** (18:30 – 22:30): `LKR 65.00 / kWh`
* **Trip Cost Estimator**: Calculates estimated charging cost in LKR and highlights potential savings by shifting charging to Off-Peak hours.

---

## 📱 User Interface Highlights

* **Compact Route Pill Bar**: Automatically collapses input fields upon route planning, maximizing map visibility while keeping distance, duration, and stop info accessible.
* **Interactive Elevation & SoC Scrubber**: Touch-enabled elevation chart displaying altitude in meters alongside projected battery SoC %, highlighting PNR and charging stops.
* **Range Anxiety Safety HUD (`RaiSafetyHud`)**: Clear `APPROVED` or `VETOED` pre-departure status, dual-track reserve floor visualizer, and environmental factors.
* **OSM Map Rendering**: Smooth vector polylines, custom status markers, and destination pins on OpenStreetMap.

---

## 📂 Project Architecture

```
evay_app/
├── lib/
│   ├── data/
│   │   └── chargenet_seed.dart            # 315 verified Sri Lanka charging stations
│   ├── l10n/
│   │   └── app_localizations.dart         # Trilingual support (English, Sinhala, Tamil)
│   ├── models/
│   │   ├── booking.dart                   # Booking models and status
│   │   ├── charger.dart                   # Charger model and metadata
│   │   ├── charger_checkin.dart           # LankaScore check-in reports
│   │   ├── ev_preset.dart                 # Sri Lanka EV presets & specs
│   │   ├── range_anxiety.dart             # RAI and PNR models
│   │   └── smart_route.dart               # Multi-stop SmartRoute & ChargingStop models
│   ├── screens/
│   │   ├── app_shell.dart                 # Main navigation shell
│   │   ├── booking_screen.dart            # Smart slot booking & waitlist
│   │   ├── home_dashboard.dart            # CEB tariff & battery overview
│   │   ├── map_screen.dart                # Interactive map & corridor planner
│   │   └── vehicle_add_screen.dart        # Vehicle profile & EV presets
│   ├── services/
│   │   ├── booking_service.dart           # Slot booking & concurrency engine
│   │   ├── chargenet_service.dart         # ChargeNET API client
│   │   ├── charger_service.dart           # Hybrid station provider & sync
│   │   ├── checkin_service.dart           # LankaScore crowdsourced reliability
│   │   ├── range_anxiety_service.dart     # RAI composite score engine
│   │   ├── smart_route_service.dart       # Pareto routing & corridor insertion
│   │   ├── spatial/                       # Spatial bounding-box & hash grid
│   │   └── topography/                    # Sri Lanka elevation & energy physics
│   ├── theme/                             # Theming & dark/light palettes
│   └── ui/
│       ├── ceb_tariff_card.dart           # CEB TOU tariff ticker
│       ├── elevation_profile_hud.dart     # Interactive elevation & SoC scrubber
│       ├── osm_map_view.dart              # OpenStreetMap widget
│       ├── radial_battery_gauge.dart      # Radial battery visualizer
│       ├── rai_safety_hud.dart            # Pre-departure safety reserve HUD
│       └── map/                           # Charger cards and filter sheets
├── test/
│   ├── algorithm_verification_test.dart   # 7 core mathematical & algorithmic pillars
│   ├── comparative_benchmark_45_scenarios_test.dart  # 45 corridor scenarios (C1–C5)
│   ├── research_simulation_suite_test.dart# Monte Carlo stochastic simulation
│   └── safety_enforcement_rejection_test.dart        # C3 pre-departure veto tests
└── EMULATOR_VERIFICATION_REPORT.md        # Full Android 16 live verification report
```

---

## 🧪 Conference Verification & Benchmark Reproducibility

Targeted for the **28th International Conference on Advanced Communications Technology (ICACT 2026)**.

| Metric / Item | Status | Verification Detail |
| :--- | :---: | :--- |
| **Android 16 Emulator Run** | **PASS** | Evaluated on Pixel 9 (`emulator-5554`, Android 16 API 36). |
| **End-to-End Corridor C3** | **PASS** | Colombo $\rightarrow$ Nuwara Eliya (158 km, +1502m climb). Detected reserve exhaustion at 30% initial SoC and inserted mitigation stop for safe arrival at 21.2% SoC. |
| **Pre-Departure Veto** | **PASS** | Unassisted 80% SoC C3 trip strictly arrives at **6.5% SoC** ($< 10\%$ floor), triggering mandatory departure **VETO**. |
| **Unit & Benchmark Suite** | **PASS** | 16 test suites passing (Pareto weights, elevation physics, Monte Carlo queueing). |

Refer to [EMULATOR_VERIFICATION_REPORT.md](EMULATOR_VERIFICATION_REPORT.md) for full benchmark tables, formulas, and screenshots.

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.29.2 or higher)
- [Dart SDK](https://dart.dev/get-dart) (3.7.2 or higher)
- Android Studio / Android SDK (Platform-tools ADB 35+)

### Setup
```bash
# 1. Clone repository
git clone https://github.com/IranthaThisal/Evay_lanka.git
cd Evay_lanka/evay_app

# 2. Install dependencies
flutter pub get

# 3. Run static analysis & test suite
flutter analyze
flutter test

# 4. Run application
flutter run
```

---

## 📄 License
This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.
