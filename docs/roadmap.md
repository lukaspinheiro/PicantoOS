# Project Roadmap

## Phase 1 — Core Telemetry, Simulation & Voice Alerts (Current)
- [x] Repository architecture, English documentation, and ADRs
- [x] `.NET 10` Minimal APIs backend + PostgreSQL + Mosquitto (`docker-compose.yml`)
- [x] `PicantoOBDKit` Swift Package with `MockELM327Transport` (5 realistic Picanto scenarios)
- [x] `PicantoOSApp` SwiftUI dashboard + `CarPlayVoiceAlertService` (`AVSpeechSynthesizer`)
- [x] GitHub Actions CI for `.NET 10` (`ubuntu-latest`) and iOS XcodeGen (`macos-latest`)
- [ ] Connect `TelemetryViewModel` to `.NET 10` REST API (`/telemetry`, `/trips/start`, `/trips/end`)
- [ ] Add `ActivityKit` Live Activities (Dynamic Island) for `ECT` and `Voltage`
- [ ] Add `AppIntents` for iOS Shortcuts / Siri CarPlay automation
- [ ] Implement `VgateBLETransport` GATT UUIDs upon physical scanner delivery

## Phase 1.5 — Custom 9" Screen Experience
- [ ] Add a USB **CarPlay AI Box** to the `ZCD9201` head unit
- [ ] Build a full-screen 9" dashboard (Android / PWA) consuming the existing `.NET 10` API & Mosquitto WebSockets (`9001`)

## Phase 2 — Connected Car & Remote Start/Stop
- [ ] Hardware module: ESP32 + 4G/LTE modem + PKE/Start-Stop kit + immobilizer bypass
- [ ] Wire gear-position (`P`/`N`) safety sensor and A/C trigger relay
- [ ] Secure `/api/v1/*` with JWT/API Key and Mosquitto with TLS + credentials
- [ ] Enable Face ID-gated remote start & climate control from `PicantoOSApp`
