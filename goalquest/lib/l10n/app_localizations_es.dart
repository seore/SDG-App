// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get navHome => 'Inicio';

  @override
  String get navMissions => 'Misiones';

  @override
  String get navPlay => 'Jugar';

  @override
  String get navMap => 'Mapa';

  @override
  String get navProfile => 'Perfil';

  @override
  String get cancel => 'Cancelar';

  @override
  String get continueLabel => 'Continuar';

  @override
  String get goToLogin => 'Ir a iniciar sesión';

  @override
  String get email => 'Correo electrónico';

  @override
  String get password => 'Contraseña';

  @override
  String get showPassword => 'Mostrar contraseña';

  @override
  String get hidePassword => 'Ocultar contraseña';

  @override
  String get explorer => 'Explorador';

  @override
  String sdgLabel(int number, String title) {
    return 'ODS $number · $title';
  }

  @override
  String get loading => 'Cargando…';

  @override
  String get sending => 'Enviando…';

  @override
  String get saving => 'Guardando…';

  @override
  String get save => 'Guardar';

  @override
  String get showFewer => 'Mostrar menos';

  @override
  String showAllCount(int count) {
    return 'Mostrar los $count';
  }

  @override
  String get authGenericError => 'Algo salió mal. Inténtalo de nuevo.';

  @override
  String get enterEmail => 'Escribe tu correo electrónico';

  @override
  String get enterValidEmail => 'Escribe un correo válido';

  @override
  String get passwordTooShort => 'Usa al menos 6 caracteres';

  @override
  String get welcomeBack => 'Hola de nuevo. Sigue donde lo dejaste.';

  @override
  String get joinTagline => 'Pequeñas acciones, impacto global. ¡Súmate!';

  @override
  String get newHereCreateAccount => '¿Primera vez aquí? Crea una cuenta';

  @override
  String get haveAccountLogIn => '¿Ya tienes cuenta? Inicia sesión';

  @override
  String get logIn => 'Iniciar sesión';

  @override
  String get signUp => 'Registrarse';

  @override
  String get enterEmailFirst => 'Primero escribe tu correo arriba.';

  @override
  String get forgotPassword => '¿Olvidaste tu contraseña?';

  @override
  String get agreePrivacyFirst =>
      'Acepta la política de privacidad para continuar.';

  @override
  String get usernameTooShort =>
      'Elige un nombre de usuario (2 caracteres o más)';

  @override
  String get usernameTooLong => 'Usa menos de 24 caracteres';

  @override
  String get username => 'Nombre de usuario';

  @override
  String get enterBirthYear => 'Escribe tu año de nacimiento';

  @override
  String get birthYear => 'Año de nacimiento';

  @override
  String get passwordHelper => 'Al menos 6 caracteres';

  @override
  String get iAgreeToThe => 'Acepto la ';

  @override
  String get privacyPolicyLink => 'política de privacidad';

  @override
  String get createAccount => 'Crear cuenta';

  @override
  String get obEyebrow1 => 'BIENVENIDA';

  @override
  String get obTitle1 => 'Pequeñas acciones.\nImpacto global.';

  @override
  String get obBody1 =>
      'La ONU fijó 17 Objetivos de Desarrollo Sostenible para un mundo más justo y verde. Tus decisiones diarias ayudan a alcanzarlos.';

  @override
  String get obEyebrow2 => 'MISIONES DIARIAS';

  @override
  String get obTitle2 => 'Cinco acciones rápidas,\ncada día.';

  @override
  String get obBody2 =>
      'Desconecta una hora, dúchate menos tiempo, camina en vez de ir en coche. Cada misión lleva unos minutos y te da XP.';

  @override
  String get obEyebrow3 => 'TU IMPACTO';

  @override
  String get obTitle3 => 'Mira cómo crece\ntu impacto.';

  @override
  String get obBody3 =>
      'Sube de nivel, mantén tu racha y mira tus acciones en un mapa en vivo junto a personas de todo el mundo.';

  @override
  String get skip => 'Saltar';

  @override
  String get startFirstMission => 'Empieza tu primera misión';

  @override
  String get continueLearning => 'Sigue aprendiendo';

  @override
  String get yourWorld => 'Tu mundo';

  @override
  String get yourWorldSubtitle =>
      'Crece con cada estrella de objetivo que ganas';

  @override
  String get explore => 'Explorar';

  @override
  String get goodMorning => 'Buenos días';

  @override
  String get goodAfternoon => 'Buenas tardes';

  @override
  String get goodEvening => 'Buenas noches';

  @override
  String get openYourProfile => 'Abrir tu perfil';

  @override
  String get levelShort => 'NIV';

  @override
  String get impactXp => 'XP de impacto';

  @override
  String xpToLevel(int xp, int level) {
    return '$xp XP para el nivel $level';
  }

  @override
  String get viewImpact => 'Ver impacto';

  @override
  String completedOf(int done, int total) {
    return '$done de $total completadas';
  }

  @override
  String get viewAll => 'Ver todo';

  @override
  String get learn => 'Aprender';

  @override
  String get learnSubtitle => 'Lecciones sobre los 17 objetivos';

  @override
  String get community => 'Comunidad';

  @override
  String get communitySubtitle => 'Historias de otras personas';

  @override
  String get yourImpact => 'Tu impacto';

  @override
  String get yourImpactSubtitle => 'Tu progreso en el tiempo';

  @override
  String get rewards => 'Recompensas';

  @override
  String get rewardsSubtitle => 'Desbloquea marcos jugando';

  @override
  String get loginToStart =>
      'Inicia sesión o regístrate para ganar XP y seguir tu impacto en los ODS.';

  @override
  String get teamChallenge => 'Reto de equipo';

  @override
  String get allTeams => 'Todos los equipos';

  @override
  String get manage => 'Gestionar';

  @override
  String get teamUpTitle => 'Forma equipo con tu clase';

  @override
  String get teamUpBody => 'Una meta semanal para alcanzar en equipo.';

  @override
  String get consentResent =>
      'Enviado de nuevo. Pide a tu madre, padre o tutor que revise su correo.';

  @override
  String get waitingForParent =>
      'Esperando la aprobación de tu madre, padre o tutor';

  @override
  String get waitingForParentBody =>
      'Ya puedes aprender y jugar. Compartir historias y fotos, el mapa y los equipos se desbloquean cuando tu madre, padre o tutor lo apruebe.';

  @override
  String get resendEmail => 'Reenviar el correo';

  @override
  String get today => 'Hoy';

  @override
  String get todaySubtitle => 'Nuevas misiones cada día';

  @override
  String get allMissionsComplete => 'Todas las misiones completadas';

  @override
  String get dailyProgress => 'Progreso diario';

  @override
  String get missionsDoneForToday =>
      '¡Buen trabajo! Mañana llegan nuevas misiones.';

  @override
  String get missionsIntro =>
      'Completa pequeñas acciones reales para ganar XP.';

  @override
  String get statusCompleted => 'Completada';

  @override
  String get statusInProgress => 'En curso';

  @override
  String get statusNotStarted => 'Sin empezar';

  @override
  String get missionComplete => 'Misión completada';

  @override
  String get missionXp => 'XP de la misión';

  @override
  String get dismiss => 'Cerrar';

  @override
  String streakBonus(int days) {
    return 'Bonus por racha de $days días';
  }

  @override
  String levelUpReached(int level) {
    return '¡Subiste de nivel! Ya estás en el nivel $level';
  }

  @override
  String levelN(int level) {
    return 'Nivel $level';
  }

  @override
  String get signOutQuestion => '¿Cerrar sesión?';

  @override
  String get signOutBody => 'Puedes volver a iniciar sesión cuando quieras.';

  @override
  String get signOut => 'Cerrar sesión';

  @override
  String get achievements => 'Logros';

  @override
  String earnedOf(int earned, int total) {
    return '$earned de $total conseguidos';
  }

  @override
  String get goalMastery => 'Dominio de los objetivos';

  @override
  String goalMasterySubtitle(int stars, int max) {
    return '$stars de $max estrellas · lección, quiz y acción por objetivo';
  }

  @override
  String get focusSdgs => 'Tus ODS prioritarios';

  @override
  String get account => 'Cuenta';

  @override
  String get appearance => 'Apariencia';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get impactDashboard => 'Panel de impacto';

  @override
  String get privacyPolicy => 'Política de privacidad';

  @override
  String get deleteAccount => 'Eliminar cuenta';

  @override
  String get language => 'Idioma';

  @override
  String get languageSystem => 'Idioma del dispositivo';

  @override
  String get languageNote =>
      'Por ahora, las lecciones y misiones están en inglés.';

  @override
  String get noQuizzesYet => 'Aún no hay quiz';

  @override
  String quizAttempts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count intentos',
      one: '1 intento',
    );
    return '$_temp0';
  }

  @override
  String get level => 'Nivel';

  @override
  String xpToNext(int xp) {
    return '$xp XP para el siguiente';
  }

  @override
  String get totalEarned => 'Total ganado';

  @override
  String get streak => 'Racha';

  @override
  String daysInARow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'días seguidos',
      one: 'día seguido',
    );
    return '$_temp0';
  }

  @override
  String get quizAverage => 'Media en los quiz';

  @override
  String levelRank(int level, String rank) {
    return 'Nivel $level · $rank';
  }

  @override
  String get rankGlobalLeader => 'Líder global';

  @override
  String get rankChangemaker => 'Agente de cambio';

  @override
  String get rankAdvocate => 'Activista';

  @override
  String get rankExplorer => 'Explorador';

  @override
  String get rankNewcomer => 'Principiante';

  @override
  String get earned => 'Conseguido';

  @override
  String get focusPrompt =>
      'Elige hasta 3 objetivos que te importen. Tus misiones diarias los incluirán.';

  @override
  String get choose => 'Elegir';

  @override
  String get editFocusGoals => 'Editar objetivos prioritarios';

  @override
  String get yourFocusGoals => 'Tus objetivos prioritarios';

  @override
  String focusChooseUpTo(int max) {
    return 'Elige hasta $max. Hasta 2 de tus misiones diarias serán de estos objetivos.';
  }

  @override
  String selectedOf(int count, int max) {
    return '$count de $max seleccionados';
  }

  @override
  String get noProfileYet => 'Aún no tienes perfil';

  @override
  String get noProfileBody =>
      'Inicia sesión o regístrate para ver tus estadísticas de los ODS.';

  @override
  String get deleteAccountQuestion => '¿Eliminar tu cuenta?';

  @override
  String get deleteAccountBody =>
      'Esto elimina para siempre tu perfil, XP, misiones, historial de quiz y juegos, historias, fotos y equipos. No se puede deshacer.';

  @override
  String get deleting => 'Eliminando…';

  @override
  String get deleteForever => 'Eliminar para siempre';

  @override
  String get reminders => 'Recordatorios';

  @override
  String remindersOn(String time) {
    return 'Cada día a las $time · aviso de racha a las 20:00';
  }

  @override
  String get remindersOff => 'Recordatorio diario de misiones y aviso de racha';

  @override
  String get notificationsBlocked =>
      'Las notificaciones están desactivadas para esta app. Actívalas en los ajustes del teléfono.';
}
