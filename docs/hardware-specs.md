# Vehicle & Hardware Specifications

## 1. Target Vehicle
- **Model:** Kia Picanto EX 1.0 12V Flex Automatic (`EX4 1.0 AT FF`)
- **Year / Platform:** 2011/2012 (2nd Generation — TA Platform)
- **Engine:** Kappa 1.0L 3-cylinder inline (`G3LA`), 12V DOHC Dual CVVT, Flex
- **Transmission:** 4-speed traditional torque-converter automatic (`A4CF0`)
- **Steering:** Column-mounted Electric Power Steering (`MDPS / EPS`)

## 2. Diagnostic Bus (OBD-II / J1962)
- **Primary Protocol:** `ISO 15765-4 CAN (11-bit ID, 500 kbps)` (Pins 6 CAN-H, 14 CAN-L)
- **Fallback Protocol:** `ISO 14230-4 KWP2000` (handled via ELM327 `AT SP 0`)
- **ECU Variants:** Bosch `MEG17.9.12` or Continental `SIM2K-243` (varies by production batch).
- **Cluster Limitation:** No analog coolant temperature needle on the factory instrument cluster (only cold/overheat warning lamps), making `PID 01 05` monitoring critical.

## 3. OBD-II Adapter
- **Hardware:** Vgate iCar Pro 2S (Bluetooth 5.2/5.3 BLE)
- **Emulation:** ELM327 v2.3 + extended AT/ST commands
- **Power Management:** Auto-sleep (~3 mA) after ignition off, auto-wake on engine start (safe for permanent installation).

## 4. Infotainment Head Unit
- **Commercial Model:** E-Tech 9" Slim IPS 2-DIN
- **Hardware / Firmware ID:** `ZCD9201-5G-MP59-GF-CVBS` (MCU `V088.156.76`)
- **OS:** Closed embedded RTOS (no `.apk` sideloading or local SDK).
- **Radio Harness:** Original 16+8 pin harness has **no CAN bus** (power, illumination `ILL`, `REVERSE`, and resistive steering wheel controls `SWC KEY1 / GND`).
- **CarPlay Connectivity:** Confirmed **native wired CarPlay** over USB (plus wireless 5 GHz CarPlay), enabling future plug-and-play **CarPlay AI Box** support without firmware modifications.

## 5. Host Mobile Device
- **Device:** iPhone 16 Pro Max (iOS)
- **Role:** BLE gateway to Vgate iCar Pro 2S, CarPlay audio alert host, and cellular uploader to the `.NET 10` backend.
