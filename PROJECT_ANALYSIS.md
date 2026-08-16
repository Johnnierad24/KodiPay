# KodiPay — System Analysis

_A technical review of the KodiPay rental property management platform, covering system architecture, design, frontend, backend, database, auth, hosting, CI/CD, security, rate limiting, caching, logging, monitoring, testing, and scaling._

**Date:** 2026-08-16
**Scope:** `backend/` (Node.js + Express 5), `frontend/` (Flutter web), deployment configs, GitHub.
**Note on "two realities":** the app is **deployed** on Vercel (frontend + backend) with a Neon PostgreSQL database — this matches the working branch `feature/vercel-deploy-invoice-downloads`. The `main` branch still carries the older Render-oriented config (`render.yaml`, Dockerfile). This split is flagged again in §7 and §8.

---

## 1. System Architecture

KodiPay is a **monolithic API + single-page web app**, organized as a monorepo:

```
Browser (Flutter web SPA, built with API_BASE_URL baked in)
        │  HTTPS
        ▼
Vercel (kodipay-frontend.vercel.app)  ── static assets, SPA rewrites to /index.html
        │
        │  HTTPS (JSON)
        ▼
Vercel (kodipay-backend.vercel.app)  ── Express app as ONE serverless function
        │  (vercel.json rewrites every path to /api, entry: api/index.js)
        ▼
Neon PostgreSQL (managed, serverless Postgres, SSL)
```

External services (all called server-side from the Express app):

| Service | Purpose | Direction |
|---|---|---|
| M-Pesa Daraja (Safaricom) | STK Push initiation + callback webhook | outbound + inbound webhook |
| Africa's Talking | SMS rent reminders | outbound |
| OpenAI | KodiBot AI assistant (tool-calling) | outbound |
| Firebase Cloud Messaging | Push notifications | outbound |
| Firebase Storage | Image / document uploads | outbound |

**Tiers:**
1. **Presentation** — Flutter web SPA (role-based dashboards for landlord, tenant, caretaker, agent).
2. **API** — single Express application, ~62 endpoints, controllers → services → `pg` Pool.
3. **Data** — PostgreSQL (`Neon`), schema applied via `db/schema.sql` + `db/migrations.sql`.
4. **External integrations** — M-Pesa, SMS, OpenAI, Firebase, FCM.

**Async flows:** M-Pesa callbacks are processed synchronously but idempotently; receipt PDF generation after payment is fire-and-forget (`generateReceiptForPayment` without `await`). Cron jobs run on Vercel Cron (3 schedules). There is **no queue/broker** — anything asynchronous is either `fire-and-forget`, a DB trigger, or a cron job.

**Assessment:** Appropriate for the current scale (small property portfolio, single tenant of the stack). It is a classic 3-tier monolith with a serverless execution model. Main risks are not architectural complexity but operational maturity (monitoring, testing, security hardening) — covered below.

---

## 2. System Design

### Domain model (tables in `db/schema.sql` + `migrations.sql`)
`users` → `properties` → `units` → `tenancies` → `invoices` / `payments` / `ledger_entries`; plus `maintenance_requests`, `notifications`, `caretaker_assignments`, `documents`, `chatbot_logs`, `password_reset_tokens`, `password_reset_otps`.

### Key business rules
- **Invoicing:** monthly rent invoice generated on the 1st (cron + manual endpoint), `due_date` = 5th of month; duplicate (tenancy, month, year) prevented.
- **Outstanding rent:** `sum(all invoices) − sum(all completed payments)`, floored at 0. Computed consistently in `tenant.controller.js` (overview), `tenancy.controller.js` (list), and `chatbot.tools.js`. *(This was recently fixed so paid history no longer under-reports outstanding.)*
- **Payments:** M-Pesa STK Push creates a `pending` payment keyed by `CheckoutRequestID`; the callback completes it with an **atomic `UPDATE ... WHERE status <> 'completed'`** (idempotent — retries/duplicates cannot double-credit). Manual/cash/bank payments are recorded as `completed` immediately. Every completed payment inserts a `ledger_entries` row and generates a receipt.
- **Maintenance:** priority/category allowlists; tenants must occupy the unit, caretakers must be assigned, landlords must own the property; emergency → `alert` notification.
- **Role model:** `landlord`, `tenant`, `caretaker`, `agent` enforced at middleware + controller level.

