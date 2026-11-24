using Microsoft.EntityFrameworkCore;
using PicantoOS.Api.Data;
using PicantoOS.Api.Endpoints;
using PicantoOS.Api.Services;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddOpenApi();

var dbProvider = builder.Configuration["Database:Provider"] ?? "Postgres";
var connectionString = builder.Configuration["Database:ConnectionString"]
    ?? "Host=localhost;Port=5433;Database=picanto_os;Username=picanto;Password=picanto_dev_password";

builder.Services.AddDbContext<AppDbContext>(options =>
{
    if (string.Equals(dbProvider, "InMemory", StringComparison.OrdinalIgnoreCase))
    {
        options.UseInMemoryDatabase("PicantoOSDev");
    }
    else
    {
        options.UseNpgsql(connectionString);
    }
});

builder.Services.Configure<MqttSettings>(builder.Configuration.GetSection("Mqtt"));
builder.Services.AddSingleton<MqttGatewayService>();
builder.Services.AddSingleton<IMqttGateway>(sp => sp.GetRequiredService<MqttGatewayService>());
builder.Services.AddHostedService(sp => sp.GetRequiredService<MqttGatewayService>());

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    if (db.Database.IsRelational())
    {
        await db.Database.EnsureCreatedAsync();
    }
}

app.MapTelemetryEndpoints();

app.Run();

public partial class Program;
