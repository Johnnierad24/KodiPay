const pool = require('../config/db');
const PDFDocument = require('pdfkit');

async function generateRentCollectionReport(startDate, endDate, landlordId) {
  try {
    const result = await pool.query(`
      SELECT 
        p.name as property_name,
        u.unit_number,
        us.first_name || ' ' || us.last_name as tenant_name,
        i.month,
        i.year,
        i.amount as invoice_amount,
        i.status as invoice_status,
        COALESCE(SUM(py.amount), 0) as paid_amount
      FROM invoices i
      JOIN tenancies t ON i.tenancy_id = t.id
      JOIN units u ON t.unit_id = u.id
      JOIN properties p ON u.property_id = p.id
      JOIN users us ON t.tenant_id = us.id
      LEFT JOIN payments py ON i.tenancy_id = py.tenancy_id AND py.status = 'completed'
      WHERE (i.year > $1 OR (i.year = $1 AND i.month >= $2))
        AND (i.year < $3 OR (i.year = $3 AND i.month <= $4))
        AND p.landlord_id = $5
      GROUP BY p.name, u.unit_number, tenant_name, i.month, i.year, i.amount, i.status
      ORDER BY p.name, u.unit_number, i.year, i.month
    `, [startDate.year, startDate.month, endDate.year, endDate.month, landlordId]);

    return { success: true, data: result.rows };
  } catch (error) {
    return { success: false, error: error.message };
  }
}

async function generateOccupancyReport(landlordId) {
  try {
    const result = await pool.query(`
      SELECT 
        p.name as property_name,
        COUNT(u.id) as total_units,
        COUNT(u.id) FILTER (WHERE u.status = 'occupied') as occupied_units,
        COUNT(u.id) FILTER (WHERE u.status = 'vacant') as vacant_units,
        ROUND(COUNT(u.id) FILTER (WHERE u.status = 'occupied') * 100.0 / COUNT(u.id), 2) as occupancy_rate
      FROM properties p
      LEFT JOIN units u ON p.id = u.property_id
      WHERE p.landlord_id = $1
      GROUP BY p.id, p.name
      ORDER BY occupancy_rate DESC
    `, [landlordId]);
    return { success: true, data: result.rows };
  } catch (error) {
    return { success: false, error: error.message };
  }
}

async function generateIncomeReport(landlordId, startDate, endDate) {
  try {
    const result = await pool.query(`
      WITH payment_totals AS (
        SELECT p.id AS property_id, COALESCE(SUM(pay.amount), 0) AS collected
        FROM properties p
        LEFT JOIN units u ON u.property_id = p.id
        LEFT JOIN tenancies t ON t.unit_id = u.id
        LEFT JOIN payments pay ON pay.tenancy_id = t.id
          AND pay.status = 'completed'
          AND pay.payment_date BETWEEN $2 AND $3
        WHERE p.landlord_id = $1
        GROUP BY p.id
      ),
      invoice_totals AS (
        SELECT p.id AS property_id, COALESCE(SUM(i.amount), 0) AS expected
        FROM properties p
        LEFT JOIN units u ON u.property_id = p.id
        LEFT JOIN tenancies t ON t.unit_id = u.id
        LEFT JOIN invoices i ON i.tenancy_id = t.id
          AND make_date(i.year, i.month, 1) BETWEEN date_trunc('month', $2::date) AND date_trunc('month', $3::date)
        WHERE p.landlord_id = $1
        GROUP BY p.id
      )
      SELECT p.id, p.name AS property_name, pt.collected, it.expected,
        GREATEST(it.expected - pt.collected, 0) AS pending
      FROM properties p
      LEFT JOIN payment_totals pt ON pt.property_id = p.id
      LEFT JOIN invoice_totals it ON it.property_id = p.id
      WHERE p.landlord_id = $1
      ORDER BY pt.collected DESC
    `, [landlordId, startDate, endDate]);

    const summary = result.rows.reduce((totals, row) => ({
      collected: totals.collected + Number(row.collected || 0),
      expected: totals.expected + Number(row.expected || 0),
      pending: totals.pending + Number(row.pending || 0),
    }), { collected: 0, expected: 0, pending: 0 });

    return { success: true, data: { summary, byProperty: result.rows } };
  } catch (error) {
    return { success: false, error: error.message };
  }
}

async function generateArrearsReport(landlordId) {
  try {
    const result = await pool.query(`
      SELECT
        us.first_name || ' ' || us.last_name AS tenant_name,
        us.phone,
        p.name AS property_name,
        u.unit_number,
        i.amount,
        i.due_date,
        GREATEST(CURRENT_DATE - i.due_date, 0) AS days_overdue,
        i.status
      FROM invoices i
      JOIN tenancies t ON i.tenancy_id = t.id
      JOIN units u ON t.unit_id = u.id
      JOIN properties p ON u.property_id = p.id
      JOIN users us ON t.tenant_id = us.id
      WHERE p.landlord_id = $1
        AND i.status IN ('pending', 'overdue')
      ORDER BY i.due_date ASC
    `, [landlordId]);

    return { success: true, data: result.rows };
  } catch (error) {
    return { success: false, error: error.message };
  }
}