### Design qualities
- **Good:** clear layering (controllers → services → db), parameterized SQL throughout, role-scoped queries, single source of truth for money movement (`ledger_entries`), read-only AI tools derived from JWT identity (never from model-supplied args).
- **Gaps:** no ORM/repository layer (raw `pool.query` everywhere — fine now, verbose at scale); the outstanding-rent formula is duplicated in 3 code paths (risk of drift); transactions are used in only a few controllers (tenancy creation, caretaker assignment, password reset) — payments/invoice flows are single-statement so mostly OK; no event sourcing or audit trail beyond `ledger_entries`; `landlord_wallet_screen.dart` / `more_screen.dart` "Wallet & Payouts" are **static demo UI, not wired to any backend**.

---

## 3. Frontend

**Stack:** Flutter (stable, pinned 3.35.3), Material 3, `http` package, `provider` (auth only), `shared_preferences`, `fl_chart`, `pdf` + `dart:js_interop` (client-side PDF), `google_fonts`, `file_picker`, `share_plus`, `url_launcher`, `web`.

**Structure:** `lib/main.dart` (MultiProvider + AuthProvider, named routes, theme) → `models/` (7 fromJson DTOs) → `providers/auth_provider.dart` → `services/api_service.dart` + `pdf_report_service.dart` + `pdf_invoice_service.dart` → `widgets/` (glass.dart, kodi_pay_logo.dart, dashboard_components.dart, shared_screen_components.dart — 88+ reusable components) → `screens/` (64 files).

**State management:** Provider only for auth (user, token, auto-login). Everything else is `StatefulWidget` + `setState` + `FutureBuilder`, with each screen instantiating its own `ApiService()`. No Bloc/Riverpod/GetX, no cache, no offline store.

**API client:** `api_service.dart` reads `API_BASE_URL` from a compile-time `--dart-define` (default `http://localhost:5000/api`; production baked as `https://kodipay-backend.vercel.app/api`). JWT stored in SharedPreferences and attached as `Authorization: Bearer`. `clearToken()` on 401. ~64 API call sites across the app.

**Screens:** landing/welcome, onboarding, register/login/auth (role-aware), forgot/reset password (OTP + email), landlord dashboards (properties, units, tenants, payments, reports, notifications, settings, wallet, tenant act, caretakers, more), tenant flow (pay rent multi-step, M-Pesa/card/bank/cash methods, success, payments table with **Download Invoice / Export Statement**, receipts, notices, maintenance wizard, profile, support, rights, documents), caretaker portal (tasks, alerts, properties, units/vacancy, incidents, profile), shared (info/features/roles/help/terms/privacy, chatbot KodiBot).

**PWA/web:** `web/manifest.json` (name, standalone, theme `#0047A1`, bg `#F8FAFC`, 192/512 + maskable icons — recently replaced with the real KodiPay logo), favicon.ico/png, default Flutter service worker (no custom offline caching), SPA fallback via Vercel rewrites.

**Assessment:**
- Responsive layouts with breakpoints (sidebar↔drawer, wide/narrow splits) — solid.
- Client-side PDF generation is a good call (offloads CPU from the server).
- **Gaps:** zero frontend tests; JWT in SharedPreferences is XSS-accessible (acceptable for web, but no refresh/rotation on 24h expiry → forced re-login); no central API error handling/retry; hardcoded demo phone (`0712 345 678`) and static wallet numbers; `Lexend` font referenced as a string without being registered (falls back silently); duplicated `ApiService` instances.

---

## 4. Backend Logic & APIs

**Stack:** Node.js 22, Express 5, `pg` (raw), `jsonwebtoken`, `bcrypt`, `express-validator`, `helmet`, `cors`, `morgan`, `multer`, `node-cron`, `pdfkit`, `openai`, `firebase-admin`, `axios`, `express-rate-limit`.

**Entry points:**
- `src/server.js` — Express bootstrap (helmet → cors → morgan → json → health → routers → cron → error handler).
- `backend/api/index.js` (Vercel) — `module.exports = require('../src/server')`, no `listen()`; Vercel rewrites all paths to it.

