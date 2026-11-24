import Foundation
import Observation
import PicantoOBDKit

@MainActor
@Observable
final class TelemetryViewModel {
    var snapshot: TelemetrySnapshot?
    var dtcs: [DiagnosticTroubleCodeInfo] = []
    var isConnected = false
    var statusMessage = "Disconnected"
    var selectedScenario: PicantoMockScenario = .urbanIdle
    var useMockTransport = true
    var voiceAlertsEnabled = true

    private let mockTransport = MockELM327Transport(initialScenario: .urbanIdle)
    private let voiceAlertService = CarPlayVoiceAlertService()
    private var client: OBDClient?
    private var pollingTask: Task<Void, Never>?

    func toggleConnection() async {
        if isConnected {
            await disconnect()
        } else {
            await connect()
        }
    }

    func connect() async {
        let transport: any OBDTransport = useMockTransport ? mockTransport : VgateBLETransport()
        let obdClient = OBDClient(transport: transport)
        client = obdClient

        do {
            statusMessage = "Connecting..."
            try await obdClient.initialize()
            isConnected = true
            statusMessage = "Connected (\(transport.name))"
            startPolling()
        } catch {
            isConnected = false
            statusMessage = "Error: \(error.localizedDescription)"
        }
    }

    func disconnect() async {
        pollingTask?.cancel()
        pollingTask = nil
        await client?.disconnect()
        isConnected = false
        statusMessage = "Disconnected"
    }

    func updateScenario(_ scenario: PicantoMockScenario) async {
        selectedScenario = scenario
        await mockTransport.setScenario(scenario)
    }

    func refreshDTCs() async {
        guard let client else { return }
        do {
            dtcs = try await client.readDTCs()
        } catch {
            statusMessage = "Failed to read DTCs"
        }
    }

    func clearDTCs() async {
        guard let client else { return }
        do {
            try await client.clearDTCs()
            dtcs = []
        } catch {
            statusMessage = "Failed to clear DTCs"
        }
    }

    private func startPolling() {
        pollingTask?.cancel()
        pollingTask = Task { [weak self] in
            while let self, !Task.isCancelled {
                do {
                    if let snap = try await self.client?.pollSnapshot() {
                        self.snapshot = snap
                        self.evaluateVoiceAlerts(for: snap)
                    }
                } catch {
                    self.statusMessage = "OBD polling error"
                }
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }
    }

    private func evaluateVoiceAlerts(for snap: TelemetrySnapshot) {
        guard voiceAlertsEnabled else { return }

        if snap.coolantTempC >= 103.0 {
            voiceAlertService.speakIfNeeded(
                key: "overheat",
                message: "Warning. Critical engine coolant temperature at \(Int(snap.coolantTempC)) degrees Celsius."
            )
        }

        if snap.controlModuleVoltage > 0 && snap.controlModuleVoltage <= 11.9 {
            let formatted = String(format: "%.1f", snap.controlModuleVoltage)
            voiceAlertService.speakIfNeeded(
                key: "low_voltage",
                message: "Warning. Low battery voltage at \(formatted) volts."
            )
        }
    }
}
