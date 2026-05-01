// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'Nexierge';

  @override
  String get appTagline => 'Tu eslogan aquí';

  @override
  String get login => 'Iniciar sesión';

  @override
  String get logout => 'Cerrar sesión';

  @override
  String get register => 'Registrarse';

  @override
  String get email => 'Correo electrónico';

  @override
  String get password => 'Contraseña';

  @override
  String get confirmPassword => 'Confirmar contraseña';

  @override
  String get forgotPassword => '¿Olvidaste tu contraseña?';

  @override
  String get resetPassword => 'Restablecer contraseña';

  @override
  String get loginWelcomeTitle => 'Bienvenido a Nexierge';

  @override
  String get loginWelcomeSubtitle =>
      'Inicia sesión para continuar gestionando las operaciones de tu hotel.';

  @override
  String get loginTabEmail => 'Correo';

  @override
  String get loginTabEmployeeCode => 'Código de empleado';

  @override
  String get loginEmailLabel => 'Correo de trabajo';

  @override
  String get loginPasswordLabel => 'Contraseña';

  @override
  String get loginEmployeeCodeLabel => 'Código de empleado';

  @override
  String get loginCodeLabel => 'Código de acceso';

  @override
  String get loginAccessButton => 'Iniciar sesión';

  @override
  String get loginEmailHint => 'tu@tuhotel.com';

  @override
  String get loginEmployeeCodeHint => 'p. ej. EMP-001';

  @override
  String get loginCodeHint => 'Ingresa tu código de acceso';

  @override
  String get loginAdminContactFooter =>
      'Si no recuerdas tus códigos de acceso o tu contraseña, contacta al administrador de tu hotel.';

  @override
  String get loginAppVersion => 'v1.0.0';

  @override
  String get loginEmployeeHelper =>
      'Usa las credenciales proporcionadas por el administrador de tu hotel.';

  @override
  String get loginErrorInvalidEmail => 'Correo o contraseña no válidos.';

  @override
  String get loginErrorInvalidCode =>
      'Código de empleado o código de acceso no válido.';

  @override
  String get loginErrorCodeExpired =>
      'El código ha caducado. Solicita uno nuevo.';

  @override
  String get loginErrorPendingReviewTitle => 'Acceso en revisión';

  @override
  String get loginErrorPendingReviewBody =>
      'Tu solicitud de acceso aún está en revisión.';

  @override
  String get loginErrorRejectedTitle => 'Acceso no aprobado';

  @override
  String get loginErrorRejectedBody =>
      'Tu solicitud de acceso no fue aprobada. Contacta a soporte.';

  @override
  String get loginErrorDisabledTitle => 'Cuenta deshabilitada';

  @override
  String get loginErrorDisabledBody =>
      'Tu cuenta está deshabilitada actualmente. Contacta a tu administrador.';

  @override
  String get loginErrorInactiveHotelTitle => 'Hotel inactivo';

  @override
  String get loginErrorInactiveHotelBody =>
      'Esta cuenta de hotel no está activa actualmente.';

  @override
  String get loginErrorGeneric => 'Algo salió mal. Inténtalo de nuevo.';

  @override
  String get loginErrorSignInFailed =>
      'No pudimos iniciar sesión ahora. Inténtalo de nuevo.';

  @override
  String get networkError =>
      'Sin conexión a internet. Comprueba tu red e inténtalo de nuevo.';

  @override
  String get timeoutError =>
      'La solicitud agotó el tiempo de espera. Inténtalo de nuevo.';

  @override
  String get unauthorizedError =>
      'Tu sesión ha caducado. Vuelve a iniciar sesión.';

  @override
  String get forbiddenError => 'No tienes permiso para realizar esta acción.';

  @override
  String get notFoundError => 'No se encontró el recurso solicitado.';

  @override
  String get serverError =>
      'Algo salió mal por nuestra parte. Inténtalo más tarde.';

  @override
  String get unknownError => 'Ocurrió un error inesperado. Inténtalo de nuevo.';

  @override
  String get validationError => 'Revisa la información e inténtalo de nuevo.';

  @override
  String get successSaved => 'Guardado correctamente.';

  @override
  String get successUpdated => 'Actualizado correctamente.';

  @override
  String get successDeleted => 'Eliminado correctamente.';

  @override
  String get save => 'Guardar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get confirm => 'Confirmar';

  @override
  String get delete => 'Eliminar';

  @override
  String get edit => 'Editar';

  @override
  String get done => 'Listo';

  @override
  String get retry => 'Reintentar';

  @override
  String get back => 'Atrás';

  @override
  String get next => 'Siguiente';

  @override
  String get submit => 'Enviar';

  @override
  String get search => 'Buscar';

  @override
  String get loading => 'Cargando…';

  @override
  String get emptyState => 'Aún no hay nada aquí.';

  @override
  String get emptySearch => 'Sin resultados.';

  @override
  String get requiredField => 'Este campo es obligatorio.';

  @override
  String get invalidEmail => 'Introduce una dirección de correo válida.';

  @override
  String get passwordTooShort =>
      'La contraseña debe tener al menos 8 caracteres.';

  @override
  String get passwordsDoNotMatch => 'Las contraseñas no coinciden.';

  @override
  String get scopeMyDept => 'Mi área';

  @override
  String get scopeAllHotel => 'Todo el hotel';

  @override
  String greeting(String name) {
    return 'Hola, $name';
  }

  @override
  String get ticketsSearchHint => 'Buscar ticket, habitación o huésped…';

  @override
  String get kpiIncoming => 'ENTRANTES';

  @override
  String get kpiInProgress => 'EN CURSO';

  @override
  String get kpiOverdue => 'VENCIDOS';

  @override
  String get subTabIncoming => 'Entrantes';

  @override
  String get subTabToday => 'Hoy';

  @override
  String get subTabScheduled => 'Programados';

  @override
  String get subTabDone => 'Hechos';

  @override
  String get sectionIncomingNow => 'ENTRANTES AHORA';

  @override
  String get sectionInProgress => 'EN CURSO';

  @override
  String get sectionCompletedToday => 'COMPLETADOS HOY';

  @override
  String get sectionScheduled => 'PROGRAMADOS';

  @override
  String get chipUniversal => 'Universal';

  @override
  String get chipCatalog => 'Catálogo';

  @override
  String get chipManual => 'Manual';

  @override
  String get statusNew => 'Nuevo';

  @override
  String get statusUnassigned => 'Sin asignar';

  @override
  String get statusAccepted => 'Aceptado';

  @override
  String get statusInProgress => 'En curso';

  @override
  String get statusDone => 'Hecho';

  @override
  String get statusCancelled => 'Cancelado';

  @override
  String get statusOverdue => 'Vencido';

  @override
  String get detailRoomLabel => 'HABITACIÓN';

  @override
  String get detailGuestLabel => 'HUÉSPED';

  @override
  String get detailRequestLabel => 'SOLICITUD';

  @override
  String get detailGuestNoteLabel => 'NOTA DEL HUÉSPED';

  @override
  String get detailTimingLabel => 'TIEMPOS';

  @override
  String get detailCreated => 'Creado';

  @override
  String get detailAccepted => 'Aceptado';

  @override
  String get detailDone => 'Hecho';

  @override
  String get detailEmpty => '—';

  @override
  String get actionAccept => 'Aceptar y fijar ETA';

  @override
  String get actionChangeDept => 'Cambiar área';

  @override
  String get actionAddNote => 'Añadir nota';

  @override
  String get actionStart => 'Iniciar';

  @override
  String get actionMarkDone => 'Marcar hecho';

  @override
  String get actionUndo => 'DESHACER';

  @override
  String get ticketTabDetails => 'Detalles';

  @override
  String get ticketTabActivity => 'Actividad';

  @override
  String get ticketSectionGuestRoom => 'HUÉSPED Y HABITACIÓN';

  @override
  String get ticketSectionInformation => 'INFORMACIÓN DEL TICKET';

  @override
  String get ticketFieldGuest => 'Huésped';

  @override
  String get ticketFieldRoom => 'Habitación';

  @override
  String get ticketFieldRoomType => 'Tipo de habitación';

  @override
  String get ticketFieldDepartment => 'Departamento';

  @override
  String get ticketFieldConversation => 'Conversación';

  @override
  String get ticketFieldStatus => 'Estado';

  @override
  String get ticketFieldTicketType => 'Tipo de ticket';

  @override
  String get ticketFieldSource => 'Origen';

  @override
  String ticketRoomNumber(String number) {
    return '#$number';
  }

  @override
  String get ticketPriorityP1 => 'P1';

  @override
  String get ticketPriorityP2 => 'P2';

  @override
  String get ticketPriorityP3 => 'P3';

  @override
  String get ticketStatusBadgeAccepted => 'ACEPTADO';

  @override
  String get ticketStatusBadgeIncoming => 'ENTRANTE';

  @override
  String get ticketStatusBadgeInProgress => 'EN CURSO';

  @override
  String get ticketStatusBadgeDone => 'HECHO';

  @override
  String get ticketStatusBadgeCancelled => 'CANCELADO';

  @override
  String get ticketSourceGuestApp => 'App del huésped';

  @override
  String get ticketSourceFrontDesk => 'Recepción';

  @override
  String get ticketSourcePhone => 'Teléfono';

  @override
  String get ticketSourceWalkIn => 'Sin cita';

  @override
  String get ticketSourceSystem => 'Sistema';

  @override
  String ticketElapsed(String elapsed) {
    return '$elapsed transcurridos';
  }

  @override
  String get ticketActionStartWork => 'Comenzar';

  @override
  String get ticketActionPause => 'Pausar';

  @override
  String get ticketActionResume => 'Reanudar';

  @override
  String get ticketActionComplete => 'Completar';

  @override
  String get ticketActionChangeDue => 'Cambiar plazo';

  @override
  String get ticketActionCancel => 'Cancelar';

  @override
  String get ticketActionReset => 'Restablecer';

  @override
  String get ticketActivityCreated => 'Ticket creado';

  @override
  String ticketActivityStatusChange(String from, String to) {
    return '$from → $to';
  }

  @override
  String get ticketActivityBadgeAcknowledged => 'Reconocido';

  @override
  String get ticketActivityBadgeCreated => 'Creado';

  @override
  String get ticketActivityBadgeDone => 'Hecho';

  @override
  String get ticketActivityBadgeCancelled => 'Cancelado';

  @override
  String get ticketActivityBadgeNote => 'Nota';

  @override
  String get ticketActivityBadgeReassigned => 'Reasignado';

  @override
  String get ticketActivityBadgeOverdue => 'Vencido';

  @override
  String get etaTitle => '¿Cuándo estará listo?';

  @override
  String etaSubtitle(String ticketCode) {
    return 'Aceptando $ticketCode';
  }

  @override
  String get eta10 => '10 minutos';

  @override
  String get eta15 => '15 minutos';

  @override
  String get eta30 => '30 minutos';

  @override
  String get eta60 => '1 hora';

  @override
  String get etaLater => 'Más tarde hoy';

  @override
  String get etaCustom => 'Hora personalizada';

  @override
  String get etaGuestNotified => 'Se notificará al huésped';

  @override
  String etaReadyBy(String time) {
    return 'Listo a las $time';
  }

  @override
  String etaConfirmMinutes(int minutes) {
    return 'Aceptar · $minutes min';
  }

  @override
  String etaConfirmHours(int hours) {
    return 'Aceptar · $hours h';
  }

  @override
  String get etaShortNow => 'Ahora';

  @override
  String etaShortMinutes(int minutes) {
    return 'ETA $minutes min';
  }

  @override
  String etaShortHours(int hours) {
    return 'ETA $hours h';
  }

  @override
  String get activityTypeAll => 'Todo';

  @override
  String get activityTypeCreated => 'Creados';

  @override
  String get activityTypeAccepted => 'Aceptados';

  @override
  String get activityTypeDone => 'Hechos';

  @override
  String get activityTypeOverdue => 'Vencidos';

  @override
  String get activityTypeCancelled => 'Cancelados';

  @override
  String get activityTypeNotes => 'Notas';

  @override
  String get activityTypeReassigned => 'Reasignados';

  @override
  String get dayToday => 'HOY';

  @override
  String get dayYesterday => 'AYER';

  @override
  String get dayOlder => 'ANTERIORES';

  @override
  String get activityCreatedTitle => 'Ticket creado';

  @override
  String activityAcceptedTitle(String actor) {
    return '$actor aceptó el ticket';
  }

  @override
  String activityDoneTitle(String actor) {
    return '$actor marcó esto como hecho';
  }

  @override
  String get activityOverdueTitle => 'El ticket está vencido';

  @override
  String activityCancelledTitle(String actor) {
    return '$actor canceló este ticket';
  }

  @override
  String activityNoteTitle(String actor) {
    return '$actor añadió una nota';
  }

  @override
  String activityReassignedTitle(String actor, String target) {
    return '$actor reasignó a $target';
  }

  @override
  String get createNewTitle => 'Crear nuevo';

  @override
  String get createNewSubtitle => '¿Qué tipo de ticket vas a crear?';

  @override
  String get createUniversalTitle => 'Universal';

  @override
  String get createUniversalDesc =>
      'Toallas, almohadas, artículos de aseo — peticiones rápidas';

  @override
  String get createCatalogTitle => 'Catálogo';

  @override
  String get createCatalogDesc =>
      'Servicio de habitaciones, spa, bar — todo lo que el huésped pague';

  @override
  String get createManualTitle => 'Manual';

  @override
  String get createManualDesc =>
      'Quejas, incidencias, cualquier cosa que no encaje arriba';

  @override
  String get createHint =>
      '¿No estás seguro? Manual sirve para cualquier caso.';

  @override
  String get universalHeading => 'Universal';

  @override
  String get universalSubheading => 'Toca lo que necesitas';

  @override
  String get itemTowels => 'Toallas';

  @override
  String get itemPillows => 'Almohadas';

  @override
  String get itemToiletries => 'Artículos de aseo';

  @override
  String get itemBlanket => 'Manta';

  @override
  String get itemWater => 'Agua';

  @override
  String get itemOther => 'Otro';

  @override
  String get roomLabel => 'HABITACIÓN';

  @override
  String get roomFind => 'Buscar';

  @override
  String get roomRecentHelper =>
      'Habitaciones recientes · toca para seleccionar';

  @override
  String get noteLabel => 'NOTA (OPCIONAL)';

  @override
  String get noteHint => 'Añade una nota para el equipo…';

  @override
  String get pickItemHint => 'Elige un artículo para empezar';

  @override
  String get pickRoomHint => 'Elige una habitación para continuar';

  @override
  String get createCta => 'Crear';

  @override
  String get createSuccessToast => 'Ticket creado';

  @override
  String get tapToAdd => 'Toca para añadir';

  @override
  String itemsSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count artículos seleccionados',
      one: '1 artículo seleccionado',
    );
    return '$_temp0';
  }

  @override
  String get roomPickerTitle => 'Seleccionar habitación';

  @override
  String get roomPickerRecent => 'Recientes';

  @override
  String get roomPickerAll => 'Todas las habitaciones';

  @override
  String roomFloor(int floor) {
    return 'Planta $floor';
  }

  @override
  String roomNumber(String number) {
    return 'Habitación $number';
  }

  @override
  String get roomSearchHint => 'Buscar número de habitación…';

  @override
  String get filterTitle => 'Filtrar por área';

  @override
  String get filterSubtitleAll => 'Mostrando todas las áreas';

  @override
  String filterSubtitleSome(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Mostrando $count áreas',
      one: 'Mostrando 1 área',
    );
    return '$_temp0';
  }

  @override
  String get filterActionClear => 'Clear';

  @override
  String get filterActionApply => 'Apply';

  @override
  String get filterActionSelectAll => 'Select All';

  @override
  String get filterSelectAll => 'Seleccionar todo';

  @override
  String get filterClear => 'Limpiar';

  @override
  String get filterApply => 'Aplicar';

  @override
  String get deptConcierge => 'Conserjería';

  @override
  String get deptFnb => 'A y B';

  @override
  String get deptFrontDesk => 'Recepción';

  @override
  String get deptHousekeeping => 'Limpieza';

  @override
  String get deptMaintenance => 'Mantenimiento';

  @override
  String get deptRoomService => 'Servicio de habitaciones';

  @override
  String dashboardGreetingMorning(String name) {
    return 'Buenos días, $name';
  }

  @override
  String dashboardGreetingAfternoon(String name) {
    return 'Buenas tardes, $name';
  }

  @override
  String dashboardGreetingEvening(String name) {
    return 'Buenas noches, $name';
  }

  @override
  String get dashboardNeedsAcknowledgment => 'Necesita confirmación';

  @override
  String get dashboardIncomingFooterEmpty => 'A la espera de aceptación';

  @override
  String get dashboardInProgressLabel => 'En curso';

  @override
  String get dashboardInProgressFooter => 'En atención ahora mismo';

  @override
  String get dashboardOverdueLabel => 'Atrasados';

  @override
  String get dashboardOverdueFooter => 'Pasada la hora límite';

  @override
  String get dashboardNotStartedLabel => 'Sin iniciar';

  @override
  String get dashboardNotStartedFooter => 'Aceptado pero no iniciado';

  @override
  String get dashboardNeedsAttention => 'Necesita atención';

  @override
  String get dashboardViewAll => 'Ver todos';

  @override
  String get dashboardAllClearTitle => 'Todo en orden';

  @override
  String get dashboardAllClearBody =>
      'Ningún ticket requiere atención inmediata en este momento.';

  @override
  String get dashboardAllClearHint =>
      'Los tickets nuevos y activos están en la pestaña Tickets.';

  @override
  String dashboardBreakdownUniversal(int n) {
    return '$n universal';
  }

  @override
  String dashboardBreakdownCatalog(int n) {
    return '$n catálogo';
  }

  @override
  String dashboardBreakdownManual(int n) {
    return '$n manual';
  }

  @override
  String dashboardOverduePill(int minutes) {
    return 'Atrasado $minutes min';
  }

  @override
  String dashboardDueSoonPill(int minutes) {
    return 'En $minutes min';
  }

  @override
  String get dashboardNotStartedPill => 'Sin iniciar';

  @override
  String dashboardWaitingPill(int minutes) {
    return 'Esperando $minutes min';
  }

  @override
  String dashboardRoomPrefix(String number) {
    return 'Habitación $number';
  }

  @override
  String get navDashboard => 'Panel';

  @override
  String get navTickets => 'Tickets';

  @override
  String get navActivity => 'Actividad';

  @override
  String get navCreate => 'Crear';

  @override
  String get navModules => 'Módulos';

  @override
  String get navProfile => 'Perfil';

  @override
  String get comingSoonTitle => 'Próximamente';

  @override
  String get comingSoonModules =>
      'Los módulos te darán acceso rápido a limpieza, A y B y más.';

  @override
  String get comingSoonProfile =>
      'Aquí estarán tu perfil, ajustes y preferencias.';

  @override
  String get comingSoonCatalog =>
      'Pide servicio de habitaciones, spa y otros artículos de pago aquí.';

  @override
  String get comingSoonManual =>
      'Ticket libre para quejas o incidencias. Lo conectaremos a continuación.';

  @override
  String get comingSoonNotifications =>
      'Bandeja de notificaciones — próximamente';

  @override
  String get backToTickets => 'Volver a tickets';

  @override
  String get labelEta => 'ETA';

  @override
  String get labelGuestCheckoutTomorrow => 'Salida mañana';

  @override
  String get relativeJustNow => 'ahora mismo';

  @override
  String relativeSeconds(int seconds) {
    return 'hace $seconds s';
  }

  @override
  String relativeMinutes(int minutes) {
    return 'hace $minutes min';
  }

  @override
  String relativeHours(int hours) {
    return 'hace $hours h';
  }

  @override
  String relativeDays(int days) {
    return 'hace $days d';
  }

  @override
  String get languageTitle => 'Idioma';

  @override
  String get languageSubtitle => 'Elige el idioma que quieres usar en la app.';

  @override
  String get languageEnglish => 'Inglés';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageSystem => 'Idioma del dispositivo';

  @override
  String get languageChangedToast => 'Idioma actualizado';

  @override
  String get languageNativeEnglish => 'English';

  @override
  String get languageNativeSpanish => 'Español';

  @override
  String get tooltipToggleTheme => 'Cambiar tema';

  @override
  String get tooltipLanguage => 'Idioma';

  @override
  String get tooltipNotifications => 'Notificaciones';

  @override
  String get profileSectionPreferences => 'Preferencias';

  @override
  String get profileSectionAccountInformation => 'Información de la cuenta';

  @override
  String get profileSectionWorkInformation => 'Información laboral';

  @override
  String get profileFieldName => 'Nombre';

  @override
  String get profileFieldEmail => 'Correo';

  @override
  String get profileFieldEmployeeCode => 'Código de empleado';

  @override
  String get profileFieldRole => 'Rol';

  @override
  String get profileFieldPhone => 'Teléfono';

  @override
  String get profileFieldHotel => 'Propiedad';

  @override
  String get profileFieldDepartments => 'Departamentos';

  @override
  String get profileFieldStatus => 'Estado';

  @override
  String get profileFieldEmptyValue => '—';

  @override
  String get profileLanguageTitle => 'Idioma';

  @override
  String get profileLanguageSubtitle => 'Elige el idioma de la interfaz';

  @override
  String get profileThemeTitle => 'Apariencia';

  @override
  String get profileThemeSubtitle => 'Elige cómo se ve la app';

  @override
  String get profileThemeLight => 'Claro';

  @override
  String get profileThemeDark => 'Oscuro';

  @override
  String get profileThemeSystem => 'Sistema';

  @override
  String get profileStatusActive => 'Activo';

  @override
  String get profileStatusInactive => 'Inactivo';

  @override
  String get profileChangeAvatar => 'Cambiar foto de perfil';

  @override
  String get profileChangeAvatarComingSoon => 'Carga de foto — próximamente';

  @override
  String get profileLogout => 'Cerrar sesión';

  @override
  String get profileLogoutConfirmTitle => '¿Cerrar sesión?';

  @override
  String get profileLogoutConfirmBody =>
      'Tendrás que iniciar sesión de nuevo para acceder a tus tickets.';

  @override
  String get profileLogoutConfirmCancel => 'Cancelar';

  @override
  String get profileLogoutConfirmAction => 'Cerrar sesión';

  @override
  String get notifChannelName => 'Notificaciones importantes';

  @override
  String get notifChannelDescription =>
      'Se usa para notificaciones críticas de la app.';

  @override
  String get notifGenericTitle => 'Nexierge';

  @override
  String notifNewTicket(String ticketCode) {
    return 'Nuevo ticket: $ticketCode';
  }

  @override
  String get notificationsTitle => 'Notificaciones';

  @override
  String notificationsUnread(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sin leer',
      one: '1 sin leer',
      zero: 'Sin no leídas',
    );
    return '$_temp0';
  }

  @override
  String notificationsTotal(int count) {
    return '$count en total';
  }

  @override
  String get notificationsMarkAllRead => 'Marcar todo como leído';

  @override
  String get notificationsEmpty => 'Estás al día';

  @override
  String get notificationsEmptyHint => 'La nueva actividad aparecerá aquí.';

  @override
  String get notificationsItemNewTicket => 'Nuevo ticket recibido';

  @override
  String relativeMinutesAgo(int minutes) {
    return 'hace $minutes min';
  }

  @override
  String relativeHoursAgo(int hours) {
    return 'hace $hours h';
  }

  @override
  String relativeDaysAgo(int days) {
    return 'hace $days d';
  }

  @override
  String get ticketKindUniversal => 'Universal';

  @override
  String get ticketKindCatalog => 'Catálogo';

  @override
  String get ticketKindManual => 'Manual';

  @override
  String get filterNewestFirst => 'Más reciente primero';

  @override
  String get filterOldestFirst => 'Más antiguo primero';

  @override
  String get filterThisWeek => 'Esta semana';

  @override
  String get filterThisMonth => 'Este mes';

  @override
  String get profileAvatarSheetTitle => 'Cambiar foto de perfil';

  @override
  String get profileAvatarSheetSubtitle =>
      'Elige cómo quieres actualizar tu foto';

  @override
  String get profileAvatarSheetUploadTitle => 'Subir foto';

  @override
  String get profileAvatarSheetUploadSubtitle =>
      'Elige una imagen de tu dispositivo';

  @override
  String get profileAvatarSheetCameraTitle => 'Tomar foto';

  @override
  String get profileAvatarSheetCameraSubtitle => 'Usa tu cámara';

  @override
  String get profileUpdateAvatarSuccess => 'Foto de perfil actualizada';

  @override
  String get profileUpdateAvatarFailed =>
      'Error al actualizar la foto de perfil';

  @override
  String get profileEditNameTitle => 'Editar nombre';

  @override
  String get profileEditNameSave => 'Guardar';

  @override
  String get profileFirstName => 'Nombre';

  @override
  String get profileLastName => 'Apellido';

  @override
  String get profileUpdateNameSuccess => 'Nombre actualizado';

  @override
  String get profileUpdateNameFailed => 'Error al actualizar el nombre';

  @override
  String get createSearchHint => 'Buscar solicitudes...';

  @override
  String get createCustomButton => '+ Personalizado';

  @override
  String get createCatalogNavTitle => 'Catálogo';

  @override
  String get createManualNavTitle => 'Crear ticket';

  @override
  String get createCatalogSelectHeading => 'Seleccionar catálogo';

  @override
  String get createCatalogSelectSubheading =>
      'Elige de los catálogos de servicio del hotel';

  @override
  String createCatalogItemCount(int count) {
    return '$count artículos';
  }

  @override
  String get catalogRestaurantName => 'Restaurante del hotel';

  @override
  String get catalogRestaurantDesc =>
      'Cocina completa — desayuno, platos principales, bebidas';

  @override
  String get catalogRoomServiceName => 'Servicio de habitaciones';

  @override
  String get catalogRoomServiceDesc =>
      'Amenidades en habitación, esenciales nocturnos';

  @override
  String get createSummaryLabel => 'Resumen';

  @override
  String get createSummaryHint => 'Describe la solicitud...';

  @override
  String get createGuestOptionalLabel => 'Huésped (opcional)';

  @override
  String get createGuestHint => 'Nombre del huésped...';

  @override
  String get createDepartmentLabel => 'Departamento';

  @override
  String get createDepartmentHint => 'Seleccionar departamento...';

  @override
  String get createDepartmentSheetTitle => 'Seleccionar departamento';

  @override
  String get createSourceLabel => 'Origen';

  @override
  String get createSourceWhatsApp => 'WhatsApp';

  @override
  String get createSourcePhone => 'Teléfono';

  @override
  String get createSourceFrontDesk => 'Recepción';

  @override
  String get createSourceInPerson => 'En persona';

  @override
  String get createSourceInternal => 'Interno';

  @override
  String get createNotesOptionalLabel => 'Notas (opcional)';

  @override
  String get createNotesHint => 'Instrucciones especiales o contexto...';

  @override
  String get createTicketCta => 'Crear ticket';

  @override
  String get createRoomLabel => 'Habitación';

  @override
  String get itemExtraTowels => 'Toallas extra';

  @override
  String get itemExtraPillows => 'Almohadas extra';

  @override
  String get itemToiletriesKit => 'Kit de aseo';

  @override
  String get itemExtraBlanket => 'Manta extra';

  @override
  String get itemRoomCleaning => 'Limpieza de habitación';

  @override
  String get itemWaterBottles => 'Botellas de agua';

  @override
  String get itemIceBucket => 'Cubo de hielo';

  @override
  String get itemConciergeHelp => 'Ayuda de conserjería';

  @override
  String get itemClimateControl => 'Control de climatización';

  @override
  String get itemLightFixture => 'Lámpara o luminaria';

  @override
  String get itemPlumbingIssue => 'Problema de plomería';

  @override
  String get categoryHousekeeping => 'Limpieza';

  @override
  String get categoryFnb => 'A&B';

  @override
  String get categoryFrontDesk => 'Recepción';

  @override
  String get categoryMaintenance => 'Mantenimiento';

  @override
  String createSelectionBarSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count solicitudes seleccionadas',
      one: '1 solicitud seleccionada',
    );
    return '$_temp0';
  }

  @override
  String get createSelectionBarClearAll => 'Limpiar todo';

  @override
  String createContinueCta(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count artículos',
      one: '1 artículo',
    );
    return 'Continuar · $_temp0';
  }

  @override
  String get createTicketHeading => 'Crear ticket';

  @override
  String createSummaryCardTitle(int requests, int items) {
    String _temp0 = intl.Intl.pluralLogic(
      requests,
      locale: localeName,
      other: '$requests SOLICITUDES',
      one: '1 SOLICITUD',
    );
    String _temp1 = intl.Intl.pluralLogic(
      items,
      locale: localeName,
      other: '$items ARTÍCULOS',
      one: '1 ARTÍCULO',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get createSummaryEdit => 'Editar';

  @override
  String get createDepartmentAuto => 'AUTO';

  @override
  String get createTicketRoomRequiredHint =>
      'Selecciona una habitación para continuar';

  @override
  String catalogSearchHintNamed(String name) {
    return 'Buscar $name…';
  }

  @override
  String get catalogAvailableSection => 'DISPONIBLE';

  @override
  String get catalogPriceFree => 'Gratis';

  @override
  String catalogCartSubtitle(int items, String total) {
    String _temp0 = intl.Intl.pluralLogic(
      items,
      locale: localeName,
      other: '$items artículos',
      one: '1 artículo',
    );
    return '$_temp0 · $total';
  }

  @override
  String catalogPrice(String amount) {
    return '$amount';
  }

  @override
  String get catalogTagRequired => 'OBLIGATORIO';

  @override
  String get catalogTagOptional => 'OPCIONAL';

  @override
  String get catalogItemTotalLabel => 'Total del artículo';

  @override
  String get catalogAddToOrderCta => 'Agregar al pedido';

  @override
  String catalogPickRequiredHint(String groupName) {
    return 'Selecciona $groupName';
  }

  @override
  String catalogLineLabel(int index, String summary) {
    return '#$index · $summary';
  }

  @override
  String get confirmTicketTitle => 'Confirmar ticket';

  @override
  String get confirmTicketRowCatalog => 'CATÁLOGO';

  @override
  String get confirmTicketRowDepartment => 'DEPARTAMENTO';

  @override
  String get confirmTicketRowRoom => 'HABITACIÓN';

  @override
  String get confirmTicketRowGuest => 'HUÉSPED';

  @override
  String get confirmTicketRowSource => 'ORIGEN';

  @override
  String get confirmTicketRowTotal => 'TOTAL';

  @override
  String get confirmTicketRowNotes => 'NOTAS';

  @override
  String confirmTicketItemsHeading(int count) {
    return 'ARTÍCULOS ($count)';
  }

  @override
  String get confirmTicketCta => 'Confirmar';
}
