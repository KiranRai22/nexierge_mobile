import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Nexierge'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Your tagline here'**
  String get appTagline;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @loginWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Nexierge'**
  String get loginWelcomeTitle;

  /// No description provided for @loginWelcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue managing your hotel operations.'**
  String get loginWelcomeSubtitle;

  /// No description provided for @loginTabEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get loginTabEmail;

  /// No description provided for @loginTabEmployeeCode.
  ///
  /// In en, this message translates to:
  /// **'Employee Code'**
  String get loginTabEmployeeCode;

  /// No description provided for @loginEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Work email'**
  String get loginEmailLabel;

  /// No description provided for @loginPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginPasswordLabel;

  /// No description provided for @loginEmployeeCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Employee Code'**
  String get loginEmployeeCodeLabel;

  /// No description provided for @loginCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Login Code'**
  String get loginCodeLabel;

  /// No description provided for @loginAccessButton.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginAccessButton;

  /// No description provided for @loginEmailHint.
  ///
  /// In en, this message translates to:
  /// **'you@yourhotel.com'**
  String get loginEmailHint;

  /// No description provided for @loginEmployeeCodeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. EMP-001'**
  String get loginEmployeeCodeHint;

  /// No description provided for @loginCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your login code'**
  String get loginCodeHint;

  /// No description provided for @loginAdminContactFooter.
  ///
  /// In en, this message translates to:
  /// **'If you don\'t remember your access codes or password, contact the admin of your hotel.'**
  String get loginAdminContactFooter;

  /// No description provided for @loginAppVersion.
  ///
  /// In en, this message translates to:
  /// **'v1.0.0'**
  String get loginAppVersion;

  /// No description provided for @loginEmployeeHelper.
  ///
  /// In en, this message translates to:
  /// **'Use the credentials provided by your hotel administrator.'**
  String get loginEmployeeHelper;

  /// No description provided for @loginErrorInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password.'**
  String get loginErrorInvalidEmail;

  /// No description provided for @loginErrorInvalidCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid employee code or login code.'**
  String get loginErrorInvalidCode;

  /// No description provided for @loginErrorCodeExpired.
  ///
  /// In en, this message translates to:
  /// **'Code expired. Please request a new one.'**
  String get loginErrorCodeExpired;

  /// No description provided for @loginErrorPendingReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Access pending review'**
  String get loginErrorPendingReviewTitle;

  /// No description provided for @loginErrorPendingReviewBody.
  ///
  /// In en, this message translates to:
  /// **'Your access request is still under review.'**
  String get loginErrorPendingReviewBody;

  /// No description provided for @loginErrorRejectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Access not approved'**
  String get loginErrorRejectedTitle;

  /// No description provided for @loginErrorRejectedBody.
  ///
  /// In en, this message translates to:
  /// **'Your access request was not approved. Please contact support.'**
  String get loginErrorRejectedBody;

  /// No description provided for @loginErrorDisabledTitle.
  ///
  /// In en, this message translates to:
  /// **'Account disabled'**
  String get loginErrorDisabledTitle;

  /// No description provided for @loginErrorDisabledBody.
  ///
  /// In en, this message translates to:
  /// **'Your account is currently disabled. Please contact your administrator.'**
  String get loginErrorDisabledBody;

  /// No description provided for @loginErrorInactiveHotelTitle.
  ///
  /// In en, this message translates to:
  /// **'Hotel inactive'**
  String get loginErrorInactiveHotelTitle;

  /// No description provided for @loginErrorInactiveHotelBody.
  ///
  /// In en, this message translates to:
  /// **'This hotel account is not currently active.'**
  String get loginErrorInactiveHotelBody;

  /// No description provided for @loginErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get loginErrorGeneric;

  /// No description provided for @loginErrorSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t sign you in right now. Please try again.'**
  String get loginErrorSignInFailed;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Please check your network and try again.'**
  String get networkError;

  /// No description provided for @timeoutError.
  ///
  /// In en, this message translates to:
  /// **'Request timed out. Please try again.'**
  String get timeoutError;

  /// No description provided for @unauthorizedError.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please login again.'**
  String get unauthorizedError;

  /// No description provided for @forbiddenError.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to perform this action.'**
  String get forbiddenError;

  /// No description provided for @notFoundError.
  ///
  /// In en, this message translates to:
  /// **'The requested resource was not found.'**
  String get notFoundError;

  /// No description provided for @serverError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong on our end. Please try again later.'**
  String get serverError;

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred. Please try again.'**
  String get unknownError;

  /// No description provided for @validationError.
  ///
  /// In en, this message translates to:
  /// **'Please check your input and try again.'**
  String get validationError;

  /// No description provided for @successSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved successfully.'**
  String get successSaved;

  /// No description provided for @successUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated successfully.'**
  String get successUpdated;

  /// No description provided for @successDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted successfully.'**
  String get successDeleted;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @emptyState.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet.'**
  String get emptyState;

  /// No description provided for @emptySearch.
  ///
  /// In en, this message translates to:
  /// **'No results found.'**
  String get emptySearch;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'This field is required.'**
  String get requiredField;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address.'**
  String get invalidEmail;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters.'**
  String get passwordTooShort;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get passwordsDoNotMatch;

  /// No description provided for @scopeMyDept.
  ///
  /// In en, this message translates to:
  /// **'My Dept'**
  String get scopeMyDept;

  /// No description provided for @scopeAllHotel.
  ///
  /// In en, this message translates to:
  /// **'All Hotel'**
  String get scopeAllHotel;

  /// No description provided for @greeting.
  ///
  /// In en, this message translates to:
  /// **'Hi, {name}'**
  String greeting(String name);

  /// No description provided for @ticketsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search ticket, room or guest…'**
  String get ticketsSearchHint;

  /// No description provided for @kpiIncoming.
  ///
  /// In en, this message translates to:
  /// **'INCOMING'**
  String get kpiIncoming;

  /// No description provided for @kpiInProgress.
  ///
  /// In en, this message translates to:
  /// **'IN PROGRESS'**
  String get kpiInProgress;

  /// No description provided for @kpiOverdue.
  ///
  /// In en, this message translates to:
  /// **'OVERDUE'**
  String get kpiOverdue;

  /// No description provided for @subTabIncoming.
  ///
  /// In en, this message translates to:
  /// **'Incoming'**
  String get subTabIncoming;

  /// No description provided for @subTabToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get subTabToday;

  /// No description provided for @subTabScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get subTabScheduled;

  /// No description provided for @subTabDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get subTabDone;

  /// No description provided for @sectionIncomingNow.
  ///
  /// In en, this message translates to:
  /// **'INCOMING NOW'**
  String get sectionIncomingNow;

  /// No description provided for @sectionInProgress.
  ///
  /// In en, this message translates to:
  /// **'IN PROGRESS'**
  String get sectionInProgress;

  /// No description provided for @sectionCompletedToday.
  ///
  /// In en, this message translates to:
  /// **'COMPLETED TODAY'**
  String get sectionCompletedToday;

  /// No description provided for @sectionScheduled.
  ///
  /// In en, this message translates to:
  /// **'SCHEDULED'**
  String get sectionScheduled;

  /// No description provided for @chipUniversal.
  ///
  /// In en, this message translates to:
  /// **'Universal'**
  String get chipUniversal;

  /// No description provided for @chipCatalog.
  ///
  /// In en, this message translates to:
  /// **'Catalog'**
  String get chipCatalog;

  /// No description provided for @chipManual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get chipManual;

  /// No description provided for @statusNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get statusNew;

  /// No description provided for @statusUnassigned.
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get statusUnassigned;

  /// No description provided for @statusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get statusAccepted;

  /// No description provided for @statusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get statusInProgress;

  /// No description provided for @statusDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get statusDone;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @statusOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get statusOverdue;

  /// No description provided for @detailRoomLabel.
  ///
  /// In en, this message translates to:
  /// **'ROOM'**
  String get detailRoomLabel;

  /// No description provided for @detailGuestLabel.
  ///
  /// In en, this message translates to:
  /// **'GUEST'**
  String get detailGuestLabel;

  /// No description provided for @detailRequestLabel.
  ///
  /// In en, this message translates to:
  /// **'REQUEST'**
  String get detailRequestLabel;

  /// No description provided for @detailGuestNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'GUEST NOTE'**
  String get detailGuestNoteLabel;

  /// No description provided for @detailTimingLabel.
  ///
  /// In en, this message translates to:
  /// **'TIMING'**
  String get detailTimingLabel;

  /// No description provided for @detailCreated.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get detailCreated;

  /// No description provided for @detailAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get detailAccepted;

  /// No description provided for @detailDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get detailDone;

  /// No description provided for @detailEmpty.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get detailEmpty;

  /// No description provided for @actionAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept & set ETA'**
  String get actionAccept;

  /// No description provided for @actionChangeDept.
  ///
  /// In en, this message translates to:
  /// **'Change dept'**
  String get actionChangeDept;

  /// No description provided for @actionAddNote.
  ///
  /// In en, this message translates to:
  /// **'Add note'**
  String get actionAddNote;

  /// No description provided for @actionStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get actionStart;

  /// No description provided for @actionMarkDone.
  ///
  /// In en, this message translates to:
  /// **'Mark done'**
  String get actionMarkDone;

  /// No description provided for @actionUndo.
  ///
  /// In en, this message translates to:
  /// **'UNDO'**
  String get actionUndo;

  /// No description provided for @etaTitle.
  ///
  /// In en, this message translates to:
  /// **'When will this be done?'**
  String get etaTitle;

  /// No description provided for @etaSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Accepting {ticketCode}'**
  String etaSubtitle(String ticketCode);

  /// No description provided for @eta10.
  ///
  /// In en, this message translates to:
  /// **'10 minutes'**
  String get eta10;

  /// No description provided for @eta15.
  ///
  /// In en, this message translates to:
  /// **'15 minutes'**
  String get eta15;

  /// No description provided for @eta30.
  ///
  /// In en, this message translates to:
  /// **'30 minutes'**
  String get eta30;

  /// No description provided for @eta60.
  ///
  /// In en, this message translates to:
  /// **'1 hour'**
  String get eta60;

  /// No description provided for @etaLater.
  ///
  /// In en, this message translates to:
  /// **'Later today'**
  String get etaLater;

  /// No description provided for @etaCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom time'**
  String get etaCustom;

  /// No description provided for @etaGuestNotified.
  ///
  /// In en, this message translates to:
  /// **'Guest will be notified'**
  String get etaGuestNotified;

  /// No description provided for @etaReadyBy.
  ///
  /// In en, this message translates to:
  /// **'Ready by {time}'**
  String etaReadyBy(String time);

  /// No description provided for @etaConfirmMinutes.
  ///
  /// In en, this message translates to:
  /// **'Accept · {minutes} min'**
  String etaConfirmMinutes(int minutes);

  /// No description provided for @etaConfirmHours.
  ///
  /// In en, this message translates to:
  /// **'Accept · {hours}h'**
  String etaConfirmHours(int hours);

  /// No description provided for @etaShortNow.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get etaShortNow;

  /// No description provided for @etaShortMinutes.
  ///
  /// In en, this message translates to:
  /// **'ETA {minutes}m'**
  String etaShortMinutes(int minutes);

  /// No description provided for @etaShortHours.
  ///
  /// In en, this message translates to:
  /// **'ETA {hours}h'**
  String etaShortHours(int hours);

  /// No description provided for @activityTypeAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get activityTypeAll;

  /// No description provided for @activityTypeCreated.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get activityTypeCreated;

  /// No description provided for @activityTypeAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get activityTypeAccepted;

  /// No description provided for @activityTypeDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get activityTypeDone;

  /// No description provided for @activityTypeOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get activityTypeOverdue;

  /// No description provided for @activityTypeCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get activityTypeCancelled;

  /// No description provided for @activityTypeNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get activityTypeNotes;

  /// No description provided for @activityTypeReassigned.
  ///
  /// In en, this message translates to:
  /// **'Reassigned'**
  String get activityTypeReassigned;

  /// No description provided for @dayToday.
  ///
  /// In en, this message translates to:
  /// **'TODAY'**
  String get dayToday;

  /// No description provided for @dayYesterday.
  ///
  /// In en, this message translates to:
  /// **'YESTERDAY'**
  String get dayYesterday;

  /// No description provided for @dayOlder.
  ///
  /// In en, this message translates to:
  /// **'OLDER'**
  String get dayOlder;

  /// No description provided for @activityCreatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Ticket created'**
  String get activityCreatedTitle;

  /// No description provided for @activityAcceptedTitle.
  ///
  /// In en, this message translates to:
  /// **'{actor} accepted the ticket'**
  String activityAcceptedTitle(String actor);

  /// No description provided for @activityDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'{actor} marked this done'**
  String activityDoneTitle(String actor);

  /// No description provided for @activityOverdueTitle.
  ///
  /// In en, this message translates to:
  /// **'Ticket is overdue'**
  String get activityOverdueTitle;

  /// No description provided for @activityCancelledTitle.
  ///
  /// In en, this message translates to:
  /// **'{actor} cancelled this ticket'**
  String activityCancelledTitle(String actor);

  /// No description provided for @activityNoteTitle.
  ///
  /// In en, this message translates to:
  /// **'{actor} added a note'**
  String activityNoteTitle(String actor);

  /// No description provided for @activityReassignedTitle.
  ///
  /// In en, this message translates to:
  /// **'{actor} reassigned to {target}'**
  String activityReassignedTitle(String actor, String target);

  /// No description provided for @createNewTitle.
  ///
  /// In en, this message translates to:
  /// **'Create new'**
  String get createNewTitle;

  /// No description provided for @createNewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'What kind of ticket are you creating?'**
  String get createNewSubtitle;

  /// No description provided for @createUniversalTitle.
  ///
  /// In en, this message translates to:
  /// **'Universal request'**
  String get createUniversalTitle;

  /// No description provided for @createUniversalDesc.
  ///
  /// In en, this message translates to:
  /// **'Towels, pillows, toiletries — quick operational asks'**
  String get createUniversalDesc;

  /// No description provided for @createCatalogTitle.
  ///
  /// In en, this message translates to:
  /// **'Catalog'**
  String get createCatalogTitle;

  /// No description provided for @createCatalogDesc.
  ///
  /// In en, this message translates to:
  /// **'Room service, spa, bar — anything a guest is paying for'**
  String get createCatalogDesc;

  /// No description provided for @createManualTitle.
  ///
  /// In en, this message translates to:
  /// **'Manual ticket'**
  String get createManualTitle;

  /// No description provided for @createManualDesc.
  ///
  /// In en, this message translates to:
  /// **'Complaints, issues, anything that doesn\'t fit above'**
  String get createManualDesc;

  /// No description provided for @createHint.
  ///
  /// In en, this message translates to:
  /// **'Not sure? Manual works for anything.'**
  String get createHint;

  /// No description provided for @universalHeading.
  ///
  /// In en, this message translates to:
  /// **'Universal request'**
  String get universalHeading;

  /// No description provided for @universalSubheading.
  ///
  /// In en, this message translates to:
  /// **'Tap what you need'**
  String get universalSubheading;

  /// No description provided for @itemTowels.
  ///
  /// In en, this message translates to:
  /// **'Towels'**
  String get itemTowels;

  /// No description provided for @itemPillows.
  ///
  /// In en, this message translates to:
  /// **'Pillows'**
  String get itemPillows;

  /// No description provided for @itemToiletries.
  ///
  /// In en, this message translates to:
  /// **'Toiletries'**
  String get itemToiletries;

  /// No description provided for @itemBlanket.
  ///
  /// In en, this message translates to:
  /// **'Blanket'**
  String get itemBlanket;

  /// No description provided for @itemWater.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get itemWater;

  /// No description provided for @itemOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get itemOther;

  /// No description provided for @roomLabel.
  ///
  /// In en, this message translates to:
  /// **'ROOM'**
  String get roomLabel;

  /// No description provided for @roomFind.
  ///
  /// In en, this message translates to:
  /// **'Find'**
  String get roomFind;

  /// No description provided for @roomRecentHelper.
  ///
  /// In en, this message translates to:
  /// **'Recent rooms · tap to select'**
  String get roomRecentHelper;

  /// No description provided for @noteLabel.
  ///
  /// In en, this message translates to:
  /// **'NOTE (OPTIONAL)'**
  String get noteLabel;

  /// No description provided for @noteHint.
  ///
  /// In en, this message translates to:
  /// **'Add a note for the team…'**
  String get noteHint;

  /// No description provided for @pickItemHint.
  ///
  /// In en, this message translates to:
  /// **'Pick an item to start'**
  String get pickItemHint;

  /// No description provided for @pickRoomHint.
  ///
  /// In en, this message translates to:
  /// **'Pick a room to continue'**
  String get pickRoomHint;

  /// No description provided for @createCta.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get createCta;

  /// No description provided for @createSuccessToast.
  ///
  /// In en, this message translates to:
  /// **'Ticket created'**
  String get createSuccessToast;

  /// No description provided for @tapToAdd.
  ///
  /// In en, this message translates to:
  /// **'Tap to add'**
  String get tapToAdd;

  /// No description provided for @itemsSelected.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 item selected} other{{count} items selected}}'**
  String itemsSelected(int count);

  /// No description provided for @roomPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Select room'**
  String get roomPickerTitle;

  /// No description provided for @roomPickerRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get roomPickerRecent;

  /// No description provided for @roomPickerAll.
  ///
  /// In en, this message translates to:
  /// **'All rooms'**
  String get roomPickerAll;

  /// No description provided for @roomFloor.
  ///
  /// In en, this message translates to:
  /// **'Floor {floor}'**
  String roomFloor(int floor);

  /// No description provided for @roomNumber.
  ///
  /// In en, this message translates to:
  /// **'Room {number}'**
  String roomNumber(String number);

  /// No description provided for @roomSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search room number…'**
  String get roomSearchHint;

  /// No description provided for @filterTitle.
  ///
  /// In en, this message translates to:
  /// **'Filter by department'**
  String get filterTitle;

  /// No description provided for @filterSubtitleAll.
  ///
  /// In en, this message translates to:
  /// **'Showing all departments'**
  String get filterSubtitleAll;

  /// No description provided for @filterSubtitleSome.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Showing 1 department} other{Showing {count} departments}}'**
  String filterSubtitleSome(int count);

  /// No description provided for @filterSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get filterSelectAll;

  /// No description provided for @filterClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get filterClear;

  /// No description provided for @filterApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get filterApply;

  /// No description provided for @deptConcierge.
  ///
  /// In en, this message translates to:
  /// **'Concierge'**
  String get deptConcierge;

  /// No description provided for @deptFnb.
  ///
  /// In en, this message translates to:
  /// **'F&B'**
  String get deptFnb;

  /// No description provided for @deptFrontDesk.
  ///
  /// In en, this message translates to:
  /// **'Front Desk'**
  String get deptFrontDesk;

  /// No description provided for @deptHousekeeping.
  ///
  /// In en, this message translates to:
  /// **'Housekeeping'**
  String get deptHousekeeping;

  /// No description provided for @deptMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get deptMaintenance;

  /// No description provided for @deptRoomService.
  ///
  /// In en, this message translates to:
  /// **'Room Service'**
  String get deptRoomService;

  /// No description provided for @dashboardGreetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning, {name}'**
  String dashboardGreetingMorning(String name);

  /// No description provided for @dashboardGreetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon, {name}'**
  String dashboardGreetingAfternoon(String name);

  /// No description provided for @dashboardGreetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening, {name}'**
  String dashboardGreetingEvening(String name);

  /// No description provided for @dashboardNeedsAcknowledgment.
  ///
  /// In en, this message translates to:
  /// **'Needs acknowledgment'**
  String get dashboardNeedsAcknowledgment;

  /// No description provided for @dashboardIncomingFooterEmpty.
  ///
  /// In en, this message translates to:
  /// **'Awaiting acceptance'**
  String get dashboardIncomingFooterEmpty;

  /// No description provided for @dashboardInProgressLabel.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get dashboardInProgressLabel;

  /// No description provided for @dashboardInProgressFooter.
  ///
  /// In en, this message translates to:
  /// **'Currently being worked on'**
  String get dashboardInProgressFooter;

  /// No description provided for @dashboardOverdueLabel.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get dashboardOverdueLabel;

  /// No description provided for @dashboardOverdueFooter.
  ///
  /// In en, this message translates to:
  /// **'Past due time'**
  String get dashboardOverdueFooter;

  /// No description provided for @dashboardNotStartedLabel.
  ///
  /// In en, this message translates to:
  /// **'Not started'**
  String get dashboardNotStartedLabel;

  /// No description provided for @dashboardNotStartedFooter.
  ///
  /// In en, this message translates to:
  /// **'Accepted but not started'**
  String get dashboardNotStartedFooter;

  /// No description provided for @dashboardNeedsAttention.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get dashboardNeedsAttention;

  /// No description provided for @dashboardViewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get dashboardViewAll;

  /// No description provided for @dashboardAllClearTitle.
  ///
  /// In en, this message translates to:
  /// **'All clear'**
  String get dashboardAllClearTitle;

  /// No description provided for @dashboardAllClearBody.
  ///
  /// In en, this message translates to:
  /// **'No tickets need immediate attention right now.'**
  String get dashboardAllClearBody;

  /// No description provided for @dashboardAllClearHint.
  ///
  /// In en, this message translates to:
  /// **'New and active tickets are available in the Tickets tab.'**
  String get dashboardAllClearHint;

  /// No description provided for @dashboardBreakdownUniversal.
  ///
  /// In en, this message translates to:
  /// **'{n} universal'**
  String dashboardBreakdownUniversal(int n);

  /// No description provided for @dashboardBreakdownCatalog.
  ///
  /// In en, this message translates to:
  /// **'{n} catalog'**
  String dashboardBreakdownCatalog(int n);

  /// No description provided for @dashboardBreakdownManual.
  ///
  /// In en, this message translates to:
  /// **'{n} manual'**
  String dashboardBreakdownManual(int n);

  /// No description provided for @dashboardOverduePill.
  ///
  /// In en, this message translates to:
  /// **'Overdue {minutes}m'**
  String dashboardOverduePill(int minutes);

  /// No description provided for @dashboardDueSoonPill.
  ///
  /// In en, this message translates to:
  /// **'Due in {minutes}m'**
  String dashboardDueSoonPill(int minutes);

  /// No description provided for @dashboardNotStartedPill.
  ///
  /// In en, this message translates to:
  /// **'Not started'**
  String get dashboardNotStartedPill;

  /// No description provided for @dashboardWaitingPill.
  ///
  /// In en, this message translates to:
  /// **'Waiting {minutes}m'**
  String dashboardWaitingPill(int minutes);

  /// No description provided for @dashboardRoomPrefix.
  ///
  /// In en, this message translates to:
  /// **'Room {number}'**
  String dashboardRoomPrefix(String number);

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navTickets.
  ///
  /// In en, this message translates to:
  /// **'Tickets'**
  String get navTickets;

  /// No description provided for @navActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get navActivity;

  /// No description provided for @navCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get navCreate;

  /// No description provided for @navModules.
  ///
  /// In en, this message translates to:
  /// **'Modules'**
  String get navModules;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @comingSoonTitle.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoonTitle;

  /// No description provided for @comingSoonModules.
  ///
  /// In en, this message translates to:
  /// **'Modules will give you quick access to housekeeping, F&B and more.'**
  String get comingSoonModules;

  /// No description provided for @comingSoonProfile.
  ///
  /// In en, this message translates to:
  /// **'Your profile, settings and preferences will live here.'**
  String get comingSoonProfile;

  /// No description provided for @comingSoonCatalog.
  ///
  /// In en, this message translates to:
  /// **'Order room service, spa, and other paid items here.'**
  String get comingSoonCatalog;

  /// No description provided for @comingSoonManual.
  ///
  /// In en, this message translates to:
  /// **'Free-form complaint or issue ticket. We\'ll wire this up next.'**
  String get comingSoonManual;

  /// No description provided for @comingSoonNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications inbox — coming soon'**
  String get comingSoonNotifications;

  /// No description provided for @backToTickets.
  ///
  /// In en, this message translates to:
  /// **'Back to tickets'**
  String get backToTickets;

  /// No description provided for @labelEta.
  ///
  /// In en, this message translates to:
  /// **'ETA'**
  String get labelEta;

  /// No description provided for @labelGuestCheckoutTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Check-out tomorrow'**
  String get labelGuestCheckoutTomorrow;

  /// No description provided for @relativeJustNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get relativeJustNow;

  /// No description provided for @relativeSeconds.
  ///
  /// In en, this message translates to:
  /// **'{seconds}s ago'**
  String relativeSeconds(int seconds);

  /// No description provided for @relativeMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String relativeMinutes(int minutes);

  /// No description provided for @relativeHours.
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String relativeHours(int hours);

  /// No description provided for @relativeDays.
  ///
  /// In en, this message translates to:
  /// **'{days}d ago'**
  String relativeDays(int days);

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTitle;

  /// No description provided for @languageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick the language you\'d like the app to use.'**
  String get languageSubtitle;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageSpanish.
  ///
  /// In en, this message translates to:
  /// **'Español'**
  String get languageSpanish;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'Match device language'**
  String get languageSystem;

  /// No description provided for @languageChangedToast.
  ///
  /// In en, this message translates to:
  /// **'Language updated'**
  String get languageChangedToast;

  /// No description provided for @languageNativeEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageNativeEnglish;

  /// No description provided for @languageNativeSpanish.
  ///
  /// In en, this message translates to:
  /// **'Español'**
  String get languageNativeSpanish;

  /// No description provided for @tooltipToggleTheme.
  ///
  /// In en, this message translates to:
  /// **'Toggle theme'**
  String get tooltipToggleTheme;

  /// No description provided for @tooltipLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get tooltipLanguage;

  /// No description provided for @tooltipNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get tooltipNotifications;

  /// No description provided for @profileSectionPreferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get profileSectionPreferences;

  /// No description provided for @profileSectionAccountInformation.
  ///
  /// In en, this message translates to:
  /// **'Account information'**
  String get profileSectionAccountInformation;

  /// No description provided for @profileSectionWorkInformation.
  ///
  /// In en, this message translates to:
  /// **'Work information'**
  String get profileSectionWorkInformation;

  /// No description provided for @profileFieldName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get profileFieldName;

  /// No description provided for @profileFieldEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get profileFieldEmail;

  /// No description provided for @profileFieldEmployeeCode.
  ///
  /// In en, this message translates to:
  /// **'Employee code'**
  String get profileFieldEmployeeCode;

  /// No description provided for @profileFieldRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get profileFieldRole;

  /// No description provided for @profileFieldDepartments.
  ///
  /// In en, this message translates to:
  /// **'Departments'**
  String get profileFieldDepartments;

  /// No description provided for @profileFieldStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get profileFieldStatus;

  /// No description provided for @profileFieldEmptyValue.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get profileFieldEmptyValue;

  /// No description provided for @profileLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get profileLanguageTitle;

  /// No description provided for @profileLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your interface language'**
  String get profileLanguageSubtitle;

  /// No description provided for @profileThemeTitle.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get profileThemeTitle;

  /// No description provided for @profileThemeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose how the app looks'**
  String get profileThemeSubtitle;

  /// No description provided for @profileThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get profileThemeLight;

  /// No description provided for @profileThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get profileThemeDark;

  /// No description provided for @profileThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get profileThemeSystem;

  /// No description provided for @profileStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get profileStatusActive;

  /// No description provided for @profileStatusInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get profileStatusInactive;

  /// No description provided for @profileChangeAvatar.
  ///
  /// In en, this message translates to:
  /// **'Change profile photo'**
  String get profileChangeAvatar;

  /// No description provided for @profileChangeAvatarComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Avatar upload — coming soon'**
  String get profileChangeAvatarComingSoon;

  /// No description provided for @profileLogout.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get profileLogout;

  /// No description provided for @profileLogoutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get profileLogoutConfirmTitle;

  /// No description provided for @profileLogoutConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ll need to sign in again to access your tickets.'**
  String get profileLogoutConfirmBody;

  /// No description provided for @profileLogoutConfirmCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get profileLogoutConfirmCancel;

  /// No description provided for @profileLogoutConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get profileLogoutConfirmAction;

  /// No description provided for @notifChannelName.
  ///
  /// In en, this message translates to:
  /// **'High importance notifications'**
  String get notifChannelName;

  /// No description provided for @notifChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'Used for critical app notifications.'**
  String get notifChannelDescription;

  /// No description provided for @notifGenericTitle.
  ///
  /// In en, this message translates to:
  /// **'Nexierge'**
  String get notifGenericTitle;

  /// No description provided for @notifNewTicket.
  ///
  /// In en, this message translates to:
  /// **'New ticket: {ticketCode}'**
  String notifNewTicket(String ticketCode);

  /// No description provided for @ticketTabDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get ticketTabDetails;

  /// No description provided for @ticketTabActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get ticketTabActivity;

  /// No description provided for @ticketSectionGuestRoom.
  ///
  /// In en, this message translates to:
  /// **'GUEST & ROOM'**
  String get ticketSectionGuestRoom;

  /// No description provided for @ticketSectionInformation.
  ///
  /// In en, this message translates to:
  /// **'TICKET INFORMATION'**
  String get ticketSectionInformation;

  /// No description provided for @ticketFieldGuest.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get ticketFieldGuest;

  /// No description provided for @ticketFieldRoom.
  ///
  /// In en, this message translates to:
  /// **'Room'**
  String get ticketFieldRoom;

  /// No description provided for @ticketFieldRoomType.
  ///
  /// In en, this message translates to:
  /// **'Room type'**
  String get ticketFieldRoomType;

  /// No description provided for @ticketFieldDepartment.
  ///
  /// In en, this message translates to:
  /// **'Department'**
  String get ticketFieldDepartment;

  /// No description provided for @ticketFieldConversation.
  ///
  /// In en, this message translates to:
  /// **'Conversation'**
  String get ticketFieldConversation;

  /// No description provided for @ticketFieldStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get ticketFieldStatus;

  /// No description provided for @ticketFieldTicketType.
  ///
  /// In en, this message translates to:
  /// **'Ticket type'**
  String get ticketFieldTicketType;

  /// No description provided for @ticketFieldSource.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get ticketFieldSource;

  /// No description provided for @ticketRoomNumber.
  ///
  /// In en, this message translates to:
  /// **'#{number}'**
  String ticketRoomNumber(String number);

  /// No description provided for @ticketPriorityP1.
  ///
  /// In en, this message translates to:
  /// **'P1'**
  String get ticketPriorityP1;

  /// No description provided for @ticketPriorityP2.
  ///
  /// In en, this message translates to:
  /// **'P2'**
  String get ticketPriorityP2;

  /// No description provided for @ticketPriorityP3.
  ///
  /// In en, this message translates to:
  /// **'P3'**
  String get ticketPriorityP3;

  /// No description provided for @ticketStatusBadgeAccepted.
  ///
  /// In en, this message translates to:
  /// **'ACCEPTED'**
  String get ticketStatusBadgeAccepted;

  /// No description provided for @ticketStatusBadgeIncoming.
  ///
  /// In en, this message translates to:
  /// **'INCOMING'**
  String get ticketStatusBadgeIncoming;

  /// No description provided for @ticketStatusBadgeInProgress.
  ///
  /// In en, this message translates to:
  /// **'IN PROGRESS'**
  String get ticketStatusBadgeInProgress;

  /// No description provided for @ticketStatusBadgeDone.
  ///
  /// In en, this message translates to:
  /// **'DONE'**
  String get ticketStatusBadgeDone;

  /// No description provided for @ticketStatusBadgeCancelled.
  ///
  /// In en, this message translates to:
  /// **'CANCELLED'**
  String get ticketStatusBadgeCancelled;

  /// No description provided for @ticketSourceGuestApp.
  ///
  /// In en, this message translates to:
  /// **'Guest app'**
  String get ticketSourceGuestApp;

  /// No description provided for @ticketSourceFrontDesk.
  ///
  /// In en, this message translates to:
  /// **'Front desk'**
  String get ticketSourceFrontDesk;

  /// No description provided for @ticketSourcePhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get ticketSourcePhone;

  /// No description provided for @ticketSourceWalkIn.
  ///
  /// In en, this message translates to:
  /// **'Walk-in'**
  String get ticketSourceWalkIn;

  /// No description provided for @ticketSourceSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get ticketSourceSystem;

  /// No description provided for @ticketElapsed.
  ///
  /// In en, this message translates to:
  /// **'{elapsed} elapsed'**
  String ticketElapsed(String elapsed);

  /// No description provided for @ticketActionStartWork.
  ///
  /// In en, this message translates to:
  /// **'Start Work'**
  String get ticketActionStartWork;

  /// No description provided for @ticketActionPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get ticketActionPause;

  /// No description provided for @ticketActionResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get ticketActionResume;

  /// No description provided for @ticketActionComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get ticketActionComplete;

  /// No description provided for @ticketActionChangeDue.
  ///
  /// In en, this message translates to:
  /// **'Change Due'**
  String get ticketActionChangeDue;

  /// No description provided for @ticketActionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get ticketActionCancel;

  /// No description provided for @ticketActionReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get ticketActionReset;

  /// No description provided for @ticketActivityCreated.
  ///
  /// In en, this message translates to:
  /// **'Ticket created'**
  String get ticketActivityCreated;

  /// No description provided for @ticketActivityStatusChange.
  ///
  /// In en, this message translates to:
  /// **'{from} → {to}'**
  String ticketActivityStatusChange(String from, String to);

  /// No description provided for @ticketActivityBadgeAcknowledged.
  ///
  /// In en, this message translates to:
  /// **'Acknowledged'**
  String get ticketActivityBadgeAcknowledged;

  /// No description provided for @ticketActivityBadgeCreated.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get ticketActivityBadgeCreated;

  /// No description provided for @ticketActivityBadgeDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get ticketActivityBadgeDone;

  /// No description provided for @ticketActivityBadgeCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get ticketActivityBadgeCancelled;

  /// No description provided for @ticketActivityBadgeNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get ticketActivityBadgeNote;

  /// No description provided for @ticketActivityBadgeReassigned.
  ///
  /// In en, this message translates to:
  /// **'Reassigned'**
  String get ticketActivityBadgeReassigned;

  /// No description provided for @ticketActivityBadgeOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get ticketActivityBadgeOverdue;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsUnread.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No unread} =1{1 unread} other{{count} unread}}'**
  String notificationsUnread(int count);

  /// No description provided for @notificationsTotal.
  ///
  /// In en, this message translates to:
  /// **'{count} total'**
  String notificationsTotal(int count);

  /// No description provided for @notificationsMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get notificationsMarkAllRead;

  /// No description provided for @notificationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up'**
  String get notificationsEmpty;

  /// No description provided for @notificationsEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'New activity will appear here.'**
  String get notificationsEmptyHint;

  /// No description provided for @notificationsItemNewTicket.
  ///
  /// In en, this message translates to:
  /// **'New ticket received'**
  String get notificationsItemNewTicket;

  /// No description provided for @relativeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String relativeMinutesAgo(int minutes);

  /// No description provided for @relativeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String relativeHoursAgo(int hours);

  /// No description provided for @relativeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days}d ago'**
  String relativeDaysAgo(int days);

  /// No description provided for @ticketKindUniversal.
  ///
  /// In en, this message translates to:
  /// **'Universal'**
  String get ticketKindUniversal;

  /// No description provided for @ticketKindCatalog.
  ///
  /// In en, this message translates to:
  /// **'Catalog'**
  String get ticketKindCatalog;

  /// No description provided for @ticketKindManual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get ticketKindManual;

  /// No description provided for @filterNewestFirst.
  ///
  /// In en, this message translates to:
  /// **'Newest first'**
  String get filterNewestFirst;

  /// No description provided for @filterOldestFirst.
  ///
  /// In en, this message translates to:
  /// **'Oldest first'**
  String get filterOldestFirst;

  /// No description provided for @filterThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get filterThisWeek;

  /// No description provided for @filterThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get filterThisMonth;

  /// No description provided for @profileAvatarSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Change profile photo'**
  String get profileAvatarSheetTitle;

  /// No description provided for @profileAvatarSheetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a new photo from your camera or gallery.'**
  String get profileAvatarSheetSubtitle;

  /// No description provided for @profileAvatarSheetUploadTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get profileAvatarSheetUploadTitle;

  /// No description provided for @profileAvatarSheetUploadSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select an existing photo from your device.'**
  String get profileAvatarSheetUploadSubtitle;

  /// No description provided for @profileAvatarSheetCameraTitle.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get profileAvatarSheetCameraTitle;

  /// No description provided for @profileAvatarSheetCameraSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use your camera to take a new photo.'**
  String get profileAvatarSheetCameraSubtitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
