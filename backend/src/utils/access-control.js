async function getPropertyAccess(pool, propertyId) {
  const result = await pool.query(
    'SELECT id, landlord_id FROM properties WHERE id = $1',
    [propertyId]
  );

  return result.rows[0] || null;
}

async function getUnitAccess(pool, unitId) {
  const result = await pool.query(
    `SELECT u.id, u.property_id, p.landlord_id
     FROM units u
     JOIN properties p ON u.property_id = p.id
     WHERE u.id = $1`,
    [unitId]
  );

  return result.rows[0] || null;
}

async function getTenancyAccess(pool, tenancyId) {
  const result = await pool.query(
    `SELECT t.id, t.tenant_id, p.landlord_id
     FROM tenancies t
     JOIN units u ON t.unit_id = u.id
     JOIN properties p ON u.property_id = p.id
     WHERE t.id = $1`,
    [tenancyId]
  );

  return result.rows[0] || null;
}

function ownsProperty(user, propertyAccess) {
  return propertyAccess && ['landlord', 'agent'].includes(user.role) && propertyAccess.landlord_id === user.id;
}

function canReadTenancy(user, tenancyAccess) {
  if (!tenancyAccess) return false;
  if (user.role === 'tenant') return tenancyAccess.tenant_id === user.id;
  if (['landlord', 'agent'].includes(user.role)) return tenancyAccess.landlord_id === user.id;
  return false;
}

module.exports = {
  getPropertyAccess,
  getUnitAccess,
  getTenancyAccess,
  ownsProperty,
  canReadTenancy,
};
