# KodiPay

A rental management platform for landlords, tenants, and caretakers. It covers property and tenant management, monthly invoicing, rent collection via M-Pesa (Daraja STK Push), maintenance requests, document generation (leases and payment receipts), analytics, and an AI tenant assistant.

## Live Demo

- Frontend (Flutter web): https://kodipay-frontend.vercel.app
- Backend API (Express): https://kodipay-backend.vercel.app
- Health check: https://kodipay-backend.vercel.app/api/health

## Demo Accounts

| Role      | Email                          | Password     | Notes                    |
| --------- | ------------------------------ | ------------ | ------------------------ |
| Landlord  | njengajohnnie@gmail.com        | password123  | Owns Demo Heights        |
| Caretaker | eunicenjenga72@gmail.com       | password123  | Assigned to Demo Heights |
| Tenant    | peternjenga71@gmail.com        | password123  | Unit A1                  |
| Tenant    | tenant@test.com                | password123  | Unit A2 (Jane Smith)     |
| Tenant    | viviankendi@gmail.com          | password123  | Unit A3                  |
| Tenant    | njengajohnie@gmail.com         | passcode123  | Unit C1                  |
| Tenant    | joannjenga@gmail.com           | joan123      | Unit C2                  |
| Tenant    | paullamar@gmail.com            | password123  | Unit D1                  |
| Tenant    | rodgersog@gmail.com            | rodgers123   | Unit D2                  |

The demo property (Demo Heights) has seven occupied units, each with paid rent history for May-July 2026 and a pending invoice for August 2026. All tenant phones are set to the Daraja sandbox MSISDN `254708374149` so M-Pesa STK pushes can be tested end to end.

## Features

**Landlord / Agent**
- Portfolio dashboard with revenue, occupancy, collection rate, and maintenance stats
- Property, unit, and tenant management with add-tenant and lease workflows
- Monthly invoice generation and status tracking (pending / paid / overdue)
- Rent collection with M-Pesa STK Push, plus bank, cash, and card flows
- Reports (payment, occupancy, income, arrears, property performance, maintenance, trends, transactions) with PDF and CSV export
- Documents: auto-generated leases and payment receipts, file uploads
- Notification center and overdue-rent alerts
- KodiBot, an AI assistant backed by the same data

**Tenant**
- Dashboard with current balance, recent transactions, and unit details
- Download Invoice (current month PDF invoice) and Download Receipt / Export Statement (PDF)
- Make Payment via M-Pesa STK Push, bank transfer, cash, or card
- Maintenance request wizard
- Legal corner (Tenant Rights, Landlord-Tenant Act)
- KodiBot assistant

**Caretaker**
- View assigned properties and units
- Manage unit occupancy status and flag vacant units

## Repository Layout

```
KodiPay/
├── backend/   Express API (Node.js + PostgreSQL)
├── frontend/  Flutter web app
└── README.md
```

## Tech Stack

- Backend: Node.js, Express, PostgreSQL (`pg`), JSON Web Tokens, `node-cron`, Multer, PDFKit
- Frontend: Flutter (web), `pdf` package for client-side PDF generation
- Payments: Safaricom Daraja API (M-Pesa) via STK Push, sandbox enabled by default
- Optional integrations: OpenAI (chatbot), AfricasTalking (SMS), Firebase (notifications/storage)
- Hosting: Vercel (serverless backend + static frontend), Neon PostgreSQL

## Getting Started (Local Development)

### Prerequisites

- Node.js 18+
- Flutter 3.35+ with web support enabled
- A PostgreSQL database (local or managed)

### 1. Backend

```bash
cd backend
cp .env.example .env
# Fill in DB_* and JWT_SECRET (M-Pesa / OpenAI / SMS / Firebase are optional for local dev)
npm install
npm run dev
```

The server runs on `http://localhost:5000` with routes under `/api`.

Required environment variables (see `backend/.env.example` for the full list):

