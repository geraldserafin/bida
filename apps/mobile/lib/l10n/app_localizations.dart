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

  /// No description provided for @addExpense.
  ///
  /// In en, this message translates to:
  /// **'Add expense'**
  String get addExpense;

  /// No description provided for @envelopes.
  ///
  /// In en, this message translates to:
  /// **'Envelopes'**
  String get envelopes;

  /// No description provided for @noEnvelopes.
  ///
  /// In en, this message translates to:
  /// **'No envelopes yet.'**
  String get noEnvelopes;

  /// No description provided for @income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get income;

  /// No description provided for @spent.
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get spent;

  /// No description provided for @overAllocated.
  ///
  /// In en, this message translates to:
  /// **'Over-allocated'**
  String get overAllocated;

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

  /// No description provided for @pickEnvelope.
  ///
  /// In en, this message translates to:
  /// **'Pick an envelope'**
  String get pickEnvelope;

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

  /// No description provided for @noteOptional.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get noteOptional;

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

  /// No description provided for @icon.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get icon;

  /// No description provided for @color.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get color;

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

  /// No description provided for @expenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expenses;

  /// No description provided for @noExpenses.
  ///
  /// In en, this message translates to:
  /// **'No expenses in this envelope yet.'**
  String get noExpenses;

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

  /// No description provided for @expenseDeleted.
  ///
  /// In en, this message translates to:
  /// **'Expense deleted'**
  String get expenseDeleted;

  /// No description provided for @spendingOverTime.
  ///
  /// In en, this message translates to:
  /// **'Spending over time'**
  String get spendingOverTime;

  /// No description provided for @notEnoughData.
  ///
  /// In en, this message translates to:
  /// **'Not enough data yet.'**
  String get notEnoughData;

  /// No description provided for @newRule.
  ///
  /// In en, this message translates to:
  /// **'New rule'**
  String get newRule;

  /// No description provided for @editRule.
  ///
  /// In en, this message translates to:
  /// **'Edit rule'**
  String get editRule;

  /// No description provided for @frequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get frequency;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @noRecurringRules.
  ///
  /// In en, this message translates to:
  /// **'No recurring rules yet. Add templates for regular income or expenses.'**
  String get noRecurringRules;

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

  /// No description provided for @dataSection.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get dataSection;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @firstDayOfMonth.
  ///
  /// In en, this message translates to:
  /// **'First day of month'**
  String get firstDayOfMonth;

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

  /// No description provided for @exportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export data (CSV)'**
  String get exportCsv;

  /// No description provided for @importCsv.
  ///
  /// In en, this message translates to:
  /// **'Import from CSV'**
  String get importCsv;

  /// No description provided for @importResult.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No expenses to import} =1{Imported 1 expense} other{Imported {count} expenses}}'**
  String importResult(int count);

  /// No description provided for @importSkipped.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{, skipped 1 duplicate} other{, skipped {count} duplicates}}'**
  String importSkipped(int count);

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @csvExported.
  ///
  /// In en, this message translates to:
  /// **'Exported to {path}'**
  String csvExported(String path);

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @noteHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Weekly groceries'**
  String get noteHint;

  /// No description provided for @addNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get addNew;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @dateRange.
  ///
  /// In en, this message translates to:
  /// **'Date range'**
  String get dateRange;

  /// No description provided for @noMatchingExpenses.
  ///
  /// In en, this message translates to:
  /// **'No expenses match the filters.'**
  String get noMatchingExpenses;

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

  /// No description provided for @addEnvelope.
  ///
  /// In en, this message translates to:
  /// **'Add envelope'**
  String get addEnvelope;

  /// No description provided for @addIncome.
  ///
  /// In en, this message translates to:
  /// **'Add income'**
  String get addIncome;

  /// No description provided for @addSubEnvelope.
  ///
  /// In en, this message translates to:
  /// **'Add sub-envelope'**
  String get addSubEnvelope;

  /// No description provided for @allocate.
  ///
  /// In en, this message translates to:
  /// **'Allocate'**
  String get allocate;

  /// No description provided for @allocated.
  ///
  /// In en, this message translates to:
  /// **'Allocated'**
  String get allocated;

  /// No description provided for @allocationDeleted.
  ///
  /// In en, this message translates to:
  /// **'Allocation deleted'**
  String get allocationDeleted;

  /// No description provided for @allocations.
  ///
  /// In en, this message translates to:
  /// **'Allocations'**
  String get allocations;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @balance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balance;

  /// No description provided for @balanceOfEnvelope.
  ///
  /// In en, this message translates to:
  /// **'Balance of {envelope}'**
  String balanceOfEnvelope(String envelope);

  /// No description provided for @canTakeBack.
  ///
  /// In en, this message translates to:
  /// **'Can take back: {amount}'**
  String canTakeBack(String amount);

  /// No description provided for @deleteAllocation.
  ///
  /// In en, this message translates to:
  /// **'Delete allocation'**
  String get deleteAllocation;

  /// No description provided for @deleteAllocationConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete the allocation of {amount}?'**
  String deleteAllocationConfirm(String amount);

  /// No description provided for @deleteEnvelope.
  ///
  /// In en, this message translates to:
  /// **'Delete envelope'**
  String get deleteEnvelope;

  /// No description provided for @deleteEnvelopeConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete “{name}” with its sub-envelopes, expenses and allocations? The money put into it goes back to the pool.'**
  String deleteEnvelopeConfirm(String name);

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

  /// No description provided for @editEnvelope.
  ///
  /// In en, this message translates to:
  /// **'Edit envelope'**
  String get editEnvelope;

  /// No description provided for @editIncome.
  ///
  /// In en, this message translates to:
  /// **'Edit income'**
  String get editIncome;

  /// No description provided for @envelopeDeleted.
  ///
  /// In en, this message translates to:
  /// **'Envelope deleted'**
  String get envelopeDeleted;

  /// No description provided for @firstDayOfMonthHint.
  ///
  /// In en, this message translates to:
  /// **'Budget months start on this day'**
  String get firstDayOfMonthHint;

  /// No description provided for @freeInEnvelope.
  ///
  /// In en, this message translates to:
  /// **'Free in envelope'**
  String get freeInEnvelope;

  /// No description provided for @fromEarlierMonths.
  ///
  /// In en, this message translates to:
  /// **'From earlier months'**
  String get fromEarlierMonths;

  /// No description provided for @incomeDeleted.
  ///
  /// In en, this message translates to:
  /// **'Income deleted'**
  String get incomeDeleted;

  /// No description provided for @incomeNoteHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Salary'**
  String get incomeNoteHint;

  /// No description provided for @incomes.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get incomes;

  /// No description provided for @manageEnvelopes.
  ///
  /// In en, this message translates to:
  /// **'Manage envelopes'**
  String get manageEnvelopes;

  /// No description provided for @monthLine.
  ///
  /// In en, this message translates to:
  /// **'Income {income} · allocated {allocated}'**
  String monthLine(String income, String allocated);

  /// No description provided for @months.
  ///
  /// In en, this message translates to:
  /// **'Months'**
  String get months;

  /// No description provided for @needEnvelopeFirst.
  ///
  /// In en, this message translates to:
  /// **'Add an envelope first.'**
  String get needEnvelopeFirst;

  /// No description provided for @newEnvelope.
  ///
  /// In en, this message translates to:
  /// **'New envelope'**
  String get newEnvelope;

  /// No description provided for @nextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get nextMonth;

  /// No description provided for @noAllocations.
  ///
  /// In en, this message translates to:
  /// **'Nothing allocated yet.'**
  String get noAllocations;

  /// No description provided for @noIncomes.
  ///
  /// In en, this message translates to:
  /// **'No income yet. Add your first payday, then split it between envelopes.'**
  String get noIncomes;

  /// No description provided for @noMonthsYet.
  ///
  /// In en, this message translates to:
  /// **'No months yet.'**
  String get noMonthsYet;

  /// No description provided for @noParent.
  ///
  /// In en, this message translates to:
  /// **'None (top-level envelope)'**
  String get noParent;

  /// No description provided for @notEnoughMoney.
  ///
  /// In en, this message translates to:
  /// **'Not enough money. Available: {amount}.'**
  String notEnoughMoney(String amount);

  /// No description provided for @parentEnvelope.
  ///
  /// In en, this message translates to:
  /// **'Parent envelope'**
  String get parentEnvelope;

  /// No description provided for @parentFreeCaption.
  ///
  /// In en, this message translates to:
  /// **'Free in “{parent}”: {amount}'**
  String parentFreeCaption(String parent, String amount);

  /// No description provided for @poolCaption.
  ///
  /// In en, this message translates to:
  /// **'Unallocated: {amount}'**
  String poolCaption(String amount);

  /// No description provided for @previousMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get previousMonth;

  /// No description provided for @subEnvelopes.
  ///
  /// In en, this message translates to:
  /// **'Sub-envelopes'**
  String get subEnvelopes;

  /// No description provided for @takeBack.
  ///
  /// In en, this message translates to:
  /// **'Take back'**
  String get takeBack;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @alreadyMember.
  ///
  /// In en, this message translates to:
  /// **'This address already belongs to a member of the envelope.'**
  String get alreadyMember;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @awaitingAnswer.
  ///
  /// In en, this message translates to:
  /// **'Waiting for an answer'**
  String get awaitingAnswer;

  /// No description provided for @awaitingApproval.
  ///
  /// In en, this message translates to:
  /// **'Accepted, waiting for approval'**
  String get awaitingApproval;

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @formerMember.
  ///
  /// In en, this message translates to:
  /// **'Former member'**
  String get formerMember;

  /// No description provided for @invitationAccepted.
  ///
  /// In en, this message translates to:
  /// **'Invitation accepted. An owner of the envelope still has to approve you.'**
  String get invitationAccepted;

  /// No description provided for @invitationBanner.
  ///
  /// In en, this message translates to:
  /// **'{inviter} invites you to the envelope “{envelope}”'**
  String invitationBanner(String inviter, String envelope);

  /// No description provided for @invitations.
  ///
  /// In en, this message translates to:
  /// **'Invitations'**
  String get invitations;

  /// No description provided for @invitationSent.
  ///
  /// In en, this message translates to:
  /// **'Invited {email}. They will see the invitation in the app once signed in with that address.'**
  String invitationSent(String email);

  /// No description provided for @invite.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get invite;

  /// No description provided for @inviteByEmail.
  ///
  /// In en, this message translates to:
  /// **'Invite by e-mail'**
  String get inviteByEmail;

  /// No description provided for @lastOwner.
  ///
  /// In en, this message translates to:
  /// **'An envelope needs at least one owner. Make somebody else an owner first.'**
  String get lastOwner;

  /// No description provided for @leave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leave;

  /// No description provided for @leaveEnvelope.
  ///
  /// In en, this message translates to:
  /// **'Leave the envelope'**
  String get leaveEnvelope;

  /// No description provided for @leaveEnvelopeConfirm.
  ///
  /// In en, this message translates to:
  /// **'Leave “{name}”? The money you put into it and your expenses in it stay.'**
  String leaveEnvelopeConfirm(String name);

  /// No description provided for @leftEnvelope.
  ///
  /// In en, this message translates to:
  /// **'You left the envelope'**
  String get leftEnvelope;

  /// No description provided for @limitReached.
  ///
  /// In en, this message translates to:
  /// **'Limit reached: an envelope has up to 10 people, and you can send 10 invitations an hour.'**
  String get limitReached;

  /// No description provided for @makeMember.
  ///
  /// In en, this message translates to:
  /// **'Make member'**
  String get makeMember;

  /// No description provided for @makeOwner.
  ///
  /// In en, this message translates to:
  /// **'Make owner'**
  String get makeOwner;

  /// No description provided for @members.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get members;

  /// No description provided for @membersOf.
  ///
  /// In en, this message translates to:
  /// **'Members · {name}'**
  String membersOf(String name);

  /// No description provided for @notShareable.
  ///
  /// In en, this message translates to:
  /// **'Only a top-level envelope can be shared; sub-envelopes go with it.'**
  String get notShareable;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Turn down'**
  String get reject;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @removeMember.
  ///
  /// In en, this message translates to:
  /// **'Remove from the envelope'**
  String get removeMember;

  /// No description provided for @removeMemberConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} from the envelope? The money they put in and their expenses stay in it.'**
  String removeMemberConfirm(String name);

  /// No description provided for @revokeInvitation.
  ///
  /// In en, this message translates to:
  /// **'Revoke the invitation'**
  String get revokeInvitation;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @roleExplained.
  ///
  /// In en, this message translates to:
  /// **'An owner manages the envelope and its members. A member adds expenses and puts in their own money.'**
  String get roleExplained;

  /// No description provided for @roleMember.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get roleMember;

  /// No description provided for @roleOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get roleOwner;

  /// No description provided for @sharedWith.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{only you} other{{count} people}}'**
  String sharedWith(int count);

  /// No description provided for @someone.
  ///
  /// In en, this message translates to:
  /// **'Somebody'**
  String get someone;

  /// No description provided for @whoPutHowMuch.
  ///
  /// In en, this message translates to:
  /// **'Who put how much'**
  String get whoPutHowMuch;

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// No description provided for @youWith.
  ///
  /// In en, this message translates to:
  /// **'{name} (you)'**
  String youWith(String name);

  /// No description provided for @addPending.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addPending;

  /// No description provided for @appliedNothing.
  ///
  /// In en, this message translates to:
  /// **'Everything is up to date'**
  String get appliedNothing;

  /// No description provided for @appliedSummary.
  ///
  /// In en, this message translates to:
  /// **'Added: {parts}.'**
  String appliedSummary(String parts);

  /// No description provided for @countAllocations.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} allocation} other{{count} allocations}}'**
  String countAllocations(int count);

  /// No description provided for @countExpenses.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} expense} other{{count} expenses}}'**
  String countExpenses(int count);

  /// No description provided for @countIncomes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} income} other{{count} incomes}}'**
  String countIncomes(int count);

  /// No description provided for @dayOfMonth.
  ///
  /// In en, this message translates to:
  /// **'Day of the month'**
  String get dayOfMonth;

  /// No description provided for @editAllocationRule.
  ///
  /// In en, this message translates to:
  /// **'Edit allocation rule'**
  String get editAllocationRule;

  /// No description provided for @editIncomeRule.
  ///
  /// In en, this message translates to:
  /// **'Edit recurring income'**
  String get editIncomeRule;

  /// No description provided for @everyMonthOn.
  ///
  /// In en, this message translates to:
  /// **'Every month on the {day}.'**
  String everyMonthOn(int day);

  /// No description provided for @newAllocationRule.
  ///
  /// In en, this message translates to:
  /// **'New allocation rule'**
  String get newAllocationRule;

  /// No description provided for @newIncomeRule.
  ///
  /// In en, this message translates to:
  /// **'New recurring income'**
  String get newIncomeRule;

  /// No description provided for @noAllocationRules.
  ///
  /// In en, this message translates to:
  /// **'No allocation rules. Add how much goes into an envelope every month, e.g. 1000 zł into Home.'**
  String get noAllocationRules;

  /// No description provided for @noRecurringIncomes.
  ///
  /// In en, this message translates to:
  /// **'No recurring income. Add a salary that comes in on the same day every month.'**
  String get noRecurringIncomes;

  /// No description provided for @pendingTitle.
  ///
  /// In en, this message translates to:
  /// **'To add this month: {parts}'**
  String pendingTitle(String parts);

  /// No description provided for @skippedAllocations.
  ///
  /// In en, this message translates to:
  /// **'Allocations skipped for lack of money in the envelope: {count}.'**
  String skippedAllocations(int count);

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

  /// No description provided for @unallocatedToEnvelopes.
  ///
  /// In en, this message translates to:
  /// **'Not in any envelope'**
  String get unallocatedToEnvelopes;

  /// No description provided for @addIncomeShort.
  ///
  /// In en, this message translates to:
  /// **'+ Income'**
  String get addIncomeShort;

  /// No description provided for @addExpenseShort.
  ///
  /// In en, this message translates to:
  /// **'+ Expense'**
  String get addExpenseShort;

  /// No description provided for @soloSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Solo · just you'**
  String get soloSubtitle;

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

  /// No description provided for @stepOf.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of {total}'**
  String stepOf(int step, int total);

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

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @currencyPln.
  ///
  /// In en, this message translates to:
  /// **'PLN – złoty'**
  String get currencyPln;

  /// No description provided for @starterFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get starterFood;

  /// No description provided for @starterHousing.
  ///
  /// In en, this message translates to:
  /// **'Home and bills'**
  String get starterHousing;

  /// No description provided for @starterTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get starterTransport;

  /// No description provided for @starterHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get starterHealth;

  /// No description provided for @starterFun.
  ///
  /// In en, this message translates to:
  /// **'Fun'**
  String get starterFun;

  /// No description provided for @starterClothes.
  ///
  /// In en, this message translates to:
  /// **'Clothes'**
  String get starterClothes;

  /// No description provided for @starterOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get starterOther;

  /// No description provided for @wizardWhoTitle.
  ///
  /// In en, this message translates to:
  /// **'Who will use the envelopes?'**
  String get wizardWhoTitle;

  /// No description provided for @soloTitle.
  ///
  /// In en, this message translates to:
  /// **'Just me · Solo'**
  String get soloTitle;

  /// No description provided for @soloBody.
  ///
  /// In en, this message translates to:
  /// **'A private budget. You can share it later.'**
  String get soloBody;

  /// No description provided for @multiTitle.
  ///
  /// In en, this message translates to:
  /// **'With others · shared envelopes'**
  String get multiTitle;

  /// No description provided for @multiBody.
  ///
  /// In en, this message translates to:
  /// **'Everyone sees the same data. You\'ll say who each entry is for.'**
  String get multiBody;

  /// No description provided for @inviteHint.
  ///
  /// In en, this message translates to:
  /// **'their@address.com'**
  String get inviteHint;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @wizardIncomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Where does the money come from?'**
  String get wizardIncomeTitle;

  /// No description provided for @wizardIncomeBody.
  ///
  /// In en, this message translates to:
  /// **'This month: {period}. Mark a salary as recurring – it is added every month when you apply the rules.'**
  String wizardIncomeBody(String period);

  /// No description provided for @newIncome.
  ///
  /// In en, this message translates to:
  /// **'New income'**
  String get newIncome;

  /// No description provided for @incomeNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Salary'**
  String get incomeNameHint;

  /// No description provided for @addIncomeAction.
  ///
  /// In en, this message translates to:
  /// **'Add income'**
  String get addIncomeAction;

  /// No description provided for @wizardBillsTitle.
  ///
  /// In en, this message translates to:
  /// **'Bills that come back every month'**
  String get wizardBillsTitle;

  /// No description provided for @wizardBillsBody.
  ///
  /// In en, this message translates to:
  /// **'Fixed ones like rent and variable ones like electricity. “Apply” adds them to every month.'**
  String get wizardBillsBody;

  /// No description provided for @addRecurringExpense.
  ///
  /// In en, this message translates to:
  /// **'+ Add a recurring expense'**
  String get addRecurringExpense;

  /// No description provided for @wizardEnvelopesTitle.
  ///
  /// In en, this message translates to:
  /// **'Split the income into envelopes'**
  String get wizardEnvelopesTitle;

  /// No description provided for @wizardEnvelopesBody.
  ///
  /// In en, this message translates to:
  /// **'How much money to put into each envelope. Amounts of recurring bills are filled in.'**
  String get wizardEnvelopesBody;

  /// No description provided for @fromRecurring.
  ///
  /// In en, this message translates to:
  /// **'recurring: {amount}'**
  String fromRecurring(String amount);

  /// No description provided for @unallocatedShort.
  ///
  /// In en, this message translates to:
  /// **'Unallocated'**
  String get unallocatedShort;

  /// No description provided for @wizardDone.
  ///
  /// In en, this message translates to:
  /// **'Done – go to the dashboard'**
  String get wizardDone;

  /// No description provided for @everyMonth.
  ///
  /// In en, this message translates to:
  /// **'every month'**
  String get everyMonth;

  /// No description provided for @everyWeek.
  ///
  /// In en, this message translates to:
  /// **'every week'**
  String get everyWeek;

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

  /// No description provided for @oneOff.
  ///
  /// In en, this message translates to:
  /// **'One-off'**
  String get oneOff;

  /// No description provided for @recurringIncome.
  ///
  /// In en, this message translates to:
  /// **'Recurring'**
  String get recurringIncome;

  /// No description provided for @saveIncome.
  ///
  /// In en, this message translates to:
  /// **'Save income'**
  String get saveIncome;

  /// No description provided for @incomeAdded.
  ///
  /// In en, this message translates to:
  /// **'Income added'**
  String get incomeAdded;

  /// No description provided for @recurringMark.
  ///
  /// In en, this message translates to:
  /// **'recurring'**
  String get recurringMark;

  /// No description provided for @noTransactions.
  ///
  /// In en, this message translates to:
  /// **'No expenses this month.'**
  String get noTransactions;

  /// No description provided for @newRulePlus.
  ///
  /// In en, this message translates to:
  /// **'+ New rule'**
  String get newRulePlus;

  /// No description provided for @applyTo.
  ///
  /// In en, this message translates to:
  /// **'Apply to {period}'**
  String applyTo(String period);

  /// No description provided for @applyHint.
  ///
  /// In en, this message translates to:
  /// **'Adds entries of the active rules. Ones already added aren\'t doubled.'**
  String get applyHint;

  /// No description provided for @ruleOff.
  ///
  /// In en, this message translates to:
  /// **'off'**
  String get ruleOff;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @enterIncome.
  ///
  /// In en, this message translates to:
  /// **'Enter your income'**
  String get enterIncome;

  /// No description provided for @envelopesTab.
  ///
  /// In en, this message translates to:
  /// **'Envelopes'**
  String get envelopesTab;

  /// No description provided for @newEnvelopePlus.
  ///
  /// In en, this message translates to:
  /// **'+ New envelope'**
  String get newEnvelopePlus;

  /// No description provided for @addEnvelopePlus.
  ///
  /// In en, this message translates to:
  /// **'+ Add envelope'**
  String get addEnvelopePlus;

  /// No description provided for @sharingPerEnvelope.
  ///
  /// In en, this message translates to:
  /// **'An envelope can be shared with other people: open it and go to “Members”.'**
  String get sharingPerEnvelope;

  /// No description provided for @sharedEnvelopes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 shared envelope} other{{count} shared envelopes}}'**
  String sharedEnvelopes(int count);

  /// No description provided for @allocatedThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Put into envelopes this month'**
  String get allocatedThisMonth;

  /// No description provided for @incomeGoesToPool.
  ///
  /// In en, this message translates to:
  /// **'The money goes to the pool, from which you put it into envelopes.'**
  String get incomeGoesToPool;

  /// No description provided for @recurringIncomeHint.
  ///
  /// In en, this message translates to:
  /// **'The income shows up every month on this day when you apply the recurring rules.'**
  String get recurringIncomeHint;

  /// No description provided for @recurringIncomeAdded.
  ///
  /// In en, this message translates to:
  /// **'Recurring income added'**
  String get recurringIncomeAdded;

  /// No description provided for @wizardStartersTitle.
  ///
  /// In en, this message translates to:
  /// **'What do you spend money on?'**
  String get wizardStartersTitle;

  /// No description provided for @wizardStartersBody.
  ///
  /// In en, this message translates to:
  /// **'Every kind of spending is an envelope. Untick the ones you don\'t need – you can add more at any time.'**
  String get wizardStartersBody;

  /// No description provided for @starterEnvelopes.
  ///
  /// In en, this message translates to:
  /// **'Envelopes to start with'**
  String get starterEnvelopes;

  /// No description provided for @shareWhichEnvelope.
  ///
  /// In en, this message translates to:
  /// **'Which envelope to share?'**
  String get shareWhichEnvelope;

  /// No description provided for @invitedPeople.
  ///
  /// In en, this message translates to:
  /// **'Invited: {emails}. They get access once they accept and you approve.'**
  String invitedPeople(String emails);

  /// No description provided for @monthIncome.
  ///
  /// In en, this message translates to:
  /// **'Income this month'**
  String get monthIncome;

  /// No description provided for @repeatMonthly.
  ///
  /// In en, this message translates to:
  /// **'Repeat every month'**
  String get repeatMonthly;

  /// No description provided for @repeatMonthlyHint.
  ///
  /// In en, this message translates to:
  /// **'These amounts go into the envelopes every month (allocation rules).'**
  String get repeatMonthlyHint;
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
