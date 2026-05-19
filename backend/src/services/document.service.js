const PDFDocument = require('pdfkit');
const pool = require('../config/db');
const { uploadFile } = require('./storage.service');

function formatKsh(amount) {
  const value = Number(amount || 0);
  return `KSh ${value.toLocaleString('en-KE', { minimumFractionDigits: 0, maximumFractionDigits: 2 })}`;
}

function formatDate(date) {
  if (!date) return '—';
  const d = new Date(date);
  return d.toLocaleDateString('en-KE', { day: '2-digit', month: 'short', year: 'numeric' });
}

function bufferFromDoc(doc) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    doc.on('data', (chunk) => chunks.push(chunk));
    doc.on('end', () => resolve(Buffer.concat(chunks)));
    doc.on('error', reject);
    doc.end();
  });
}

function drawHeader(doc, title, subtitle) {
  doc.fillColor('#0B1736').fontSize(22).font('Helvetica-Bold').text('KodiPay', 50, 50);
  doc.fillColor('#64748B').fontSize(10).font('Helvetica').text('Rental Management', 50, 76);

  doc.fillColor('#0F172A').fontSize(16).font('Helvetica-Bold').text(title, 50, 110);
  if (subtitle) {
    doc.fillColor('#64748B').fontSize(11).font('Helvetica').text(subtitle, 50, 132);
  }

  doc.moveTo(50, 158).lineTo(545, 158).strokeColor('#E2E8F0').stroke();
}

function drawKeyValueRow(doc, key, value, y) {
  doc.fillColor('#64748B').fontSize(11).font('Helvetica').text(key, 50, y, { width: 180 });
  doc.fillColor('#0F172A').fontSize(11).font('Helvetica-Bold').text(value || '—', 230, y, { width: 320 });
  return y + 22;
}

async function buildLeasePdf({ tenancy, terms }) {
  const doc = new PDFDocument({ size: 'A4', margin: 50 });

  drawHeader(
    doc,
    'Tenancy Lease Agreement',
    `Issued ${formatDate(new Date())}`
  );

  let y = 180;
  y = drawKeyValueRow(doc, 'Property', tenancy.property_name, y);
  y = drawKeyValueRow(doc, 'Unit', tenancy.unit_number, y);
  y = drawKeyValueRow(doc, 'Landlord', tenancy.landlord_name, y);
  y = drawKeyValueRow(doc, 'Tenant', tenancy.tenant_name, y);
  y = drawKeyValueRow(doc, 'Tenant phone', tenancy.tenant_phone, y);
  y = drawKeyValueRow(doc, 'Tenant email', tenancy.tenant_email, y);
  y = drawKeyValueRow(doc, 'Start date', formatDate(tenancy.start_date), y);
  y = drawKeyValueRow(doc, 'End date', formatDate(terms.end_date || tenancy.end_date), y);
  y = drawKeyValueRow(doc, 'Monthly rent', formatKsh(tenancy.rent_amount), y);
  y = drawKeyValueRow(doc, 'Deposit', formatKsh(tenancy.deposit_amount), y);

  y += 8;
  doc.fillColor('#0F172A').fontSize(13).font('Helvetica-Bold').text('Terms and Conditions', 50, y);
  y += 22;

  const defaultTerms = [
    'Rent is payable monthly in advance, on or before the 5th day of each month.',
    'A deposit equal to one month\'s rent is held as security against damages and unpaid rent.',
    'The tenant shall keep the unit in good and clean condition throughout the tenancy.',
    'Repairs to structural elements are the responsibility of the landlord. Damages caused by the tenant are the tenant\'s responsibility.',
    'Either party may terminate this lease by giving 30 days\' written notice.',
    'Any disputes shall first be resolved through good-faith discussion between the parties.',
  ];

  const clauses = Array.isArray(terms.clauses) && terms.clauses.length > 0 ? terms.clauses : defaultTerms;
  doc.fontSize(10).fillColor('#0F172A').font('Helvetica');
  clauses.forEach((clause, idx) => {
    doc.text(`${idx + 1}. ${clause}`, 50, y, { width: 495, align: 'justify' });
    y = doc.y + 6;
  });

  y = doc.y + 30;
  if (y > 700) { doc.addPage(); y = 80; }

  doc.fontSize(11).fillColor('#0F172A').font('Helvetica-Bold').text('Signatures', 50, y);
  y += 30;
  doc.font('Helvetica').fillColor('#64748B').fontSize(10);
  doc.text('Landlord:', 50, y);
  doc.moveTo(120, y + 12).lineTo(290, y + 12).strokeColor('#94A3B8').stroke();
  doc.text('Tenant:', 310, y);
  doc.moveTo(360, y + 12).lineTo(545, y + 12).strokeColor('#94A3B8').stroke();
  y += 36;
  doc.text(tenancy.landlord_name || '', 120, y);
  doc.text(tenancy.tenant_name || '', 360, y);

  return bufferFromDoc(doc);
}

async function buildReceiptPdf({ payment }) {
  const doc = new PDFDocument({ size: 'A4', margin: 50 });

  drawHeader(
    doc,
    'Payment Receipt',
    `Receipt #${payment.id} • ${formatDate(payment.payment_date)}`
  );

  let y = 180;
  y = drawKeyValueRow(doc, 'Property', payment.property_name, y);
  y = drawKeyValueRow(doc, 'Unit', payment.unit_number, y);
  y = drawKeyValueRow(doc, 'Tenant', payment.tenant_name, y);
  y = drawKeyValueRow(doc, 'Tenant phone', payment.tenant_phone, y);
  y = drawKeyValueRow(doc, 'Payment method', payment.payment_method, y);
  y = drawKeyValueRow(doc, 'Reference', payment.transaction_ref, y);
  y = drawKeyValueRow(doc, 'Amount paid', formatKsh(payment.amount), y);
  y = drawKeyValueRow(doc, 'Status', payment.status, y);

  y += 16;
  doc.moveTo(50, y).lineTo(545, y).strokeColor('#E2E8F0').stroke();
  y += 24;

  doc.fillColor('#0F172A').fontSize(14).font('Helvetica-Bold')
    .text(`Total: ${formatKsh(payment.amount)}`, 50, y);

  y += 50;
  doc.fillColor('#64748B').fontSize(9).font('Helvetica').text(
    'This receipt is auto-generated by KodiPay. For queries, contact your landlord.',
    50, y, { width: 495, align: 'center' }
  );

  return bufferFromDoc(doc);
}

