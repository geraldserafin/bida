// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'PLNing';

  @override
  String get dashboardEmptyTitle => 'Your envelope budget lives here.';

  @override
  String get dashboardEmptyBody =>
      'Create a period and split your income to get started.';

  @override
  String get newPeriod => 'New period';

  @override
  String get addExpense => 'Add expense';

  @override
  String get envelopes => 'Envelopes';

  @override
  String get noEnvelopes => 'No categories allocated yet.';

  @override
  String get income => 'Income';

  @override
  String get planned => 'Planned';

  @override
  String get spent => 'Spent';

  @override
  String get unallocated => 'Unallocated';

  @override
  String get overAllocated => 'Over-allocated';

  @override
  String get remaining => 'Remaining';

  @override
  String remainingIn(String period) {
    return 'Remaining · $period';
  }

  @override
  String amountLeft(String amount) {
    return '$amount left';
  }

  @override
  String overBy(String amount) {
    return 'Over by $amount';
  }

  @override
  String get periodName => 'Period name';

  @override
  String get enterName => 'Enter a name';

  @override
  String get start => 'Start';

  @override
  String get end => 'End';

  @override
  String get incomeForPeriod => 'Income for this period';

  @override
  String get enterIncome => 'Enter your income';

  @override
  String get splitAcrossCategories => 'Split across categories';

  @override
  String overAllocationWarning(String amount) {
    return 'You\'ve allocated $amount more than your income. You can still continue.';
  }

  @override
  String get createPeriod => 'Create period';

  @override
  String get editPlan => 'Edit plan';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get noEnvelopesForExpense =>
      'This period has no envelopes yet. Add categories to the period before logging expenses.';

  @override
  String get envelope => 'Envelope';

  @override
  String get pickEnvelope => 'Pick an envelope';

  @override
  String get amount => 'Amount';

  @override
  String get enterAmount => 'Enter an amount';

  @override
  String get date => 'Date';

  @override
  String get noteOptional => 'Note (optional)';

  @override
  String get saveExpense => 'Save expense';

  @override
  String get editExpense => 'Edit expense';

  @override
  String get categories => 'Categories';

  @override
  String get manageCategories => 'Manage categories';

  @override
  String get newCategory => 'New category';

  @override
  String get editCategory => 'Edit category';

  @override
  String get name => 'Name';

  @override
  String get icon => 'Icon';

  @override
  String get color => 'Color';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get addCategory => 'Add category';

  @override
  String get noCategories => 'No categories yet. Add your first one.';

  @override
  String get categoryInUse =>
      'Can\'t delete a category that\'s used in a period.';

  @override
  String get period => 'Period';

  @override
  String get expenses => 'Expenses';

  @override
  String get noExpenses => 'No expenses in this envelope yet.';

  @override
  String get deleteExpense => 'Delete expense';

  @override
  String deleteExpenseConfirm(String amount) {
    return 'Delete this expense of $amount?';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get expenseDeleted => 'Expense deleted';

  @override
  String get plannedSplit => 'Planned split';

  @override
  String get plannedVsSpent => 'Planned vs. spent';

  @override
  String get spendingOverTime => 'Spending over time';

  @override
  String get notEnoughData => 'Not enough data yet.';

  @override
  String get recurringRules => 'Recurring rules';

  @override
  String get newRule => 'New rule';

  @override
  String get editRule => 'Edit rule';

  @override
  String get addRule => 'Add rule';

  @override
  String get category => 'Category';

  @override
  String get note => 'Note';

  @override
  String get frequency => 'Frequency';

  @override
  String get weekly => 'Weekly';

  @override
  String get monthly => 'Monthly';

  @override
  String get active => 'Active';

  @override
  String get noRecurringRules =>
      'No recurring rules yet. Add templates for regular income or expenses.';

  @override
  String get prefillFromRecurring => 'Pre-fill from recurring';

  @override
  String get applyRecurring => 'Add recurring to this period';

  @override
  String recurringApplied(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Added $count recurring expenses',
      one: 'Added 1 recurring expense',
      zero: 'Everything is already up to date',
    );
    return '$_temp0';
  }

  @override
  String get needCategoryFirst => 'Add a category first.';

  @override
  String get settings => 'Settings';

  @override
  String get security => 'Security';

  @override
  String get appLock => 'App lock (PIN)';

  @override
  String get appLockSubtitle => 'Require a PIN to open the app';

  @override
  String get changePin => 'Change PIN';

  @override
  String get biometricUnlock => 'Unlock with biometrics';

  @override
  String get setPin => 'Set PIN';

  @override
  String get enterPin => 'Enter PIN';

  @override
  String get confirmPin => 'Confirm PIN';

  @override
  String get pinTooShort => 'PIN must be at least 6 digits';

  @override
  String get pinsDontMatch => 'PINs don\'t match';

  @override
  String get wrongPin => 'Incorrect PIN';

  @override
  String get unlock => 'Unlock';

  @override
  String get unlockTitle => 'Enter your PIN';

  @override
  String get useBiometrics => 'Use biometrics';

  @override
  String get biometricReason => 'Authenticate to unlock Money Planner';

  @override
  String get pinSaved => 'PIN saved';

  @override
  String get lockDisabled => 'App lock disabled';

  @override
  String get general => 'General';

  @override
  String get appearance => 'Appearance';

  @override
  String get dataSection => 'Data';

  @override
  String get currency => 'Currency';

  @override
  String get firstDayOfMonth => 'First day of month';

  @override
  String get theme => 'Theme';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeLight => 'Light';

  @override
  String get themeAuto => 'Auto';

  @override
  String get exportCsv => 'Export data (CSV)';

  @override
  String get importCsv => 'Import from CSV';

  @override
  String importResult(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Imported $count expenses',
      one: 'Imported 1 expense',
      zero: 'No expenses to import',
    );
    return '$_temp0';
  }

  @override
  String importSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: ', skipped $count duplicates',
      one: ', skipped 1 duplicate',
    );
    return '$_temp0';
  }

  @override
  String get about => 'About';

  @override
  String csvExported(String path) {
    return 'Exported to $path';
  }

  @override
  String get today => 'Today';

  @override
  String get noteHint => 'e.g. Weekly groceries';

  @override
  String get addNew => 'New';

  @override
  String remainingInCategory(String category) {
    return 'Remaining in $category';
  }

  @override
  String get history => 'History';

  @override
  String get periods => 'Periods';

  @override
  String get all => 'All';

  @override
  String get dateRange => 'Date range';

  @override
  String get noMatchingExpenses => 'No expenses match the filters.';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get noPeriodsYet => 'No periods yet.';

  @override
  String get upcoming => 'Upcoming';

  @override
  String get currentSet => 'Current';

  @override
  String get earlier => 'Earlier';

  @override
  String get newExpense => 'New expense';

  @override
  String get deletePeriod => 'Delete period';

  @override
  String deletePeriodConfirm(String name) {
    return 'Delete \"$name\" and all its data?';
  }

  @override
  String get periodDeleted => 'Period deleted';

  @override
  String get dashboard => 'Dashboard';

  @override
  String periodRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get errorUnreachable =>
      'Can\'t reach the server. Check your connection and try again.';

  @override
  String get errorNotFound =>
      'That data no longer exists. It may have been changed on another device.';

  @override
  String get errorConflict =>
      'This conflicts with the data that is already there.';

  @override
  String get errorInvalid =>
      'The server did not accept these values. Check what you entered.';

  @override
  String get errorServer =>
      'Something went wrong on the server. Try again in a moment.';

  @override
  String get retry => 'Try again';

  @override
  String get loadFailed => 'Couldn\'t load your data';

  @override
  String get errorUnauthorized => 'You are signed out. Sign in again.';

  @override
  String get errorRateLimited => 'Too many tries. Wait a while and try again.';

  @override
  String get signInTitle => 'Sign in';

  @override
  String get signInSubtitle =>
      'Enter your e-mail address. We will send you a code and a link to sign in; there is no password.';

  @override
  String get emailAddress => 'E-mail address';

  @override
  String get enterValidEmail => 'Enter a valid e-mail address';

  @override
  String get sendCode => 'Send code';

  @override
  String codeSentTo(String email) {
    return 'We sent a code to $email. Enter it below.';
  }

  @override
  String get signInCode => 'Code';

  @override
  String get enterCode => 'Enter the 6-digit code';

  @override
  String get signInAction => 'Sign in';

  @override
  String get useOtherEmail => 'Use another address';

  @override
  String get resendCode => 'Send the code again';

  @override
  String get invalidCode => 'The code is wrong or has expired.';

  @override
  String get account => 'Account';

  @override
  String signedInAs(String email) {
    return 'Signed in as $email';
  }

  @override
  String get signOut => 'Sign out';

  @override
  String get signOutConfirm => 'Sign out of this device?';

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String get googleSignInFailed =>
      'Google sign-in did not work. Try again or use the e-mail code.';

  @override
  String get orSeparator => 'or';
}
