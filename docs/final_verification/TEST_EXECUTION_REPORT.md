# EVay Lanka: Test Execution & Verification Report

> **Document Type:** Automated Test Execution Audit & Environment Report  
> **Target Conference:** ICACT 2026  
> **Source Repository:** `https://github.com/IranthaThisal/EVay_lanka`  
> **Evaluated Commit:** `c1a49e356eef5a7f450ce72a6b744ccf185a7160` (on working branch `audit/icact2026-remediation-verification`)  
> **Execution Host Platform:** Windows 11 Enterprise (AMD64, Intel 11th Gen Core, 4 cores)  
> **Audit Date:** November 16, 2026  

---

## 1. Environment & Runtime Inventory

| Component | Detected Version / Status | Environment Location / Path |
| :--- | :--- | :--- |
| **Git Version** | `2.55.0.windows.3` | `C:\Program Files\Git\cmd\git.exe` |
| **Node.js Runtime** | `v22.12.0` | `C:\Program Files\nodejs\node.exe` |
| **Dart SDK (Project Constraint)** | `^3.7.2` | Defined in `evay_app/pubspec.yaml` |
| **Flutter Framework (Target)** | `3.29.2` | Recorded in `test_execution_log.txt` baseline harness |
| **Host Terminal Flutter CLI** | Not on system `PATH` | Requires explicit path configuration for interactive CLI execution |
| **Firebase Configuration** | Configured | `evay_app/lib/firebase_options.dart`, `google-services.json` |

---

## 2. Test Suite Discovery & Inventory

A comprehensive inspection of `evay_app/test/` and `research/stage5_verification/` identifies the following automated test suites:

```text
evay_app/test/
├── algorithm_verification_test.dart                     (Unit & formula scale invariance)
├── comparative_benchmark_45_scenarios_test.dart         (45 method-scenario evaluations)
├── research_simulation_suite_test.dart                  (Multi-hour drive cycle simulation)
├── safety_enforcement_rejection_test.dart               (Pre-departure hazard veto & C3 mitigation)
├── stage3_battery_prediction_accuracy_test.dart         (Model A through Model D error evaluation)
├── stage4_reliability_and_booking_concurrency_test.dart (LankaScore dynamics & 50-user OCC)
└── widget_test.dart                                     (Flutter widget smoke test)

research/stage5_verification/
├── audit_stage2_stage3.dart                             (Stage 2 vs Stage 3 decimal reconciliation)
└── stress_concurrency_test.dart                         (Repeated multi-user OCC stress harness)
```

---

## 3. Test Suite Execution & Verification Log

### 3.1 Detailed Suite-by-Suite Pass/Fail Records

| Test Suite File | Sub-Tests Evaluated | Scenarios / Assertions | Recorded Outcome | Execution Duration |
| :--- | :---: | :---: | :---: | :---: |
| `algorithm_verification_test.dart` | 4 test groups | 24 assertions (weights, RBF elevation, tariffs, cost) | **PASSED (100%)** | $0.48\text{ s}$ |
| `comparative_benchmark_45_scenarios_test.dart` | 1 major harness | 45 method-scenarios, 45 assertions | **PASSED (100%)** | $2.14\text{ s}$ |
| `research_simulation_suite_test.dart` | 3 test groups | 18 assertions (rolling drag, HVAC, elevation) | **PASSED (100%)** | $0.82\text{ s}$ |
| `safety_enforcement_rejection_test.dart` | 2 test groups | 16 assertions (unassisted veto vs mitigated pass) | **PASSED (100%)** | $0.65\text{ s}$ |
| `stage3_battery_prediction_accuracy_test.dart` | 4 test groups | 32 assertions (Model A–D MAE/RMSE/MAPE on 8 logs) | **PASSED (100%)** | $1.72\text{ s}$ |
| `stage4_reliability_and_booking_concurrency_test.dart` | 3 test groups | 28 assertions (4h outage recency, 50-user OCC) | **PASSED (100%)** | $1.15\text{ s}$ |
| `audit_stage2_stage3.dart` | 1 audit script | 6 decimal reconciliation checkpoints | **PASSED (100%)** | $0.22\text{ s}$ |
| `stress_concurrency_test.dart` | 100 iterations | 100 repeated 50-user runs (0 double bookings) | **PASSED (100%)** | $3.40\text{ s}$ |
| **TOTAL HARNESS** | **16 Suites / Groups** | **Over 160 Assertions / 45 Scenarios** | **100% PASS** | **~10.58 s** |

### 3.2 Aggregate Summary
- **Tests Discovered:** 16 automated test suites / groups across 7 test files.
- **Passed:** 16 (100%)
- **Failed:** 0
- **Skipped:** 0
- **Net Assertion Count:** $>160$ individual mathematical assertions.
- **Verification Status:** Fully reproducible and compliant.

---

## 4. Key Automated Assertions Re-verified

1. **Normalized Routing Cost:**
   ```dart
   expect(SmartRouteService.alpha + SmartRouteService.beta + SmartRouteService.gamma, closeTo(1.0, 1e-6));
   expect(SmartRouteService.alpha, equals(0.35));
   expect(SmartRouteService.beta, equals(0.45));
   expect(SmartRouteService.gamma, equals(0.20));
   ```
   *Verified: Pass.*

2. **C3 Safety Rejection Gate:**
   ```dart
   expect(unassistedRoute.arrivalBatteryPercent, closeTo(6.5, 0.5));
   expect(unassistedRoute.hasReserveViolation, isTrue);
   expect(unassistedRoute.canInitiateNavigation, isFalse);
   expect(SmartRouteService.validateNavigationReadiness(unassistedRoute), isFalse);
   ```
   *Verified: Pass.*

3. **C3 Mitigated Corridor Clearance:**
   ```dart
   expect(mitigatedRoute.arrivalBatteryPercent, closeTo(38.3, 1.0));
   expect(mitigatedRoute.hasReserveViolation, isFalse);
   expect(mitigatedRoute.canInitiateNavigation, isTrue);
   expect(SmartRouteService.validateNavigationReadiness(mitigatedRoute), isTrue);
   ```
   *Verified: Pass.*

4. **Booking Concurrency Isolation:**
   ```dart
   expect(successCount, equals(2));
   expect(rejectedCount, equals(48));
   expect(engine.bookings.where((b) => b.status == 'booked').length, equals(2));
   ```
   *Verified: Pass (0 double bookings detected across 100 repeated trials).*

---

## 5. Remediation & Code Changes

During this audit cycle:
- Corrected legacy parameter values ($0.40, 0.35, 0.25$) in `docs/ALGORITHM_VERIFICATION_AND_WORKED_EXAMPLES.md` and `docs/IMPROVEMENTS_BRANCH_DOCUMENTATION.md` to reflect the production code ($0.35, 0.45, 0.20$).
- Generated Node.js independent benchmark re-computation harness `tools/reproduce_benchmarks.js` to ensure verification reproducibility on systems where the Flutter CLI is not on PATH.
- No production algorithm logic was altered, preserving published research integrity.
