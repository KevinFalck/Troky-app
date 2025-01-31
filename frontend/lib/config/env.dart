class Env {
  static const backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue:
        'http://10.0.2.2:5000', // Valeur par défaut pour le développement
  );
}
