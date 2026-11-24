import Foundation

/// High-level ELM327 / SAE J1979 client decoupled from the underlying transport.
public actor OBDClient {
    private let transport: any OBDTransport

    public init(transport: any OBDTransport) {
        self.transport = transport
    }

    public func initialize() async throws {
        try await transport.connect()
        _ = try await transport.sendCommand("AT Z")
        _ = try await transport.sendCommand("AT E0")
        _ = try await transport.sendCommand("AT L0")
        _ = try await transport.sendCommand("AT SP 0")
    }

    public func disconnect() async {
        await transport.disconnect()
    }

    public func pollSnapshot() async throws -> TelemetrySnapshot {
        let milAndCount = try ELM327Parser.parseMilAndDtcCount(from: try await transport.sendCommand("01 01"))
        let load = try ELM327Parser.parseEngineLoadPct(from: try await transport.sendCommand("01 04"))
        let ect = try ELM327Parser.parseCoolantTempC(from: try await transport.sendCommand("01 05"))
        let rpm = try ELM327Parser.parseRPM(from: try await transport.sendCommand("01 0C"))
        let speed = try ELM327Parser.parseSpeedKmh(from: try await transport.sendCommand("01 0D"))
        let iat = try ELM327Parser.parseIntakeAirTempC(from: try await transport.sendCommand("01 0F"))
        let voltage = try ELM327Parser.parseControlModuleVoltage(from: try await transport.sendCommand("01 42"))

        return TelemetrySnapshot(
            coolantTempC: ect,
            intakeAirTempC: iat,
            rpm: rpm,
            speedKmh: speed,
            engineLoadPct: load,
            controlModuleVoltage: voltage,
            milOn: milAndCount.milOn,
            dtcCount: milAndCount.dtcCount,
            source: transport.name
        )
    }

    public func readDTCs() async throws -> [DiagnosticTroubleCodeInfo] {
        let raw = try await transport.sendCommand("03")
        return try ELM327Parser.parseDTCs(from: raw)
    }

    public func clearDTCs() async throws {
        _ = try await transport.sendCommand("04")
    }
}
