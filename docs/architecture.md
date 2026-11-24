# System Architecture — PicantoOS

## 1. Topology

```mermaid
flowchart LR
    OBD["Vgate iCar Pro 2S\n(BLE / ELM327)"] -->|CoreBluetooth| IOS["iPhone 16 Pro Max\n(PicantoOSApp)"]
    MOCK["MockELM327Transport\n(Picanto Scenarios)"] -.->|Same OBDTransport protocol| IOS
    IOS -->|Wired CarPlay USB: TTS Audio\nAVSpeechSynthesizer| HU["Head Unit ZCD9201 9\"\n(Wired CarPlay)"]
    IOS -->|HTTPS REST\nTelemetry & DTCs| API["Backend .NET 10\n(Minimal APIs)"]
    API --> PG[("PostgreSQL")]
    API <-->|MQTTnet| MQTT["Mosquitto Broker"]
    ESP["[Phase 2] ESP32 + 4G\nStart/Stop & A/C"] <-->|MQTT / TLS| MQTT
    AIBOX["[Phase 2] CarPlay AI Box\nCustom 9\" Dashboard"] -->|REST / WebSocket / MQTT| API
```

---

## 2. Software Layers

### 2.1. iOS Application (`ios/`)
Designed for Windows-based development with cloud builds on GitHub Actions (`macos-latest`) and **zero manual `.pbxproj` editing**:
- **`PicantoOBDKit` (Swift Package):**
  - `OBDTransport`: Async transport protocol (`sendCommand(_:) async throws -> String`).
  - `MockELM327Transport`: Full ELM327 v2.3 simulator supporting `AT` commands (`AT Z`, `AT E0`, `AT L0`, `AT SP 0`, `AT RV`, `AT I`) and **SAE J1979** PIDs (`01 00`, `01 01`, `01 04`, `01 05`, `01 0C`, `01 0D`, `01 0F`, `01 42`, `03`, `04`) across 5 realistic Picanto 1.0 AT scenarios.
  - `ELM327Parser`: Pure, unit-tested hexadecimal frame decoder converting raw SAE J1979 responses into physical values (°C, RPM, V, km/h, %, DTC codes).
  - `VgateBLETransport`: `CoreBluetooth`-ready actor awaiting physical GATT UUIDs from the Vgate iCar Pro 2S.
- **`PicantoOSApp` (SwiftUI + `project.yml` via XcodeGen):**
  - Real-time dashboard highlighting critical metrics (especially Coolant Temp `01 05`, since the Picanto 2012 cluster lacks an analog temp gauge).
  - Transport switcher (`Mock ELM327` vs `Vgate BLE`) and mock scenario selector.
  - `CarPlayVoiceAlertService`: Uses `AVSpeechSynthesizer` with `AVAudioSession` configured to `.playback` + `.duckOthers`, temporarily lowering CarPlay music to announce critical alerts through the car speakers.

### 2.2. `.NET 10` Backend (`backend/`)
- **ASP.NET Core Minimal APIs** organized into focused modules:
  - `Models`: `TelemetryReading`, `TripSession`, `DiagnosticTroubleCode`, and Phase 2 `RemoteStartRequest`/`RemoteStartResponse`.
  - `Data`: `AppDbContext` (EF Core + PostgreSQL in Docker/production; `InMemory` for isolated integration tests).
  - `Services`: `TelemetryAlertEvaluator` (pure domain rules) and `MqttGatewayService` (`BackgroundService` using `MQTTnet`).
  - `Endpoints`: `/api/v1/health`, `/api/v1/telemetry`, `/api/v1/trips`, `/api/v1/dtcs`, `/api/v1/commands`.

### 2.3. Phase 2 Readiness (Remote Start/Stop, A/C & AI Box)
1. **Remote Start Safety Interlocks:** `/api/v1/commands/remote-start` enforces biometric confirmation, `P`/`N` gear verification, and battery voltage `>= 12.1 V` before publishing to `picanto/v1/{vehicleId}/cmd/start`.
2. **CarPlay AI Box:** Exposing standard JSON REST + MQTT allows any future Android app or PWA running on a USB CarPlay AI Box to consume the exact same backend without firmware reverse engineering.

---

## 3. Production Hardening Checklist (Before Public Cloud Exposure)
- Replace `EnsureCreatedAsync()` in `Program.cs` with EF Core Migrations.
- Add API Key / JWT authentication to `/api/v1/*` endpoints.
- Disable `allow_anonymous true` in `mosquitto.conf` and enable username/password + TLS (`8883`).
- Move database credentials out of `appsettings.json` into environment variables or secret managers.
