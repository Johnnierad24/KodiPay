const cron = require('node-cron');
const { generateMonthlyInvoices } = require('./services/invoice.service');
const { sendRentReminder } = require('./services/sms.service');
const pool = require('./config/db');

function setupCronJobs() {
  // Monthly invoice generation: 1st of every month at 00:00 EAT
  cron.schedule('0 0 1 * *', async () => {
    console.log('Running monthly invoice generation...');
    const result = await generateMonthlyInvoices();
    console.log(`Monthly invoices generated: ${result.processed || 0}`);
  }, { timezone: 'Africa/Nairobi' });

  // Daily rent reminders: Every day at 09:00 EAT, check for rent due in 5 days
  cron.schedule('0 9 * * *', async () => {
    console.log('Checking for upcoming rent dues...');
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
        }
      }
    } catch (error) {
      console.error('Rent reminder check failed:', error.message);
    }
  }, { timezone: 'Africa/Nairobi' });

  console.log('Automation cron jobs initialized');
}

module.exports = setupCronJobs;
