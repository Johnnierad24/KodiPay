const bcrypt = require('bcrypt');
const crypto = require('crypto');
const jwt = require('jsonwebtoken');
const { validationResult } = require('express-validator');
const pool = require('../config/db');

function hashResetToken(token) {
  return crypto.createHash('sha256').update(token).digest('hex');
}

function resetResponse(payload = {}) {
  return {
    message: 'If that email exists, password reset instructions have been sent.',
    ...payload,
  };
}

exports.register = async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return res.status(400).json({ errors: errors.array() });

  try {
    const { email, password, first_name, last_name, phone, role } = req.body;
    const password_hash = await bcrypt.hash(password, 10);
    
    const result = await pool.query(
      `INSERT INTO users (email, password_hash, first_name, last_name, phone, role) 
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING id, email, first_name, last_name, phone, role`,
      [email, password_hash, first_name, last_name, phone, role]
    );
    
    const token = jwt.sign({ id: result.rows[0].id, role: result.rows[0].role }, process.env.JWT_SECRET, { expiresIn: '24h' });
    res.status(201).json({ user: result.rows[0], token });
  } catch (error) {
    if (error.code === '23505') return res.status(400).json({ error: 'Email already exists' });
    res.status(500).json({ error: 'Registration failed' });
  }
};

exports.login = async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return res.status(400).json({ errors: errors.array() });

  try {
    const { email, password } = req.body;
    const identifier = (email || '').trim();

    const result = await pool.query(
      'SELECT * FROM users WHERE email = $1 OR phone = $1',
      [identifier]
    );

    if (result.rows.length === 0) return res.status(401).json({ error: 'Invalid credentials' });

    const user = result.rows[0];
    const validPassword = await bcrypt.compare(password, user.password_hash);
    if (!validPassword) return res.status(401).json({ error: 'Invalid credentials' });

    const token = jwt.sign({ id: user.id, role: user.role }, process.env.JWT_SECRET, { expiresIn: '24h' });
    res.json({
      user: { id: user.id, email: user.email, role: user.role, first_name: user.first_name, last_name: user.last_name, phone: user.phone },
      token
    });
  } catch (error) {
    res.status(500).json({ error: 'Login failed' });
  }
};

exports.requestPasswordReset = async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return res.status(400).json({ errors: errors.array() });

  try {
    const { email } = req.body;
    const userResult = await pool.query(
      'SELECT id, email FROM users WHERE LOWER(email) = LOWER($1)',
      [email]
    );

    if (userResult.rows.length === 0) {
      return res.json(resetResponse());
    }

    const user = userResult.rows[0];
    const resetToken = crypto.randomBytes(32).toString('hex');
    const tokenHash = hashResetToken(resetToken);

    await pool.query(
      `UPDATE password_reset_tokens
       SET used_at = CURRENT_TIMESTAMP
       WHERE user_id = $1 AND used_at IS NULL`,
      [user.id]
    );

    await pool.query(
      `INSERT INTO password_reset_tokens (user_id, token_hash, expires_at)
       VALUES ($1, $2, CURRENT_TIMESTAMP + INTERVAL '30 minutes')`,
      [user.id, tokenHash]
    );

    const resetUrl = `${process.env.PASSWORD_RESET_URL || 'http://localhost:5173/#/reset-password'}?token=${resetToken}`;

    if (process.env.NODE_ENV !== 'production') {
      return res.json(resetResponse({
        reset_token: resetToken,
        reset_url: resetUrl,
      }));
    }

    // TODO: send resetUrl through a trusted email/SMS provider.
    res.json(resetResponse());
  } catch (error) {
    console.error('Password reset request failed:', error);
    res.status(500).json({ error: 'Failed to request password reset' });
  }
};

