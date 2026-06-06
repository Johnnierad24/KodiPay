const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
require('dotenv').config();

const app = express();

// Behind a reverse proxy (Render/Railway/Nginx) the client IP arrives via
// X-Forwarded-For. Trust one proxy hop so rate limiting and IP checks see
// the real client IP. Enable with TRUST_PROXY=true in those environments.
if (process.env.TRUST_PROXY === 'true') {
  app.set('trust proxy', 1);
}

// CORS: restrict to an explicit allowlist in production.
// CORS_ORIGINS is a comma-separated list of allowed origins.
// When unset (typical local dev), all origins are allowed.
const corsOrigins = (process.env.CORS_ORIGINS || '')
  .split(',')
  .map((o) => o.trim())
  .filter(Boolean);

const corsOptions = corsOrigins.length > 0
  ? {
      origin: (origin, callback) => {
        // Allow non-browser clients (mobile apps, curl) that send no Origin.
        if (!origin || corsOrigins.includes(origin)) {
          return callback(null, true);
        }
        return callback(new Error('Not allowed by CORS'));
      },
    }
  : {};

app.use(helmet());
app.use(cors(corsOptions));
app.use(morgan('dev'));
app.use(express.json());

app.get('/api/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

const authMiddleware = require('./middleware/auth.middleware');

app.use('/api/auth', require('./routes/auth.routes'));
app.use('/api/properties', authMiddleware, require('./routes/property.routes'));
app.use('/api/units', authMiddleware, require('./routes/unit.routes'));
app.use('/api/tenancies', authMiddleware, require('./routes/tenancy.routes'));
app.use('/api/payments', require('./routes/payment.routes'));
app.use('/api/maintenance', authMiddleware, require('./routes/maintenance.routes'));
app.use('/api/notifications', authMiddleware, require('./routes/notification.routes'));
app.use('/api/invoices', authMiddleware, require('./routes/invoice.routes'));
app.use('/api/analytics', authMiddleware, require('./routes/analytics.routes'));
app.use('/api/reports', authMiddleware, require('./routes/report.routes'));
app.use('/api/chatbot', authMiddleware, require('./routes/chatbot.routes'));
app.use('/api/upload', authMiddleware, require('./routes/upload.routes'));
app.use('/api/documents', authMiddleware, require('./routes/document.routes'));
app.use('/api/caretakers', authMiddleware, require('./routes/caretaker.routes'));

const setupCronJobs = require('./cron');
setupCronJobs();

app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Something went wrong!' });
});

const PORT = process.env.PORT || 5000;

if (require.main === module) {
  // Validate configuration before binding the port — fail fast on misconfig.
  require('./config/validateEnv')();
  app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
  });
}

module.exports = app;
