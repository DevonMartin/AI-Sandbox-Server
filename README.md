# AI Sandbox Server

A container‑ready Swift (Vapor) backend that powers the ChatGPT-powered iOS app AI Sandbox, downloadable [here](https://apps.apple.com/us/app/ai-sandbox-chat-now/id6451053684).
It exposes REST endpoints for:

* user registration & alias management
* OpenAI ChatGPT conversation proxying
* token‑balance tracking
* RevenueCat‑backed in‑app‑purchase (IAP) validation

The stack is designed for **12‑factor** deployment on Fly.io but can run anywhere Docker and PostgreSQL are available.

---

## Table of contents

1. [Architecture overview](#architecture-overview)
2. [File & directory layout](#file--directory-layout)
3. [Getting started](#getting-started)
4. [Environment variables](#environment-variables)
5. [Database schema](#database-schema)
6. [API reference](#api-reference)
7. [Running tests](#running-tests)
8. [Deployment (Fly.io)](#deployment-flyio)
9. [Troubleshooting & FAQ](#troubleshooting--faq)
10. [Contributing](#contributing)

---

## Architecture overview

```
┌────────────────────┐      HTTP/JSON       ┌────────────────────┐
│  Client (iOS app)  ├──────────────────────▶   AI Sandbox API   │
└────────────────────┘                      │  (Vapor on Swift)  │
                                            ├──────────┬─────────┤
              Postgres over TCP             │          │
                   (docker‑compose)         │          │
                                            │          │
         ┌───────────────────────┐       OpenAI   RevenueCat
         │      Postgres DB      │        API      REST API
         └───────────────────────┘
```

### Key components

| Area                        | File(s)                                                                                                                | Responsibility                                             |
| --------------------------- | ---------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------- |
| **Server entry**            | `entrypoint.swift`, `configure.swift`                                                                                  | Boots Vapor, registers providers, middle‑ware & routes     |
| **Routing**                 | `routes.swift`                                                                                                         | Declares all HTTP endpoints                                |
| **Domain models**           | `User.swift`, `InAppPurchase.swift`, `BalanceData.swift`, `ChatGPTEndpointData.swift`                                  | Codable structs that mirror DB tables & external payloads  |
| **Controllers / Use‑cases** | `UserCreate.swift`, `UserAddAliases.swift`, `ChatGPT.swift`, `InAppPurchaseCreate.swift`, `RevenueCatController.swift` | Request handling, validation & orchestration               |
| **Infrastructure**          | `DatabaseController.swift`, `Sequence+Extensions.swift`, `SecretClearance.swift`                                       | DB access, helpers & secrets management                    |
| **Third‑party integration** | `ChatGPTModel+Extensions.swift`, `RevenueCatPayload.swift`                                                             | OpenAI & RevenueCat adapters                               |
| **Config / Ops**            | `Dockerfile`, `docker-compose.yml`, `fly.toml`, `DB Guide.md`                                                          | Container build, local stack, Fly.io deploy & schema notes |
| **Tests**                   | `AppTests.swift`                                                                                                       | End‑to‑end & unit tests with XCTest                        |

---

## Getting started

### Prerequisites

| Tool             | Version                       |
| ---------------- | ----------------------------- |
| Swift            | **5.9** or newer              |
| Docker           | ≥ 24                          |
| Fly CLI (deploy) | 0.2+                          |
| Postgres         | 15 (local dev without Docker) |

### Quick start (Docker‑Compose)

```bash
# 1. Clone repository
git clone <repo‑url>
cd ai-sandbox-server

# 2. Copy example env and edit keys
cp .env.sample .env   # see “Environment variables” below

# 3. Build & run everything (API + Postgres)
docker compose up --build
```

Server becomes available at [http://localhost:8080](http://localhost:8080).
Swagger/OpenAPI output isn’t bundled by default; use `curl` examples in the [API reference](#api-reference).

### Local Swift (no Docker)

```bash
brew install vapor/tap/vapor
createdb ai_sandbox
export $(cat .env | xargs)   # load environment
vapor run
```

---

## Environment variables

Create a `.env` at the repo root or configure secrets in Fly.io:

| Variable             | Required | Example                                        | Purpose                                  |
| -------------------- | -------- | ---------------------------------------------- | ---------------------------------------- |
| `DATABASE_URL`       | ✔        | `postgresql://sandbox:pass@db:5432/ai_sandbox` | Postgres DSN                             |
| `OPENAI_API_KEY`     | ✔        | `sk‑...`                                       | Calls OpenAI Chat Completions            |
| `REVENUECAT_API_KEY` | ✖        | `rc_secret_...`                                | Verifies App Store / Play Store receipts |
| `JWT_SECRET`         | ✖        | Any base64 string                              | Future auth (not yet enforced)           |
| `PORT`               | ✖        | `8080`                                         | HTTP listen port                         |

When running under Docker the compose file will bootstrap Postgres and inject `DATABASE_URL` automatically.

---

## Database schema

> **Reference:** `DB Guide.md`

The application uses **Fluent Postgres** migrations (generated via `vapor run migrate`).
Core tables:

| Table              | Columns (key fields)                                       | Notes                                 |
| ------------------ | ---------------------------------------------------------- | ------------------------------------- |
| `users`            | `id` (UUID PK), `aliases` (text\[]), `created_at`          | Multiple log‑in identities per person |
| `balances`         | `user_id` (FK → users.id), `tokens` (int), `updated_at`    | Tracks ChatGPT usage quota            |
| `in_app_purchases` | `id`, `user_id`, `product_id`, `purchase_date`, `verified` | Written after RevenueCat webhook      |

Run migrations locally:

```bash
docker compose exec api vapor run migrate --yes
```

---

## API reference

<!-- Keep this section updated when routes change -->

| Method & Path             | Purpose                    | Body / Query                           | Returns                     |
| ------------------------- | -------------------------- | -------------------------------------- | --------------------------- |
| `POST /users`             | Register a new user        | `{ "aliases": ["email@example.com"] }` | `201 Created` + `User` JSON |
| `POST /users/:id/aliases` | Add more login aliases     | `{ "aliases": ["…"] }`                 | Updated `User`              |
| `GET /users/:id/balance`  | Current token balance      | –                                      | `{ "tokens": 123 }`         |
| `POST /chat`              | ChatGPT proxy (paid quota) | `ChatGPTEndpointData`                  | `ChatCompletion` JSON       |
| `POST /in-app-purchases`  | Verify IAP with RevenueCat | Apple/Google receipt payload           | `200 OK` + purchase record  |
| `GET /health`             | Liveness / readiness       | –                                      | `"OK"`                      |

Example: chat request

```bash
curl -X POST http://localhost:8080/chat \
  -H "Content-Type: application/json" \
  -d '{
        "model": "gpt-4o-mini",
        "messages": [
          { "role": "user", "content": "Hello!" }
        ],
        "user_id": "18F73944-..."
      }'
```

---

## Running tests

```bash
swift test
```

`AppTests.swift` spins up an embedded Vapor app and asserts:

* route wiring and middle‑ware
* DB migrations create expected tables
* mock calls to OpenAI & RevenueCat return 200

---

## Deployment (Fly.io)

1. **Create app**

   ```bash
   fly launch --swift --name ai-sandbox-api
   fly secrets set $(cat .env | xargs)
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

| Symptom                                       | Fix                                                                                             |
| --------------------------------------------- | ----------------------------------------------------------------------------------------------- |
| **`connection refused` to Postgres**          | `docker compose ps` and ensure `db` is healthy; check `DATABASE_URL`.                           |
| **Chat endpoint returns 401**                 | Confirm `OPENAI_API_KEY` is valid; watch container logs `docker compose logs -f api`.           |
| **Fly deploy times out during health checks** | Make sure `configure.swift` registers an `/health` route and PORT matches Fly `.internal_port`. |

---

## Contributing

1. Fork → feature branch.
2. Run **`swiftformat .`** (or the formatter of your choice) before committing.
3. Ensure `swift test` passes.
4. Open a PR describing your changes.

Bug reports & feature suggestions are welcome in the issue tracker.
For security disclosures, please email **[security@yourdomain.com](mailto:security@yourdomain.com)** instead of filing an issue.

---

> © 2025 AI Sandbox — MIT License. See `LICENSE` for details.
