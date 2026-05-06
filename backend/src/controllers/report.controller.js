const { generateRentCollectionReport, generateOccupancyReport, generatePDFReport } = require('../services/report.service');

exports.getRentCollectionReport = async (req, res) => {
  try {
    const { startMonth, startYear, endMonth, endYear } = req.query;
    const result = await generateRentCollectionReport(
      { month: parseInt(startMonth) || 1, year: parseInt(startYear) || new Date().getFullYear() },
      { month: parseInt(endMonth) || 12, year: parseInt(endYear) || new Date().getFullYear() }
    );
    if (!result.success) return res.status(500).json({ error: result.error });
    res.json(result.data);
  } catch (error) {
    res.status(500).json({ error: 'Failed to generate report' });
  }
};

exports.getOccupancyReport = async (req, res) => {
  try {
    const result = await generateOccupancyReport();
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
      { month: parseInt(endMonth) || 12, year: parseInt(endYear) || new Date().getFullYear() }
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
