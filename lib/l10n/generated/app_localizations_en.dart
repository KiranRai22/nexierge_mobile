// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Nexierge';

  @override
  String get appTagline => 'Your tagline here';

  @override
  String get login => 'Login';

  @override
  String get logout => 'Logout';

  @override
  String get register => 'Register';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get loginWelcomeTitle => 'Welcome to Nexierge';

  @override
  String get loginWelcomeSubtitle =>
      'Sign in to continue managing your hotel operations.';

  @override
  String get loginTabEmail => 'Email';

  @override
  String get loginTabEmployeeCode => 'Employee Code';

  @override
  String get loginEmailLabel => 'Work email';

  @override
  String get loginPasswordLabel => 'Password';

  @override
  String get loginEmployeeCodeLabel => 'Employee Code';

  @override
  String get loginCodeLabel => 'Login Code';

  @override
  String get loginAccessButton => 'Sign in';

  @override
  String get loginEmailHint => 'you@yourhotel.com';

  @override
  String get loginEmployeeCodeHint => 'e.g. EMP-001';

  @override
  String get loginCodeHint => 'Enter your login code';

  @override
  String get loginAdminContactFooter =>
      'If you don\'t remember your access codes or password, contact the admin of your hotel.';

  @override
  String get loginAppVersion => 'v1.0.0';

  @override
  String get loginEmployeeHelper =>
      'Use the credentials provided by your hotel administrator.';

  @override
  String get loginErrorInvalidEmail => 'Invalid email or password.';

  @override
  String get loginErrorInvalidCode => 'Invalid employee code or login code.';

  @override
  String get loginErrorCodeExpired => 'Code expired. Please request a new one.';

  @override
  String get loginErrorPendingReviewTitle => 'Access pending review';

  @override
  String get loginErrorPendingReviewBody =>
      'Your access request is still under review.';

  @override
  String get loginErrorRejectedTitle => 'Access not approved';

  @override
  String get loginErrorRejectedBody =>
      'Your access request was not approved. Please contact support.';

  @override
  String get loginErrorDisabledTitle => 'Account disabled';

  @override
  String get loginErrorDisabledBody =>
      'Your account is currently disabled. Please contact your administrator.';

  @override
  String get loginErrorInactiveHotelTitle => 'Hotel inactive';

  @override
  String get loginErrorInactiveHotelBody =>
      'This hotel account is not currently active.';

  @override
  String get loginErrorGeneric => 'Something went wrong. Please try again.';

  @override
  String get loginErrorSignInFailed =>
      'We couldn\'t sign you in right now. Please try again.';

  @override
  String get networkError =>
      'No internet connection. Please check your network and try again.';

  @override
  String get timeoutError => 'Request timed out. Please try again.';

  @override
  String get unauthorizedError =>
      'Your session has expired. Please login again.';

  @override
  String get forbiddenError =>
      'You don\'t have permission to perform this action.';

  @override
  String get notFoundError => 'The requested resource was not found.';

  @override
  String get serverError =>
      'Something went wrong on our end. Please try again later.';

  @override
  String get unknownError => 'An unexpected error occurred. Please try again.';

  @override
  String get validationError => 'Please check your input and try again.';

  @override
  String get successSaved => 'Saved successfully.';

  @override
  String get successUpdated => 'Updated successfully.';

  @override
  String get successDeleted => 'Deleted successfully.';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get done => 'Done';

  @override
  String get retry => 'Retry';

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String get submit => 'Submit';

  @override
  String get search => 'Search';

  @override
  String get loading => 'Loading...';

  @override
  String get emptyState => 'Nothing here yet.';

  @override
  String get emptySearch => 'No results found.';

  @override
  String get requiredField => 'This field is required.';

  @override
  String get invalidEmail => 'Please enter a valid email address.';

  @override
  String get passwordTooShort => 'Password must be at least 8 characters.';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match.';

  @override
  String get scopeMyDept => 'My Dept';

  @override
  String get scopeAllHotel => 'All Hotel';

  @override
  String greeting(String name) {
    return 'Hi, $name';
  }

  @override
  String get ticketsSearchHint => 'Search ticket, room or guest…';

  @override
  String get kpiIncoming => 'INCOMING';

  @override
  String get kpiInProgress => 'IN PROGRESS';

  @override
  String get kpiOverdue => 'OVERDUE';

  @override
  String get subTabIncoming => 'Incoming';

  @override
  String get subTabToday => 'Today';

  @override
  String get subTabScheduled => 'Scheduled';

  @override
  String get subTabDone => 'Done';

  @override
  String get sectionIncomingNow => 'INCOMING NOW';

  @override
  String get sectionInProgress => 'IN PROGRESS';

  @override
  String get sectionCompletedToday => 'COMPLETED TODAY';

  @override
  String get sectionScheduled => 'SCHEDULED';

  @override
  String get chipUniversal => 'Universal';

  @override
  String get chipCatalog => 'Catalog';

  @override
  String get chipManual => 'Manual';

  @override
  String get statusNew => 'New';

  @override
  String get statusUnassigned => 'Unassigned';

  @override
  String get statusAccepted => 'Accepted';

  @override
  String get statusInProgress => 'In progress';

  @override
  String get statusDone => 'Done';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get statusOverdue => 'Overdue';

  @override
  String get detailRoomLabel => 'ROOM';

  @override
  String get detailGuestLabel => 'GUEST';

  @override
  String get detailRequestLabel => 'REQUEST';

  @override
  String get detailGuestNoteLabel => 'GUEST NOTE';

  @override
  String get detailTimingLabel => 'TIMING';

  @override
  String get detailCreated => 'Created';

  @override
  String get detailAccepted => 'Accepted';

  @override
  String get detailDone => 'Done';

  @override
  String get detailEmpty => '—';

  @override
  String get actionAccept => 'Accept & set ETA';

  @override
  String get actionChangeDept => 'Change dept';

  @override
  String get actionAddNote => 'Add note';

  @override
  String get actionStart => 'Start';

  @override
  String get actionMarkDone => 'Mark done';

  @override
  String get actionUndo => 'UNDO';

  @override
  String get etaTitle => 'When will this be done?';

  @override
  String etaSubtitle(String ticketCode) {
    return 'Accepting $ticketCode';
  }

  @override
  String get eta10 => '10 minutes';

  @override
  String get eta15 => '15 minutes';

  @override
  String get eta30 => '30 minutes';

  @override
  String get eta60 => '1 hour';

  @override
  String get etaLater => 'Later today';

  @override
  String get etaCustom => 'Custom time';

  @override
  String get etaGuestNotified => 'Guest will be notified';

  @override
  String etaReadyBy(String time) {
    return 'Ready by $time';
  }

  @override
  String etaConfirmMinutes(int minutes) {
    return 'Accept · $minutes min';
  }

  @override
  String etaConfirmHours(int hours) {
    return 'Accept · ${hours}h';
  }

  @override
  String get etaShortNow => 'Now';

  @override
  String etaShortMinutes(int minutes) {
    return 'ETA ${minutes}m';
  }

  @override
  String etaShortHours(int hours) {
    return 'ETA ${hours}h';
  }

  @override
  String get activityTypeAll => 'All';

  @override
  String get activityTypeCreated => 'Created';

  @override
  String get activityTypeAccepted => 'Accepted';

  @override
  String get activityTypeDone => 'Done';

  @override
  String get activityTypeOverdue => 'Overdue';

  @override
  String get activityTypeCancelled => 'Cancelled';

  @override
  String get activityTypeNotes => 'Notes';

  @override
  String get activityTypeReassigned => 'Reassigned';

  @override
  String get dayToday => 'TODAY';

  @override
  String get dayYesterday => 'YESTERDAY';

  @override
  String get dayOlder => 'OLDER';

  @override
  String get activityCreatedTitle => 'Ticket created';

  @override
  String activityAcceptedTitle(String actor) {
    return '$actor accepted the ticket';
  }

  @override
  String activityDoneTitle(String actor) {
    return '$actor marked this done';
  }

  @override
  String get activityOverdueTitle => 'Ticket is overdue';

  @override
  String activityCancelledTitle(String actor) {
    return '$actor cancelled this ticket';
  }

  @override
  String activityNoteTitle(String actor) {
    return '$actor added a note';
  }

  @override
  String activityReassignedTitle(String actor, String target) {
    return '$actor reassigned to $target';
  }

  @override
  String get createNewTitle => 'Create new';

  @override
  String get createNewSubtitle => 'What kind of ticket are you creating?';

  @override
  String get createUniversalTitle => 'Universal request';

  @override
  String get createUniversalDesc =>
      'Towels, pillows, toiletries — quick operational asks';

  @override
  String get createCatalogTitle => 'Catalog';

  @override
  String get createCatalogDesc =>
      'Room service, spa, bar — anything a guest is paying for';

  @override
  String get createManualTitle => 'Manual ticket';

  @override
  String get createManualDesc =>
      'Complaints, issues, anything that doesn\'t fit above';

  @override
  String get createHint => 'Not sure? Manual works for anything.';

  @override
  String get universalHeading => 'Universal request';

  @override
  String get universalSubheading => 'Tap what you need';

  @override
  String get itemTowels => 'Towels';

  @override
  String get itemPillows => 'Pillows';

  @override
  String get itemToiletries => 'Toiletries';

  @override
  String get itemBlanket => 'Blanket';

  @override
  String get itemWater => 'Water';

  @override
  String get itemOther => 'Other';

  @override
  String get roomLabel => 'ROOM';

  @override
  String get roomFind => 'Find';

  @override
  String get roomRecentHelper => 'Recent rooms · tap to select';

  @override
  String get noteLabel => 'NOTE (OPTIONAL)';

  @override
  String get noteHint => 'Add a note for the team…';

  @override
  String get pickItemHint => 'Pick an item to start';

  @override
  String get pickRoomHint => 'Pick a room to continue';

  @override
  String get createCta => 'Create';

  @override
  String get createSuccessToast => 'Ticket created';

  @override
  String get tapToAdd => 'Tap to add';

  @override
  String itemsSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items selected',
      one: '1 item selected',
    );
    return '$_temp0';
  }

  @override
  String get roomPickerTitle => 'Select room';

  @override
  String get roomPickerRecent => 'Recent';

  @override
  String get roomPickerAll => 'All rooms';

  @override
  String roomFloor(int floor) {
    return 'Floor $floor';
  }

  @override
  String roomNumber(String number) {
    return 'Room $number';
  }

  @override
  String get roomSearchHint => 'Search room number…';

  @override
  String get filterTitle => 'Filter by department';

  @override
  String get filterSubtitleAll => 'Showing all departments';

  @override
  String filterSubtitleSome(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Showing $count departments',
      one: 'Showing 1 department',
    );
    return '$_temp0';
  }

  @override
  String get filterSelectAll => 'Select all';

  @override
  String get filterClear => 'Clear';

  @override
  String get filterApply => 'Apply';

  @override
  String get deptConcierge => 'Concierge';

  @override
  String get deptFnb => 'F&B';

  @override
  String get deptFrontDesk => 'Front Desk';

  @override
  String get deptHousekeeping => 'Housekeeping';

  @override
  String get deptMaintenance => 'Maintenance';

  @override
  String get deptRoomService => 'Room Service';

  @override
  String dashboardGreetingMorning(String name) {
    return 'Good morning, $name';
  }

  @override
  String dashboardGreetingAfternoon(String name) {
    return 'Good afternoon, $name';
  }

  @override
  String dashboardGreetingEvening(String name) {
    return 'Good evening, $name';
  }

  @override
  String get dashboardIncomingNow => 'Incoming Now';

  @override
  String get dashboardInProgressLabel => 'In Progress';

  @override
  String get dashboardOverdueLabel => 'Overdue';

  @override
  String get dashboardNeedsAttention => 'Needs attention';

  @override
  String get dashboardViewAll => 'View all';

  @override
  String get dashboardAllCaughtUp => 'All caught up';

  @override
  String dashboardAllCaughtUpDept(String dept) {
    return 'Nothing urgent in $dept right now.';
  }

  @override
  String get dashboardAllCaughtUpGeneric =>
      'No overdue or urgent items right now.';

  @override
  String dashboardBreakdownUniversal(int n) {
    return '$n universal';
  }

  @override
  String dashboardBreakdownCatalog(int n) {
    return '$n catalog';
  }

  @override
  String dashboardBreakdownManual(int n) {
    return '$n manual';
  }

  @override
  String dashboardWaitPill(int minutes) {
    return '${minutes}m';
  }

  @override
  String dashboardEtaPill(int minutes) {
    return 'ETA ${minutes}m';
  }

  @override
  String dashboardRoomPrefix(String number) {
    return 'Room $number';
  }

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navTickets => 'Tickets';

  @override
  String get navActivity => 'Activity';

  @override
  String get navCreate => 'Create';

  @override
  String get navModules => 'Modules';

  @override
  String get navProfile => 'Profile';

  @override
  String get comingSoonTitle => 'Coming soon';

  @override
  String get comingSoonModules =>
      'Modules will give you quick access to housekeeping, F&B and more.';

  @override
  String get comingSoonProfile =>
      'Your profile, settings and preferences will live here.';

  @override
  String get comingSoonCatalog =>
      'Order room service, spa, and other paid items here.';

  @override
  String get comingSoonManual =>
      'Free-form complaint or issue ticket. We\'ll wire this up next.';

  @override
  String get comingSoonNotifications => 'Notifications inbox — coming soon';

  @override
  String get backToTickets => 'Back to tickets';

  @override
  String get labelEta => 'ETA';

  @override
  String get labelGuestCheckoutTomorrow => 'Check-out tomorrow';

  @override
  String get relativeJustNow => 'Just now';

  @override
  String relativeSeconds(int seconds) {
    return '${seconds}s ago';
  }

  @override
  String relativeMinutes(int minutes) {
    return '${minutes}m ago';
  }

  @override
  String relativeHours(int hours) {
    return '${hours}h ago';
  }

  @override
  String relativeDays(int days) {
    return '${days}d ago';
  }

  @override
  String get languageTitle => 'Language';

  @override
  String get languageSubtitle =>
      'Pick the language you\'d like the app to use.';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageSystem => 'Match device language';

  @override
  String get languageChangedToast => 'Language updated';

  @override
  String get languageNativeEnglish => 'English';

  @override
  String get languageNativeSpanish => 'Español';

  @override
  String get tooltipToggleTheme => 'Toggle theme';

  @override
  String get tooltipLanguage => 'Language';

  @override
  String get tooltipNotifications => 'Notifications';

  @override
  String get profileSectionPreferences => 'Preferences';

  @override
  String get notifChannelName => 'High importance notifications';

  @override
  String get notifChannelDescription => 'Used for critical app notifications.';

  @override
  String get notifGenericTitle => 'Nexierge';

  @override
  String notifNewTicket(String ticketCode) {
    return 'New ticket: $ticketCode';
  }
}
