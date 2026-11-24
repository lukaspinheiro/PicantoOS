using PicantoOS.Api.Models;

namespace PicantoOS.Api.Services;

public static class TelemetryAlertEvaluator
{
    public const double CoolantCriticalCelsius = 103.0;
    public const double CoolantWarningCelsius = 98.0;
    public const double IntakeAirWarningCelsius = 72.0;
    public const double VoltageLowCritical = 11.9;
    public const double VoltageHighWarning = 15.0;

    public static IReadOnlyList<TelemetryAlert> Evaluate(TelemetryReading reading)
    {
        var alerts = new List<TelemetryAlert>();

        if (reading.CoolantTempC >= CoolantCriticalCelsius)
        {
            alerts.Add(new TelemetryAlert(
                "COOLANT_OVERHEAT",
                "CRITICAL",
                $"Critical engine coolant temperature: {reading.CoolantTempC:F1} °C.",
                reading.CoolantTempC));
        }
        else if (reading.CoolantTempC >= CoolantWarningCelsius)
        {
            alerts.Add(new TelemetryAlert(
                "COOLANT_ELEVATED",
                "WARNING",
                $"Elevated engine coolant temperature: {reading.CoolantTempC:F1} °C.",
                reading.CoolantTempC));
        }

        if (reading.IntakeAirTempC >= IntakeAirWarningCelsius)
        {
            alerts.Add(new TelemetryAlert(
                "INTAKE_AIR_HIGH",
                "WARNING",
                $"High intake air temperature: {reading.IntakeAirTempC:F1} °C.",
                reading.IntakeAirTempC));
        }

        if (reading.ControlModuleVoltage is > 0 and <= VoltageLowCritical)
        {
            alerts.Add(new TelemetryAlert(
                "BATTERY_LOW",
                "CRITICAL",
                $"Low battery/alternator voltage: {reading.ControlModuleVoltage:F2} V.",
                reading.ControlModuleVoltage));
        }
        else if (reading.ControlModuleVoltage >= VoltageHighWarning)
        {
            alerts.Add(new TelemetryAlert(
                "BATTERY_OVERCHARGE",
                "WARNING",
                $"Alternator overvoltage detected: {reading.ControlModuleVoltage:F2} V.",
                reading.ControlModuleVoltage));
        }

        if (reading.MilOn)
        {
            alerts.Add(new TelemetryAlert(
                "MIL_ACTIVE",
                "WARNING",
                $"Check engine light (MIL) active with {reading.DtcCount} trouble code(s).",
                reading.DtcCount));
        }

        return alerts;
    }
}
