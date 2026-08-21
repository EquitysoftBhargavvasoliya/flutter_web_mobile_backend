# flutter_web_mobile_backend

Orbit Marketplace — a buyer/seller marketplace with a Dart backend, a Flutter web storefront, a Flutter admin panel, and a Flutter mobile app, sharing two small Dart packages.

## Architecture

```
Web (Flutter Web, Vercel)      ┐
Admin (Flutter Web, Vercel)    ├──►  Backend API (Dart Shelf, Docker) ──►  PostgreSQL (managed)
Mobile (Flutter, app stores)   ┘
```

- Web and Admin never talk to PostgreSQL directly — only the Backend does.
- All three frontends share `packages/models` (data classes) and `packages/api_client` (Dio-based HTTP client: auth header injection, typed error mapping, request logging).
- Auth: JWT (7-day expiry), verified in `backend/lib/src/core/network/middleware.dart`. Passwords are hashed (`Crypt.sha256`), never stored in plaintext.

```
orbit_marketplace/
├── backend/            Dart Shelf API
├── web_app/            Flutter Web storefront
├── admin_panel/        Flutter Web admin dashboard
├── mobile_app/         Flutter mobile app
├── packages/
│   ├── models/         Shared data models (User, Product, Category, Order)
│   └── api_client/     Shared Dio API client, typed exceptions, logger
├── render.yaml          Render Blueprint (backend + Postgres)
└── .github/workflows/   CI
```

## Local development

Requires Dart SDK `^3.10.3` (Flutter 3.44.5 / Dart 3.12.2 stable is what this was built and tested against) and Docker (for local Postgres).

```bash
# 1. Database (from repo root)
docker compose up -d

# 2. Backend
cd backend
dart pub get
dart run bin/server.dart
# First time only, against a fresh database: psql in the init.sql schema
# (docker-compose does this automatically via docker-entrypoint-initdb.d).

# 3. Web
cd web_app
cp .env.development .env   # or write your own from .env.example
flutter pub get
flutter run -d chrome

# 4. Admin
cd admin_panel
cp .env.development .env
flutter pub get
flutter run -d chrome

# 5. Mobile
cd mobile_app
cp .env.development .env
flutter pub get
flutter run
# On a physical device, either `adb reverse tcp:8080 tcp:8080` (keep
# localhost in .env) or point .env at your machine's LAN IP and allow
# inbound connections to dart.exe through your firewall.
```

The root `.env` (backend) and each app's `.env` are gitignored — never commit real values. Copy from the matching `.env.example` / `.env.development` / `.env.staging` / `.env.production` file instead.

## Environment variables

### Backend (`.env` at repo root, or real env vars on the host)

| Variable | Purpose | Where configured |
|---|---|---|
| `DATABASE_URL` | Postgres connection string | Local `.env`; Render (auto-linked to the `orbit-db` database) |
| `JWT_SECRET` | Signs/verifies auth tokens | Local `.env`; Render (`generateValue: true` in `render.yaml`) |
| `PORT` | Port the server binds to | Usually injected by the host; falls back to `8080` locally |
| `APP_ENV` | `development` / `staging` / `production`, surfaced at `GET /health` | Local `.env`; Render (`render.yaml`) |
| `CORS_ORIGINS` | Comma-separated allowed browser origins | Unset in dev (any localhost origin is allowed automatically); must be set explicitly on Render — see below |
| `DB_SSL_MODE` | `require` to enforce TLS to Postgres | Unset locally (docker-compose Postgres has no TLS); `require` on Render |

### Frontend apps (`web_app/.env`, `admin_panel/.env`, `mobile_app/.env`)

| Variable | Purpose | Where configured |
|---|---|---|
| `API_BASE_URL` | Backend base URL, e.g. `http://localhost:8080/api/v1` | Local `.env`; on Vercel, set as a project Environment Variable (the build writes it into `.env` at build time — see `vercel.json`) |

## Vercel

Two independent Vercel projects, both configured via the `vercel.json` already committed in each app's folder:

**platform-web**
- Root Directory: `web_app`
- Build Command (from `web_app/vercel.json`): installs Flutter, then `flutter build web --release`
- Output Directory: `build/web`
- Environment Variables: `API_BASE_URL` (set per Vercel environment — Production/Preview/Development)
- **Required setting**: enable "Include files outside the root directory" in the project's General settings — `web_app` depends on `../packages/models` and `../packages/api_client` via path dependencies, which live outside the Root Directory.

**platform-admin**
- Root Directory: `admin_panel`
- Same Build Command / Output Directory pattern (from `admin_panel/vercel.json`)
- Same `API_BASE_URL` variable and "include files outside root directory" requirement.

## Backend deployment

