abstract class StringManager {
  // App
  static const String appName = 'Nexierge';
  static const String appTagline = 'Your tagline here';

  // Auth
  static const String login = 'Login';
  static const String logout = 'Logout';
  static const String register = 'Register';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm Password';
  static const String forgotPassword = 'Forgot Password?';
  static const String resetPassword = 'Reset Password';

  // Login screen
  static const String loginWelcomeTitle = 'Welcome to Nexierge';
  static const String loginWelcomeSubtitle =
      'Sign in to continue managing your hotel operations.';
  static const String loginTabEmail = 'Email';
  static const String loginTabEmployeeCode = 'Employee Code';
  static const String loginEmailLabel = 'Work email';
  static const String loginPasswordLabel = 'Password';
  static const String loginEmployeeCodeLabel = 'Employee Code';
  static const String loginCodeLabel = 'Login Code';
  static const String loginAccessButton = 'Sign in';
  static const String loginEmailHint = 'you@yourhotel.com';
  static const String loginEmployeeCodeHint = 'e.g. EMP-001';
  static const String loginCodeHint = 'Enter your login code';
  static const String loginAdminContactFooter =
      "If you don't remember your access codes or password, "
      'contact the admin of your hotel.';
  static const String loginAppVersion = 'v1.0.0';

  // Errors
  static const String networkError =
      'No internet connection. Please check your network and try again.';
  static const String timeoutError = 'Request timed out. Please try again.';
  static const String unauthorizedError =
      'Your session has expired. Please login again.';
  static const String forbiddenError =
      "You don't have permission to perform this action.";
  static const String notFoundError =
      'The requested resource was not found.';
  static const String serverError =
      'Something went wrong on our end. Please try again later.';
  static const String unknownError =
      'An unexpected error occurred. Please try again.';
  static const String validationError =
      'Please check your input and try again.';

  // Success
  static const String successSaved = 'Saved successfully.';
  static const String successUpdated = 'Updated successfully.';
  static const String successDeleted = 'Deleted successfully.';

  // Common labels
  static const String save = 'Save';
  static const String cancel = 'Cancel';
  static const String confirm = 'Confirm';
  static const String delete = 'Delete';
  static const String edit = 'Edit';
  static const String done = 'Done';
  static const String retry = 'Retry';
  static const String back = 'Back';
  static const String next = 'Next';
  static const String submit = 'Submit';
  static const String search = 'Search';
  static const String loading = 'Loading...';

  // Empty states
  static const String emptyState = 'Nothing here yet.';
  static const String emptySearch = 'No results found.';

  // Validation
  static const String requiredField = 'This field is required.';
  static const String invalidEmail = 'Please enter a valid email address.';
  static const String passwordTooShort =
      'Password must be at least 8 characters.';
  static const String passwordsDoNotMatch = 'Passwords do not match.';

  // ---------------------------------------------------------------------------
  // HotelOps strings
  // ---------------------------------------------------------------------------

  // Top bar / scope tabs
  static const String scopeMyDept = 'My Dept';
  static const String scopeAllHotel = 'All Hotel';
  static const String greetingPrefix = 'Hi, ';

  // Tickets dashboard
  static const String ticketsSearchHint = 'Search ticket, room or guest…';
  static const String kpiIncoming = 'INCOMING';
  static const String kpiInProgress = 'IN PROGRESS';
  static const String kpiOverdue = 'OVERDUE';

  static const String subTabIncoming = 'Incoming';
  static const String subTabToday = 'Today';
  static const String subTabScheduled = 'Scheduled';
  static const String subTabDone = 'Done';

  static const String sectionIncomingNow = 'INCOMING NOW';
  static const String sectionInProgress = 'IN PROGRESS';
  static const String sectionCompletedToday = 'COMPLETED TODAY';
  static const String sectionScheduled = 'SCHEDULED';

  // Ticket card / detail
  static const String chipUniversal = 'Universal';
  static const String chipCatalog = 'Catalog';
  static const String chipManual = 'Manual';
  static const String statusNew = 'New';
  static const String statusUnassigned = 'Unassigned';
  static const String statusAccepted = 'Accepted';
  static const String statusInProgress = 'In progress';
  static const String statusDone = 'Done';
  static const String statusCancelled = 'Cancelled';

  static const String detailRoomLabel = 'ROOM';
  static const String detailGuestLabel = 'GUEST';
  static const String detailRequestLabel = 'REQUEST';
  static const String detailGuestNoteLabel = 'GUEST NOTE';
  static const String detailTimingLabel = 'TIMING';
  static const String detailCreated = 'Created';
  static const String detailAccepted = 'Accepted';
  static const String detailDone = 'Done';
  static const String detailEmpty = '—';

  static const String actionAccept = 'Accept & set ETA';
  static const String actionChangeDept = 'Change dept';
  static const String actionAddNote = 'Add note';
  static const String actionStart = 'Start';
  static const String actionMarkDone = 'Mark done';
  static const String actionUndo = 'UNDO';

