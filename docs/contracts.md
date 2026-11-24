# Communication Contracts (OBD-II, REST API, MQTT)

## 1. OBD-II / ELM327 Protocol (`PicantoOBDKit`)

All commands strictly follow **SAE J1979** (compatible with both Bosch `MEG17.9.12` and Continental `SIM2K-243` ECUs).

### ELM327 Initialization Sequence
1. `AT Z` → Reset (`ELM327 v2.3`)
2. `AT E0` → Echo Off (`OK`)
3. `AT L0` → Linefeeds Off (`OK`)
4. `AT SP 0` → Auto-detect protocol (`OK` → `ISO 15765-4 CAN 11/500`)

### Monitored PIDs (Phase 1)

| Command | Description | SAE J1979 Formula | Normal Range (Picanto 1.0 AT) | Critical Alert |
| :--- | :--- | :--- | :--- | :--- |
| `01 01` | MIL Status & DTC Count | Bit 7 of `A` = MIL; Bits 0–6 = Count | `MIL = OFF, 0 DTCs` | `MIL = ON` |
| `01 04` | Calculated Engine Load | `A * 100 / 255` (%) | `22–35%` (idle) / `35–45%` (D + A/C) | — |
| `01 05` | Engine Coolant Temp (ECT) | `A - 40` (°C) | `88–96 °C` (warmed up) | `>= 103 °C` (CarPlay Voice) |
| `01 0C` | Engine RPM | `((A * 256) + B) / 4` | `780–850` (P/N) / `660–730` (D + A/C) | `> 6200 RPM` |
| `01 0D` | Vehicle Speed (VSS) | `A` (km/h) | `0–140 km/h` | — |
| `01 0F` | Intake Air Temp (IAT) | `A - 40` (°C) | `45–65 °C` (warm bay) | `>= 72 °C` |
| `01 42` | Control Module Voltage | `((A * 256) + B) / 1000` (V) | `13.8–14.3 V` (running) / `12.3–12.6 V` (key on) | `<= 11.9 V` or `>= 15.0 V` |
| `AT RV` | OBD-II Port Voltage | Direct string (e.g., `14.1V`) | `12.3–14.3 V` | `<= 11.9 V` |
| `03` | Read Stored DTCs | Hex pairs (2 bytes per DTC) | — | Any stored DTC |
| `04` | Clear DTCs & Reset MIL | `44` (confirmation) | — | — |

---

## 2. REST API (`.NET 10` Minimal APIs)

Local base URL: `http://localhost:5080/api/v1`

- `GET /health` — API, PostgreSQL, and MQTT broker connectivity status.
- `POST /telemetry` — Ingests a telemetry snapshot from iOS, persists to PostgreSQL, evaluates alert rules, and publishes to MQTT.
  ```json
  {
    "vehicleId": "picanto-2012",
    "tripId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
    "timestampUtc": "2026-11-24T01:30:00Z",
    "coolantTempC": 92.0,
    "intakeAirTempC": 54.0,
    "rpm": 810,
    "speedKmh": 0,
    "engineLoadPct": 28.5,
    "controlModuleVoltage": 14.1,
    "milOn": true,
    "dtcCount": 1,
    "source": "mock-elm327"
  }
  ```
- `GET /telemetry/latest?vehicleId=picanto-2012` — Returns the most recent reading.
- `POST /trips/start` / `POST /trips/{id}/end` — Trip session lifecycle (triggered by app or iOS Shortcuts on CarPlay connect/disconnect).
- `GET /dtcs?vehicleId=picanto-2012` & `POST /dtcs/sync` — DTC history and synchronization.
- `POST /commands/remote-start` *(Phase 2)* — Validates safety interlocks and dispatches a remote start + A/C command to MQTT.

---

## 3. MQTT Topics (`Mosquitto`)

Topic prefix: `picanto/v1/{vehicleId}/`

| Topic | Direction | Payload (JSON) | Purpose |
| :--- | :--- | :--- | :--- |
| `picanto/v1/{id}/telemetry` | Backend / iOS → Broker | OBD-II Snapshot | Real-time mirroring (Phase 1 & AI Box). |
| `picanto/v1/{id}/alerts` | Backend → Broker | `{ type, severity, message, value }` | Overheat or low-battery alerts. |
| `picanto/v1/{id}/cmd/start` | Backend → ESP32 (Phase 2) | `{ commandId, action, acOn, requestedAtUtc }` | Remote Start/Stop + A/C command. |
| `picanto/v1/{id}/hw/status` | ESP32 → Backend (Phase 2) | `{ gearParkOrNeutral, batteryV, engineRunning, rssi }` | Hardware safety state telemetry. |
