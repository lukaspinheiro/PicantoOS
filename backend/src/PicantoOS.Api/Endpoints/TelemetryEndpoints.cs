using Microsoft.EntityFrameworkCore;
using PicantoOS.Api.Data;
using PicantoOS.Api.Models;
using PicantoOS.Api.Services;

namespace PicantoOS.Api.Endpoints;

public static class TelemetryEndpoints
{
    public static void MapTelemetryEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/v1");

        group.MapGet("/health", async (AppDbContext db, IMqttGateway mqtt, CancellationToken ct) =>
        {
            var canConnectDb = await db.Database.CanConnectAsync(ct);
            return Results.Ok(new
            {
                service = "PicantoOS.Api",
                status = canConnectDb ? "Healthy" : "Degraded",
                databaseConnected = canConnectDb,
                mqttConnected = mqtt.IsConnected,
                timestampUtc = DateTimeOffset.UtcNow
            });
        });

        group.MapPost("/telemetry", async (
            TelemetryIngestRequest request,
            AppDbContext db,
            IMqttGateway mqtt,
            CancellationToken ct) =>
        {
            var vehicleId = string.IsNullOrWhiteSpace(request.VehicleId) ? "picanto-2012" : request.VehicleId.Trim();

            var reading = new TelemetryReading
            {
                VehicleId = vehicleId,
                TripId = request.TripId,
                TimestampUtc = request.TimestampUtc ?? DateTimeOffset.UtcNow,
                CoolantTempC = request.CoolantTempC,
                IntakeAirTempC = request.IntakeAirTempC,
                Rpm = request.Rpm,
                SpeedKmh = request.SpeedKmh,
                EngineLoadPct = request.EngineLoadPct,
                ControlModuleVoltage = request.ControlModuleVoltage,
                MilOn = request.MilOn,
                DtcCount = request.DtcCount,
                Source = string.IsNullOrWhiteSpace(request.Source) ? "mock-elm327" : request.Source.Trim()
            };

            db.TelemetryReadings.Add(reading);

            if (request.TripId.HasValue)
            {
                var trip = await db.TripSessions.FirstOrDefaultAsync(t => t.Id == request.TripId.Value, ct);
                if (trip is not null)
                {
                    trip.MaxCoolantTempC = trip.MaxCoolantTempC.HasValue
                        ? Math.Max(trip.MaxCoolantTempC.Value, reading.CoolantTempC)
                        : reading.CoolantTempC;
                    trip.MinVoltage = trip.MinVoltage.HasValue
                        ? Math.Min(trip.MinVoltage.Value, reading.ControlModuleVoltage)
                        : reading.ControlModuleVoltage;
                }
            }

            await db.SaveChangesAsync(ct);

            var alerts = TelemetryAlertEvaluator.Evaluate(reading);
            await mqtt.PublishAsync($"picanto/v1/{vehicleId}/telemetry", reading, ct);

            if (alerts.Count > 0)
            {
                await mqtt.PublishAsync($"picanto/v1/{vehicleId}/alerts", alerts, ct);
            }

            return Results.Created($"/api/v1/telemetry/{reading.Id}", new TelemetryIngestResponse(reading.Id, alerts));
        });

        group.MapGet("/telemetry/latest", async (string? vehicleId, AppDbContext db, CancellationToken ct) =>
        {
            var id = string.IsNullOrWhiteSpace(vehicleId) ? "picanto-2012" : vehicleId.Trim();
            var latest = await db.TelemetryReadings
                .Where(r => r.VehicleId == id)
                .OrderByDescending(r => r.TimestampUtc)
                .FirstOrDefaultAsync(ct);

            return latest is null ? Results.NotFound() : Results.Ok(latest);
        });

        group.MapPost("/trips/start", async (StartTripRequest request, AppDbContext db, CancellationToken ct) =>
        {
            var trip = new TripSession
            {
                VehicleId = string.IsNullOrWhiteSpace(request.VehicleId) ? "picanto-2012" : request.VehicleId.Trim(),
                TriggerSource = string.IsNullOrWhiteSpace(request.TriggerSource) ? "ios-app" : request.TriggerSource.Trim()
            };

            db.TripSessions.Add(trip);
            await db.SaveChangesAsync(ct);

            return Results.Created($"/api/v1/trips/{trip.Id}", trip);
        });

