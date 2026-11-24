using PicantoOS.Api.Models;
using PicantoOS.Api.Services;

namespace PicantoOS.Tests;

public class TelemetryAlertEvaluatorTests
{
    [Fact]
    public void Evaluate_NormalPicantoUrbanIdle_ReturnsNoAlerts()
    {
        var reading = new TelemetryReading
        {
            CoolantTempC = 92.0,
            IntakeAirTempC = 55.0,
            Rpm = 810,
            SpeedKmh = 0,
            EngineLoadPct = 28.0,
            ControlModuleVoltage = 14.1,
            MilOn = false,
            DtcCount = 0
        };

        var alerts = TelemetryAlertEvaluator.Evaluate(reading);

        Assert.Empty(alerts);
    }

    [Fact]
    public void Evaluate_CriticalCoolantAndLowVoltageAndMil_ReturnsExpectedAlerts()
    {
        var reading = new TelemetryReading
        {
            CoolantTempC = 104.5,
            IntakeAirTempC = 74.0,
            Rpm = 900,
            ControlModuleVoltage = 11.7,
            MilOn = true,
            DtcCount = 2
        };

        var alerts = TelemetryAlertEvaluator.Evaluate(reading);

        Assert.Contains(alerts, a => a.Type == "COOLANT_OVERHEAT" && a.Severity == "CRITICAL");
        Assert.Contains(alerts, a => a.Type == "INTAKE_AIR_HIGH" && a.Severity == "WARNING");
        Assert.Contains(alerts, a => a.Type == "BATTERY_LOW" && a.Severity == "CRITICAL");
        Assert.Contains(alerts, a => a.Type == "MIL_ACTIVE" && a.Severity == "WARNING");
    }
}
