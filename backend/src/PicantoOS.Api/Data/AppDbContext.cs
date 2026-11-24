using Microsoft.EntityFrameworkCore;
using PicantoOS.Api.Models;

namespace PicantoOS.Api.Data;

public sealed class AppDbContext(DbContextOptions<AppDbContext> options) : DbContext(options)
{
    public DbSet<TelemetryReading> TelemetryReadings => Set<TelemetryReading>();
    public DbSet<TripSession> TripSessions => Set<TripSession>();
    public DbSet<DiagnosticTroubleCode> DiagnosticTroubleCodes => Set<DiagnosticTroubleCode>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<TelemetryReading>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => new { e.VehicleId, e.TimestampUtc });
            entity.Property(e => e.VehicleId).HasMaxLength(64);
            entity.Property(e => e.Source).HasMaxLength(32);
        });

        modelBuilder.Entity<TripSession>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => new { e.VehicleId, e.StartedAtUtc });
            entity.Property(e => e.VehicleId).HasMaxLength(64);
            entity.Property(e => e.TriggerSource).HasMaxLength(32);
        });

        modelBuilder.Entity<DiagnosticTroubleCode>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => new { e.VehicleId, e.Code });
            entity.Property(e => e.VehicleId).HasMaxLength(64);
            entity.Property(e => e.Code).HasMaxLength(16);
            entity.Property(e => e.Description).HasMaxLength(256);
        });
    }
}
