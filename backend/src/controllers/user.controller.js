const pool = require('../config/db');
const { uploadFile } = require('../services/storage.service');

exports.updateProfilePhoto = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'No photo uploaded' });
    }

    const result = await uploadFile(req.file.buffer, req.file.originalname, 'profiles', req.file.mimetype);
    if (!result.success) {
      return res.status(500).json({ error: result.error || 'Failed to upload photo' });
    }

    const updated = await pool.query(
      `UPDATE users
       SET profile_photo_url = $1, updated_at = CURRENT_TIMESTAMP
       WHERE id = $2
       RETURNING id, email, first_name, last_name, phone, role,
                 emergency_contact_name, emergency_contact_relation, emergency_contact_phone,
                 business_name, business_registration, business_kra_pin, business_contact_person,
                 business_address, business_city, business_county, business_postal_code,
                 business_phone, business_email, profile_photo_url`,
      [result.url, req.user.id]
    );

    if (updated.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json({ user: updated.rows[0], url: result.url, simulated: result.simulated || false });
  } catch (error) {
    console.error('Update profile photo failed:', error);
    res.status(500).json({ error: 'Failed to update profile photo' });
  }
};