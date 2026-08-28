// Reusable data-quality validators for Flutter forms.
//
// These go beyond "field is required" — they reject clearly invalid real-world
// data such as a name of "1", an email of "1@gmail.com", or implausible phone
// numbers. Return an error string to reject, or `null` to accept.

final RegExp _nameRegex = RegExp(r"^[^\p{N}\p{P}\p{S}][\p{L}\s'.-]{1,99}$", unicode: true);
final RegExp _emailRegex = RegExp(r'^[^\s@]{2,64}@[^\s@]{1,253}\.[A-Za-z]{2,}$');
final RegExp _phoneRegex = RegExp(r'^\+?[0-9]{7,15}$');

/// Validates a human name: must start with a letter, contain only letters,
/// spaces, apostrophes, hyphens, and be at least 2 characters long.
String? validateHumanName(String? value, String label) {
  final v = value?.trim() ?? '';
  if (v.isEmpty) return '$label is required';
  if (v.length < 2) return '$label must be at least 2 characters';
  if (!_nameRegex.hasMatch(v)) return '$label can only contain letters';
  return null;
}

/// Validates a realistic email address (2+ char local part, real TLD).
String? validateEmail(String? value) {
  final v = value?.trim() ?? '';
  if (v.isEmpty) return 'Email is required';
  if (!_emailRegex.hasMatch(v)) return 'Enter a valid email address';
  return null;
}

/// Validates an optional phone number.
String? validatePhone(String? value) {
  final v = value?.trim() ?? '';
  if (v.isEmpty) return null;
  if (!_phoneRegex.hasMatch(v)) return 'Enter a valid phone number';
  return null;
}
