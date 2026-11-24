using System.Net;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using PicantoOS.Api.Models;

namespace PicantoOS.Tests;

public class PicantoOSApiFactory : WebApplicationFactory<Program>
{
    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.UseSetting("Database:Provider", "InMemory");
        builder.UseSetting("Mqtt:Enabled", "false");
    }
}

public class TelemetryApiTests(PicantoOSApiFactory factory) : IClassFixture<PicantoOSApiFactory>
{
    private readonly HttpClient _client = factory.CreateClient();

    [Fact]
    public async Task HealthEndpoint_ReturnsOk()
    {
        var response = await _client.GetAsync("/api/v1/health");
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task TelemetryIngestAndLatest_PersistsAndEvaluatesAlerts()
    {
        var tripResponse = await _client.PostAsJsonAsync("/api/v1/trips/start", new StartTripRequest("picanto-2012", "carplay-shortcut"));
        Assert.Equal(HttpStatusCode.Created, tripResponse.StatusCode);
        var trip = await tripResponse.Content.ReadFromJsonAsync<TripSession>();
        Assert.NotNull(trip);

        var request = new TelemetryIngestRequest(
            VehicleId: "picanto-2012",
            TripId: trip!.Id,
            TimestampUtc: DateTimeOffset.UtcNow,
            CoolantTempC: 103.5,
            IntakeAirTempC: 58.0,
            Rpm: 710,
            SpeedKmh: 0,
            EngineLoadPct: 39.0,
            ControlModuleVoltage: 14.0,
            MilOn: true,
            DtcCount: 1,
            Source: "mock-elm327");

        var ingestResponse = await _client.PostAsJsonAsync("/api/v1/telemetry", request);
        Assert.Equal(HttpStatusCode.Created, ingestResponse.StatusCode);

        var body = await ingestResponse.Content.ReadFromJsonAsync<TelemetryIngestResponse>();
        Assert.NotNull(body);
        Assert.Contains(body!.Alerts, a => a.Type == "COOLANT_OVERHEAT");

        var latestResponse = await _client.GetAsync("/api/v1/telemetry/latest?vehicleId=picanto-2012");
        Assert.Equal(HttpStatusCode.OK, latestResponse.StatusCode);
    }

    [Fact]
    public async Task RemoteStart_RejectsUnsafeGear_AndAcceptsValidRequest()
    {
        var unsafeRequest = new RemoteStartRequest("picanto-2012", true, GearInParkOrNeutral: false, 12.6, true);
        var unsafeResponse = await _client.PostAsJsonAsync("/api/v1/commands/remote-start", unsafeRequest);
        Assert.Equal(HttpStatusCode.UnprocessableEntity, unsafeResponse.StatusCode);

        var validRequest = new RemoteStartRequest("picanto-2012", true, GearInParkOrNeutral: true, 12.6, true);
        var validResponse = await _client.PostAsJsonAsync("/api/v1/commands/remote-start", validRequest);
        Assert.Equal(HttpStatusCode.Accepted, validResponse.StatusCode);
    }
}