**Endpoints (~62):** `POST /api/auth/register|login|forgot-password|reset-password|send-otp|verify-otp|reset-password-with-otp`, `GET/PUT /api/auth/me|profile`, `POST /auth/change-password`; tenant `GET /api/tenant/overview`; full CRUD for properties, units, tenancies (`/with-new-tenant`), invoices (+ `/generate-monthly`); payments (`POST /api/payments` for M-Pesa/manual, `GET /payments/tenancy/:id`, `PUT /:id/status`, **public webhooks** `POST /api/payments/mpesa/callback[/:token]`); maintenance; notifications (+ announcement/rent-reminder/test); analytics (6 endpoints); reports (8 + PDF/CSV downloads); documents (list/get/upload/generate-lease/generate-receipt/delete); caretakers; chatbot (`POST /chat` rate-limited 20/15min, `GET /history`); upload (`POST /image`, multer 5MB); `GET /api/health`.

**Key flows:**
- **M-Pesa:** `initiateSTKPush` → insert `pending` payment → user is pinged by Safaricom → callback hits secret-path route → optional IP allowlist + STK re-verification in production → idempotent completion → ledger + receipt.
- **Password reset:** 32-byte token (SHA-256 at rest, 30-min expiry, single-use, transactional) and 6-digit OTP (10-min, max 5 attempts). **Dev-mode returns tokens/OTPs in HTTP responses** (guarded by `NODE_ENV !== 'production'`).
- **Chatbot:** OpenAI tool-calling capped at `MAX_TOOL_ROUNDS = 4`, role-scoped read/write tools, last 5 messages injected, logged to `chatbot_logs`, Kenyan rental-law reference + legal disclaimer, demo mode when unkeyed.
- **Cron (Vercel Cron + secret-gated routes):** monthly invoices (1st 00:00), rent reminders (daily 09:00), overdue check (daily 09:30).

**Assessment:** Well-structured for its size; consistent auth patterns; hardened webhook handling. Gaps: no input-validation framework beyond auth/payments (most controllers hand-roll checks); one SQL-interpolation spot (`analytics.service.js` `INTERVAL '${months} months'`) is safe only because the caller `parseInt`s — should be parameterized properly; CORS-rejection errors bubble into the generic 500 handler instead of returning 403.

---

## 5. Databases & Storage

**Database:** PostgreSQL (Neon in production) via a single shared `pg.Pool` (`src/config/db.js`), SSL enabled in production (`DB_SSL=true` → `{ rejectUnauthorized: false }`). All queries are parameterized (`$1…`). Multi-statement flows (tenancy creation, caretaker assignment, password reset) use explicit `pool.connect()` + `BEGIN/COMMIT/ROLLBACK`.

**Schema management:** `db/schema.sql` (190 lines, 13+ tables + indexes) and `db/migrations.sql` (additive idempotent script: fcm_token, OTP table, category/priority constraints, documents table, unique transaction_ref). **No migration runner** — applied manually (`node src/scripts/*.js` or psql). This is the biggest database risk: schema changes are manual and easy to drift.

**Queries:** Heavy use of LATERAL joins to compute stats (units, occupancy, expected rent, arrears, last payment) in property/unit/analytics/tenancy queries. Works today; worth an `EXPLAIN ANALYZE` pass and index review as data grows.

**Storage:** Firebase Storage for uploads (images 5MB MIME-filtered via `/api/upload/image`; PDF/images 10MB via `/api/documents/upload`), with a **simulated URL fallback** when Firebase isn't configured — meaning in dev/staging, "uploads" return fake URLs that point nowhere. Client-side generated PDFs (invoices/receipts/statements/reports) are produced in the browser, not stored server-side by default.

---

## 6. Auth & Permissions

**Mechanism:**
- **JWT (HS256, `expiresIn: '24h'`)** signed with `JWT_SECRET`; `Authorization: Bearer` verified by `auth.middleware.js`; payload `{ id, role }`. **No refresh tokens.**
- **bcrypt cost 10** for all passwords (register, reset, change-password, generated temp passwords).
- **Roles:** `landlord`, `tenant`, `caretaker`, `agent` — DB CHECK constraint + registration whitelist + `checkRole([...])` middleware (403) + controller-level ownership checks.
- **OTP / reset:** OTP hashed SHA-256, 10-min expiry, 5-attempt cap; reset tokens hashed, 30-min, single-use, transactional.
- **Boot validation:** `validateEnv.js` fails fast on missing `JWT_SECRET`/DB vars and **refuses the placeholder secret in production**.

