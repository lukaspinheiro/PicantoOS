# ADR-003: Strict SAE J1979 Standard PIDs in Phase 1

- **Status:** Accepted
- **Context:** The 2011/2012 Kia Picanto EX 1.0 Flex AT shipped with either a Bosch `MEG17.9.12` or Continental `SIM2K-243` ECU. Proprietary extended PIDs (e.g., ATF temperature) vary between ECUs and cannot be safely assumed before physical probing.
- **Decision:** Restrict `PicantoOBDKit` and `MockELM327Transport` to universal **SAE J1979** Mode 01, Mode 03, and Mode 04 commands, using `AT SP 0` for automatic protocol detection.
- **Consequences:** Guaranteed compatibility across both ECU variants and reliable mock behavior before hardware delivery.
