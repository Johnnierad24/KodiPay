const pool = require('../config/db');
const PDFDocument = require('pdfkit');

async function generateRentCollectionReport(startDate, endDate) {
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
      GROUP BY p.name, u.unit_number, tenant_name, i.month, i.year, i.amount, i.status
      ORDER BY p.name, u.unit_number, i.year, i.month
    `, [startDate.year, startDate.month, endDate.year, endDate.month]);

    return { success: true, data: result.rows };
  } catch (error) {
    return { success: false, error: error.message };
  }
}

async function generateOccupancyReport() {
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
      GROUP BY p.id, p.name
      ORDER BY occupancy_rate DESC
    `);
    return { success: true, data: result.rows };
  } catch (error) {
    return { success: false, error: error.message };
  }
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
  generatePDFReport
};