**Assessment:** Solid fundamentals (bcrypt, short-lived JWTs, hashed-at-rest reset tokens, single-use semantics). Gaps:
- No refresh-token rotation — users are forced to log in every 24h.
- No session revocation besides JWT expiry.
- Dev-mode response leakage of reset tokens/OTPs (fine for dev; ensure `NODE_ENV=production` everywhere deployed).
- Google sign-in: **not implemented** in the backend (no google-auth-library, no `/auth/google`); no `google_sign_in` package in the frontend — the feature named on branch `feature/google-sign-in` appears to be UI-only/absent in the current code.
- No 2FA / device management.

---

## 7. Hosting & Cloud

**Production (live, verified):**
- **Frontend:** Vercel — `https://kodipay-frontend.vercel.app` (Flutter web, built locally then deployed prebuilt; SPA rewrite to `index.html`).
- **Backend:** Vercel — `https://kodipay-backend.vercel.app` (Express as one serverless function; `vercel.json` rewrites all → `/api`; health at `/api/health`).
- **Database:** Neon (serverless Postgres, `?sslmode=require`).
- **Cron:** Vercel Cron Jobs — 3 schedules (`/api/cron/monthly-invoices`, `/rent-reminders`, `/overdue-check`), gated by `Authorization: Bearer $CRON_SECRET`. Vercel Hobby plans cap cron frequency — the 3 daily jobs may exceed the free tier, so verify in the dashboard.
- **Integrations:** M-Pesa Daraja (sandbox — **no live STK Push has ever run**), Africa's Talking SMS (sandbox), OpenAI (KodiBot), Firebase (FCM + Storage).

**Alternative config on `main`:** `render.yaml` + `backend/Dockerfile` (node:22-alpine, non-root `USER node`) — an unused-but-present Render path.

**Repo-state risk (important):** the deployed Vercel config, Vercel cron routes, and the full README (live URLs, demo accounts, deploy guide) live on the **unmerged branch** `feature/vercel-deploy-invoice-downloads`. `main` is a Render-only stub. Merging PR #14 would reconcile the repo with production.

---

## 8. CI/CD & Version Control

**Version control:** GitHub (`github.com/Johnnierad24/KodiPay`), `main` + long-lived `feature/*` branches, PR-based workflow (13+ merged PRs). Git history is clean and descriptive.

**CI (.github/workflows/ci.yml):**
- Triggers: push to `main`, all PRs, manual `workflow_dispatch`.
- **Backend job:** ubuntu-latest, Node 22, `npm ci` → `npm test` (`node --test`).
- **Frontend job:** ubuntu-latest, `subosito/flutter-action@v3` pinned to **3.35.3 stable** with cache → `flutter pub get` → `flutter analyze`.
- No `flutter test` (there are no tests), no coverage, no concurrency guard, no artifact upload, no dependabot.

**Blockers:**
- **GitHub Actions is currently blocked by an account billing lock** — CI checks cannot run on PRs until the billing issue is resolved at github.com/settings/billing. This is the #1 thing to fix for a healthy workflow.
- **Deploys are manual** (local `flutter build` + `vercel deploy`), not part of CI — no automatic staging/preview on PRs, and no reproducible "pushed to main = deployed" contract.
- **main ≠ production:** deployed code trails the Vercel branch (see §7).

**Assessment:** Good hygiene (pinned toolchain, PR workflow), but CI is under-powered (no tests to run, no deployment step) and currently non-functional due to billing.

---

## 9. Security

**Strengths:**
- `helmet()` security headers; CORS allowlist when `CORS_ORIGINS` is set.
- Parameterized SQL throughout (mitigates SQLi).
- bcrypt(10) passwords; JWTs with boot-time secret validation; placeholder secret refused in production.
- M-Pesa callback hardening: **secret path** (unknown → 404), optional **IP allowlist** (`MPESA_ALLOWED_IPS`, needs `TRUST_PROXY=true`), **STK re-verification** in production before crediting, **idempotent credit** (`UPDATE ... WHERE status <> 'completed'`).
- Uploads MIME-filtered with size caps; multer in-memory.
- Docker non-root; `.dockerignore` excludes secrets; `.env` gitignored.

