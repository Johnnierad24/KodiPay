const {
  listPayouts,
  createPayout,
  getBalance,
} = require('../services/payout.service');
const pool = require('../config/db');
const escrowService = require('../services/escrow.service');

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

// Update a payout's status (the simulated disbursement step). If a payout is
// marked failed, the escrow hold is reversed so the landlord can retry.
exports.updatePayoutStatus = async (req, res) => {
  try {
    const { status } = req.body;
    const allowed = ['scheduled', 'pending', 'completed', 'failed'];
    if (!allowed.includes(status)) {
      return res.status(400).json({ error: `status must be one of: ${allowed.join(', ')}` });
    }

    const find = await pool.query(
      'SELECT id, landlord_id, amount, status, reference FROM payouts WHERE id = $1 AND landlord_id = $2',
      [req.params.id, req.user.id]
    );
    if (find.rows.length === 0) return res.status(404).json({ error: 'Payout not found' });
    const payout = find.rows[0];

    // If transitioning to failed, return the held funds to escrow (only once).
    if (status === 'failed' && payout.status !== 'failed') {
      await escrowService.reverseEscrowDebit(
        payout.landlord_id,
        Number(payout.amount),
        `Payout-${payout.reference || payout.id}`,
        'Payout failed, funds returned to escrow'
      );
    }

    let result;
    if (status === 'completed') {
      result = await pool.query(
        `UPDATE payouts
         SET status = 'completed', completed_date = CURRENT_TIMESTAMP, updated_at = CURRENT_TIMESTAMP
         WHERE id = $1
         RETURNING *`,
        [req.params.id]
      );
    } else {
      result = await pool.query(
        `UPDATE payouts
         SET status = $1, updated_at = CURRENT_TIMESTAMP
         WHERE id = $2
         RETURNING *`,
        [status, req.params.id]
      );
    }
    res.json(result.rows[0]);
  } catch (error) {
    console.error('Update payout status failed:', error.message);
    res.status(500).json({ error: 'Failed to update payout status' });
  }
};