async function generatePropertyPerformanceReport(landlordId, startDate, endDate) {
  try {
    const result = await pool.query(`
      SELECT
        p.id,
        p.name AS property_name,
        COUNT(DISTINCT u.id) AS total_units,
        COUNT(DISTINCT u.id) FILTER (WHERE u.status = 'occupied') AS occupied_units,
        COUNT(DISTINCT u.id) FILTER (WHERE u.status = 'vacant') AS vacant_units,
        COALESCE(SUM(pay.amount), 0) AS income
      FROM properties p
      LEFT JOIN units u ON u.property_id = p.id
      LEFT JOIN tenancies t ON t.unit_id = u.id
      LEFT JOIN payments pay ON pay.tenancy_id = t.id
        AND pay.status = 'completed'
        AND pay.payment_date BETWEEN $2 AND $3
      WHERE p.landlord_id = $1
      GROUP BY p.id, p.name
      ORDER BY income DESC
    `, [landlordId, startDate, endDate]);

    return { success: true, data: result.rows };
  } catch (error) {
    return { success: false, error: error.message };
  }
}

async function generateMaintenanceReport(landlordId, startDate, endDate) {
  try {
    const result = await pool.query(`
      SELECT
        mr.status,
        mr.priority,
        COUNT(*) AS issue_count
      FROM maintenance_requests mr
      JOIN units u ON mr.unit_id = u.id
      JOIN properties p ON u.property_id = p.id
      WHERE p.landlord_id = $1
        AND mr.created_at::date BETWEEN $2 AND $3
      GROUP BY mr.status, mr.priority
      ORDER BY mr.status, mr.priority
    `, [landlordId, startDate, endDate]);

    const frequentProblems = await pool.query(`
      SELECT title, COUNT(*) AS issue_count
      FROM maintenance_requests mr
      JOIN units u ON mr.unit_id = u.id
      JOIN properties p ON u.property_id = p.id
      WHERE p.landlord_id = $1
        AND mr.created_at::date BETWEEN $2 AND $3
      GROUP BY title
      ORDER BY issue_count DESC
      LIMIT 5
    `, [landlordId, startDate, endDate]);

    return { success: true, data: { byStatus: result.rows, frequentProblems: frequentProblems.rows } };
  } catch (error) {
    return { success: false, error: error.message };
  }
}

async function generatePaymentTrendsReport(landlordId, months = 12) {
  try {
    const result = await pool.query(`
      SELECT
        date_trunc('month', pay.payment_date)::date AS month,
        SUM(pay.amount) AS income,
        COUNT(pay.id) AS payment_count
      FROM payments pay
      JOIN tenancies t ON pay.tenancy_id = t.id
      JOIN units u ON t.unit_id = u.id
      JOIN properties p ON u.property_id = p.id
      WHERE p.landlord_id = $1
        AND pay.status = 'completed'
        AND pay.payment_date >= CURRENT_DATE - ($2::int || ' months')::interval
      GROUP BY month
      ORDER BY month
    `, [landlordId, months]);

    return { success: true, data: result.rows };
  } catch (error) {
    return { success: false, error: error.message };
  }
}

async function generateTransactionReport(landlordId, startDate, endDate) {
  try {
    const result = await pool.query(`
      SELECT
        pay.id,
        pay.amount,
        pay.payment_method,
        pay.transaction_ref,
        pay.status,
        pay.payment_date,
        us.first_name || ' ' || us.last_name AS tenant_name,
        p.name AS property_name,
        u.unit_number
      FROM payments pay
      JOIN tenancies t ON pay.tenancy_id = t.id
      JOIN units u ON t.unit_id = u.id
      JOIN properties p ON u.property_id = p.id
      JOIN users us ON t.tenant_id = us.id
      WHERE p.landlord_id = $1
        AND pay.payment_date::date BETWEEN $2 AND $3
      ORDER BY pay.payment_date DESC
    `, [landlordId, startDate, endDate]);

    return { success: true, data: result.rows };
  } catch (error) {
    return { success: false, error: error.message };
  }
}

function generateCSV(data, columns) {
  const escape = (value) => `"${String(value ?? '').replace(/"/g, '""')}"`;
  const header = columns.map((column) => escape(column.header)).join(',');
  const rows = data.map((row) => columns.map((column) => escape(row[column.field])).join(','));
  return [header, ...rows].join('\n');
}

function generatePDFReport(data, title, columns) {
  return new Promise((resolve, reject) => {
    const doc = new PDFDocument();
    const chunks = [];
    
    doc.on('data', chunk => chunks.push(chunk));
    doc.on('end', () => resolve(Buffer.concat(chunks)));
    doc.on('error', reject);
    
    doc.fontSize(20).text(title, { align: 'center' });
    doc.moveDown();
    
    const tableTop = 150;
    const colWidth = 100;
    let y = tableTop;
    
    columns.forEach((col, i) => {
      doc.fontSize(10).text(col.header, 50 + i * colWidth, y, { width: colWidth });
    });
    
    y += 20;
    doc.moveTo(50, y).lineTo(50 + columns.length * colWidth, y).stroke();
    y += 10;
    
    data.forEach(row => {
      columns.forEach((col, i) => {
        doc.fontSize(9).text(row[col.field] || '', 50 + i * colWidth, y, { width: colWidth });
      });
      y += 20;
    });
    
    doc.end();
  });
}

module.exports = {
  generateRentCollectionReport,
  generateOccupancyReport,
  generateIncomeReport,
  generateArrearsReport,
  generatePropertyPerformanceReport,
  generateMaintenanceReport,
  generatePaymentTrendsReport,
  generateTransactionReport,
  generateCSV,
  generatePDFReport
};
