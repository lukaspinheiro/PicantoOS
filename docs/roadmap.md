# Project Roadmap

The implementation is organized around **hardware arrival and installation effort**, keeping software $0-cost and testable from Day 1.

---

## Phase 1 — Core Platform, Simulation & iOS Automation (Current — Vgate in Transit)
- [x] Repository architecture, English/PT-BR READMEs, MIT License, and ADRs
- [x] `.NET 10` Minimal APIs backend + PostgreSQL + Mosquitto (`docker-compose.yml`)
- [x] `PicantoOBDKit` Swift Package with `MockELM327Transport` (5 realistic Picanto scenarios)
- [x] `PicantoOSApp` SwiftUI dashboard + `CarPlayVoiceAlertService` (`AVSpeechSynthesizer`)
- [x] GitHub Actions CI for `.NET 10` (`ubuntu-latest`) and iOS XcodeGen (`macos-latest`)
- [ ] Connect `TelemetryViewModel` to `.NET 10` REST API (`/telemetry`, `/trips/start`, `/trips/end`) with offline local queue (`SwiftData` / `SQLite`)
- [ ] Add `ActivityKit` Live Activities (Dynamic Island) for `ECT` and `Voltage`
- [ ] Add `AppIntents` for iOS Shortcuts / Siri (CarPlay USB connect/disconnect triggers & Driving Focus automation)
- [ ] Add **Alert Debounce** (filter starter cranking voltage drops) and configurable **Silent/Voice Ignition Briefing** (with user toggle to enable/disable)

---

## Phase 1.2 — Physical OBD-II Integration & Predictive Analytics (When Vgate iCar Pro 2S Arrives)
- [ ] Implement `VgateBLETransport` GATT UUIDs (`CoreBluetooth`) and tiered PID polling cadence (fast RPM/VSS, medium ECT/Voltage/IAT, on-demand MIL/DTC)
- [ ] Probe physical ECU (`MEG17.9.12` vs `SIM2K-243`), read active DTCs (`Mode 03`), and establish `IAT (01 0F)` baseline before/after cold-air duct `28210-1Y200`
- [ ] **Predictive Battery & Alternator Health:** Track cranking `MinVoltage` degradation curves over time to warn before a no-start event
- [ ] **Real Severe-Use Preventive Maintenance:** Track engine-hours (`RPM > 0`), idle traffic percentage (`Speed == 0`), and thermal exposure (`ECT >= 98 °C`) for oil and `A4CF0` ATF intervals
- [ ] **Flex Fuel Trim & Trip Cost Analytics:** Monitor `STFT (01 06)`, `LTFT (01 07)`, and `MAP (01 0B)` to infer Ethanol/Gasoline adaptation and estimate trip cost

---

## Phase 1.5 — Custom 9" Head Unit Experience (USB CarPlay AI Box)
- [ ] Plug USB **CarPlay AI Box** into the `ZCD9201` wired CarPlay port (mounted with airflow clearance for 32–35 °C ambient heat)
- [ ] Build a custom full-screen 9" dashboard (Android / PWA) consuming the `.NET 10` REST API and Mosquitto WebSockets (`9001`)

---

## Phase 2 — Connected Car, Remote Start/Stop & Security (ESP32 + 4G Hardware)
- [ ] Hardware module: ESP32 + 4G/LTE modem + PKE/Start-Stop kit + immobilizer bypass + A/C trigger relay
- [ ] Wire physical `A4CF0` `P`/`N` gear-inhibitor safety interlock into the starter relay circuit
- [ ] Production hardening: EF Core Migrations, JWT/API Key auth on `/api/v1/*`, and Mosquitto TLS (`8883`) + credentials
- [ ] **Biometric Remote Start & A/C** from `PicantoOSApp` with automatic engine shutdown on timeout or `ECT >= 98 °C`
- [ ] **Smart Pre-conditioning:** Cross iOS Calendar + Weather to prompt Face ID-confirmed remote start + A/C before trips
- [ ] **Valet / Workshop Mode:** Real-time alerts if the vehicle leaves a 300 m geofence, exceeds `50 km/h`, or exceeds `3,500 RPM`