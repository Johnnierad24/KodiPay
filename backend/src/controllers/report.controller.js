const {
  generateRentCollectionReport,
  generateOccupancyReport,
  generateIncomeReport,
  generateArrearsReport,
  generatePropertyPerformanceReport,
  generateMaintenanceReport,
  generatePaymentTrendsReport,
  generateTransactionReport,
  generateCSV,
  generatePDFReport,
} = require('../services/report.service');

function getDateRange(req) {
  const end = req.query.endDate ? new Date(req.query.endDate) : new Date();
  const start = req.query.startDate ? new Date(req.query.startDate) : new Date(end);

  if (!req.query.startDate) {
    start.setDate(1);
  }

  return {
    startDate: start.toISOString().slice(0, 10),
    endDate: end.toISOString().slice(0, 10),
  };
}

exports.getRentCollectionReport = async (req, res) => {
  try {
    const { startMonth, startYear, endMonth, endYear } = req.query;
    const result = await generateRentCollectionReport(
      { month: parseInt(startMonth) || 1, year: parseInt(startYear) || new Date().getFullYear() },
      { month: parseInt(endMonth) || 12, year: parseInt(endYear) || new Date().getFullYear() },
      req.user.id
    );
    if (!result.success) return res.status(500).json({ error: result.error });
    res.json(result.data);
  } catch (error) {
    res.status(500).json({ error: 'Failed to generate report' });
  }
};

exports.getOccupancyReport = async (req, res) => {
  try {
    const result = await generateOccupancyReport(req.user.id);
    if (!result.success) return res.status(500).json({ error: result.error });
    res.json(result.data);
  } catch (error) {
    res.status(500).json({ error: 'Failed to generate report' });
  }
};

exports.downloadRentReportPDF = async (req, res) => {
  try {
    const { startMonth, startYear, endMonth, endYear } = req.query;
    const result = await generateRentCollectionReport(
      { month: parseInt(startMonth) || 1, year: parseInt(startYear) || new Date().getFullYear() },
      { month: parseInt(endMonth) || 12, year: parseInt(endYear) || new Date().getFullYear() },
      req.user.id
    );
    
    if (!result.success) return res.status(500).json({ error: result.error });
    
    const pdfBuffer = await generatePDFReport(
      result.data,
      'Rent Collection Report',
      [
        { header: 'Property', field: 'property_name' },
        { header: 'Unit', field: 'unit_number' },
        { header: 'Tenant', field: 'tenant_name' },
        { header: 'Period', field: 'month' },
        { header: 'Amount', field: 'invoice_amount' },
        { header: 'Status', field: 'invoice_status' }
      ]
    );
    
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', 'attachment; filename=rent-collection-report.pdf');
    res.send(pdfBuffer);
  } catch (error) {
    res.status(500).json({ error: 'Failed to generate PDF' });
  }
};

exports.getIncomeReport = async (req, res) => {
  try {
    const { startDate, endDate } = getDateRange(req);
    const result = await generateIncomeReport(req.user.id, startDate, endDate);
    if (!result.success) return res.status(500).json({ error: result.error });
    res.json(result.data);
  } catch (error) {
    res.status(500).json({ error: 'Failed to generate income report' });
  }
};

exports.getArrearsReport = async (req, res) => {
  try {
    const result = await generateArrearsReport(req.user.id);
    if (!result.success) return res.status(500).json({ error: result.error });
    res.json(result.data);
  } catch (error) {
    res.status(500).json({ error: 'Failed to generate arrears report' });
  }
};

exports.getPropertyPerformanceReport = async (req, res) => {
  try {
    const { startDate, endDate } = getDateRange(req);
    const result = await generatePropertyPerformanceReport(req.user.id, startDate, endDate);
    if (!result.success) return res.status(500).json({ error: result.error });
    res.json(result.data);
  } catch (error) {
    res.status(500).json({ error: 'Failed to generate property performance report' });
  }
};

exports.getMaintenanceReport = async (req, res) => {
  try {
    const { startDate, endDate } = getDateRange(req);
    const result = await generateMaintenanceReport(req.user.id, startDate, endDate);
    if (!result.success) return res.status(500).json({ error: result.error });
    res.json(result.data);
  } catch (error) {
    res.status(500).json({ error: 'Failed to generate maintenance report' });
  }
};

exports.getPaymentTrendsReport = async (req, res) => {
  try {
    const months = parseInt(req.query.months) || 12;
    const result = await generatePaymentTrendsReport(req.user.id, months);
    if (!result.success) return res.status(500).json({ error: result.error });
    res.json(result.data);
  } catch (error) {
    res.status(500).json({ error: 'Failed to generate payment trends report' });
  }
};

exports.getTransactionReport = async (req, res) => {
  try {
    const { startDate, endDate } = getDateRange(req);
    const result = await generateTransactionReport(req.user.id, startDate, endDate);
    if (!result.success) return res.status(500).json({ error: result.error });
    res.json(result.data);
  } catch (error) {
    res.status(500).json({ error: 'Failed to generate transaction report' });
  }
};

exports.downloadTransactionReportCSV = async (req, res) => {
  try {
    const { startDate, endDate } = getDateRange(req);
    const result = await generateTransactionReport(req.user.id, startDate, endDate);
    if (!result.success) return res.status(500).json({ error: result.error });

    const csv = generateCSV(result.data, [
      { header: 'Date', field: 'payment_date' },
      { header: 'Tenant', field: 'tenant_name' },
      { header: 'Property', field: 'property_name' },
      { header: 'Unit', field: 'unit_number' },
      { header: 'Method', field: 'payment_method' },
      { header: 'Reference', field: 'transaction_ref' },
      { header: 'Amount', field: 'amount' },
      { header: 'Status', field: 'status' },
    ]);

    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', 'attachment; filename=transaction-report.csv');
    res.send(csv);
  } catch (error) {
    res.status(500).json({ error: 'Failed to generate CSV' });
  }
};
