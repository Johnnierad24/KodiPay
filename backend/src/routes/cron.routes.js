const express = require('express');
const router = express.Router();
const {
  generateMonthlyInvoicesJob,
  checkUpcomingRent,
  checkOverdueInvoices,
} = require('../cron');

// Vercel Cron Jobs invoke these routes with `Authorization: Bearer $CRON_SECRET`
// (set CRON_SECRET in the Vercel project env). In dev, run them with the same
// header or leave CRON_SECRET unset to allow local testing.
function authorize(req, res, next) {
  const secret = process.env.CRON_SECRET;
  if (!secret) return next(); // no secret configured -> allow (dev)
  const header = req.headers.authorization || '';
  const token = header.replace(/^Bearer\s+/i, '').trim();
  if (token && token === secret) return next();
  return res.status(401).json({ error: 'Unauthorized' });
}

router.use(authorize);

router.post('/monthly-invoices', async (req, res) => {
  try {
    const result = await generateMonthlyInvoicesJob();
    res.json(result);
  } catch (error) {
    console.error('Monthly invoice cron failed:', error);
    res.status(500).json({ error: error.message });
  }
});

router.post('/rent-reminders', async (req, res) => {
  try {
    const result = await checkUpcomingRent();
    res.json(result);
  } catch (error) {
    console.error('Rent reminder cron failed:', error);
    res.status(500).json({ error: error.message });
  }
});

router.post('/overdue-check', async (req, res) => {
  try {
    const result = await checkOverdueInvoices();
    res.json(result);
  } catch (error) {
    console.error('Overdue check cron failed:', error);
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
