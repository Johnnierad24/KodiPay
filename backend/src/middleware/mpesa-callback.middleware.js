const mpesaConfig = require('../config/mpesa');

// The M-Pesa STK callback is a public, unauthenticated webhook — Safaricom calls
// it machine-to-machine, so it cannot sit behind login/JWT. To stop anyone on the
// internet from forging "payment successful" calls, we gate it two additive ways,
// both optional:
//   1. MPESA_CALLBACK_SECRET — an unguessable token baked into the URL path.
//   2. MPESA_ALLOWED_IPS     — an allowlist of Safaricom's published egress IPs.
// A failed check returns a bare 404 (not 401/403) so we never confirm the endpoint
// even exists to a prober.

// Lightweight matcher: supports exact IPs ("196.201.214.200") and dotted prefixes
// ("196.201.214.") so an entire published block can be allowed without a CIDR lib.
function ipAllowed(ip, allowlist) {
  return allowlist.some((entry) => ip === entry || ip.startsWith(entry));
}

function verifyCallbackSource(req, res, next) {
  // 1. Secret path segment. req.params.token is undefined on the legacy
  //    secret-less route, which only matches when no secret is configured.
  if (mpesaConfig.callbackSecret && req.params.token !== mpesaConfig.callbackSecret) {
    return res.status(404).json({ ResultCode: 1, ResultDesc: 'Not found' });
  }

  // 2. Optional IP allowlist (defense in depth). Requires TRUST_PROXY=true behind
  //    a reverse proxy so req.ip is the real client, not the proxy.
  const allowlist = (process.env.MPESA_ALLOWED_IPS || '')
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean);

  if (allowlist.length > 0) {
    const ip = (req.ip || '').replace('::ffff:', ''); // unwrap IPv4-mapped IPv6
    if (!ipAllowed(ip, allowlist)) {
      console.warn(`M-Pesa callback rejected from unlisted IP: ${ip}`);
      return res.status(404).json({ ResultCode: 1, ResultDesc: 'Not found' });
    }
  }

  next();
}

module.exports = verifyCallbackSource;
