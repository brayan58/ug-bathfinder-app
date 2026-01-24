
class AppStrings {
  static const String appName = 'UG BathFinder';
  static const String appSubtitle = 'Encuentra baños en el campus';
  
  // Login
  static const String emailHint = 'correo@ug.edu.ec';
  static const String passwordHint = 'Contraseña';
  static const String loginButton = 'INICIAR SESIÓN';
  static const String forgotPassword = '¿Olvidaste tu contraseña?';
  
  // Errores
  static const String invalidEmail = 'Debes usar tu correo institucional (@ug.edu.ec)';
  static const String shortPassword = 'La contraseña debe tener al menos 6 caracteres';
  static const String loginError = 'Email o contraseña incorrectos';
  static const String networkError = 'No hay conexión a internet';
  static const String serverError = 'Error del servidor. Intenta más tarde';

  // Reportes de baños
  static const String tipoLimpieza = 'Limpieza necesaria';
  static const String tipoDanoInstalaciones = 'Daño en instalaciones';
  static const String tipoSinPapel = 'Sin papel higiénico';
  static const String tipoSinAgua = 'Sin agua';
  static const String tipoPuertaDanada = 'Puerta dañada';
  static const String tipoSinLuz = 'Sin luz';
  static const String tipoOtro = 'Otro';

  // Reportes de puertas 
  static const String tipoPuertaCerrada = 'Puerta cerrada';

  static const String urgenciaBaja = 'Baja';
  static const String urgenciaMedia = 'Media';
  static const String urgenciaAlta = 'Alta';

  static const String estadoPendiente = 'Pendiente';
  static const String estadoEnProceso = 'En proceso';
  static const String estadoResuelto = 'Resuelto';
  static const String estadoRechazado = 'Rechazado';

  // Puertas 
  static const String puertaAbierta = 'Abierta';
  static const String puertaCerrada = 'Cerrada';
  static const String entradaSugerida = 'Entrada sugerida';
  static const String puertaPrincipal = 'Entrada principal';
  static const String horarioNoDefinido = 'Horario no definido';
}