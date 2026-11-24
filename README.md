# PicantoOS

*Leia em [Português (Brasil)](README.pt-BR.md).*

[![iOS CI](https://github.com/lukaspinheiro/PicantoOS/actions/workflows/ios-ci.yml/badge.svg)](https://github.com/lukaspinheiro/PicantoOS/actions/workflows/ios-ci.yml)
[![Backend CI](https://github.com/lukaspinheiro/PicantoOS/actions/workflows/backend-ci.yml/badge.svg)](https://github.com/lukaspinheiro/PicantoOS/actions/workflows/backend-ci.yml)
![Swift 6](https://img.shields.io/badge/Swift-6.0-F05138?logo=swift&logoColor=white)
![iOS 17+](https://img.shields.io/badge/iOS-17%2B-000000?logo=apple&logoColor=white)
![.NET 10](https://img.shields.io/badge/.NET-10.0-512BD4?logo=dotnet&logoColor=white)
![MQTT](https://img.shields.io/badge/MQTT-Mosquitto-3C5280?logo=eclipsemosquitto&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-17-4169E1?logo=postgresql&logoColor=white)
![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)

**Open-source OBD-II ELM327 BLE telemetry, CarPlay voice alerts, and connected-car automation platform** — built with **Swift / SwiftUI (`CoreBluetooth`)**, **SAE J1979 OBD-II Simulator**, **.NET 10 Minimal APIs**, **PostgreSQL**, and **MQTT** for the **Kia Picanto EX 1.0 Flex Automatic (2011/2012 — TA Platform)**.

> **Note:** While calibrated for the Kia Picanto (`G3LA` engine + `A4CF0` 4-speed AT), `PicantoOBDKit` uses standard **SAE J1979** PIDs and works as a clean **iOS Swift ELM327 BLE + Mock Simulator** starter for any OBD-II vehicle.

---

## Architecture Overview

PicantoOS is designed in **two phases** so Phase 1 runs with **$0 software/cloud cost** during local development and gradually evolves into a 4G-connected remote-start & CarPlay AI Box ecosystem:

- **Phase 1 (Current — Telemetry, Voice Alerts & Simulation):**
  - **iOS (`ios/PicantoOSApp` + `ios/PicantoOBDKit`):** Native Swift/SwiftUI app for iPhone. Uses an abstract `OBDTransport` protocol with `MockELM327Transport` (realistic Picanto driving scenarios) for offline testing and `VgateBLETransport` (`CoreBluetooth`) for the physical **Vgate iCar Pro 2S BLE** adapter. Delivers spoken alerts over wired CarPlay (`AVSpeechSynthesizer`) since the factory cluster has no analog coolant temperature gauge.
  - **Backend (`backend/`):** **.NET 10 (ASP.NET Core Minimal APIs)** + **PostgreSQL** + **MQTT (`MQTTnet` + Mosquitto)** to persist trips, OBD-II snapshots, DTC history, and alert evaluations.
  - **CI/CD (`.github/workflows/`):** Automated build and test for `.NET 10` (`ubuntu-latest`) and iOS via **XcodeGen** (`macos-latest`).
- **Phase 2 (Planned — Remote Start/Stop, A/C & CarPlay AI Box):**
  - **IoT Hardware (ESP32 + 4G/LTE + Start/Stop & Immobilizer Bypass):** Connects to the **Mosquitto** broker over MQTT/TLS using the topics defined in [docs/contracts.md](docs/contracts.md).
  - **USB CarPlay AI Box:** Leverages the head unit's confirmed native wired CarPlay port (`ZCD9201-5G-MP59-GF-CVBS`) to display a full custom dashboard on the 9" screen without Apple CarPlay entitlement restrictions.

---

## Repository Structure

```text
├── .github/workflows/       # GitHub Actions CI (.NET 10 & iOS XcodeGen on macos-latest)
├── backend/                 # .NET 10 solution (Minimal APIs + PostgreSQL + MQTTnet + xUnit)
├── docs/                    # Architecture, API/MQTT contracts, hardware specs, roadmap, ADRs
├── infra/                   # docker-compose.yml (PostgreSQL 17 on port 5433 + Mosquitto 2.0)
├── ios/                     # PicantoOBDKit (Swift Package) + PicantoOSApp (XcodeGen)
├── AGENTS.md                # Full project context & rules for AI coding assistants
└── LICENSE                  # MIT License
```

---

## Quick Start (Local Development)

### 1. Start PostgreSQL and Mosquitto
```powershell
docker compose -f infra/docker-compose.yml up -d
```
- **PostgreSQL:** `localhost:5433` (mapped to `5433` to avoid colliding with any local PostgreSQL on `5432`)
- **Mosquitto MQTT:** `localhost:1883` (WebSockets on `9001`)

### 2. Run Backend Tests and API (.NET 10)
```powershell
dotnet test backend/PicantoOS.sln
dotnet run --project backend/src/PicantoOS.Api
```
- **Health Check:** `GET http://localhost:5080/api/v1/health`
- **OpenAPI Spec (Development):** `http://localhost:5080/openapi/v1.json`

### 3. Documentation
- [System Architecture](docs/architecture.md)
- [OBD-II, REST & MQTT Contracts](docs/contracts.md)
- [Vehicle & Hardware Specifications](docs/hardware-specs.md)
- [Project Roadmap](docs/roadmap.md)
- [Architecture Decision Records (ADRs)](docs/adr/001-carplay-audio-vs-entitlement.md)
- [AI Assistant Context (AGENTS.md)](AGENTS.md)

---

## Author

Built and maintained by **Lukas Pinheiro** — [GitHub](https://github.com/lukaspinheiro) · [LinkedIn](https://www.linkedin.com/in/lukas-pinheiro/).
