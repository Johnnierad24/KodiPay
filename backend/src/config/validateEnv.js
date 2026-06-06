require('dotenv').config();

// Fail fast at boot if critical configuration is missing. A server that starts
// without JWT_SECRET or a database silently issues broken tokens / 500s on every
// request — far worse than refusing to start. Optional integrations only warn.

// Always required — the app cannot function without these.
const REQUIRED = ['JWT_SECRET', 'DB_HOST', 'DB_NAME', 'DB_USER', 'DB_PASSWORD'];

// Required only when going live with real M-Pesa payments (MPESA_ENV=production).
const MPESA_PRODUCTION_REQUIRED = [
  'MPESA_CONSUMER_KEY',
  'MPESA_CONSUMER_SECRET',
  'MPESA_SHORTCODE',
  'MPESA_PASSKEY',
  'MPESA_CALLBACK_URL',
];

// Optional integrations — degrade gracefully, just warn if unset.
const OPTIONAL = {
  'OPENAI_API_KEY': 'KodiBot AI assistant will be unavailable',
  'SMS_API_KEY': 'SMS notifications will be disabled',
  'FIREBASE_SERVICE_ACCOUNT': 'Push notifications will be disabled',
  'MPESA_CONSUMER_KEY': 'M-Pesa payments will be unavailable',
};

function validateEnv() {
  const missing = REQUIRED.filter((key) => !process.env[key]);

  // In production, never run on the well-known fallback secrets.
  if (process.env.NODE_ENV === 'production') {
    if (process.env.JWT_SECRET === 'your_jwt_secret_key') {
      missing.push('JWT_SECRET (still set to the example placeholder value)');
    }
    if (process.env.MPESA_ENV === 'production') {
      MPESA_PRODUCTION_REQUIRED.forEach((key) => {
        if (!process.env[key]) missing.push(`${key} (required when MPESA_ENV=production)`);
      });
    }
  }

  if (missing.length > 0) {
    console.error('\n[startup] FATAL: missing required environment variables:');
    missing.forEach((key) => console.error(`  - ${key}`));
    console.error('Set them in backend/.env (see backend/.env.example) and restart.\n');
    process.exit(1);
  }

  Object.entries(OPTIONAL).forEach(([key, consequence]) => {
    if (!process.env[key]) {
      console.warn(`[startup] WARNING: ${key} not set — ${consequence}.`);
    }
  });

  console.log(`[startup] Environment validated (NODE_ENV=${process.env.NODE_ENV || 'development'}, MPESA_ENV=${process.env.MPESA_ENV || 'sandbox'}).`);
}

module.exports = validateEnv;