**Weaknesses / gaps (priority order):**
1. **`.env.local` not gitignored** in `backend/` and `frontend/` — they contain a live `VERCEL_OIDC_TOKEN`. A careless `git add .` would commit it. Fix `.gitignore` (e.g. `.env*`) and rotate the token.
2. **Auth brute-force limiter is dead code** — `authLimiter` (10/15min) is defined in `auth.routes.js` but attached to **no route**. `DEPLOYMENT.md` claims auth rate limiting exists; it doesn't.
3. **No global/API rate limiting** — only chatbot is limited (20/15min). M-Pesa callback relies on idempotency + IP allowlist (no IP allowlist in sandbox by default).
4. **Compromised OpenAI key** — `DEPLOYMENT.md` flags an OpenAI key was pasted in chat (2026-06-02); it must be rotated.
5. **Dev-mode token/OTP leakage** in HTTP responses when `NODE_ENV !== 'production'`.
6. `express.json()` has no explicit body-size limit.
7. CORS rejections return 500 (not 403).
8. No CSP customization beyond helmet defaults; no CSRF (mitigated by Bearer-header JWTs); no request signing on webhooks other than M-Pesa's.
9. No secrets scanner / secret-leak detection in CI.

---

## 10. Rate Limiting

Current state (all via `express-rate-limit`):
- **Chatbot:** `POST /api/chatbot/chat` — 20 req / 15 min / IP. ✅ wired.
- **Auth:** `authLimiter` — 10 req / 15 min / IP — ❌ **defined but never attached** (dead code).
- **Everything else:** unlimited — including login, registration, payment creation, OTP endpoints, M-Pesa callback.

Gaps: no per-user/IP limits on payment or property mutating endpoints; no lockout strategy beyond OTP attempt cap; no keyed limiting (e.g., by user id); no limiter for the M-Pesa callback path (mitigated by IP allowlist + idempotency in production).

**Recommendation:** attach `authLimiter` (and a stricter OTP/login limiter), add a conservative global limiter behind a trusted proxy (set `TRUST_PROXY=true` on Vercel — currently only set in dev/Render config), and consider IP allowlisting the M-Pesa callback in production (already supported).

---

## 11. Caching & CDN

- **Server caching: none.** No Redis, node-cache, or DB-level caching — every request hits Postgres. The hot dashboard/overview queries (LATERAL joins) would benefit most.
- **CDN:** Vercel serves the static Flutter build from its edge — asset caching works out of the box; the default Flutter service worker caches the app shell.
- **Client caching:** none beyond per-screen in-memory state; no shared_preferences persistence for data (only JWT).
- **API caching:** no `Cache-Control` headers on read endpoints, no stale-while-revalidate, no conditional requests.

**Recommendation:** add `Cache-Control` for static assets (already handled by Vercel), consider `immutable` hashed asset caching, add DB query caching for landlord dashboard/analytics (Redis or Neon serverless caching), and cache tenant overview per tenancy with short TTL.

---

## 12. Error Tracking & Logs

- **Request logs:** `morgan('dev')` → stdout (Vercel function logs, limited retention on Hobby).
- **Errors:** single global handler in `server.js` — `console.error(err.stack)` → generic `500 {"error":"Something went wrong!"}`. Controllers log via `console.log/error/warn`.
- **No structured logging** (no winston/pino), **no error tracking** (no Sentry/Datadog), **no request IDs**, **no log shipping or retention strategy**.

Gaps: 5xx errors are silently swallowed to console; no error grouping/alerting; no request correlation between Vercel, Neon, and third parties; cron failures are logged to console only (Vercel can surface cron failures if configured).

**Recommendation:** add Sentry (Node SDK, minimal effort, catches unhandled + async errors and M-Pesa callback failures), switch morgan to `tiny` in production, add request-ID middleware, and persist a lightweight audit/error table for payment/callback failures.

---

## 13. Monitoring & Alerts

**Effectively absent:**
- No uptime monitor configured (Vercel has built-in status for the site, but no external check).
- No APM (response times, DB latency, cold starts).
- No error alerting (see §12).
- No database monitoring beyond Neon's dashboard.
- No traffic/usage analytics (no GA/PostHog) — only **business** analytics (occupancy, collection rate, revenue trends) which are app features, not telemetry.