async function loadTenancy(tenancyId) {
  const result = await pool.query(
    `SELECT t.id, t.start_date, t.end_date, t.unit_id, t.tenant_id,
            u.unit_number, u.rent_amount, u.deposit_amount, u.property_id,
            p.name AS property_name, p.landlord_id,
            tu.first_name || ' ' || tu.last_name AS tenant_name,
            tu.phone AS tenant_phone,
            tu.email AS tenant_email,
            lu.first_name || ' ' || lu.last_name AS landlord_name
       FROM tenancies t
       JOIN units u ON t.unit_id = u.id
       JOIN properties p ON u.property_id = p.id
       JOIN users tu ON t.tenant_id = tu.id
       JOIN users lu ON p.landlord_id = lu.id
      WHERE t.id = $1`,
    [tenancyId]
  );
  return result.rows[0] || null;
}

async function loadPayment(paymentId) {
  const result = await pool.query(
    `SELECT pay.id, pay.amount, pay.payment_method, pay.transaction_ref, pay.status, pay.payment_date,
            t.id AS tenancy_id, t.tenant_id, t.unit_id,
            u.unit_number, u.property_id,
            p.name AS property_name, p.landlord_id,
            tu.first_name || ' ' || tu.last_name AS tenant_name,
            tu.phone AS tenant_phone
       FROM payments pay
       JOIN tenancies t ON pay.tenancy_id = t.id
       JOIN units u ON t.unit_id = u.id
       JOIN properties p ON u.property_id = p.id
       JOIN users tu ON t.tenant_id = tu.id
      WHERE pay.id = $1`,
    [paymentId]
  );
  return result.rows[0] || null;
}

async function generateLeaseForTenancy({ tenancyId, terms = {}, uploadedBy }) {
  const tenancy = await loadTenancy(tenancyId);
  if (!tenancy) return { success: false, error: 'Tenancy not found' };

  const pdfBuffer = await buildLeasePdf({ tenancy, terms });
  const fileName = `lease_tenancy-${tenancy.id}_${Date.now()}.pdf`;
  const upload = await uploadFile(pdfBuffer, fileName, 'documents/leases', 'application/pdf');
  if (!upload.success) return { success: false, error: upload.error };

  const insert = await pool.query(
    `INSERT INTO documents (property_id, unit_id, tenant_id, tenancy_id, uploaded_by,
                            type, title, file_url, mime_type, size_bytes, generated, metadata,
                            starts_on, expires_on, status)
     VALUES ($1, $2, $3, $4, $5, 'lease', $6, $7, 'application/pdf', $8, TRUE, $9, $10, $11, 'active')
     RETURNING *`,
    [
      tenancy.property_id,
      tenancy.unit_id,
      tenancy.tenant_id,
      tenancy.id,
      uploadedBy,
      `Lease — ${tenancy.tenant_name} (${tenancy.unit_number})`,
      upload.url,
      pdfBuffer.length,
      JSON.stringify({ rent_amount: tenancy.rent_amount, deposit_amount: tenancy.deposit_amount, ...terms }),
      tenancy.start_date,
      terms.end_date || tenancy.end_date || null,
    ]
  );

  return { success: true, data: insert.rows[0], simulated: upload.simulated };
}

async function generateReceiptForPayment({ paymentId, uploadedBy = null }) {
  const payment = await loadPayment(paymentId);
  if (!payment) return { success: false, error: 'Payment not found' };

  const existing = await pool.query(
    `SELECT id FROM documents WHERE type = 'receipt' AND payment_id = $1 LIMIT 1`,
    [payment.id]
  );
  if (existing.rows.length > 0) {
    return { success: true, data: existing.rows[0], reused: true };
  }

  const pdfBuffer = await buildReceiptPdf({ payment });
  const fileName = `receipt_payment-${payment.id}_${Date.now()}.pdf`;
  const upload = await uploadFile(pdfBuffer, fileName, 'documents/receipts', 'application/pdf');
  if (!upload.success) return { success: false, error: upload.error };

  const insert = await pool.query(
    `INSERT INTO documents (property_id, unit_id, tenant_id, tenancy_id, payment_id, uploaded_by,
                            type, title, file_url, mime_type, size_bytes, generated, metadata, status)
     VALUES ($1, $2, $3, $4, $5, $6, 'receipt', $7, $8, 'application/pdf', $9, TRUE, $10, 'active')
     RETURNING *`,
    [
      payment.property_id,
      payment.unit_id,
      payment.tenant_id,
      payment.tenancy_id,
      payment.id,
      uploadedBy,
      `Receipt — ${payment.tenant_name} (${formatDate(payment.payment_date)})`,
      upload.url,
      pdfBuffer.length,
      JSON.stringify({ amount: payment.amount, method: payment.payment_method, transaction_ref: payment.transaction_ref }),
    ]
  );

  return { success: true, data: insert.rows[0], simulated: upload.simulated };
}

module.exports = {
  generateLeaseForTenancy,
  generateReceiptForPayment,
  buildLeasePdf,
  buildReceiptPdf,
};
