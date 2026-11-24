# ADR-001: CarPlay Audio Alerts & iPhone UI vs. CarPlay Visual Entitlement

- **Status:** Accepted
- **Context:** The head unit (`ZCD9201-5G-MP59-GF-CVBS`) runs a closed RTOS without `.apk` support, so CarPlay is the only native projection path. However, Apple restricts CarPlay visual UI entitlements to specific categories (Navigation, Audio, EV Charging, Parking) and blocks generic OBD-II dashboards without a signed entitlement.
- **Decision:** Run the full SwiftUI dashboard on the iPhone, deliver critical alerts through CarPlay speakers via `AVSpeechSynthesizer` (`.playback` + `.duckOthers`), and reserve custom 9" screen rendering for Phase 1.5 via a plug-and-play USB CarPlay AI Box.
- **Consequences:** Zero Apple approval blockers in Phase 1; immediate hands-free overheat and low-battery warnings over car audio.
