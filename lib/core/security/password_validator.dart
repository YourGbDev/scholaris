// lib/core/security/password_validator.dart
//
// IAS Security Validation Module:
// - Password complexity: Minimum 8 characters, uppercase, lowercase, numeric digit, special char.
// - Confirm password matching.
// - Compatible with existing test suites while strictly enforcing IAS security policies.

class PasswordValidator {
  static final RegExp _upperCaseRegex = RegExp(r'[A-Z]');
  static final RegExp _lowerCaseRegex = RegExp(r'[a-z]');
  static final RegExp _digitRegex = RegExp(r'[0-9]');
  static final RegExp _specialCharRegex = RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-+=\[\]\\;/]');

  static bool hasMinLength(String password) => password.length >= 8;
  static bool hasUppercase(String password) => _upperCaseRegex.hasMatch(password);
  static bool hasLowercase(String password) => _lowerCaseRegex.hasMatch(password);
  static bool hasDigit(String password) => _digitRegex.hasMatch(password);
  static bool hasSpecialChar(String password) => _specialCharRegex.hasMatch(password);

  static bool isComplex(String password) =>
      hasMinLength(password) &&
      hasUppercase(password) &&
      hasLowercase(password) &&
      hasDigit(password) &&
      hasSpecialChar(password);

  /// Validates a new password against IAS complexity rules.
  /// Returns null if valid, or an error message string if invalid.
  static String? validatePassword(String? password, {String emptyMessage = 'Enter a password.'}) {
    final value = password ?? '';
    if (value.isEmpty) {
      return emptyMessage;
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters.';
    }
    if (!_upperCaseRegex.hasMatch(value) ||
        !_lowerCaseRegex.hasMatch(value) ||
        !_digitRegex.hasMatch(value) ||
        !_specialCharRegex.hasMatch(value)) {
      return 'Password must include uppercase, lowercase, number, and special character.';
    }
    return null;
  }

  /// Validates confirm password matches the chosen password.
  static String? validateConfirmPassword(
    String? confirm,
    String? password, {
    String emptyMessage = 'Confirm your password.',
  }) {
    final confirmVal = confirm ?? '';
    if (confirmVal.isEmpty) {
      return emptyMessage;
    }
    if (confirmVal != (password ?? '')) {
      return 'Passwords do not match.';
    }
    return null;
  }

  /// Calculates strength score between 0 and 3.
  static int strengthScore(String password) {
    if (password.isEmpty) return 0;
    if (password.length < 8) return 1;
    final hasUpper = _upperCaseRegex.hasMatch(password);
    final hasLower = _lowerCaseRegex.hasMatch(password);
    final hasNum = _digitRegex.hasMatch(password);
    final hasSpecial = _specialCharRegex.hasMatch(password);

    if (hasUpper && hasLower && hasNum && hasSpecial) {
      return 3;
    }
    return 2;
  }

  /// Returns user-friendly strength label based on score.
  static String strengthLabel(int score) {
    switch (score) {
      case 1:
        return 'Weak';
      case 2:
        return 'Fair';
      case 3:
        return 'Strong';
      default:
        return 'Too weak';
    }
  }
}
