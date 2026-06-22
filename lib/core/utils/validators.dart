class Validators {
  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Email tidak boleh kosong';
    final pattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!pattern.hasMatch(text)) return 'Format email tidak valid';
    return null;
  }

  static String? password(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'Password tidak boleh kosong';
    if (text.length < 6) return 'Password minimal 6 karakter';
    return null;
  }

  static String? requiredText(String? value, {String label = 'Field'}) {
    if ((value ?? '').trim().isEmpty) return '$label tidak boleh kosong';
    return null;
  }
}