**What exists that helps:** `/api/health` endpoint (ready for UptimeRobot/Pingdom/Vercel monitoring), Vercel deployment + cron notifications, Neon DB metrics.

**Recommendation:** set up an uptime check on `https://kodipay-frontend.vercel.app` and `https://kodipay-backend.vercel.app/api/health`; add Sentry for error alerting; review Neon dashboard for slow queries; add a cron-failure alert; consider simple status pages or APM (e.g. Sentry Performance) when traffic justifies it.

---

## 14. Testing

- **Backend:** Node built-in runner (`npm test` → `node --test`). **Exactly 1 file** — `src/config/mpesa.test.js` (6 tests: env→URL mapping, paybill/till mapping). Controllers, routes, services (M-Pesa flow, payments, auth, invoice generation, cron) are **untested**.
- **Frontend:** **zero tests.** No `test/` directory. CI runs only `flutter analyze`.
- **No integration tests, no e2e** (M-Pesa sandbox flow never automated), **no coverage reporting**, no contract tests.

Assessment: the project's weakest discipline. The critical money-moving path (M-Pesa pending→callback→completed→ledger→receipt) has no automated tests; regression risk is high. Note CI's `flutter test` step is absent largely because there is nothing to run.

**Recommendation (incrementally):**
1. Attach `authLimiter` bug test + basic auth/login/registration tests (supertest + node:test).
2. Test the M-Pesa callback idempotency (the `UPDATE ... WHERE status <> 'completed'` invariant) and payment flow.
3. Add Flutter widget tests for the money screens (payments table, invoice download, forms) and `flutter test` to CI.
4. Add coverage gates and an e2e smoke test against the sandbox when a sandbox phone is available.

---

## 15. Scaling

**Current posture:** Serverless single-function backend + serverless Postgres — effectively "scale to zero," no capacity planning needed at current usage. Vercel/Neon both auto-scale within their plans.

**Bottlenecks as usage grows:**
1. **Database:** heavy LATERAL-join aggregate queries on dashboards; single shared Pool on a serverless function risks connection exhaustion → enable **Neon pooled connection** (PgBouncer) and review indexes/`EXPLAIN`.
2. **No caching** (§11) → each dashboard hit re-computes aggregates; a 10–100× data growth will show on the overview queries.
3. **Serverless cold starts** for the single Express function (acceptable for a small app; revisit if latency matters).
4. **OpenAI costs/latency** per chat (capped at 4 tool rounds; demo mode exists).
5. **Vercel Hobby limits:** cron frequency and function execution (paying-proportional usage) — plan to move to Pro when traffic grows.
6. **Monolith split:** not needed yet; keep the API whole until a boundary (e.g. webhooks vs app API) justifies separate functions.

**Recommendation:** index the hot query columns (`payments.transaction_ref`, `invoices(tenancy_id, month, year)`, `tenancies(user_id, status)`), use Neon pooled endpoint + `DB_SSL=true`, add short-TTL caching for dashboard aggregates, and add an index-review + `EXPLAIN ANALYZE` pass before public launch.

---

## Summary & Prioritized Roadmap

**What's solid:** cohesive domain model; hardened M-Pesa webhook (secret path, IP allowlist, verification, idempotency); parameterized SQL; role-based access; clean frontend structure; client-side PDFs; pinned CI toolchain; good git hygiene.

**Critical fixes before/around public launch:**
1. Unblock GitHub Actions billing so CI actually runs on PRs.
2. Gitignore `.env.local` (both dirs) and rotate `VERCEL_OIDC_TOKEN`; rotate the compromised OpenAI key.
3. Merge `feature/vercel-deploy-invoice-downloads` so `main` matches production (Vercel config, cron routes, README).
4. Wire the auth rate limiter + add a global limiter (and set `TRUST_PROXY=true` on Vercel).
5. Add error tracking (Sentry) + uptime monitoring + cron-failure alerts.

**High-value next:** automated tests for the payment/invoice flow; Neon pooled connection + index review; caching for dashboard queries; refresh-token/rotation strategy; schema migration tooling; dependabot + secrets scanning in CI.

---

*This document is an analysis artifact — no code was changed to produce it. Facts reflect the repository and the live Vercel deployment as of 2026-08-16.*