- `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD` — set `DB_SSL=true` for managed Postgres (e.g. Neon)
- `JWT_SECRET` — any long random string
- `CORS_ORIGINS` — comma-separated browser origins to allow (unset = allow all, for development)
- `MPESA_CONSUMER_KEY`, `MPESA_CONSUMER_SECRET`, `MPESA_SHORTCODE`, `MPESA_PASSKEY`, `MPESA_ENV=sandbox`, `MPESA_CALLBACK_URL` — for M-Pesa payments (sandbox by default)
- Optional: `OPENAI_API_KEY`, `SMS_API_KEY`/`SMS_USERNAME`, `FIREBASE_SERVICE_ACCOUNT`

Load the schema and seed data:

```bash
# Apply backend/db/schema.sql to your database (via psql or the pg client of your choice)
```

### 2. Frontend

```bash
cd frontend
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:5000/api
```

`API_BASE_URL` defaults to `http://localhost:5000/api` when not provided.

### 3. Verify

- Open the frontend, register or log in with one of the demo accounts
- Confirm the tenant dashboard shows the balance and that Download Invoice produces a PDF

## M-Pesa (Sandbox)

- Set `MPESA_ENV=sandbox` and use your Daraja sandbox credentials and the sandbox shortcode `174379`
- The callback endpoint is `POST /api/payments/mpesa/callback` (the app appends `MPESA_CALLBACK_SECRET` if set)
- Test phones must be registered in your Daraja sandbox; the demo uses `254708374149`
- In production, set `MPESA_ENV=production` and harden the callback (`MPESA_CALLBACK_SECRET`, `MPESA_VERIFY_CALLBACK`, `MPESA_ALLOWED_IPS`)

## Deploying to Vercel

### Backend

1. `cd backend && vercel` and link to a project (e.g. `kodipay-backend`).
2. Set the environment variables (Production) in the Vercel project: `NODE_ENV=production`, `TRUST_PROXY=true`, `CORS_ORIGINS=https://kodipay-frontend.vercel.app`, `DB_*` (with `DB_SSL=true`), `JWT_SECRET`, `CRON_SECRET`, and the M-Pesa / optional vars. Never store secrets in the repository.
3. `vercel deploy --prod`.

`backend/vercel.json` rewrites every path to the single serverless function `backend/api/index.js`, which serves the Express app per request. The app does not call `app.listen()` or start `node-cron` in serverless mode.

### Frontend

Vercel cannot build Flutter, so the web build is produced locally and deployed prebuilt:

```bash
cd frontend
flutter build web --release --dart-define=API_BASE_URL=https://kodipay-backend.vercel.app/api
npx vercel build --prod
npx vercel deploy --prebuilt --prod
```

`frontend/vercel.json` serves `build/web` and rewrites all routes to `index.html` for client-side routing.

### Cron Jobs

Scheduled jobs run as Vercel Cron Jobs (`backend/vercel.json`):

- Monthly invoice generation: 1st of each month, `0 0 1 * *` (UTC)
- Rent reminders: daily `0 6 * * *` (UTC)
- Overdue invoice check: daily `30 6 * * *` (UTC)

Vercel Cron sends `Authorization: Bearer $CRON_SECRET`, which the routes in `backend/src/routes/cron.routes.js` verify against the `CRON_SECRET` env var. On an always-on host (Docker/Render/VPS) the same jobs run via `node-cron` in Africa/Nairobi time instead.

Note: Vercel Hobby plan limits the number of cron jobs that run per day; check the project Cron tab if a schedule is missing.

## API Overview

All endpoints live under `/api` and are grouped by resource:

- `/api/auth` — register, login, password reset, OTP
- `/api/properties`, `/api/units`, `/api/tenancies` — portfolio management
- `/api/invoices` — create, list, generate monthly, update status
- `/api/payments` — record payments, M-Pesa STK Push and callback, per-tenancy history
- `/api/reports` — PDF/CSV reports for landlords
- `/api/documents` — uploads, lease generation, payment receipts
- `/api/maintenance` — maintenance request lifecycle
- `/api/caretakers` — caretaker assignment, my-properties, my-units
- `/api/chatbot` — KodiBot assistant
- `/api/cron` — internal cron job triggers (Vercel Cron)
- `/api/tenant` — tenant overview

Protected routes require `Authorization: Bearer <jwt>`.
