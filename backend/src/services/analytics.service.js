const pool = require('../config/db');

async function getRevenueTrend(months = 12) {
  try {
    const result = await pool.query(`
      SELECT 
        EXTRACT(YEAR FROM p.payment_date) as year,
        EXTRACT(MONTH FROM p.payment_date) as month,
        SUM(p.amount) as total_revenue,
        COUNT(p.id) as payment_count
      FROM payments p
      WHERE p.status = 'completed' 
        AND p.payment_date >= CURRENT_DATE - INTERVAL '${months} months'
      GROUP BY year, month
      ORDER BY year, month
    `);
    return { success: true, data: result.rows };
  } catch (error) {
    return { success: false, error: error.message };
  }
}

async function getOccupancyRate() {
  try {
    const result = await pool.query(`
      SELECT 
        COUNT(*) FILTER (WHERE status = 'occupied') as occupied_units,
        COUNT(*) as total_units,
        ROUND(COUNT(*) FILTER (WHERE status = 'occupied') * 100.0 / COUNT(*), 2) as occupancy_rate
      FROM units
    `);
    return { success: true, data: result.rows[0] };
  } catch (error) {
    return { success: false, error: error.message };
  }
}

async function getPaymentMethodDistribution() {
  try {
    const result = await pool.query(`
      SELECT 
        payment_method,
        COUNT(*) as count,
        SUM(amount) as total_amount
      FROM payments
      WHERE status = 'completed'
      GROUP BY payment_method
      ORDER BY count DESC
    `);
    return { success: true, data: result.rows };
  } catch (error) {
    return { success: false, error: error.message };
  }
}

async function getMaintenanceStats() {
  try {
    const result = await pool.query(`
      SELECT 
        status,
        priority,
        COUNT(*) as count
      FROM maintenance_requests
      GROUP BY status, priority
      ORDER BY status, priority
    `);
    return { success: true, data: result.rows };
  } catch (error) {
    return { success: false, error: error.message };
  }
}

async function getRentCollectionRate(year, month) {
  try {
    const result = await pool.query(`
      SELECT 
        COUNT(i.id) as total_invoices,
        COUNT(i.id) FILTER (WHERE i.status = 'paid') as paid_invoices,
        ROUND(COUNT(i.id) FILTER (WHERE i.status = 'paid') * 100.0 / NULLIF(COUNT(i.id), 0), 2) as collection_rate
      FROM invoices i
      WHERE i.year = $1 AND i.month = $2
    `, [year, month]);
    return { success: true, data: result.rows[0] };
  } catch (error) {
    return { success: false, error: error.message };
  }
}

module.exports = {
  getRevenueTrend,
  getOccupancyRate,
  getPaymentMethodDistribution,
  getMaintenanceStats,
  getRentCollectionRate
};