Vercel cannot run this backend — it's a persistent Dart Shelf server holding a PostgreSQL connection pool, and Vercel only supports stateless serverless functions with no Dart runtime and no Docker/container support. The backend deploys instead via **Render**, using the existing `backend/Dockerfile` and the `render.yaml` Blueprint at the repo root:

1. On [render.com](https://render.com), New + → Blueprint → select this repo. Render reads `render.yaml` and provisions the `orbit-backend` web service and `orbit-db` Postgres database together.
2. It will prompt for `CORS_ORIGINS` (not auto-filled, since it depends on your actual `web_app`/`admin_panel` domains) — enter something like `https://example.com,https://admin.example.com`.
3. One-time: apply `backend/init.sql` to the new `orbit-db` database (Render's dashboard → the database → Connect → PSQL shell), since Render's Postgres starts empty.
4. `backend/bin/migrate.dart` holds a few ad-hoc, idempotent schema tweaks (safe to re-run) — see the note under "Remaining manual steps" about it seeding a default admin account.

Manual Docker build/run, if you want to test the image locally:

```bash
docker build -f backend/Dockerfile -t orbit-backend .
docker run -p 8080:8080 -e DATABASE_URL=postgres://orbit_admin:orbit_password@host.docker.internal:5433/orbit_db orbit-backend
```

## PostgreSQL

Local dev uses the Postgres container in `docker-compose.yml` (`orbit_admin` / `orbit_password` / `orbit_db`, port 5433). In production, `DATABASE_URL` should point at your managed Postgres provider's connection string in the form `postgres://user:password@host:port/database`; set `DB_SSL_MODE=require` alongside it for providers (like Render) that enforce TLS. Nothing outside the backend ever receives a database credential — Web/Admin/Mobile only ever talk to the backend's HTTP API.

## Domains

Not hard-coded anywhere in source. To wire up real domains:
- **example.com** → point your registrar/DNS at Vercel, add the domain to the **platform-web** Vercel project.
- **admin.example.com** → same, but add it to **platform-admin** instead.
- **api.example.com** → add a custom domain on the Render `orbit-backend` service, then update `API_BASE_URL` in each frontend's Vercel Environment Variables (and each app's local `.env.production`) to `https://api.example.com/api/v1`, and add the same origin to the backend's `CORS_ORIGINS`.

## CI/CD

`.github/workflows/ci.yml` runs on every push/PR to `main`. A `changes` job detects which of `backend/`, `mobile_app/`, `web_app/`, `admin_panel/`, `packages/**` changed and only runs the relevant jobs (a change under `packages/**` runs every consumer, since all four apps depend on it). Each job: `pub get`, a non-blocking format check, static analysis (errors only — this repo has pre-existing style warnings not worth blocking CI over), and a build (`flutter build web` for web/admin, `dart compile exe` + a Docker image build for backend). `mobile_app`'s CI stops at analyze/test — it isn't deployed via CI, and a full APK build would need Android SDK/license setup in the runner, which is a common source of CI flakiness for little benefit here.

CI itself doesn't deploy anything: Vercel deploys `web_app`/`admin_panel` on push once each Vercel project is connected to this GitHub repo (its own native Git integration, not a GitHub Actions step), and Render redeploys `orbit-backend` on push the same way once the Blueprint is created.

## Remaining manual steps

- **GitHub**: push this branch (`git push -u origin main`); connect the repo in both Vercel projects and in Render.
- **Vercel**: create `platform-web` (Root Directory `web_app`) and `platform-admin` (Root Directory `admin_panel`); enable "include files outside the root directory" on both; set `API_BASE_URL` per environment.
- **Render**: deploy the Blueprint; fill in `CORS_ORIGINS` when prompted; run `backend/init.sql` against the new database once.
- **DNS**: point `example.com` / `admin.example.com` at Vercel, `api.example.com` at Render, once you have real domains.
- **`backend/bin/migrate.dart`**: seeds a `Super Admin` account with a hardcoded password (`123456`) if `admin@gmail.com` doesn't already exist. Fine for local dev; change the password or remove that block before ever running this script against a production database.
- **Test suite**: there wasn't a real one — the only test files present were unmodified `flutter create`/`dart create` templates (testing a counter button and a `Hello, World!` echo route that don't exist in this app), so they were removed rather than wired into CI misleadingly. Writing actual tests is worthwhile follow-up work, not done here.
- **Migrations**: `backend/bin/migrate.dart` is a single hand-written, idempotent script, not a versioned migration system. It works, but has no tracking of what's been applied. If this grows further, consider numbered `backend/migrations/NNNN_description.sql` files plus a small runner that records applied migrations in a `schema_migrations` table — not done here since it wasn't asked for and the current script still works.
