import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pl.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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
    Locale('pl'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'PLNing'**
  String get appTitle;

  /// No description provided for @envelopes.
  ///
  /// In en, this message translates to:
  /// **'Envelopes'**
  String get envelopes;

  /// No description provided for @spent.
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get spent;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @noEnvelopesForExpense.
  ///
  /// In en, this message translates to:
  /// **'You have no envelopes yet. Add one before saving an expense.'**
  String get noEnvelopesForExpense;

  /// No description provided for @envelope.
  ///
  /// In en, this message translates to:
  /// **'Envelope'**
  String get envelope;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @enterAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount'**
  String get enterAmount;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @saveExpense.
  ///
  /// In en, this message translates to:
  /// **'Save expense'**
  String get saveExpense;

  /// No description provided for @editExpense.
  ///
  /// In en, this message translates to:
  /// **'Edit expense'**
  String get editExpense;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deleteExpense.
  ///
  /// In en, this message translates to:
  /// **'Delete expense'**
  String get deleteExpense;

  /// No description provided for @deleteExpenseConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this expense of {amount}?'**
  String deleteExpenseConfirm(String amount);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @appLock.
  ///
  /// In en, this message translates to:
  /// **'App lock (PIN)'**
  String get appLock;

  /// No description provided for @appLockSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Require a PIN to open the app'**
  String get appLockSubtitle;

  /// No description provided for @changePin.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get changePin;

  /// No description provided for @biometricUnlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock with biometrics'**
  String get biometricUnlock;

  /// No description provided for @setPin.
  ///
  /// In en, this message translates to:
  /// **'Set PIN'**
  String get setPin;

  /// No description provided for @enterPin.
  ///
  /// In en, this message translates to:
  /// **'Enter PIN'**
  String get enterPin;

  /// No description provided for @confirmPin.
  ///
  /// In en, this message translates to:
  /// **'Confirm PIN'**
  String get confirmPin;

  /// No description provided for @pinTooShort.
  ///
  /// In en, this message translates to:
  /// **'PIN must be at least 6 digits'**
  String get pinTooShort;

  /// No description provided for @pinsDontMatch.
  ///
  /// In en, this message translates to:
  /// **'PINs don\'t match'**
  String get pinsDontMatch;

  /// No description provided for @wrongPin.
  ///
  /// In en, this message translates to:
  /// **'Incorrect PIN'**
  String get wrongPin;

  /// No description provided for @unlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlock;

  /// No description provided for @unlockTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your PIN'**
  String get unlockTitle;

  /// No description provided for @useBiometrics.
  ///
  /// In en, this message translates to:
  /// **'Use biometrics'**
  String get useBiometrics;

  /// No description provided for @biometricReason.
  ///
  /// In en, this message translates to:
  /// **'Authenticate to unlock Money Planner'**
  String get biometricReason;

  /// No description provided for @pinSaved.
  ///
  /// In en, this message translates to:
  /// **'PIN saved'**
  String get pinSaved;

  /// No description provided for @lockDisabled.
  ///
  /// In en, this message translates to:
  /// **'App lock disabled'**
  String get lockDisabled;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get themeAuto;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @newExpense.
  ///
  /// In en, this message translates to:
  /// **'New expense'**
  String get newExpense;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @errorUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach the server. Check your connection and try again.'**
  String get errorUnreachable;

  /// No description provided for @errorNotFound.
  ///
  /// In en, this message translates to:
  /// **'That data no longer exists. It may have been changed on another device.'**
  String get errorNotFound;

  /// No description provided for @errorConflict.
  ///
  /// In en, this message translates to:
  /// **'This conflicts with the data that is already there.'**
  String get errorConflict;

  /// No description provided for @errorInvalid.
  ///
  /// In en, this message translates to:
  /// **'The server did not accept these values. Check what you entered.'**
  String get errorInvalid;

  /// No description provided for @errorServer.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong on the server. Try again in a moment.'**
  String get errorServer;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @loadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your data'**
  String get loadFailed;

  /// No description provided for @errorUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'You are signed out. Sign in again.'**
  String get errorUnauthorized;

  /// No description provided for @errorRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many tries. Wait a while and try again.'**
  String get errorRateLimited;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'E-mail address'**
  String get emailAddress;

  /// No description provided for @enterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid e-mail address'**
  String get enterValidEmail;

  /// No description provided for @sendCode.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get sendCode;

  /// No description provided for @codeSentTo.
  ///
  /// In en, this message translates to:
  /// **'We sent a code to {email}. Enter it below.'**
  String codeSentTo(String email);

  /// No description provided for @enterCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code'**
  String get enterCode;

  /// No description provided for @signInAction.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInAction;

  /// No description provided for @useOtherEmail.
  ///
  /// In en, this message translates to:
  /// **'Use another address'**
  String get useOtherEmail;

  /// No description provided for @invalidCode.
  ///
  /// In en, this message translates to:
  /// **'The code is wrong or has expired.'**
  String get invalidCode;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @signedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {email}'**
  String signedInAs(String email);

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @signOutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Sign out of this device?'**
  String get signOutConfirm;

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get signInWithGoogle;

  /// No description provided for @googleSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in did not work. Try again or use the e-mail code.'**
  String get googleSignInFailed;

  /// No description provided for @orSeparator.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get orSeparator;

  /// No description provided for @manageEnvelopes.
  ///
  /// In en, this message translates to:
  /// **'Manage envelopes'**
  String get manageEnvelopes;

  /// No description provided for @loginHeadline.
  ///
  /// In en, this message translates to:
  /// **'Household budget,\ntogether or solo'**
  String get loginHeadline;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with your e-mail – we\'ll send you a code. No password.'**
  String get loginSubtitle;

  /// No description provided for @codeFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Code from the e-mail (6 digits)'**
  String get codeFieldLabel;

  /// No description provided for @codeValidity.
  ///
  /// In en, this message translates to:
  /// **'The code is valid for 15 minutes. Didn\'t get it?'**
  String get codeValidity;

  /// No description provided for @resendShort.
  ///
  /// In en, this message translates to:
  /// **'Send again'**
  String get resendShort;

  /// No description provided for @consent.
  ///
  /// In en, this message translates to:
  /// **'I accept the information on processing my data (e-mail, name, budget data).'**
  String get consent;

  /// No description provided for @consentRequired.
  ///
  /// In en, this message translates to:
  /// **'Tick the consent to sign in.'**
  String get consentRequired;

  /// No description provided for @recurringTab.
  ///
  /// In en, this message translates to:
  /// **'Recurring'**
  String get recurringTab;

  /// No description provided for @addExpenseShort.
  ///
  /// In en, this message translates to:
  /// **'+ Expense'**
  String get addExpenseShort;

  /// No description provided for @wizardStartTitle.
  ///
  /// In en, this message translates to:
  /// **'Let\'s set up your budget'**
  String get wizardStartTitle;

  /// No description provided for @wizardStartBody.
  ///
  /// In en, this message translates to:
  /// **'Five short steps: envelopes, sharing, income, bills and putting the money into envelopes.'**
  String get wizardStartBody;

  /// No description provided for @wizardStart.
  ///
  /// In en, this message translates to:
  /// **'Let\'s start'**
  String get wizardStart;

  /// No description provided for @descriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get descriptionOptional;

  /// No description provided for @descriptionHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. groceries'**
  String get descriptionHint;

  /// No description provided for @addRule.
  ///
  /// In en, this message translates to:
  /// **'Add a rule'**
  String get addRule;

  /// No description provided for @allEnvelopes.
  ///
  /// In en, this message translates to:
  /// **'All envelopes'**
  String get allEnvelopes;

  /// No description provided for @allPeriods.
  ///
  /// In en, this message translates to:
  /// **'All periods'**
  String get allPeriods;

  /// No description provided for @anyAuthor.
  ///
  /// In en, this message translates to:
  /// **'Any author'**
  String get anyAuthor;

  /// No description provided for @appliedToTodo.
  ///
  /// In en, this message translates to:
  /// **'It did not fit and went to the to-do list.'**
  String get appliedToTodo;

  /// No description provided for @applyAllExpenses.
  ///
  /// In en, this message translates to:
  /// **'Apply all recurring expenses: {name}'**
  String applyAllExpenses(String name);

  /// No description provided for @applyEstimateHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the real amount.'**
  String get applyEstimateHint;

  /// No description provided for @applyNow.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get applyNow;

  /// No description provided for @archive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archive;

  /// No description provided for @archived.
  ///
  /// In en, this message translates to:
  /// **'archived'**
  String get archived;

  /// No description provided for @byAuthor.
  ///
  /// In en, this message translates to:
  /// **'By {name}'**
  String byAuthor(String name);

  /// No description provided for @carryIn.
  ///
  /// In en, this message translates to:
  /// **'Unspent from the previous period'**
  String get carryIn;

  /// No description provided for @changeLog.
  ///
  /// In en, this message translates to:
  /// **'Change log'**
  String get changeLog;

  /// No description provided for @chooseHousehold.
  ///
  /// In en, this message translates to:
  /// **'Choose a household'**
  String get chooseHousehold;

  /// No description provided for @closedCarried.
  ///
  /// In en, this message translates to:
  /// **'Went on to the next period'**
  String get closedCarried;

  /// No description provided for @closedCarriedHint.
  ///
  /// In en, this message translates to:
  /// **'This money is now in the current period, shared by everybody.'**
  String get closedCarriedHint;

  /// No description provided for @closedNothingCarried.
  ///
  /// In en, this message translates to:
  /// **'Nothing went on this time.'**
  String get closedNothingCarried;

  /// No description provided for @closedOk.
  ///
  /// In en, this message translates to:
  /// **'Great'**
  String get closedOk;

  /// No description provided for @closedPeriod.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get closedPeriod;

  /// No description provided for @closedPutIn.
  ///
  /// In en, this message translates to:
  /// **'Put in'**
  String get closedPutIn;

  /// No description provided for @closedSpent.
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get closedSpent;

  /// No description provided for @closedTitle.
  ///
  /// In en, this message translates to:
  /// **'Period closed: {name}'**
  String closedTitle(String name);

  /// No description provided for @comparedToPrevious.
  ///
  /// In en, this message translates to:
  /// **'vs previous: {delta}'**
  String comparedToPrevious(String delta);

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @correctionBody.
  ///
  /// In en, this message translates to:
  /// **'After this correction the wallet goes {amount} below zero. Take the missing amount back from a household, or keep the minus until the next income?'**
  String correctionBody(String amount);

  /// No description provided for @correctionKeepMinus.
  ///
  /// In en, this message translates to:
  /// **'Keep the minus'**
  String get correctionKeepMinus;

  /// No description provided for @correctionTitle.
  ///
  /// In en, this message translates to:
  /// **'The wallet goes below zero'**
  String get correctionTitle;

  /// No description provided for @correctionWithdrawFrom.
  ///
  /// In en, this message translates to:
  /// **'Take back from {name}'**
  String correctionWithdrawFrom(String name);

  /// No description provided for @currentPeriod.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get currentPeriod;

  /// No description provided for @currentPeriodEnd.
  ///
  /// In en, this message translates to:
  /// **'End of the current period'**
  String get currentPeriodEnd;

  /// No description provided for @currentPeriodEndHint.
  ///
  /// In en, this message translates to:
  /// **'Not before today'**
  String get currentPeriodEndHint;

  /// No description provided for @cycle.
  ///
  /// In en, this message translates to:
  /// **'Periods'**
  String get cycle;

  /// No description provided for @cycleEveryWeeks.
  ///
  /// In en, this message translates to:
  /// **'{weeks, plural, =1{every week} other{every {weeks} weeks}}'**
  String cycleEveryWeeks(int weeks);

  /// No description provided for @cycleFromDay.
  ///
  /// In en, this message translates to:
  /// **'from {day}'**
  String cycleFromDay(String day);

  /// No description provided for @cycleManual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get cycleManual;

  /// No description provided for @cycleManualHint.
  ///
  /// In en, this message translates to:
  /// **'You set the end; a new period lasts as long as the one before.'**
  String get cycleManualHint;

  /// No description provided for @cycleMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get cycleMonthly;

  /// No description provided for @cycleMonthlyFrom.
  ///
  /// In en, this message translates to:
  /// **'monthly from day {day}'**
  String cycleMonthlyFrom(int day);

  /// No description provided for @cycleWeeks.
  ///
  /// In en, this message translates to:
  /// **'Every N weeks'**
  String get cycleWeeks;

  /// No description provided for @dashboardRangeLabel.
  ///
  /// In en, this message translates to:
  /// **'Households {from} – {to}'**
  String dashboardRangeLabel(String from, String to);

  /// No description provided for @dashboardShows.
  ///
  /// In en, this message translates to:
  /// **'The dashboard shows'**
  String get dashboardShows;

  /// No description provided for @dateAndTime.
  ///
  /// In en, this message translates to:
  /// **'Date and time'**
  String get dateAndTime;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountBody.
  ///
  /// In en, this message translates to:
  /// **'Your wallet, incomes and rules go. Your positive shares stay in the households as nobody\'s money. Type your e-mail address to confirm.'**
  String get deleteAccountBody;

  /// No description provided for @deleteHousehold.
  ///
  /// In en, this message translates to:
  /// **'Delete household'**
  String get deleteHousehold;

  /// No description provided for @deleteHouseholdConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete “{name}” with its envelopes and expenses? Positive shares go back to the wallets.'**
  String deleteHouseholdConfirm(String name);

  /// No description provided for @deleteHouseholdHint.
  ///
  /// In en, this message translates to:
  /// **'Not while anybody has a negative share.'**
  String get deleteHouseholdHint;

  /// No description provided for @deleteRule.
  ///
  /// In en, this message translates to:
  /// **'Delete rule'**
  String get deleteRule;

  /// No description provided for @deleteRuleConfirm.
  ///
  /// In en, this message translates to:
  /// **'What the rule has made stays.'**
  String get deleteRuleConfirm;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'E-mail address'**
  String get email;

  /// No description provided for @envelopeHasExpensesTitle.
  ///
  /// In en, this message translates to:
  /// **'The envelope has expenses'**
  String get envelopeHasExpensesTitle;

  /// No description provided for @errAlreadyMember.
  ///
  /// In en, this message translates to:
  /// **'That person is a member already.'**
  String get errAlreadyMember;

  /// No description provided for @errCannotUndo.
  ///
  /// In en, this message translates to:
  /// **'This change can no longer be undone.'**
  String get errCannotUndo;

  /// No description provided for @errConfirmationMismatch.
  ///
  /// In en, this message translates to:
  /// **'The address does not match.'**
  String get errConfirmationMismatch;

  /// No description provided for @errDateOutsidePeriod.
  ///
  /// In en, this message translates to:
  /// **'The date has to be in the current period and not later than now.'**
  String get errDateOutsidePeriod;

  /// No description provided for @errDuplicateEnvelope.
  ///
  /// In en, this message translates to:
  /// **'There is an envelope with this name already.'**
  String get errDuplicateEnvelope;

  /// No description provided for @errEnvelopeHasExpenses.
  ///
  /// In en, this message translates to:
  /// **'An envelope with expenses cannot be deleted – archive it; its expenses stay in the history.'**
  String get errEnvelopeHasExpenses;

  /// No description provided for @errInvalidPeriodEnd.
  ///
  /// In en, this message translates to:
  /// **'The end cannot be before today or run into the next period.'**
  String get errInvalidPeriodEnd;

  /// No description provided for @errLastEnvelope.
  ///
  /// In en, this message translates to:
  /// **'A household needs at least one active envelope.'**
  String get errLastEnvelope;

  /// No description provided for @errLastOwner.
  ///
  /// In en, this message translates to:
  /// **'A household needs at least one owner. Give the role to somebody else first.'**
  String get errLastOwner;

  /// No description provided for @errMemberFrozen.
  ///
  /// In en, this message translates to:
  /// **'You are frozen in this household: even out your share to spend again.'**
  String get errMemberFrozen;

  /// No description provided for @errNegativeShare.
  ///
  /// In en, this message translates to:
  /// **'A negative share has to be evened out first: {list}'**
  String errNegativeShare(String list);

  /// No description provided for @errNextPeriodOpen.
  ///
  /// In en, this message translates to:
  /// **'The next period is open already.'**
  String get errNextPeriodOpen;

  /// No description provided for @errNotEnoughMoney.
  ///
  /// In en, this message translates to:
  /// **'Not enough money. Available: {amount}.'**
  String errNotEnoughMoney(String amount);

  /// No description provided for @errPeriodClosed.
  ///
  /// In en, this message translates to:
  /// **'The period is closed: only the title of an expense can change.'**
  String get errPeriodClosed;

  /// No description provided for @errPeriodNotCurrent.
  ///
  /// In en, this message translates to:
  /// **'Money is spent only from the current period.'**
  String get errPeriodNotCurrent;

  /// No description provided for @errPlanBelowSpent.
  ///
  /// In en, this message translates to:
  /// **'A plan cannot be lower than what was spent.'**
  String get errPlanBelowSpent;

  /// No description provided for @errWalletNegative.
  ///
  /// In en, this message translates to:
  /// **'The wallet is below zero – transfers wait for the next income.'**
  String get errWalletNegative;

  /// No description provided for @estimated.
  ///
  /// In en, this message translates to:
  /// **'estimated'**
  String get estimated;

  /// No description provided for @estimatedExpenseRule.
  ///
  /// In en, this message translates to:
  /// **'Estimated amount (to confirm)'**
  String get estimatedExpenseRule;

  /// No description provided for @estimatedIncome.
  ///
  /// In en, this message translates to:
  /// **'Estimated (to confirm)'**
  String get estimatedIncome;

  /// No description provided for @estimatedIncomeRule.
  ///
  /// In en, this message translates to:
  /// **'Estimated: goes in with its estimate on the day'**
  String get estimatedIncomeRule;

  /// No description provided for @estimatedSpent.
  ///
  /// In en, this message translates to:
  /// **'of it estimated'**
  String get estimatedSpent;

  /// No description provided for @everyWeeksFrom.
  ///
  /// In en, this message translates to:
  /// **'{weeks, plural, =1{every week} other{every {weeks} weeks}} from {day}'**
  String everyWeeksFrom(int weeks, String day);

  /// No description provided for @expense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get expense;

  /// No description provided for @firstPeriodEnd.
  ///
  /// In en, this message translates to:
  /// **'End of the first period'**
  String get firstPeriodEnd;

  /// No description provided for @forAnybody.
  ///
  /// In en, this message translates to:
  /// **'For anybody'**
  String get forAnybody;

  /// No description provided for @forMember.
  ///
  /// In en, this message translates to:
  /// **'for {name}'**
  String forMember(String name);

  /// No description provided for @forWhom.
  ///
  /// In en, this message translates to:
  /// **'For whom'**
  String get forWhom;

  /// No description provided for @forWhomNobody.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get forWhomNobody;

  /// No description provided for @forWhomShared.
  ///
  /// In en, this message translates to:
  /// **'Shared'**
  String get forWhomShared;

  /// No description provided for @forecast.
  ///
  /// In en, this message translates to:
  /// **'Forecast to the end of the period'**
  String get forecast;

  /// No description provided for @forecastBalance.
  ///
  /// In en, this message translates to:
  /// **'Projected balance'**
  String get forecastBalance;

  /// No description provided for @forecastRecurring.
  ///
  /// In en, this message translates to:
  /// **'of it recurring'**
  String get forecastRecurring;

  /// No description provided for @forecastSpent.
  ///
  /// In en, this message translates to:
  /// **'Projected spending'**
  String get forecastSpent;

  /// No description provided for @freeMoney.
  ///
  /// In en, this message translates to:
  /// **'Free: {amount}'**
  String freeMoney(String amount);

  /// No description provided for @freeMoneyLabel.
  ///
  /// In en, this message translates to:
  /// **'Free money'**
  String get freeMoneyLabel;

  /// No description provided for @freeze.
  ///
  /// In en, this message translates to:
  /// **'Freeze'**
  String get freeze;

  /// No description provided for @frequency.
  ///
  /// In en, this message translates to:
  /// **'How often'**
  String get frequency;

  /// No description provided for @frozen.
  ///
  /// In en, this message translates to:
  /// **'frozen'**
  String get frozen;

  /// No description provided for @household.
  ///
  /// In en, this message translates to:
  /// **'Household'**
  String get household;

  /// No description provided for @householdSettings.
  ///
  /// In en, this message translates to:
  /// **'Household settings'**
  String get householdSettings;

  /// No description provided for @householdSpentInRange.
  ///
  /// In en, this message translates to:
  /// **'Spent: {amount}'**
  String householdSpentInRange(String amount);

  /// No description provided for @householdTab.
  ///
  /// In en, this message translates to:
  /// **'Household'**
  String get householdTab;

  /// No description provided for @invitationPending.
  ///
  /// In en, this message translates to:
  /// **'Waiting for an answer'**
  String get invitationPending;

  /// No description provided for @invitationTo.
  ///
  /// In en, this message translates to:
  /// **'Invitation to “{name}”'**
  String invitationTo(String name);

  /// No description provided for @invitedBy.
  ///
  /// In en, this message translates to:
  /// **'From {name}'**
  String invitedBy(String name);

  /// No description provided for @leaveBody.
  ///
  /// In en, this message translates to:
  /// **'You leave “{name}”. Take your shares back to the wallet? Otherwise they stay in the household as nobody\'s money.'**
  String leaveBody(String name);

  /// No description provided for @leaveHousehold.
  ///
  /// In en, this message translates to:
  /// **'Leave household'**
  String get leaveHousehold;

  /// No description provided for @leaveKeepShares.
  ///
  /// In en, this message translates to:
  /// **'Leave them'**
  String get leaveKeepShares;

  /// No description provided for @leaveWithdraw.
  ///
  /// In en, this message translates to:
  /// **'Take them back'**
  String get leaveWithdraw;

  /// No description provided for @leftAmount.
  ///
  /// In en, this message translates to:
  /// **'{amount} left'**
  String leftAmount(String amount);

  /// No description provided for @leftInPlan.
  ///
  /// In en, this message translates to:
  /// **'Left in the plan of “{name}”'**
  String leftInPlan(String name);

  /// No description provided for @logEmpty.
  ///
  /// In en, this message translates to:
  /// **'No changes in the open periods.'**
  String get logEmpty;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @monthlyOnDay.
  ///
  /// In en, this message translates to:
  /// **'monthly on day {day}'**
  String monthlyOnDay(int day);

  /// No description provided for @negativeShareHint.
  ///
  /// In en, this message translates to:
  /// **'A negative share: this person spent more than they put in.'**
  String get negativeShareHint;

  /// No description provided for @newHousehold.
  ///
  /// In en, this message translates to:
  /// **'New household'**
  String get newHousehold;

  /// No description provided for @nextPeriod.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextPeriod;

  /// No description provided for @noExpensesForFilters.
  ///
  /// In en, this message translates to:
  /// **'No expenses for the chosen filters'**
  String get noExpensesForFilters;

  /// No description provided for @noExpensesInPeriod.
  ///
  /// In en, this message translates to:
  /// **'No expenses in this period.'**
  String get noExpensesInPeriod;

  /// No description provided for @nobodysMoney.
  ///
  /// In en, this message translates to:
  /// **'Nobody\'s money'**
  String get nobodysMoney;

  /// No description provided for @openNextPeriod.
  ///
  /// In en, this message translates to:
  /// **'Open the next period'**
  String get openNextPeriod;

  /// No description provided for @periods.
  ///
  /// In en, this message translates to:
  /// **'Periods'**
  String get periods;

  /// No description provided for @piggyBalance.
  ///
  /// In en, this message translates to:
  /// **'Piggy bank balance'**
  String get piggyBalance;

  /// No description provided for @planOf.
  ///
  /// In en, this message translates to:
  /// **'Plan: {name}'**
  String planOf(String name);

  /// No description provided for @planRaised.
  ///
  /// In en, this message translates to:
  /// **'The plan went up by {amount} out of free money.'**
  String planRaised(String amount);

  /// No description provided for @planRecurringPart.
  ///
  /// In en, this message translates to:
  /// **'Of it from recurring expenses: {amount}'**
  String planRecurringPart(String amount);

  /// No description provided for @plansExceedBalance.
  ///
  /// In en, this message translates to:
  /// **'The plans exceed the balance of the household'**
  String get plansExceedBalance;

  /// No description provided for @plansTotal.
  ///
  /// In en, this message translates to:
  /// **'Plans in total'**
  String get plansTotal;

  /// No description provided for @rangeCustom.
  ///
  /// In en, this message translates to:
  /// **'A range of days'**
  String get rangeCustom;

  /// No description provided for @rangeMonth.
  ///
  /// In en, this message translates to:
  /// **'The current month'**
  String get rangeMonth;

  /// No description provided for @rangePeriod.
  ///
  /// In en, this message translates to:
  /// **'The period of the chosen household'**
  String get rangePeriod;

  /// No description provided for @recurringInPlan.
  ///
  /// In en, this message translates to:
  /// **'recurring {amount}'**
  String recurringInPlan(String amount);

  /// No description provided for @recurringIntro.
  ///
  /// In en, this message translates to:
  /// **'They run on their own when the app starts: incomes, then transfers, then expenses.'**
  String get recurringIntro;

  /// No description provided for @returnedFrom.
  ///
  /// In en, this message translates to:
  /// **'Share given back: {name}'**
  String returnedFrom(String name);

  /// No description provided for @revoke.
  ///
  /// In en, this message translates to:
  /// **'Revoke'**
  String get revoke;

  /// No description provided for @roleConfirm.
  ///
  /// In en, this message translates to:
  /// **'Change the role of {name}?'**
  String roleConfirm(String name);

  /// No description provided for @ruleExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get ruleExpense;

  /// No description provided for @ruleIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get ruleIncome;

  /// No description provided for @ruleTransfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get ruleTransfer;

  /// No description provided for @rulesExpenses.
  ///
  /// In en, this message translates to:
  /// **'Recurring expenses'**
  String get rulesExpenses;

  /// No description provided for @rulesIncomes.
  ///
  /// In en, this message translates to:
  /// **'Incomes into the wallet'**
  String get rulesIncomes;

  /// No description provided for @rulesTransfers.
  ///
  /// In en, this message translates to:
  /// **'Transfers into households'**
  String get rulesTransfers;

  /// No description provided for @shareOf.
  ///
  /// In en, this message translates to:
  /// **'share {amount}'**
  String shareOf(String amount);

  /// No description provided for @shares.
  ///
  /// In en, this message translates to:
  /// **'Shares'**
  String get shares;

  /// No description provided for @stepBring.
  ///
  /// In en, this message translates to:
  /// **'Bring {amount} from the wallet'**
  String stepBring(String amount);

  /// No description provided for @stepBringAndRaise.
  ///
  /// In en, this message translates to:
  /// **'Bring {amount} and raise the plan'**
  String stepBringAndRaise(String amount);

  /// No description provided for @stepNotEnoughBody.
  ///
  /// In en, this message translates to:
  /// **'There is only {amount} in the piggy bank.'**
  String stepNotEnoughBody(String amount);

  /// No description provided for @stepNotEnoughTitle.
  ///
  /// In en, this message translates to:
  /// **'Not enough in the piggy bank'**
  String get stepNotEnoughTitle;

  /// No description provided for @stepPlanTooSmallBody.
  ///
  /// In en, this message translates to:
  /// **'The plan of the envelope is {amount} short and there is no free money.'**
  String stepPlanTooSmallBody(String amount);

  /// No description provided for @stepPlanTooSmallTitle.
  ///
  /// In en, this message translates to:
  /// **'The plan has to go up'**
  String get stepPlanTooSmallTitle;

  /// No description provided for @stepRaiseOnly.
  ///
  /// In en, this message translates to:
  /// **'Only raise the plan'**
  String get stepRaiseOnly;

  /// No description provided for @stepWalletNegativeBody.
  ///
  /// In en, this message translates to:
  /// **'The wallet goes below zero: {amount}. No transfers until the next income.'**
  String stepWalletNegativeBody(String amount);

  /// No description provided for @stepWalletNegativeConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm the minus'**
  String get stepWalletNegativeConfirm;

  /// No description provided for @stepWalletNegativeTitle.
  ///
  /// In en, this message translates to:
  /// **'The wallet is short'**
  String get stepWalletNegativeTitle;

  /// No description provided for @takeOwner.
  ///
  /// In en, this message translates to:
  /// **'Take the owner role'**
  String get takeOwner;

  /// No description provided for @thisPeriod.
  ///
  /// In en, this message translates to:
  /// **'This period'**
  String get thisPeriod;

  /// No description provided for @titleOptional.
  ///
  /// In en, this message translates to:
  /// **'Title (optional)'**
  String get titleOptional;

  /// No description provided for @toNextPeriod.
  ///
  /// In en, this message translates to:
  /// **'to the next period'**
  String get toNextPeriod;

  /// No description provided for @toNextPeriodHint.
  ///
  /// In en, this message translates to:
  /// **'To the next period (e.g. pay on the 28th for the next month)'**
  String get toNextPeriodHint;

  /// No description provided for @todoAddExpense.
  ///
  /// In en, this message translates to:
  /// **'Add the expense'**
  String get todoAddExpense;

  /// No description provided for @todoConfirmAmount.
  ///
  /// In en, this message translates to:
  /// **'Confirm the amount'**
  String get todoConfirmAmount;

  /// No description provided for @todoDismiss.
  ///
  /// In en, this message translates to:
  /// **'Leave it'**
  String get todoDismiss;

  /// No description provided for @todoDo.
  ///
  /// In en, this message translates to:
  /// **'Do it'**
  String get todoDo;

  /// No description provided for @todoExpenseEstimate.
  ///
  /// In en, this message translates to:
  /// **'Estimated expense “{what}”: {amount}. Confirm the real amount before the period ends.'**
  String todoExpenseEstimate(String what, String amount);

  /// No description provided for @todoExpenseMissed.
  ///
  /// In en, this message translates to:
  /// **'“{what}” ({amount}) fell in a period that has closed.'**
  String todoExpenseMissed(String what, String amount);

  /// No description provided for @todoExpenseNotFit.
  ///
  /// In en, this message translates to:
  /// **'The recurring expense “{what}” ({amount}) does not fit the plan or the balance.'**
  String todoExpenseNotFit(String what, String amount);

  /// No description provided for @todoIncomeEstimate.
  ///
  /// In en, this message translates to:
  /// **'The income “{what}” went in with its estimate {amount}. Correct it.'**
  String todoIncomeEstimate(String what, String amount);

  /// No description provided for @todoTitle.
  ///
  /// In en, this message translates to:
  /// **'To do'**
  String get todoTitle;

  /// No description provided for @todoTransfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get todoTransfer;

  /// No description provided for @todoTransferNoMoney.
  ///
  /// In en, this message translates to:
  /// **'The recurring transfer “{what}” ({amount}) did not go: the wallet was short.'**
  String todoTransferNoMoney(String what, String amount);

  /// No description provided for @transfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get transfer;

  /// No description provided for @transferFromWallet.
  ///
  /// In en, this message translates to:
  /// **'Transfer from the wallet'**
  String get transferFromWallet;

  /// No description provided for @transferHint.
  ///
  /// In en, this message translates to:
  /// **'In the wallet: {amount}'**
  String transferHint(String amount);

  /// No description provided for @transferTo.
  ///
  /// In en, this message translates to:
  /// **'Transfer: {name}'**
  String transferTo(String name);

  /// No description provided for @transfers.
  ///
  /// In en, this message translates to:
  /// **'Transfers'**
  String get transfers;

  /// No description provided for @unarchive.
  ///
  /// In en, this message translates to:
  /// **'Bring back'**
  String get unarchive;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @unfreeze.
  ///
  /// In en, this message translates to:
  /// **'Unfreeze'**
  String get unfreeze;

  /// No description provided for @usedUnconfirmed.
  ///
  /// In en, this message translates to:
  /// **'Part of the transfer came from unconfirmed incomes.'**
  String get usedUnconfirmed;

  /// No description provided for @wallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get wallet;

  /// No description provided for @walletBalance.
  ///
  /// In en, this message translates to:
  /// **'Wallet balance'**
  String get walletBalance;

  /// No description provided for @walletEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet. Add the first income.'**
  String get walletEmpty;

  /// No description provided for @walletNegativeHint.
  ///
  /// In en, this message translates to:
  /// **'The wallet is below zero: transfers come back after the next income.'**
  String get walletNegativeHint;

  /// No description provided for @walletUnconfirmed.
  ///
  /// In en, this message translates to:
  /// **'of it unconfirmed: {amount}'**
  String walletUnconfirmed(String amount);

  /// No description provided for @walletUnconfirmedLabel.
  ///
  /// In en, this message translates to:
  /// **'of it unconfirmed'**
  String get walletUnconfirmedLabel;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Every N weeks'**
  String get weekly;

  /// No description provided for @withdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get withdraw;

  /// No description provided for @withdrawHint.
  ///
  /// In en, this message translates to:
  /// **'At most your share and at most what is in the piggy bank.'**
  String get withdrawHint;

  /// No description provided for @withdrawalFrom.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal: {name}'**
  String withdrawalFrom(String name);

  /// No description provided for @withdrawals.
  ///
  /// In en, this message translates to:
  /// **'Withdrawals'**
  String get withdrawals;

  /// No description provided for @wizardDoneBody.
  ///
  /// In en, this message translates to:
  /// **'All set. You can invite others later in “Members”.'**
  String get wizardDoneBody;

  /// No description provided for @wizardDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get wizardDoneTitle;

  /// No description provided for @wizardFinish.
  ///
  /// In en, this message translates to:
  /// **'To the dashboard'**
  String get wizardFinish;

  /// No description provided for @wizardHouseholdBody.
  ///
  /// In en, this message translates to:
  /// **'A household holds envelopes and periods – for you alone or several people.'**
  String get wizardHouseholdBody;

  /// No description provided for @wizardHouseholdTitle.
  ///
  /// In en, this message translates to:
  /// **'Your household'**
  String get wizardHouseholdTitle;

  /// No description provided for @wizardStep.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of {total}'**
  String wizardStep(int step, int total);

  /// No description provided for @wizardTitle.
  ///
  /// In en, this message translates to:
  /// **'Getting started'**
  String get wizardTitle;

  /// No description provided for @wizardTransferBody.
  ///
  /// In en, this message translates to:
  /// **'How much of the wallet ({amount}) goes into the current period?'**
  String wizardTransferBody(String amount);

  /// No description provided for @wizardTransferTitle.
  ///
  /// In en, this message translates to:
  /// **'Transfer to the household'**
  String get wizardTransferTitle;

  /// No description provided for @wizardEnvelopesTitle.
  ///
  /// In en, this message translates to:
  /// **'Envelopes'**
  String get wizardEnvelopesTitle;

  /// No description provided for @wizardEnvelopesBody.
  ///
  /// In en, this message translates to:
  /// **'Pick the first envelopes. You can change them later.'**
  String get wizardEnvelopesBody;

  /// No description provided for @wizardIncomeTitle.
  ///
  /// In en, this message translates to:
  /// **'The first income'**
  String get wizardIncomeTitle;

  /// No description provided for @wizardIncomeBody.
  ///
  /// In en, this message translates to:
  /// **'How much do you have to hand out? It goes into your private wallet.'**
  String get wizardIncomeBody;

  /// No description provided for @yourName.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get yourName;

  /// No description provided for @yourNameHint.
  ///
  /// In en, this message translates to:
  /// **'Other members of your households see it.'**
  String get yourNameHint;

  /// No description provided for @addEnvelope.
  ///
  /// In en, this message translates to:
  /// **'Add envelope'**
  String get addEnvelope;

  /// No description provided for @editEnvelope.
  ///
  /// In en, this message translates to:
  /// **'Edit envelope'**
  String get editEnvelope;

  /// No description provided for @editIncome.
  ///
  /// In en, this message translates to:
  /// **'Correct income'**
  String get editIncome;

  /// No description provided for @deleteIncome.
  ///
  /// In en, this message translates to:
  /// **'Delete income'**
  String get deleteIncome;

  /// No description provided for @deleteIncomeConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete the income of {amount}?'**
  String deleteIncomeConfirm(String amount);

  /// No description provided for @editRule.
  ///
  /// In en, this message translates to:
  /// **'Edit rule'**
  String get editRule;

  /// No description provided for @makeOwner.
  ///
  /// In en, this message translates to:
  /// **'Make owner'**
  String get makeOwner;

  /// No description provided for @removeMember.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeMember;

  /// No description provided for @removeMemberConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}? A positive share goes back to their wallet.'**
  String removeMemberConfirm(String name);

  /// No description provided for @roleOwner.
  ///
  /// In en, this message translates to:
  /// **'owner'**
  String get roleOwner;

  /// No description provided for @roleMember.
  ///
  /// In en, this message translates to:
  /// **'member'**
  String get roleMember;

  /// No description provided for @invite.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get invite;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @members.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get members;

  /// No description provided for @formerMember.
  ///
  /// In en, this message translates to:
  /// **'former member'**
  String get formerMember;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get income;

  /// No description provided for @addIncome.
  ///
  /// In en, this message translates to:
  /// **'Add income'**
  String get addIncome;
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
      <String>['en', 'pl'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pl':
      return AppLocalizationsPl();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
