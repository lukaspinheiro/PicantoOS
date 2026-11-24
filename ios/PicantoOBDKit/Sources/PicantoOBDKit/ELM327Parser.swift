import Foundation

/// Pure SAE J1979 / ELM327 hexadecimal response parser.
public enum ELM327Parser {
    public static func cleanHexBytes(from response: String, expectedPrefix: String) throws -> [UInt8] {
        let cleaned = response
            .replacingOccurrences(of: ">", with: "")
            .replacingOccurrences(of: "\r", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let tokens = cleaned.split(separator: " ").map(String.init)
        let hexJoined = tokens.joined()

        guard hexJoined.uppercased().hasPrefix(expectedPrefix.uppercased()) else {
            throw OBDTransportError.invalidResponse(response)
        }

        let payloadHex = String(hexJoined.dropFirst(expectedPrefix.count))
        guard payloadHex.count % 2 == 0 else {
            throw OBDTransportError.invalidResponse(response)
        }

        var bytes: [UInt8] = []
        var index = payloadHex.startIndex
        while index < payloadHex.endIndex {
            let nextIndex = payloadHex.index(index, offsetBy: 2)
            let byteString = String(payloadHex[index..<nextIndex])
            guard let byte = UInt8(byteString, radix: 16) else {
                throw OBDTransportError.invalidResponse(response)
            }
            bytes.append(byte)
            index = nextIndex
        }

        return bytes
    }

    /// PID 01 05: A - 40 (°C)
    public static func parseCoolantTempC(from response: String) throws -> Double {
        let bytes = try cleanHexBytes(from: response, expectedPrefix: "4105")
        guard let a = bytes.first else { throw OBDTransportError.invalidResponse(response) }
        return Double(Int(a) - 40)
    }

    /// PID 01 0F: A - 40 (°C)
    public static func parseIntakeAirTempC(from response: String) throws -> Double {
        let bytes = try cleanHexBytes(from: response, expectedPrefix: "410F")
        guard let a = bytes.first else { throw OBDTransportError.invalidResponse(response) }
        return Double(Int(a) - 40)
    }

    /// PID 01 0C: ((A * 256) + B) / 4
    public static func parseRPM(from response: String) throws -> Int {
        let bytes = try cleanHexBytes(from: response, expectedPrefix: "410C")
        guard bytes.count >= 2 else { throw OBDTransportError.invalidResponse(response) }
        return ((Int(bytes[0]) * 256) + Int(bytes[1])) / 4
    }

    /// PID 01 0D: A (km/h)
    public static func parseSpeedKmh(from response: String) throws -> Int {
        let bytes = try cleanHexBytes(from: response, expectedPrefix: "410D")
        guard let a = bytes.first else { throw OBDTransportError.invalidResponse(response) }
        return Int(a)
    }

    /// PID 01 04: A * 100 / 255 (%)
    public static func parseEngineLoadPct(from response: String) throws -> Double {
        let bytes = try cleanHexBytes(from: response, expectedPrefix: "4104")
        guard let a = bytes.first else { throw OBDTransportError.invalidResponse(response) }
        return (Double(a) * 100.0) / 255.0
    }

    /// PID 01 42: ((A * 256) + B) / 1000 (V)
    public static func parseControlModuleVoltage(from response: String) throws -> Double {
        let bytes = try cleanHexBytes(from: response, expectedPrefix: "4142")
        guard bytes.count >= 2 else { throw OBDTransportError.invalidResponse(response) }
        return Double((Int(bytes[0]) * 256) + Int(bytes[1])) / 1000.0
    }

    /// PID 01 01: Bit 7 of A = MIL ON, Bits 0..6 of A = DTC count
    public static func parseMilAndDtcCount(from response: String) throws -> (milOn: Bool, dtcCount: Int) {
        let bytes = try cleanHexBytes(from: response, expectedPrefix: "4101")
        guard let a = bytes.first else { throw OBDTransportError.invalidResponse(response) }
        let milOn = (a & 0x80) != 0
        let count = Int(a & 0x7F)
        return (milOn, count)
    }

    /// Mode 03: Stored DTCs (2 bytes per DTC after 0x43)
    public static func parseDTCs(from response: String) throws -> [DiagnosticTroubleCodeInfo] {
        let bytes = try cleanHexBytes(from: response, expectedPrefix: "43")
        var codes: [DiagnosticTroubleCodeInfo] = []
        let prefixes = ["P", "C", "B", "U"]

        var i = 0
        while i + 1 < bytes.count {
            let b1 = bytes[i]
            let b2 = bytes[i + 1]
            i += 2

            if b1 == 0 && b2 == 0 { continue }

            let typeIndex = Int((b1 & 0xC0) >> 6)
            let d1 = (b1 & 0x30) >> 4
            let d2 = b1 & 0x0F
            let d3 = (b2 & 0xF0) >> 4
            let d4 = b2 & 0x0F

            let code = "\(prefixes[typeIndex])\(d1)\(String(d2, radix: 16).uppercased())\(String(d3, radix: 16).uppercased())\(String(d4, radix: 16).uppercased())"
            codes.append(DiagnosticTroubleCodeInfo(code: code))
        }

        return codes
    }
}
