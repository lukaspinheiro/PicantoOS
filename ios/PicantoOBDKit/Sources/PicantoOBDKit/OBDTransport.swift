import Foundation

public enum OBDTransportError: Error, Sendable, Equatable {
    case notConnected
    case invalidResponse(String)
    case timeout
    case unsupportedCommand(String)
}

/// Abstract transport layer allowing seamless switching between MockELM327Transport
/// and physical VgateBLETransport (CoreBluetooth).
public protocol OBDTransport: Sendable {
    var name: String { get }
    var isConnected: Bool { get async }
    func connect() async throws
    func disconnect() async
    func sendCommand(_ command: String) async throws -> String
}

public struct TelemetrySnapshot: Sendable, Codable, Equatable {
    public let timestampUtc: Date
    public let coolantTempC: Double
    public let intakeAirTempC: Double
    public let rpm: Int
    public let speedKmh: Int
    public let engineLoadPct: Double
    public let controlModuleVoltage: Double
    public let milOn: Bool
    public let dtcCount: Int
    public let source: String

    public init(
        timestampUtc: Date = Date(),
        coolantTempC: Double,
        intakeAirTempC: Double,
        rpm: Int,
        speedKmh: Int,
        engineLoadPct: Double,
        controlModuleVoltage: Double,
        milOn: Bool,
        dtcCount: Int,
        source: String
    ) {
        self.timestampUtc = timestampUtc
        self.coolantTempC = coolantTempC
        self.intakeAirTempC = intakeAirTempC
        self.rpm = rpm
        self.speedKmh = speedKmh
        self.engineLoadPct = engineLoadPct
        self.controlModuleVoltage = controlModuleVoltage
        self.milOn = milOn
        self.dtcCount = dtcCount
        self.source = source
    }
}

public struct DiagnosticTroubleCodeInfo: Sendable, Codable, Equatable, Identifiable {
    public var id: String { code }
    public let code: String

    public init(code: String) {
        self.code = code
    }
}
