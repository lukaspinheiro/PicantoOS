import XCTest
@testable import PicantoOBDKit

final class PicantoOBDKitTests: XCTestCase {
    func testMockUrbanIdleMatchesPicantoParameters() async throws {
        let mock = MockELM327Transport(initialScenario: .urbanIdle)
        let client = OBDClient(transport: mock)

        try await client.initialize()
        let snapshot = try await client.pollSnapshot()

        XCTAssertTrue((88.0...96.0).contains(snapshot.coolantTempC))
        XCTAssertTrue((45.0...65.0).contains(snapshot.intakeAirTempC))
        XCTAssertTrue((760...860).contains(snapshot.rpm))
        XCTAssertTrue((13.5...14.5).contains(snapshot.controlModuleVoltage))
        XCTAssertTrue(snapshot.milOn)
        XCTAssertEqual(snapshot.dtcCount, 1)

        let dtcs = try await client.readDTCs()
        XCTAssertEqual(dtcs.map(\.code), ["P0130"])

        try await client.clearDTCs()
        let afterClear = try await client.pollSnapshot()
        XCTAssertFalse(afterClear.milOn)
        XCTAssertEqual(afterClear.dtcCount, 0)
    }

    func testOverheatScenarioTriggersExpectedCoolantTemperature() async throws {
        let mock = MockELM327Transport(initialScenario: .overheatWarning)
        let client = OBDClient(transport: mock)

        try await client.initialize()
        let snapshot = try await client.pollSnapshot()

        XCTAssertGreaterThanOrEqual(snapshot.coolantTempC, 103.0)
    }
}