exports.resetPassword = async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return res.status(400).json({ errors: errors.array() });

  try {
    const { token, password } = req.body;
    const tokenHash = hashResetToken(token);

    const tokenResult = await pool.query(
      `SELECT id, user_id
       FROM password_reset_tokens
       WHERE token_hash = $1
         AND used_at IS NULL
         AND expires_at > CURRENT_TIMESTAMP`,
      [tokenHash]
    );

    if (tokenResult.rows.length === 0) {
      return res.status(400).json({ error: 'Reset link is invalid or expired' });
    }

    const resetToken = tokenResult.rows[0];
    const passwordHash = await bcrypt.hash(password, 10);

    await pool.query('BEGIN');
    await pool.query(
      'UPDATE users SET password_hash = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2',
      [passwordHash, resetToken.user_id]
    );
    await pool.query(
      'UPDATE password_reset_tokens SET used_at = CURRENT_TIMESTAMP WHERE id = $1',
      [resetToken.id]
    );
    await pool.query(
      `UPDATE password_reset_tokens
       SET used_at = CURRENT_TIMESTAMP
       WHERE user_id = $1 AND used_at IS NULL`,
      [resetToken.user_id]
    );
    await pool.query('COMMIT');

    res.json({ message: 'Password reset successfully' });
  } catch (error) {
    await pool.query('ROLLBACK').catch(() => {});
    console.error('Password reset failed:', error);
    res.status(500).json({ error: 'Failed to reset password' });
  }
};

exports.sendOtp = async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return res.status(400).json({ errors: errors.array() });

  try {
    const { identifier, method } = req.body;
    if (!['email', 'phone'].includes(method)) {
      return res.status(400).json({ error: 'Method must be email or phone' });
    }

    const userResult = await pool.query(
      'SELECT id, email, phone FROM users WHERE email = $1 OR phone = $1',
      [identifier]
    );

    if (userResult.rows.length === 0) {
      return res.json({ message: 'If that account exists, an OTP has been sent.' });
    }

    const user = userResult.rows[0];
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const otpHash = crypto.createHash('sha256').update(otp).digest('hex');

    const otpResult = await pool.query(
      `INSERT INTO password_reset_otps (user_id, identifier, otp_hash, method, expires_at)
       VALUES ($1, $2, $3, $4, CURRENT_TIMESTAMP + INTERVAL '10 minutes')
       RETURNING id`,
      [user.id, identifier, otpHash, method]
    );

    if (process.env.NODE_ENV !== 'production') {
      console.log(`[DEV OTP] ${method} OTP for ${identifier}: ${otp} (expires in 10 min)`);
      return res.json({
        message: 'If that account exists, an OTP has been sent.',
        dev_otp: otp,
        otp_id: otpResult.rows[0].id,
      });
    }

    if (method === 'email') {
      console.log(`[EMAIL] Would send OTP ${otp} to ${identifier}`);
    } else {
      console.log(`[SMS] Would send OTP ${otp} to ${identifier}`);
    }

    res.json({ message: 'If that account exists, an OTP has been sent.' });
  } catch (error) {
    console.error('Send OTP failed:', error);
    res.status(500).json({ error: 'Failed to send OTP' });
  }
};

exports.verifyOtp = async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return res.status(400).json({ errors: errors.array() });

  try {
    const { identifier, otp } = req.body;
    const otpHash = crypto.createHash('sha256').update(otp.toString()).digest('hex');

    const result = await pool.query(
      `SELECT id, user_id, attempted
       FROM password_reset_otps
       WHERE identifier = $1
         AND otp_hash = $2
         AND used_at IS NULL
         AND expires_at > CURRENT_TIMESTAMP
         AND attempted < 5
       ORDER BY created_at DESC
       LIMIT 1`,
      [identifier, otpHash]
    );

    if (result.rows.length === 0) {
      return res.status(400).json({ error: 'Invalid or expired OTP' });
    }

    const otpRecord = result.rows[0];
    const token = crypto.randomBytes(32).toString('hex');
    const tokenHash = crypto.createHash('sha256').update(token).digest('hex');

    await pool.query('BEGIN');
    await pool.query(
      'UPDATE password_reset_otps SET used_at = CURRENT_TIMESTAMP WHERE id = $1',
      [otpRecord.id]
    );
    await pool.query(
      `UPDATE password_reset_tokens
       SET used_at = CURRENT_TIMESTAMP
       WHERE user_id = $1 AND used_at IS NULL`,
      [otpRecord.user_id]
    );
    await pool.query(
      `INSERT INTO password_reset_tokens (user_id, token_hash, expires_at)
       VALUES ($1, $2, CURRENT_TIMESTAMP + INTERVAL '10 minutes')`,
      [otpRecord.user_id, tokenHash]
    );
    await pool.query('COMMIT');

    res.json({ message: 'OTP verified', reset_token: token });
  } catch (error) {
    await pool.query('ROLLBACK').catch(() => {});
    console.error('Verify OTP failed:', error);
    res.status(500).json({ error: 'Failed to verify OTP' });
  }
};

