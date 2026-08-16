// Vercel serverless entry point.
// Serves the Express app as a single serverless function. Vercel rewrites
// all paths to this function (see vercel.json). The app is NOT started with
// app.listen() here - Vercel calls it per request, and cron scheduling is
// handled by Vercel Cron Jobs (see src/routes/cron.routes.js).
module.exports = require('../src/server');
