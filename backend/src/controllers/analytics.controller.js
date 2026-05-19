const {
  getRevenueTrend,
  getOccupancyRate,
  getPaymentMethodDistribution,
  getMaintenanceStats,
  getRentCollectionRate,
  getLandlordOverview,
} = require('../services/analytics.service');

exports.getRevenueTrend = async (req, res) => {
  try {
    const months = parseInt(req.query.months) || 12;
    const result = await getRevenueTrend(months);
    if (!result.success) return res.status(500).json({ error: result.error });
    res.json(result.data);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch revenue trend' });
  }
};

exports.getOccupancyRate = async (req, res) => {
  try {
    const result = await getOccupancyRate();
    if (!result.success) return res.status(500).json({ error: result.error });
    res.json(result.data);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch occupancy rate' });
  }
};

exports.getPaymentMethods = async (req, res) => {
  try {
    const result = await getPaymentMethodDistribution();
    if (!result.success) return res.status(500).json({ error: result.error });
    res.json(result.data);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch payment methods' });
  }
};

exports.getMaintenanceStats = async (req, res) => {
  try {
    const result = await getMaintenanceStats();
    if (!result.success) return res.status(500).json({ error: result.error });
    res.json(result.data);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch maintenance stats' });
  }
};

exports.getDashboardOverview = async (req, res) => {
  try {
    if (!['landlord', 'agent'].includes(req.user.role)) {
      return res.status(403).json({ error: 'Access denied' });
    }
    const result = await getLandlordOverview(req.user.id);
    if (!result.success) return res.status(500).json({ error: result.error });
    res.json(result.data);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch dashboard overview' });
  }
};

exports.getCollectionRate = async (req, res) => {
  try {
    const { year, month } = req.query;
    if (!year || !month) return res.status(400).json({ error: 'Year and month required' });
    const result = await getRentCollectionRate(parseInt(year), parseInt(month));
    if (!result.success) return res.status(500).json({ error: result.error });
    res.json(result.data);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch collection rate' });
  }
};
