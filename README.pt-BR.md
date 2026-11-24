# PicantoOS

*Read this in [English](README.md).*

![Swift 6](https://img.shields.io/badge/Swift-6.0-F05138?logo=swift&logoColor=white)
![iOS 17+](https://img.shields.io/badge/iOS-17%2B-000000?logo=apple&logoColor=white)
![.NET 10](https://img.shields.io/badge/.NET-10.0-512BD4?logo=dotnet&logoColor=white)
![MQTT](https://img.shields.io/badge/MQTT-Mosquitto-3C5280?logo=eclipsemosquitto&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-17-4169E1?logo=postgresql&logoColor=white)
![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)

**Plataforma open-source de telemetria OBD-II ELM327 BLE, alertas por voz no CarPlay e automação veicular** — desenvolvida com **Swift / SwiftUI (`CoreBluetooth`)**, **Simulador OBD-II SAE J1979**, **.NET 10 Minimal APIs**, **PostgreSQL** e **MQTT** para o **Kia Picanto EX 1.0 Flex Automático (2011/2012 — Plataforma TA)**.

> **Nota:** Embora calibrado para o Kia Picanto (motor `G3LA` + câmbio `A4CF0`), o pacote `PicantoOBDKit` utiliza estritamente PIDs padrão **SAE J1979** e serve como base limpa de **ELM327 BLE + Simulador Mock em Swift/iOS** para qualquer veículo OBD-II.

---

## Visão Geral da Arquitetura

O PicantoOS foi projetado em **duas fases** para rodar com **custo R$ 0 em software** no desenvolvimento local e evoluir gradualmente para um ecossistema conectado via 4G com partida remota e CarPlay AI Box:

- **Fase 1 (Atual — Telemetria, Alertas por Voz & Simulação):**
  - **iOS (`ios/PicantoOSApp` + `ios/PicantoOBDKit`):** App nativo Swift/SwiftUI para iPhone. Usa a abstração `OBDTransport` com `MockELM327Transport` (5 cenários realistas do Picanto) para testes offline e `VgateBLETransport` (`CoreBluetooth`) para o scanner físico **Vgate iCar Pro 2S BLE**. Emite alertas falados no som do carro via CarPlay com fio (`AVSpeechSynthesizer`), já que o painel original não possui ponteiro de temperatura.
  - **Backend (`backend/`):** **.NET 10 (ASP.NET Core Minimal APIs)** + **PostgreSQL** + **MQTT (`MQTTnet` + Mosquitto)** para persistir viagens, leituras OBD-II, histórico de DTCs e avaliação de alertas.
  - **CI/CD (`.github/workflows/`):** Build e testes automatizados para `.NET 10` (`ubuntu-latest`) e iOS via **XcodeGen** (`macos-latest`).
- **Fase 2 (Planejada — Start/Stop Remoto, A/C & CarPlay AI Box):**
  - **Hardware IoT (ESP32 + 4G/LTE + Start/Stop + bypass de imobilizador):** Conecta-se ao broker **Mosquitto** via MQTT/TLS usando os tópicos definidos em [docs/contracts.md](docs/contracts.md).
  - **CarPlay AI Box USB:** Aproveita a porta USB com CarPlay nativo confirmado na central `ZCD9201-5G-MP59-GF-CVBS` para exibir um dashboard customizado direto na tela de 9" sem restrições de entitlement da Apple.

---

## Estrutura do Repositório

```text
├── .github/workflows/       # CI no GitHub Actions (.NET 10 e iOS XcodeGen em macos-latest)
├── backend/                 # Solution .NET 10 (Minimal APIs + PostgreSQL + MQTTnet + xUnit)
├── docs/                    # Arquitetura, contratos REST/MQTT, specs de hardware, roadmap e ADRs
├── infra/                   # docker-compose.yml (PostgreSQL 17 na porta 5433 + Mosquitto 2.0)
├── ios/                     # PicantoOBDKit (Swift Package) + PicantoOSApp (XcodeGen)
├── AGENTS.md                # Contexto completo e regras do projeto para assistentes de IA
└── LICENSE                  # Licença MIT
```

---

## Quick Start (Desenvolvimento Local)

### 1. Subir PostgreSQL e Mosquitto
```powershell
docker compose -f infra/docker-compose.yml up -d
```
- **PostgreSQL:** `localhost:5433` (mapeado em `5433` para evitar conflito com PostgreSQL local na `5432`)
- **Mosquitto MQTT:** `localhost:1883` (WebSockets na `9001`)

### 2. Rodar Testes e API (.NET 10)
```powershell
dotnet test backend/PicantoOS.sln
dotnet run --project backend/src/PicantoOS.Api
```
- **Health Check:** `GET http://localhost:5080/api/v1/health`
- **OpenAPI Spec (Desenvolvimento):** `http://localhost:5080/openapi/v1.json`

### 3. Documentação Técnica (em Inglês)
- [System Architecture](docs/architecture.md)
- [OBD-II, REST & MQTT Contracts](docs/contracts.md)
- [Vehicle & Hardware Specifications](docs/hardware-specs.md)
- [Project Roadmap](docs/roadmap.md)
- [Architecture Decision Records (ADRs)](docs/adr/001-carplay-audio-vs-entitlement.md)
- [Contexto para IA (AGENTS.md)](AGENTS.md)