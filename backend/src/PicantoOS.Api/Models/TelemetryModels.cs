namespace PicantoOS.Api.Models;

public sealed class TelemetryReading
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string VehicleId { get; set; } = "picanto-2012";
    public Guid? TripId { get; set; }
    public DateTimeOffset TimestampUtc { get; set; } = DateTimeOffset.UtcNow;

    /// <summary>PID 01 05 - Engine Coolant Temperature (°C). Critical on Picanto 2012 (no analog gauge).</summary>
    public double CoolantTempC { get; set; }

    /// <summary>PID 01 0F - Intake Air Temperature (°C).</summary>
    public double IntakeAirTempC { get; set; }

    /// <summary>PID 01 0C - Engine RPM.</summary>
    public int Rpm { get; set; }

    /// <summary>PID 01 0D - Vehicle Speed (km/h).</summary>
    public int SpeedKmh { get; set; }

    /// <summary>PID 01 04 - Calculated Engine Load (%).</summary>
    public double EngineLoadPct { get; set; }

    /// <summary>PID 01 42 / AT RV - Control Module / Battery Voltage (V).</summary>
    public double ControlModuleVoltage { get; set; }

    /// <summary>PID 01 01 - Malfunction Indicator Lamp status.</summary>
    public bool MilOn { get; set; }

    /// <summary>PID 01 01 - Stored DTC count.</summary>
    public int DtcCount { get; set; }

    /// <summary>Source transport identifier (e.g. "mock-elm327", "vgate-ble").</summary>
    public string Source { get; set; } = "mock-elm327";
}

public sealed class TripSession
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string VehicleId { get; set; } = "picanto-2012";
    public DateTimeOffset StartedAtUtc { get; set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset? EndedAtUtc { get; set; }
    public string TriggerSource { get; set; } = "ios-app";
    public double? MaxCoolantTempC { get; set; }
    public double? MinVoltage { get; set; }
}

public sealed class DiagnosticTroubleCode
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string VehicleId { get; set; } = "picanto-2012";
    public string Code { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public DateTimeOffset DetectedAtUtc { get; set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset? ClearedAtUtc { get; set; }
    public bool IsActive => ClearedAtUtc is null;
}

public sealed record TelemetryIngestRequest(
    string VehicleId,
    Guid? TripId,
    DateTimeOffset? TimestampUtc,
    double CoolantTempC,
    double IntakeAirTempC,
    int Rpm,
    int SpeedKmh,
    double EngineLoadPct,
    double ControlModuleVoltage,
    bool MilOn,
    int DtcCount,
    string? Source);

public sealed record TelemetryAlert(
    string Type,
    string Severity,
    string Message,
    double Value);

public sealed record TelemetryIngestResponse(
    Guid ReadingId,
    IReadOnlyList<TelemetryAlert> Alerts);

public sealed record StartTripRequest(string VehicleId, string? TriggerSource);

public sealed record SyncDtcsRequest(string VehicleId, IReadOnlyList<DtcItemRequest> Codes);
public sealed record DtcItemRequest(string Code, string? Description);

/// <summary>Phase 2 preparation: Remote Start / A/C command with safety interlocks.</summary>
public sealed record RemoteStartRequest(
    string VehicleId,
    bool TurnOnAc,
    bool GearInParkOrNeutral,
    double CurrentBatteryVoltage,
    bool BiometricConfirmed);

public sealed record RemoteStartResponse(
    Guid CommandId,
    string Status,
    string MqttTopic,
    string Message);
