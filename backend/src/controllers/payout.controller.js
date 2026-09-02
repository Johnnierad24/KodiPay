const {
  listPayouts,
  createPayout,
  getBalance,
} = require('../services/payout.service');

exports.listPayouts = async (req, res) => {
  try {
    const result = await listPayouts(req.user.id);
    if (!result.success) return res.status(500).json({ error: result.error });
    res.json(result.data);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch payouts' });
  }
};

exports.createPayout = async (req, res) => {
  try {
    const result = await createPayout(req.user.id, req.body);
    if (!result.success) return res.status(400).json({ error: result.error });
    res.status(201).json(result.data);
  } catch (error) {
    res.status(500).json({ error: 'Failed to create payout' });
  }
};

exports.getBalance = async (req, res) => {
  try {
    const result = await getBalance(req.user.id);
    if (!result.success) return res.status(500).json({ error: result.error });
    res.json(result.data);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch balance' });
  }
};
