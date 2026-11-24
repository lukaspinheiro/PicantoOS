import Foundation

/// CoreBluetooth transport for Vgate iCar Pro 2S (BLE 5.2/5.3).
/// Actor-isolated for Swift 6 strict concurrency; ready for physical GATT UUIDs.
public actor VgateBLETransport: OBDTransport {
    public nonisolated let name = "Vgate iCar Pro 2S (BLE)"
    public private(set) var isConnected = false

    public init() {}

    public func connect() async throws {
        // TODO: Scan for Vgate iCar Pro 2S peripheral (FFE0/FFF0 or custom 128-bit GATT service)
        // and discover RX/TX characteristics once physical hardware arrives.
        throw OBDTransportError.unsupportedCommand("Vgate BLE transport awaiting physical hardware pairing.")
    }

    public func disconnect() async {
        isConnected = false
    }

    public func sendCommand(_ command: String) async throws -> String {
        guard isConnected else { throw OBDTransportError.notConnected }
        throw OBDTransportError.unsupportedCommand(command)
    }
}
