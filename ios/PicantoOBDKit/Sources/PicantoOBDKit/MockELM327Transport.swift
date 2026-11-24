import Foundation

public enum PicantoMockScenario: String, CaseIterable, Sendable, Identifiable {
    case coldStart = "Cold Start (32 °C)"
    case urbanIdle = "Urban Idle P/N (88–96 °C)"
    case urbanDriveACOn = "Urban Drive D + A/C (32–35 °C)"
    case overheatWarning = "Overheat Warning (104 °C)"
    case lowBatteryWarning = "Low Battery Warning (11.7 V)"

    public var id: String { rawValue }
}

/// Realistic ELM327 v2.3 simulator tuned for Kia Picanto EX 1.0 AT 2011/2012 (G3LA + A4CF0).
public actor MockELM327Transport: OBDTransport {
    public nonisolated let name = "Mock ELM327 (Picanto 1.0 AT)"
    public private(set) var isConnected = false
    public private(set) var scenario: PicantoMockScenario
    private var storedDTCs: [UInt8] = [0x01, 0x30] // P0130 (O2 Sensor Circuit) when MIL is ON
    private var milOn: Bool = true
    private var tick: Int = 0

    public init(initialScenario: PicantoMockScenario = .urbanIdle) {
        self.scenario = initialScenario
    }

    public func setScenario(_ newScenario: PicantoMockScenario) {
        self.scenario = newScenario
        if newScenario == .urbanIdle || newScenario == .urbanDriveACOn {
            self.milOn = true
            if storedDTCs.isEmpty { storedDTCs = [0x01, 0x30] }
        }
    }

    public func connect() async throws {
        try await Task.sleep(nanoseconds: 50_000_000)
        isConnected = true
    }

    public func disconnect() async {
        isConnected = false
    }

    public func sendCommand(_ command: String) async throws -> String {
        guard isConnected else { throw OBDTransportError.notConnected }

        let normalized = command
            .uppercased()
            .replacingOccurrences(of: " ", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        tick += 1
        let jitter = (tick % 3) - 1

        switch normalized {
        case "ATZ":
            return "ELM327 v2.3\r\r>"
        case "ATE0", "ATL0", "ATS0", "ATSP0":
            return "OK\r\r>"
        case "ATI":
            return "ELM327 v2.3 (PicantoOS Mock)\r\r>"
        case "ATDP":
            return "AUTO, ISO 15765-4 (CAN 11/500)\r\r>"
        case "ATRV":
            let v = currentVoltage()
            return String(format: "%.1fV\r\r>", v)
        case "0100":
            return "41 00 BE 3F A8 13\r\r>"
        case "0101":
            let count = milOn ? (storedDTCs.count / 2) : 0
            let byteA = (milOn ? 0x80 : 0x00) | UInt8(count & 0x7F)
            return String(format: "41 01 %02X 07 65 00\r\r>", byteA)
        case "0104":
            let loadPct = currentLoadPct(jitter: jitter)
            let byteA = UInt8(clamping: Int((loadPct * 255.0) / 100.0))
            return String(format: "41 04 %02X\r\r>", byteA)
        case "0105":
            let ect = currentCoolantC(jitter: jitter)
            let byteA = UInt8(clamping: ect + 40)
            return String(format: "41 05 %02X\r\r>", byteA)
        case "010C":
            let rpm = currentRPM(jitter: jitter)
            let raw = rpm * 4
            let a = UInt8((raw >> 8) & 0xFF)
            let b = UInt8(raw & 0xFF)
            return String(format: "41 0C %02X %02X\r\r>", a, b)
        case "010D":
            let speed = currentSpeedKmh(jitter: jitter)
            return String(format: "41 0D %02X\r\r>", UInt8(clamping: speed))
        case "010F":
            let iat = currentIntakeC(jitter: jitter)
            let byteA = UInt8(clamping: iat + 40)
            return String(format: "41 0F %02X\r\r>", byteA)
        case "0142":
            let mv = Int(currentVoltage() * 1000.0)
            let a = UInt8((mv >> 8) & 0xFF)
            let b = UInt8(mv & 0xFF)
            return String(format: "41 42 %02X %02X\r\r>", a, b)
        case "03":
            if storedDTCs.isEmpty {
                return "43 00 00\r\r>"
            }
            let hex = storedDTCs.map { String(format: "%02X", $0) }.joined(separator: " ")
            return "43 \(hex)\r\r>"
        case "04":
            storedDTCs.removeAll()
            milOn = false
            return "44\r\r>"
        default:
            return "NO DATA\r\r>"
        }
    }

    private func currentCoolantC(jitter: Int) -> Int {
        switch scenario {
        case .coldStart: return 32 + jitter
        case .urbanIdle: return 92 + jitter
        case .urbanDriveACOn: return 94 + jitter
        case .overheatWarning: return 104 + max(0, jitter)
        case .lowBatteryWarning: return 89 + jitter
        }
    }

    private func currentIntakeC(jitter: Int) -> Int {
        switch scenario {
        case .coldStart: return 34 + jitter
        case .urbanIdle: return 55 + jitter
        case .urbanDriveACOn: return 61 + jitter
        case .overheatWarning: return 66 + jitter
        case .lowBatteryWarning: return 50 + jitter
        }
    }

    private func currentRPM(jitter: Int) -> Int {
        switch scenario {
        case .coldStart: return 1080 + (jitter * 15)
        case .urbanIdle: return 810 + (jitter * 20)
        case .urbanDriveACOn: return 2250 + (jitter * 120)
        case .overheatWarning: return 710 + (jitter * 15)
        case .lowBatteryWarning: return 690 + (jitter * 20)
        }
    }

    private func currentSpeedKmh(jitter: Int) -> Int {
        switch scenario {
        case .urbanDriveACOn: return max(0, 42 + (jitter * 4))
        default: return 0
        }
    }

    private func currentLoadPct(jitter: Int) -> Double {
        switch scenario {
        case .coldStart: return 34.0 + Double(jitter)
        case .urbanIdle: return 28.0 + Double(jitter * 2)
        case .urbanDriveACOn: return 41.0 + Double(jitter * 3)
        case .overheatWarning: return 43.0 + Double(jitter)
        case .lowBatteryWarning: return 31.0 + Double(jitter)
        }
    }

    private func currentVoltage() -> Double {
        switch scenario {
        case .coldStart: return 12.5
        case .urbanIdle: return 14.1
        case .urbanDriveACOn: return 13.9
        case .overheatWarning: return 13.8
        case .lowBatteryWarning: return 11.7
        }
    }
}