  // ETA bottom sheet
  static const String etaTitle = 'When will this be done?';
  static const String etaSubtitlePrefix = 'Accepting ';
  static const String eta10 = '10 minutes';
  static const String eta15 = '15 minutes';
  static const String eta30 = '30 minutes';
  static const String eta60 = '1 hour';
  static const String etaLater = 'Later today';
  static const String etaCustom = 'Custom time';
  static const String etaGuestNotified = 'Guest will be notified';
  static const String etaReadyByPrefix = 'Ready by ';
  static const String etaConfirmPrefix = 'Accept · ';

  // Activity feed
  static const String activityTypeAll = 'All';
  static const String activityTypeCreated = 'Created';
  static const String activityTypeAccepted = 'Accepted';
  static const String activityTypeDone = 'Done';
  static const String activityTypeOverdue = 'Overdue';
  static const String activityTypeCancelled = 'Cancelled';
  static const String activityTypeNotes = 'Notes';
  static const String activityTypeReassigned = 'Reassigned';

  static const String dayToday = 'TODAY';
  static const String dayYesterday = 'YESTERDAY';
  static const String dayOlder = 'OLDER';

  static const String activityCreatedTitle = 'Ticket created';
  static const String activityAcceptedTitle = 'accepted the ticket';
  static const String activityDoneTitle = 'marked this done';
  static const String activityOverdueTitle = 'Ticket is overdue';
  static const String activityCancelledTitle = 'cancelled this ticket';
  static const String activityNoteTitle = 'added a note';
  static const String activityReassignedTitle = 'reassigned to ';

  // Create-new sheet
  static const String createNewTitle = 'Create new';
  static const String createNewSubtitle = 'What kind of ticket are you creating?';
  static const String createUniversalTitle = 'Universal request';
  static const String createUniversalDesc =
      'Towels, pillows, toiletries — quick operational asks';
  static const String createCatalogTitle = 'Catalog';
  static const String createCatalogDesc =
      'Room service, spa, bar — anything a guest is paying for';
  static const String createManualTitle = 'Manual ticket';
  static const String createManualDesc =
      "Complaints, issues, anything that doesn't fit above";
  static const String createHint = 'Not sure? Manual works for anything.';

  // Universal create
  static const String universalHeading = 'Universal request';
  static const String universalSubheading = 'Tap what you need';
  static const String itemTowels = 'Towels';
  static const String itemPillows = 'Pillows';
  static const String itemToiletries = 'Toiletries';
  static const String itemBlanket = 'Blanket';
  static const String itemWater = 'Water';
  static const String itemOther = 'Other';
  static const String roomLabel = 'ROOM';
  static const String roomFind = 'Find';
  static const String roomRecentHelper = 'Recent rooms · tap to select';
  static const String noteLabel = 'NOTE (OPTIONAL)';
  static const String noteHint = 'Add a note for the team…';
  static const String pickItemHint = 'Pick an item to start';
  static const String pickRoomHint = 'Pick a room to continue';
  static const String createCta = 'Create';
  static const String createSuccessToast = 'Ticket created';

  // Room picker
  static const String roomPickerTitle = 'Select room';
  static const String roomPickerRecent = 'Recent';
  static const String roomPickerAll = 'All rooms';
  static const String roomFloorPrefix = 'Floor ';

  // Filter sheet
  static const String filterTitle = 'Filter by department';
  static const String filterSubtitleAll = 'Showing all departments';
  static const String filterSubtitleSomePrefix = 'Showing ';
  static const String filterSubtitleSomeSuffix = ' department(s)';
  static const String filterSelectAll = 'Select all';
  static const String filterClear = 'Clear';
  static const String filterApply = 'Apply';

  // Departments
  static const String deptConcierge = 'Concierge';
  static const String deptFnb = 'F&B';
  static const String deptFrontDesk = 'Front Desk';
  static const String deptHousekeeping = 'Housekeeping';
  static const String deptMaintenance = 'Maintenance';
  static const String deptRoomService = 'Room Service';

  // Bottom nav
  static const String navTickets = 'Tickets';
  static const String navActivity = 'Activity';
  static const String navModules = 'Modules';
  static const String navProfile = 'Profile';

  // Placeholder screens
  static const String comingSoonTitle = 'Coming soon';
  static const String comingSoonModules =
      "Modules will give you quick access to housekeeping, F&B and more.";
  static const String comingSoonProfile =
      'Your profile, settings and preferences will live here.';
  static const String comingSoonCatalog =
      'Order room service, spa, and other paid items here.';
  static const String comingSoonManual =
      "Free-form complaint or issue ticket. We'll wire this up next.";
  static const String backToTickets = 'Back to tickets';

  // Misc / common labels for ops
  static const String labelEta = 'ETA';
  static const String labelEtaIn = 'ETA in ';
  static const String labelXItems = ' items';
  static const String labelOneItem = '1 item';
  static const String labelGuestCheckoutTomorrow = 'Check-out tomorrow';
}
