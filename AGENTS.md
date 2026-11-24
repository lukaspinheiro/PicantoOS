# AGENTS.md — PicantoOS Project Context & Engineering Rules

This file provides complete context for AI coding assistants (such as Antigravity) when opening this repository on any machine.

## 1. Project Goal
Build **PicantoOS**, an open-source connected-car, OBD-II telemetry, and automation ecosystem for a **2011/2012 Kia Picanto EX 1.0 12V Flex Automatic (`EX4 1.0 AT FF`, TA Platform)**:
- **Phase 1 (Current — $0 software cost):** Real-time OBD-II monitoring on iPhone 16 Pro Max (Swift/SwiftUI + `CoreBluetooth`), spoken alerts over wired CarPlay (`AVSpeechSynthesizer`), simulated ELM327 scenarios (`MockELM327Transport`) while waiting for the physical **Vgate iCar Pro 2S BLE** adapter, and telemetry/alert/trip persistence in a **.NET 10** + **PostgreSQL** + **Mosquitto MQTT** backend.
- **Phase 1.5 (Near-term):** Plug a **USB CarPlay AI Box** into the head unit's confirmed wired CarPlay port to render a custom 9" dashboard without Apple CarPlay entitlement restrictions.
- **Phase 2 (Next year):** Add **ESP32 + 4G/LTE + PKE Start/Stop + immobilizer bypass** hardware communicating over MQTT/TLS for biometric-gated remote engine start and A/C pre-conditioning.

## 2. Physical Hardware & Constraints
- **Vehicle:** Kia Picanto EX 1.0 AT 2011/2012 (`G3LA` 3-cyl engine, `A4CF0` 4-speed AT, `MDPS/EPS` electric steering).
- **Cluster limitation:** No analog coolant temperature needle on the factory cluster — `PID 01 05` (Coolant Temp) monitoring + CarPlay voice alerts (`>= 103 °C`) are critical.
- **ECU uncertainty:** Either Bosch `MEG17.9.12` or Continental `SIM2K-243`. **Rule:** Strictly use universal **SAE J1979** PIDs (`Mode 01/03/04`) until physical scanning confirms proprietary PIDs.
- **Head Unit:** `ZCD9201-5G-MP59-GF-CVBS` (MCU `V088.156.76`), closed RTOS (no `.apk`), original radio harness has **no CAN bus** (resistive SWC only). Native **wired USB CarPlay** is physically confirmed.
- **OBD-II Adapter:** Vgate iCar Pro 2S (BLE 5.2/5.3, ELM327 v2.3, ~3 mA auto-sleep).
- **Baseline Mock State (32–35 °C urban Brazil):** `MIL = ON` (pending physical DTC read), `ECT 88–96 °C`, `IAT 45–65 °C` (currently missing front cold-air duct `28210-1Y200`), `13.8–14.3 V` running / `12.3–12.6 V` key-on, `780–850 RPM` in `P/N`, `660–730 RPM` in `D/R + A/C`, load `22–35%` idle / `35–45%` in `D + A/C`.

## 3. Development Environment & Conventions
- **OS:** Primary development is on **Windows** (no local Mac).
- **iOS Project Management:** Never hand-edit `.xcodeproj` or `.pbxproj`. Always edit `ios/project.yml` (XcodeGen) and `ios/PicantoOBDKit`. iOS builds and Swift tests run in GitHub Actions (`macos-latest`).
- **Free iOS Deployment:** Target `$0` software cost (unsigned `.ipa` / sideloading via SideStore or Sideloadly if no paid Apple Developer account is used).
- **Backend:** `.NET 10` Minimal APIs (`backend/PicantoOS.sln`). Keep `backend/nuget.config` pointing to `https://api.nuget.org/v3/index.json` so private machine NuGet feeds do not break restore.
- **Docker Ports:** PostgreSQL is mapped to host port **`5433`** (not `5432`) in `infra/docker-compose.yml` and `appsettings.json` to avoid collisions with local Windows PostgreSQL services. Mosquitto runs on `1883` / `9001`.
- **Language:** Code, technical docs (`docs/`), and `AGENTS.md` are in **English**. `README.pt-BR.md` provides a Portuguese entry point for the Brazilian Kia Picanto community.

## 4. Key Documentation
- `docs/architecture.md` — Topology and hardening checklist
- `docs/contracts.md` — SAE J1979 PIDs, REST endpoints, and MQTT topics
- `docs/hardware-specs.md` — Audited vehicle & head unit specs
- `docs/roadmap.md` — Phase 1, 1.5, and 2 milestones
- `docs/adr/` — Architecture Decision Records