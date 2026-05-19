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

async function getLandlordOverview(landlordId) {
  try {
    const result = await pool.query(`
      SELECT
        COALESCE(prop.total_properties, 0)::int AS total_properties,
        COALESCE(units.total_units, 0)::int AS total_units,
        COALESCE(units.occupied_units, 0)::int AS occupied_units,
        COALESCE(units.vacant_units, 0)::int AS vacant_units,
        COALESCE(income.this_month_income, 0)::numeric AS this_month_income,
        COALESCE(income.last_month_income, 0)::numeric AS last_month_income,
        COALESCE(pending.pending_invoices, 0)::int AS pending_invoices,
        COALESCE(pending.overdue_invoices, 0)::int AS overdue_invoices,
        COALESCE(pending.pending_amount, 0)::numeric AS pending_amount,
        COALESCE(maintenance.open_requests, 0)::int AS open_maintenance,
        COALESCE(maintenance.urgent_requests, 0)::int AS urgent_maintenance
      FROM (SELECT 1) seed
      LEFT JOIN LATERAL (
        SELECT COUNT(*) AS total_properties
        FROM properties WHERE landlord_id = $1
      ) prop ON TRUE
      LEFT JOIN LATERAL (
        SELECT
          COUNT(*) AS total_units,
          COUNT(*) FILTER (WHERE u.status = 'occupied') AS occupied_units,
          COUNT(*) FILTER (WHERE u.status = 'vacant') AS vacant_units
        FROM units u JOIN properties p ON u.property_id = p.id
        WHERE p.landlord_id = $1
      ) units ON TRUE
      LEFT JOIN LATERAL (
        SELECT
          SUM(pay.amount) FILTER (
            WHERE pay.payment_date >= date_trunc('month', CURRENT_DATE)
          ) AS this_month_income,
          SUM(pay.amount) FILTER (
            WHERE pay.payment_date >= date_trunc('month', CURRENT_DATE - INTERVAL '1 month')
              AND pay.payment_date < date_trunc('month', CURRENT_DATE)
          ) AS last_month_income
        FROM payments pay
        JOIN tenancies t ON pay.tenancy_id = t.id
        JOIN units u ON t.unit_id = u.id
        JOIN properties p ON u.property_id = p.id
        WHERE p.landlord_id = $1 AND pay.status = 'completed'
      ) income ON TRUE
      LEFT JOIN LATERAL (
        SELECT
          COUNT(*) FILTER (WHERE i.status IN ('pending', 'overdue')) AS pending_invoices,
          COUNT(*) FILTER (WHERE i.status IN ('pending', 'overdue') AND i.due_date < CURRENT_DATE) AS overdue_invoices,
          SUM(i.amount) FILTER (WHERE i.status IN ('pending', 'overdue')) AS pending_amount
        FROM invoices i
        JOIN tenancies t ON i.tenancy_id = t.id
        JOIN units u ON t.unit_id = u.id
        JOIN properties p ON u.property_id = p.id
        WHERE p.landlord_id = $1
      ) pending ON TRUE
      LEFT JOIN LATERAL (
        SELECT
          COUNT(*) FILTER (WHERE mr.status IN ('pending', 'in_progress')) AS open_requests,
          COUNT(*) FILTER (WHERE mr.status IN ('pending', 'in_progress') AND mr.priority IN ('high', 'urgent')) AS urgent_requests
        FROM maintenance_requests mr
        JOIN units u ON mr.unit_id = u.id
        JOIN properties p ON u.property_id = p.id
        WHERE p.landlord_id = $1
      ) maintenance ON TRUE
    `, [landlordId]);

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
  getRentCollectionRate,
  getLandlordOverview,
};
