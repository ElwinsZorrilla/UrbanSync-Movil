class Validators {
  const Validators._();

  static String? required(String? value, {String field = 'Este campo'}) {
    if (value == null || value.trim().isEmpty) return '$field es obligatorio.';
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty)
      return 'El correo es obligatorio.';
    final regex = RegExp(r'^[\w.\-+]+@([\w\-]+\.)+[\w\-]{2,}$');
    if (!regex.hasMatch(value.trim())) return 'Correo inválido.';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'La contraseña es obligatoria.';
    if (value.length < 6)
      return 'La contraseña debe tener al menos 6 caracteres.';
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return 'Debe confirmar la contraseña.';
    if (value != original) return 'Las contraseñas no coinciden.';
    return null;
  }

  static String? cedula(String? value) {
    if (value == null || value.trim().isEmpty)
      return 'La cédula es obligatoria.';
    if (value.trim().length < 6) return 'Cédula inválida.';
    return null;
  }
}