exports.resetPasswordWithOtp = async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return res.status(400).json({ errors: errors.array() });

  try {
    const { identifier, otp, password } = req.body;

    const otpHash = crypto.createHash('sha256').update(otp.toString()).digest('hex');

    const otpResult = await pool.query(
      `SELECT id, user_id
       FROM password_reset_otps
       WHERE identifier = $1
         AND otp_hash = $2
         AND used_at IS NOT NULL
         AND expires_at > CURRENT_TIMESTAMP - INTERVAL '10 minutes'
       ORDER BY created_at DESC
       LIMIT 1`,
      [identifier, otpHash]
    );

    let userId;
    if (otpResult.rows.length > 0) {
      userId = otpResult.rows[0].user_id;
    } else {
      const tokenResult = await pool.query(
        `SELECT prt.user_id
         FROM password_reset_tokens prt
         JOIN password_reset_otps pro ON pro.user_id = prt.user_id
         WHERE pro.identifier = $1
           AND prt.used_at IS NULL
           AND prt.expires_at > CURRENT_TIMESTAMP
         ORDER BY prt.created_at DESC
         LIMIT 1`,
        [identifier]
      );
      if (tokenResult.rows.length > 0) {
        userId = tokenResult.rows[0].user_id;
      } else {
        return res.status(400).json({ error: 'OTP not verified. Please verify your OTP first.' });
      }
    }

    const passwordHash = await bcrypt.hash(password, 10);

    await pool.query('BEGIN');
    await pool.query(
      'UPDATE users SET password_hash = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2',
      [passwordHash, userId]
    );
    await pool.query(
      `UPDATE password_reset_tokens
       SET used_at = CURRENT_TIMESTAMP
       WHERE user_id = $1 AND used_at IS NULL`,
      [userId]
    );
    await pool.query(
      `UPDATE password_reset_otps
       SET used_at = CURRENT_TIMESTAMP
       WHERE user_id = $1 AND used_at IS NULL`,
      [userId]
    );
    await pool.query('COMMIT');

    res.json({ message: 'Password reset successfully. You can now log in.' });
  } catch (error) {
    await pool.query('ROLLBACK').catch(() => {});
    console.error('Reset password with OTP failed:', error);
    res.status(500).json({ error: 'Failed to reset password' });
  }
};

exports.getCurrentUser = async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT id, email, first_name, last_name, phone, role FROM users WHERE id = $1',
      [req.user.id]
    );

    if (result.rows.length === 0) return res.status(404).json({ error: 'User not found' });
    res.json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch current user' });
  }
};

exports.updateProfile = async (req, res) => {
  try {
    const { first_name, last_name, email, phone } = req.body;
    const userId = req.user.id;

    if (email) {
      const existing = await pool.query(
        'SELECT id FROM users WHERE email = $1 AND id != $2',
        [email.trim(), userId]
      );
      if (existing.rows.length > 0) {
        return res.status(400).json({ error: 'Email already in use' });
      }
    }

    const result = await pool.query(
      `UPDATE users
       SET first_name = COALESCE(NULLIF($1, ''), first_name),
           last_name  = COALESCE(NULLIF($2, ''), last_name),
           email      = COALESCE(NULLIF($3, ''), email),
           phone      = COALESCE(NULLIF($4, ''), phone),
           updated_at = CURRENT_TIMESTAMP
       WHERE id = $5
       RETURNING id, email, first_name, last_name, phone, role`,
      [first_name, last_name, email, phone, userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json({ user: result.rows[0] });
  } catch (error) {
    console.error('Update profile failed:', error);
    res.status(500).json({ error: 'Failed to update profile' });
  }
};

exports.changePassword = async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return res.status(400).json({ errors: errors.array() });

  try {
    const { current_password, new_password } = req.body;
    if (!current_password || !new_password) {
      return res.status(400).json({ error: 'current_password and new_password are required' });
    }

    const result = await pool.query(
      'SELECT id, password_hash FROM users WHERE id = $1',
      [req.user.id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    const valid = await bcrypt.compare(current_password, result.rows[0].password_hash);
    if (!valid) {
      return res.status(401).json({ error: 'Current password is incorrect' });
    }

    const newHash = await bcrypt.hash(new_password, 10);
    await pool.query(
      'UPDATE users SET password_hash = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2',
      [newHash, req.user.id]
    );

    res.json({ message: 'Password updated' });
  } catch (error) {
    console.error('Change password failed:', error);
    res.status(500).json({ error: 'Failed to change password' });
  }
};
