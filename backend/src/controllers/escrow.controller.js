const {
  getEscrowBalance,
  listEscrowLedger,
} = require('../services/escrow.service');

exports.getBalance = async (req, res) => {
  try {
    const result = await getEscrowBalance(req.user.id);
    res.json(result);
  } catch (error) {
    console.error('Get escrow balance failed:', error.message);
    res.status(500).json({ error: 'Failed to fetch escrow balance' });
  }
};

exports.getLedger = async (req, res) => {
  try {
    const result = await listEscrowLedger(req.user.id);
    res.json(result);
  } catch (error) {
    console.error('Get escrow ledger failed:', error.message);
    res.status(500).json({ error: 'Failed to fetch escrow ledger' });
  }
};
