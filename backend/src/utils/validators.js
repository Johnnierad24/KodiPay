/**
 * Data-quality validation helpers for express-validator custom validators.
 *
 * These go beyond "field is non-empty" — they reject clearly invalid real-world
 * data such as a name of "1", an email of "1@gmail.com", or phone numbers that
 * aren't plausible. Used in express-validator rules via `custom(validators.x)`.
 */

/** Friendly display name for FieldValue / brand labels. */
const { body } = require('express-validator');

// A valid human name: letters (incl. accented/unicode), spaces, hyphens,
// apostrophes, periods. Max reasonable length. Rejects pure digits/punctuation.
const NAME_REGEX = /^[\p{L}][\p{L}\s'.\-]{0,99}$/u;

// A reasonably realistic email: local@domain.tld. The local part needs at
// least 2 characters (so "1@gmail.com" is rejected) and there is a real TLD
// of 2+ letters. The domain itself may be 1+ char (e.g. x.com).
const EMAIL_REGEX = /^[^\s@]{2,64}@[^\s@]{1,253}\.[A-Za-z]{2,}$/;

// A plausible phone: optional + or 0, then digits, 7-15 total digits.
const PHONE_REGEX = /^\+?[0-9]{7,15}$/;

/**
 * Returns true if value is a plausible human name.
 * Accepts only strings with at least one letter and no leading digits/symbols.
 */
function isHumanName(value) {
  if (typeof value !== 'string') return false;
  const v = value.trim();
  if (v.length < 2) return false;
  return NAME_REGEX.test(v);
}

/** Returns true if value is a realistic email address. */
function isRealisticEmail(value) {
  if (typeof value !== 'string') return false;
  const v = value.trim();
  return EMAIL_REGEX.test(v);
}

/** Returns true if value is a plausible phone number (or empty/optional). */
function isPhone(value) {
  if (value === undefined || value === null || value === '') return true;
  return PHONE_REGEX.test(String(value).trim());
}

/** Custom express-validator middleware factory for a human name field. */
function validateName(field, { optional = false } = {}) {
  const rule = body(field).trim();
  if (optional) rule.optional({ values: 'falsy' });
  return rule
    .custom(isHumanName)
    .withMessage(
      `${field.replace(/_/g, ' ')} must be a valid name (letters only, 2+ characters)`
    );
}

/** Custom express-validator middleware factory for a realistic email field. */
function validateEmail(field, { optional = false } = {}) {
  const rule = body(field).trim().normalizeEmail();
  if (optional) rule.optional({ values: 'falsy' });
  return rule.custom(isRealisticEmail).withMessage('Enter a valid email address');
}

/** Custom express-validator middleware factory for an optional phone field. */
function validatePhone(field, { optional = true } = {}) {
  const rule = body(field).trim();
  if (optional) rule.optional({ values: 'falsy' });
  return rule.custom(isPhone).withMessage('Enter a valid phone number');
}

module.exports = {
  isHumanName,
  isRealisticEmail,
  isPhone,
  validateName,
  validateEmail,
  validatePhone,
};
