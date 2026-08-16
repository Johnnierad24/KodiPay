# kodipay (Frontend)

Flutter web client for KodiPay, a rental management platform. The app is built as a static web app; the Flutter build output is uploaded to Vercel, which serves it with client-side routing.

## Prerequisites

- Flutter 3.35+ with web support enabled
- A running KodiPay backend (see the root README) or the deployed backend at `https://kodipay-backend.vercel.app/api`

## Running Locally

```bash
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:5000/api
```

`API_BASE_URL` defaults to `http://localhost:5000/api` when the flag is omitted. Use the deployed API with:

```bash
flutter run -d chrome --dart-define=API_BASE_URL=https://kodipay-backend.vercel.app/api
```

## Key Dependencies

- `pdf` — client-side PDF generation (rent invoices, payment receipts, rent statements)
- `fl_chart` — landlord dashboard charts
- `google_fonts` — typography
- `file_picker`, `share_plus`, `url_launcher` — document handling and sharing
- `web` — web-only utilities (file downloads via Blob)

## Building for Web

```bash
flutter build web --release --dart-define=API_BASE_URL=https://kodipay-backend.vercel.app/api
```

Output is written to `build/web`.

## Deploying to Vercel

Vercel cannot compile Flutter, so the web build is produced locally and deployed as prebuilt output:

```bash
flutter build web --release --dart-define=API_BASE_URL=https://kodipay-backend.vercel.app/api
npx vercel build --prod
npx vercel deploy --prebuilt --prod
```

`vercel.json` sets the output directory to `build/web` and rewrites all routes to `index.html` for SPA routing. Rebuild and redeploy after every frontend change.

## Project Structure

```
lib/
├── main.dart                     App entry point
├── services/                     API client, PDF report/invoice services, M-Pesa client
├── screens/                      Landlord, tenant, caretaker, and auth screens
├── models/                       Data models
├── utils/                        Constants, app config, formatting helpers
├── widgets/                      Shared components
```