        group.MapPost("/trips/{id:guid}/end", async (Guid id, AppDbContext db, CancellationToken ct) =>
        {
            var trip = await db.TripSessions.FirstOrDefaultAsync(t => t.Id == id, ct);
            if (trip is null)
            {
                return Results.NotFound();
            }

            trip.EndedAtUtc ??= DateTimeOffset.UtcNow;
            await db.SaveChangesAsync(ct);

            return Results.Ok(trip);
        });

        group.MapGet("/dtcs", async (string? vehicleId, bool? activeOnly, AppDbContext db, CancellationToken ct) =>
        {
            var id = string.IsNullOrWhiteSpace(vehicleId) ? "picanto-2012" : vehicleId.Trim();
            var query = db.DiagnosticTroubleCodes.Where(d => d.VehicleId == id);

            if (activeOnly == true)
            {
                query = query.Where(d => d.ClearedAtUtc == null);
            }

            var items = await query.OrderByDescending(d => d.DetectedAtUtc).ToListAsync(ct);
            return Results.Ok(items);
        });

        group.MapPost("/dtcs/sync", async (SyncDtcsRequest request, AppDbContext db, CancellationToken ct) =>
        {
            var vehicleId = string.IsNullOrWhiteSpace(request.VehicleId) ? "picanto-2012" : request.VehicleId.Trim();
            var incomingCodes = request.Codes
                .Select(c => c.Code.Trim().ToUpperInvariant())
                .Where(c => !string.IsNullOrEmpty(c))
                .ToHashSet();

            var activeExisting = await db.DiagnosticTroubleCodes
                .Where(d => d.VehicleId == vehicleId && d.ClearedAtUtc == null)
                .ToListAsync(ct);

            var now = DateTimeOffset.UtcNow;

            foreach (var existing in activeExisting.Where(e => !incomingCodes.Contains(e.Code)))
            {
                existing.ClearedAtUtc = now;
            }

            var activeSet = activeExisting.Select(e => e.Code).ToHashSet();
            foreach (var item in request.Codes)
            {
                var normalized = item.Code.Trim().ToUpperInvariant();
                if (string.IsNullOrEmpty(normalized) || activeSet.Contains(normalized))
                {
                    continue;
                }

                db.DiagnosticTroubleCodes.Add(new DiagnosticTroubleCode
                {
                    VehicleId = vehicleId,
                    Code = normalized,
                    Description = item.Description ?? "Pending physical OBD-II lookup",
                    DetectedAtUtc = now
                });
                activeSet.Add(normalized);
            }

            await db.SaveChangesAsync(ct);
            return Results.Ok(new { vehicleId, activeCount = incomingCodes.Count });
        });

        group.MapPost("/commands/remote-start", async (
            RemoteStartRequest request,
            IMqttGateway mqtt,
            CancellationToken ct) =>
        {
            if (!request.BiometricConfirmed)
            {
                return Results.BadRequest(new { error = "Biometric confirmation is required for remote start." });
            }

            if (!request.GearInParkOrNeutral)
            {
                return Results.UnprocessableEntity(new { error = "Safety interlock: gear must be in P or N." });
            }

            if (request.CurrentBatteryVoltage < 12.1)
            {
                return Results.UnprocessableEntity(new { error = "Safety interlock: battery voltage too low (< 12.1 V)." });
            }

            var vehicleId = string.IsNullOrWhiteSpace(request.VehicleId) ? "picanto-2012" : request.VehicleId.Trim();
            var commandId = Guid.NewGuid();
            var topic = $"picanto/v1/{vehicleId}/cmd/start";

            await mqtt.PublishAsync(topic, new
            {
                commandId,
                action = "START_ENGINE",
                acOn = request.TurnOnAc,
                requestedAtUtc = DateTimeOffset.UtcNow
            }, ct);

            return Results.Accepted(value: new RemoteStartResponse(
                commandId,
                mqtt.IsConnected ? "DISPATCHED" : "QUEUED_OFFLINE",
                topic,
                "Phase 2 remote start command validated and routed."));
        });
    }
}
