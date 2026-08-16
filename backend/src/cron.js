const cron = require('node-cron');
const { generateMonthlyInvoices } = require('./services/invoice.service');
const { sendRentReminder } = require('./services/sms.service');
const pool = require('./config/db');

async function generateMonthlyInvoicesJob() {
  console.log('Running monthly invoice generation...');
  const result = await generateMonthlyInvoices();
  const count = result.processed || 0;
  console.log(`Monthly invoices generated: ${count}`);
  return { ok: true, processed: count };
}

async function checkUpcomingRent() {
  console.log('Checking for upcoming rent dues...');
  let sent = 0;
  try {
    const tenancies = await pool.query(`
      SELECT t.id, t.start_date, u.rent_amount
      FROM tenancies t
      JOIN units u ON t.unit_id = u.id
      WHERE t.status = 'active'
    `);

    const today = new Date();
    for (const tenancy of tenancies.rows) {
      const startDate = new Date(tenancy.start_date);
      const nextDue = new Date(startDate);
      nextDue.setMonth(nextDue.getMonth() + 1);

      const diffDays = Math.ceil((nextDue - today) / (1000 * 60 * 60 * 24));
      if (diffDays >= 0 && diffDays <= 5) {
        await sendRentReminder(tenancy.id);
        console.log(`Rent reminder sent for tenancy ${tenancy.id}`);
        sent += 1;
      }
    }
  } catch (error) {
    console.error('Rent reminder check failed:', error.message);
  }
  return { ok: true, remindersSent: sent };
}

async function checkOverdueInvoices() {
  console.log('Checking for overdue invoices...');
  let candidates = 0;
  try {
    const overdue = await pool.query(`
      SELECT i.id AS invoice_id, i.amount, i.due_date, i.month, i.year,
             t.id AS tenancy_id,
             us.first_name AS tenant_first_name, us.last_name AS tenant_last_name,
             un.unit_number, p.name AS property_name, p.landlord_id
        FROM invoices i
        JOIN tenancies t ON i.tenancy_id = t.id
        JOIN users us ON t.tenant_id = us.id
        JOIN units un ON t.unit_id = un.id
        JOIN properties p ON un.property_id = p.id
       WHERE i.status IN ('pending', 'overdue')
         AND i.due_date < CURRENT_DATE
    `);
    candidates = overdue.rows.length;

    for (const row of overdue.rows) {
      // Skip if we already pinged the landlord about this invoice today
      const recent = await pool.query(
        `SELECT 1 FROM notifications
          WHERE user_id = $1 AND related_id = $2 AND related_type = 'invoice'
            AND created_at::date = CURRENT_DATE
          LIMIT 1`,
        [row.landlord_id, row.invoice_id]
      );
      if (recent.rows.length > 0) continue;

      const tenantName = `${row.tenant_first_name || ''} ${row.tenant_last_name || ''}`.trim() || 'A tenant';
      const where = row.unit_number
        ? `${row.property_name || ''} • Unit ${row.unit_number}`.trim()
        : row.property_name || '';
      const message = `${tenantName}'s rent of KES ${Number(row.amount).toFixed(0)} for ${where} is overdue (was due ${row.due_date.toISOString().split('T')[0]}). Consider sending a reminder.`;

      await pool.query(
        `INSERT INTO notifications (user_id, type, title, message, related_id, related_type)
         VALUES ($1, 'rent_reminder', $2, $3, $4, 'invoice')`,
        [row.landlord_id, 'Rent overdue', message, row.invoice_id]
      );

      // Also mark invoice as overdue if it was still 'pending'
      await pool.query(
        `UPDATE invoices SET status = 'overdue', updated_at = CURRENT_TIMESTAMP
          WHERE id = $1 AND status = 'pending'`,
        [row.invoice_id]
      );
    }
    console.log(`Overdue invoice check complete: ${candidates} candidates`);
  } catch (error) {
    console.error('Overdue invoice check failed:', error.message);
  }
  return { ok: true, candidates };
}

// Always-on scheduler (Docker/Render/VPS). Schedules run in Africa/Nairobi
// time. Serverless hosts (Vercel) skip this and use Vercel Cron Jobs hitting
// /api/cron/* routes instead - see routes/cron.routes.js and vercel.json.
function setupCronJobs() {
  // Monthly invoice generation: 1st of every month at 00:00 EAT
  cron.schedule('0 0 1 * *', generateMonthlyInvoicesJob, { timezone: 'Africa/Nairobi' });

  // Daily rent reminders: Every day at 09:00 EAT, check for rent due in 5 days
  cron.schedule('0 9 * * *', checkUpcomingRent, { timezone: 'Africa/Nairobi' });

  // Daily overdue-rent alert to landlord: Every day at 09:30 EAT
  cron.schedule('30 9 * * *', checkOverdueInvoices, { timezone: 'Africa/Nairobi' });

  console.log('Automation cron jobs initialized');
}

module.exports = setupCronJobs;
module.exports.generateMonthlyInvoicesJob = generateMonthlyInvoicesJob;
module.exports.checkUpcomingRent = checkUpcomingRent;
module.exports.checkOverdueInvoices = checkOverdueInvoices;
