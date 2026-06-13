/// Pure, framework-free form validators.
///
/// Each returns `null` when the input is valid, or an error message otherwise —
/// the shape Flutter's [FormFieldValidator] expects. Being pure functions, they
/// are the highest-value, easiest-to-cover unit-test target in the app.
class Validators {
  Validators._();

  static final RegExp _emailPattern = RegExp(
    r'^[\w.+-]+@([\w-]+\.)+[\w-]{2,}$',
  );

  static String? email(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return 'Email is required.';
    if (!_emailPattern.hasMatch(input)) return 'Enter a valid email address.';
    return null;
  }

  static String? password(String? value) {
    final input = value ?? '';
    if (input.isEmpty) return 'Password is required.';
    if (input.length < 8) return 'Password must be at least 8 characters.';
    return null;
  }

  static String? name(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return 'Name is required.';
    if (input.length < 2) return 'Name is too short.';
    return null;
  }

  static String? confirmPassword(String? value, String? original) {
    final input = value ?? '';
    if (input.isEmpty) return 'Please confirm your password.';
    if (input != original) return 'Passwords do not match.';
    return null;
  }
}
