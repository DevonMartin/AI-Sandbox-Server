# AI Sandbox Server

A container-ready Swift (Vapor) backend that powers the iOS app **AI Sandbox**, downloadable [here](https://apps.apple.com/us/app/ai-sandbox-chat-now/id6451053684).

It exposes REST endpoints for:

* OpenAI ChatGPT conversation proxying with token-based billing
* User registration & alias management
* Token balance tracking
* RevenueCat-backed in-app purchase (IAP) validation

The stack is designed for **12-factor** deployment on Fly.io but can run anywhere Docker and PostgreSQL are available.

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [File & Directory Layout](#file--directory-layout)
3. [Getting Started](#getting-started)
4. [Environment Variables](#environment-variables)
5. [Database Schema](#database-schema)
6. [API Reference](#api-reference)
7. [Running Tests](#running-tests)
8. [Deployment (Fly.io)](#deployment-flyio)
9. [Troubleshooting & FAQ](#troubleshooting--faq)

---

## Architecture Overview

```
┌────────────────────┐      HTTP/JSON       ┌────────────────────┐
│  Client (iOS app)  ├──────────────────────▶   AI Sandbox API   │
└────────────────────┘                      │  (Vapor on Swift)  │
                                            ├──────────┬─────────┤
              Postgres over TCP             │          │
                   (docker-compose)         │          │
                                            │          │
         ┌───────────────────────┐       OpenAI   RevenueCat
         │      Postgres DB      │        API      REST API
         └───────────────────────┘
```

### Key Components

| Area                        | File(s)                                                     | Responsibility                                       |
| --------------------------- | ----------------------------------------------------------- | ---------------------------------------------------- |
| **Server entry**            | `entrypoint.swift`, `configure.swift`                       | Boots Vapor, registers providers, middleware & routes |
| **Routing**                 | `routes.swift`                                              | Declares all HTTP endpoints                          |
| **Domain models**           | `User.swift`, `InAppPurchase.swift`                         | Fluent models that mirror DB tables                  |
| **Request/Response DTOs**   | `BalanceData.swift`, `ChatGPTEndpointData.swift`            | Codable structs for API payloads                     |
| **Controllers**             | `ChatGPT.swift`, `DatabaseController.swift`, `RevenueCatController.swift` | Request handling, validation & orchestration |
| **Infrastructure**          | `SecretClearance.swift`, `Sequence+Extensions.swift`        | Auth helpers & utilities                             |
| **Third-party integration** | `ChatGPTModel+Extensions.swift`, `RevenueCatPayload.swift`  | OpenAI & RevenueCat adapters                         |
| **Config / Ops**            | `Dockerfile`, `docker-compose.yml`, `fly.toml`              | Container build, local stack & Fly.io deploy         |
| **Tests**                   | `AppTests.swift`                                            | End-to-end & unit tests                              |

---

## Getting Started

### Prerequisites

| Tool             | Version          |
| ---------------- | ---------------- |
| Swift            | **5.10** or newer |
| Docker           | ≥ 24             |
| Fly CLI (deploy) | 0.2+             |
| Postgres         | 16 (local dev)   |

### Quick Start (Docker Compose)

```bash
# 1. Clone repository
git clone <repo-url>
cd ai-sandbox-server

# 2. Set environment variables
export API_KEY="your-openai-api-key"
export SECRET="your-webhook-secret"

# 3. Build & run everything (API + Postgres)
docker compose up --build
```

Server becomes available at [http://localhost:8080](http://localhost:8080).

### Local Swift (no Docker)

```bash
brew install vapor/tap/vapor
createdb ai_sandbox
export DATABASE_URL="postgresql://localhost/ai_sandbox"
export API_KEY="your-openai-api-key"
export SECRET="your-webhook-secret"
swift run App serve
```

---

## Environment Variables

Configure these via environment or in Fly.io secrets:

| Variable       | Required | Example                                | Purpose                           |
| -------------- | -------- | -------------------------------------- | --------------------------------- |
| `DATABASE_URL` | ✔        | `postgresql://user:pass@db:5432/mydb`  | Postgres connection string        |
| `API_KEY`      | ✔        | `sk-...`                               | OpenAI API key for chat proxying  |
| `SECRET`       | ✔        | Any secure string                      | Auth header for protected endpoints |
| `LOG_LEVEL`    | ✖        | `debug`, `info`                        | Logging verbosity                 |
| `PORT`         | ✖        | `8080`                                 | HTTP listen port                  |

When running under Docker Compose, `DATABASE_URL` is injected automatically.

---

## Database Schema

The application uses **Fluent Postgres** migrations (run automatically on startup).

### Tables

**users**
| Column        | Type       | Notes                                |
| ------------- | ---------- | ------------------------------------ |
| `id`          | String PK  | User identifier                      |
| `aliases`     | String[]   | Multiple login identities per user   |
| `used_credits`| Double     | Total ChatGPT tokens consumed        |
| `created_at`  | Timestamp  |                                      |
| `updated_at`  | Timestamp  |                                      |

**in_app_purchases**
| Column         | Type       | Notes                                    |
| -------------- | ---------- | ---------------------------------------- |
| `id`           | String PK  | Transaction ID                           |
| `user_id`      | String FK  | References users.id                      |
| `product_id`   | String     | Format: `{amount}Tokens` (e.g., "10Tokens") |
| `purchase_date`| Timestamp  |                                          |
| `created_at`   | Timestamp  |                                          |
| `updated_at`   | Timestamp  |                                          |

---

## API Reference

| Method | Path                    | Auth     | Purpose                          |
| ------ | ----------------------- | -------- | -------------------------------- |
| `GET`  | `/`                     | None     | Health check                     |
| `POST` | `/api/chatCompletion`   | None     | Proxy ChatGPT request            |
| `GET`  | `/api/availableModels`  | None     | List available OpenAI models     |
| `POST` | `/api/getBalance`       | None     | Get user's token balance         |
| `PUT`  | `/api/merge`            | None     | Merge multiple user accounts     |
| `POST` | `/revenueCat`           | `SECRET` | RevenueCat webhook handler       |
| `GET`  | `/api/data`             | `SECRET` | Get all users' data              |
| `GET`  | `/api/data/:userID`     | `SECRET` | Get specific user's data         |

### Example: Chat Completion

```bash
curl -X POST http://localhost:8080/api/chatCompletion \
  -H "Content-Type: application/json" \
  -d '{
        "model": "gpt-4o-mini",
        "messages": [
          { "role": "user", "content": "Hello!" }
        ],
        "userID": "18F73944-..."
      }'
```

**Response:**
```json
{
  "message": "Hello! How can I help you today?",
  "cost": 0.0001,
  "newBalance": 9.9999
}
```

### Protected Endpoints

Endpoints marked with `SECRET` auth require an `Authorization` header matching the `SECRET` environment variable.

---

## Running Tests

```bash
swift test
```

Tests use an in-memory SQLite database and cover:

* Route wiring and middleware
* Database migrations
* Chat completion flow
* User balance calculations

---

## Deployment (Fly.io)

1. **Create app**

   ```bash
   fly launch --name ai-sandbox-api
   fly secrets set API_KEY="your-openai-key" SECRET="your-secret"
   ```

2. **Provision Postgres**

   ```bash
   fly postgres create --name sandbox-db
   fly postgres attach --app ai-sandbox-api sandbox-db
   ```

3. **Deploy**

   ```bash
   fly deploy --remote-only
   ```

Autoscaling and regional placement are controlled in `fly.toml`.

---

## Troubleshooting & FAQ

| Symptom                                       | Fix                                                                             |
| --------------------------------------------- | ------------------------------------------------------------------------------- |
| **`connection refused` to Postgres**          | Run `docker compose ps` and ensure `db` is healthy; check `DATABASE_URL`.       |
| **Chat endpoint returns 401**                 | Confirm `API_KEY` is valid; check container logs with `docker compose logs -f`. |
| **Fly deploy times out during health checks** | Ensure the root route `/` returns a response and PORT matches `.internal_port`. |

---

> MIT License
