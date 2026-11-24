import PicantoOBDKit
import SwiftUI

struct DashboardView: View {
    @State private var viewModel = TelemetryViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    statusHeader
                    metricsGrid
                    mockControlsSection
                    dtcSection
                }
                .padding()
            }
            .navigationTitle("PicantoOS")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(viewModel.isConnected ? "Disconnect" : "Connect") {
                        Task { await viewModel.toggleConnection() }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(viewModel.isConnected ? .red : .blue)
                }
            }
        }
    }

    private var statusHeader: some View {
        HStack {
            Circle()
                .fill(viewModel.isConnected ? Color.green : Color.gray)
                .frame(width: 10, height: 10)
            Text(viewModel.statusMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Toggle("CarPlay Voice", isOn: $viewModel.voiceAlertsEnabled)
                .labelsHidden()
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private var metricsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            MetricCard(
                title: "Coolant (ECT)",
                value: viewModel.snapshot.map { String(format: "%.0f °C", $0.coolantTempC) } ?? "--",
                accent: (viewModel.snapshot?.coolantTempC ?? 0) >= 103 ? .red : .orange
            )
            MetricCard(
                title: "Battery / Alternator",
                value: viewModel.snapshot.map { String(format: "%.1f V", $0.controlModuleVoltage) } ?? "--",
                accent: (viewModel.snapshot?.controlModuleVoltage ?? 14) <= 11.9 ? .red : .green
            )
            MetricCard(
                title: "Engine Speed (RPM)",
                value: viewModel.snapshot.map { "\($0.rpm)" } ?? "--",
                accent: .blue
            )
            MetricCard(
                title: "Intake Air (IAT)",
                value: viewModel.snapshot.map { String(format: "%.0f °C", $0.intakeAirTempC) } ?? "--",
                accent: .purple
            )
            MetricCard(
                title: "Speed",
                value: viewModel.snapshot.map { "\($0.speedKmh) km/h" } ?? "--",
                accent: .cyan
            )
            MetricCard(
                title: "Engine Load",
                value: viewModel.snapshot.map { String(format: "%.0f%%", $0.engineLoadPct) } ?? "--",
                accent: .teal
            )
        }
    }

    private var mockControlsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle("Use Mock ELM327 (Simulator)", isOn: $viewModel.useMockTransport)
                .disabled(viewModel.isConnected)

            if viewModel.useMockTransport {
                Picker("Picanto Scenario", selection: Binding(
                    get: { viewModel.selectedScenario },
                    set: { newValue in
                        Task { await viewModel.updateScenario(newValue) }
                    }
                )) {
                    ForEach(PicantoMockScenario.allCases) { scenario in
                        Text(scenario.rawValue).tag(scenario)
                    }
                }
                .pickerStyle(.menu)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private var dtcSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Diagnostics (MIL / DTCs)")
                    .font(.headline)
                Spacer()
                if viewModel.snapshot?.milOn == true {
                    Label("MIL ON", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption.bold())
                        .foregroundStyle(.orange)
                }
            }

            HStack {
                Button("Read DTCs (Mode 03)") {
                    Task { await viewModel.refreshDTCs() }
                }
                .buttonStyle(.bordered)
                .disabled(!viewModel.isConnected)

                Button("Clear (Mode 04)") {
                    Task { await viewModel.clearDTCs() }
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .disabled(!viewModel.isConnected)
            }

            if !viewModel.dtcs.isEmpty {
                ForEach(viewModel.dtcs) { dtc in
                    Text("• \(dtc.code)")
                        .font(.monospaced(.body)())
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct MetricCard: View {
    let title: String
    let value: String
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(accent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}
