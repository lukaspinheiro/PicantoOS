using System.Text.Json;
using Microsoft.Extensions.Options;
using MQTTnet;
using MQTTnet.Client;

namespace PicantoOS.Api.Services;

public sealed class MqttSettings
{
    public bool Enabled { get; set; } = true;
    public string Host { get; set; } = "localhost";
    public int Port { get; set; } = 1883;
    public string ClientId { get; set; } = "picanto-os-api";
}

public interface IMqttGateway
{
    bool IsConnected { get; }
    Task PublishAsync<T>(string topic, T payload, CancellationToken cancellationToken = default);
}

public sealed class MqttGatewayService : BackgroundService, IMqttGateway
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);
    private readonly MqttSettings _settings;
    private readonly ILogger<MqttGatewayService> _logger;
    private readonly IMqttClient _client;

    public MqttGatewayService(IOptions<MqttSettings> options, ILogger<MqttGatewayService> logger)
    {
        _settings = options.Value;
        _logger = logger;
        _client = new MqttFactory().CreateMqttClient();
    }

    public bool IsConnected => _client.IsConnected;

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        if (!_settings.Enabled)
        {
            _logger.LogInformation("MQTT gateway is disabled by configuration.");
            return;
        }

        var clientOptions = new MqttClientOptionsBuilder()
            .WithTcpServer(_settings.Host, _settings.Port)
            .WithClientId(_settings.ClientId)
            .WithCleanSession()
            .Build();

        _client.ApplicationMessageReceivedAsync += args =>
        {
            var topic = args.ApplicationMessage.Topic;
            var payload = args.ApplicationMessage.ConvertPayloadToString();
            _logger.LogInformation("MQTT message received on {Topic}: {Payload}", topic, payload);
            return Task.CompletedTask;
        };

        while (!stoppingToken.IsCancellationRequested)
        {
            if (!_client.IsConnected)
            {
                try
                {
                    await _client.ConnectAsync(clientOptions, stoppingToken);
                    await _client.SubscribeAsync("picanto/v1/+/hw/status", cancellationToken: stoppingToken);
                    _logger.LogInformation("Connected to MQTT broker at {Host}:{Port}", _settings.Host, _settings.Port);
                }
                catch (Exception ex) when (!stoppingToken.IsCancellationRequested)
                {
                    _logger.LogWarning("MQTT broker unavailable at {Host}:{Port}: {Message}", _settings.Host, _settings.Port, ex.Message);
                }
            }

            try
            {
                await Task.Delay(TimeSpan.FromSeconds(10), stoppingToken);
            }
            catch (OperationCanceledException)
            {
                break;
            }
        }
    }

    public async Task PublishAsync<T>(string topic, T payload, CancellationToken cancellationToken = default)
    {
        if (!_settings.Enabled || !_client.IsConnected)
        {
            return;
        }

        var json = JsonSerializer.Serialize(payload, JsonOptions);
        var message = new MqttApplicationMessageBuilder()
            .WithTopic(topic)
            .WithPayload(json)
            .Build();

        await _client.PublishAsync(message, cancellationToken);
    }

    public override async Task StopAsync(CancellationToken cancellationToken)
    {
        if (_client.IsConnected)
        {
            await _client.DisconnectAsync(cancellationToken: cancellationToken);
        }

        _client.Dispose();
        await base.StopAsync(cancellationToken);
    }
}
