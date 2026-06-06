# KodiPay — Deployment & Pre-Launch Checklist

Status as of the deployment-hardening pass. Items are grouped by who can complete them.

## ✅ Done (in code)

- **M-Pesa environment switching** — `backend/src/config/mpesa.js` now selects the
  sandbox vs production Daraja host from `MPESA_ENV`. Unknown values fall back to
  sandbox so you can never *accidentally* go live. Verified by `mpesa.test.js`.
- **Paybill vs Till support** — `MPESA_SHORTCODE_TYPE` (`paybill`/`till`) sets the
  STK Push `TransactionType` (`CustomerPayBillOnline` / `CustomerBuyGoodsOnline`).
  Defaults to `paybill`. Set it to match whichever shortcode Safaricom issues you.
- **Boot-time env validation** — `backend/src/config/validateEnv.js` fails fast if
  `JWT_SECRET`/DB vars are missing, refuses the example placeholder secret in
  production, and requires real M-Pesa creds when `MPESA_ENV=production`. Optional
  integrations (OpenAI, SMS, Firebase) only warn.
- **CORS allowlist, trust-proxy, DB SSL, auth rate limiting** — driven by
  `CORS_ORIGINS`, `TRUST_PROXY`, `DB_SSL` env vars (see `backend/.env.example`).
- **Deployment config** — `backend/Dockerfile`, `backend/.dockerignore`, and
  `render.yaml` (backend web service + managed Postgres blueprint).
- **CI** — `.github/workflows/ci.yml` runs backend tests and `flutter analyze` on
  every push/PR. Backend `npm test` runs the Node built-in test runner.

## 🚀 Deploy steps (you, via Render)

1. Push this branch to GitHub.
2. In Render: **New → Blueprint**, point it at the repo. It reads `render.yaml`,
   creates `kodipay-backend` + `kodipay-db`, and auto-wires the DB env vars.
3. Run the schema against the new database: `backend/db/schema.sql` then
   `backend/db/migrations.sql`.
4. Fill in the `sync: false` secrets in the Render dashboard: `CORS_ORIGINS`,
   `MPESA_ENV`, all `MPESA_*`, `SMS_*`, `OPENAI_API_KEY`, `FIREBASE_SERVICE_ACCOUNT`.
5. Set `MPESA_CALLBACK_URL` to `https://<your-render-url>/api/payments/mpesa/callback`.
6. Build the Flutter app pointing at the deployed API:
   `flutter build apk --dart-define=API_BASE_URL=https://<your-render-url>/api`

## ⚠️ Must be done before taking real money / public launch (you)

- [ ] **Rotate the OpenAI API key** that was pasted in chat on 2026-06-02 — treat it
      as compromised. Generate a new one and set it only in the Render dashboard.
- [ ] **Get the Daraja production credentials** (Go-Live on the Safaricom portal):
      production consumer key/secret, shortcode, passkey. Set `MPESA_ENV=production`.
- [ ] **Live end-to-end M-Pesa test** — no real STK Push has been run yet. Test a
      KSh 1 payment against production before announcing.
- [ ] **Lawyer review of the Kenyan legal reference text** in
      `backend/src/services/chatbot.prompts.js` (KodiBot rights guidance). The
      "general information, not legal advice" disclaimer is wired, but the substance
      should be reviewed by a Kenyan-law professional.
- [ ] **Live E2E test of KodiBot** across all three roles — no live OpenAI calls have
      been made; confirm tool-calling works against real data once the key is rotated.

## 🟢 Nice-to-have (post-launch)

- Expand test coverage beyond the M-Pesa config (auth, payments controller).
- Add structured logging / error monitoring (e.g. Sentry) in production.
- Database backups schedule on the managed Postgres instance.
