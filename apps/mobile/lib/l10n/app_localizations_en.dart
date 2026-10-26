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
  String get signInWithGoogle => 'Continue with Google';

  @override
  String get googleSignInFailed =>
      'Google sign-in did not work. Try again or use the e-mail code.';

  @override
  String get orSeparator => 'or';

  @override
  String get loginHeadline => 'Household budget,\ntogether or solo';

  @override
  String get loginSubtitle =>
      'Sign in with your e-mail – we\'ll send you a code. No password.';

  @override
  String get codeFieldLabel => 'Code from the e-mail (6 digits)';

  @override
  String get codeValidity =>
      'The code is valid for 15 minutes. Didn\'t get it?';

  @override
  String get resendShort => 'Send again';

  @override
  String get consent =>
      'I accept the information on processing my data (e-mail, name, budget data).';

  @override
  String get consentRequired => 'Tick the consent to sign in.';

  @override
  String get recurringTab => 'Recurring';

  @override
  String get householdTab => 'Household';

  @override
  String get incomes => 'Income';

  @override
  String get periodBalance => 'Period balance';

  @override
  String get unallocatedToEnvelopes => 'Not in any envelope';

  @override
  String get addIncomeShort => '+ Income';

  @override
  String get addExpenseShort => '+ Expense';

  @override
  String get soloSubtitle => 'Solo · just you';

  @override
  String get previousPeriod => 'Previous period';

  @override
  String get nextPeriod => 'Next period';

  @override
  String get wizardStartTitle => 'Let\'s set up your budget';

  @override
  String get wizardStartBody =>
      'Five short steps: name, people, income, bills and envelopes.';

  @override
  String get wizardStart => 'Let\'s start';

  @override
  String stepOf(int step, int total) {
    return 'Step $step of $total';
  }

  @override
  String get later => 'Later';

  @override
  String get next => 'Next';

  @override
  String get back => 'Back';

  @override
  String get wizardNameTitle => 'What will you call your household?';

  @override
  String get wizardNameBody =>
      'It can be “Home”, “The flat” or “Mine”. You can add more later.';

  @override
  String get currencyPln => 'PLN – złoty';

  @override
  String get starterCategories =>
      'We\'ll add these categories to start with – change them any time';

  @override
  String get starterFood => 'Food';

  @override
  String get starterHousing => 'Home and bills';

  @override
  String get starterTransport => 'Transport';

  @override
  String get starterHealth => 'Health';

  @override
  String get starterFun => 'Fun';

  @override
  String get starterClothes => 'Clothes';

  @override
  String get starterOther => 'Other';

  @override
  String wizardWhoTitle(String name) {
    return 'Who will use “$name”?';
  }

  @override
  String get soloTitle => 'Just me · Solo';

  @override
  String get soloBody => 'A private budget. You can share it later.';

  @override
  String get multiTitle => 'With others · Multi';

  @override
  String get multiBody =>
      'Everyone sees the same data. You\'ll say who each entry is for.';

  @override
  String get inviteByEmail => 'Invite by e-mail';

  @override
  String get inviteHint => 'name@example.com';

  @override
  String get send => 'Send';

  @override
  String get sharingSoon =>
      'Shared households and invitations are coming soon. For now the budget is just yours.';

  @override
  String get wizardIncomeTitle => 'Where does the money come from?';

  @override
  String wizardIncomeBody(String period) {
    return 'First period: $period. Enter an amount you don\'t know yet as an estimate – correct it once it arrives.';
  }

  @override
  String get newIncome => 'New income';

  @override
  String get fixedAmount => 'Fixed';

  @override
  String get estimatedAmount => 'Estimated';

  @override
  String get incomeNameHint => 'e.g. Salary';

  @override
  String get addIncomeAction => 'Add income';

  @override
  String get periodIncome => 'Period income';

  @override
  String get wizardBillsTitle => 'Bills that come back every month';

  @override
  String get wizardBillsBody =>
      'Fixed ones like rent and variable ones like electricity. “Apply” adds them to every period.';

  @override
  String get addRecurringExpense => '+ Add a recurring expense';

  @override
  String get wizardEnvelopesTitle => 'Split the income into envelopes';

  @override
  String get wizardEnvelopesBody =>
      'How much you plan to spend in each category this period. Amounts of recurring bills are filled in.';

  @override
  String fromRecurring(String amount) {
    return 'recurring: $amount';
  }

  @override
  String get addCategoryPlus => '+ Add a category';

  @override
  String get allocated => 'Allocated';

  @override
  String get unallocatedShort => 'Unallocated';

  @override
  String get wizardDone => 'Done – go to the dashboard';

  @override
  String get everyMonth => 'every month';

  @override
  String get everyWeek => 'every week';

  @override
  String get descriptionOptional => 'Description (optional)';

  @override
  String get descriptionHint => 'e.g. groceries';

  @override
  String get oneOff => 'One-off';

  @override
  String get recurringIncome => 'Recurring';

  @override
  String get recurringIncomeSoon => 'Recurring income is coming soon.';

  @override
  String incomeGoesTo(String period) {
    return 'The income is added to $period.';
  }

  @override
  String get saveIncome => 'Save income';

  @override
  String get incomeAdded => 'Income added';

  @override
  String get recurringMark => 'recurring';

  @override
  String get noTransactions => 'No expenses in this period.';

  @override
  String get newRulePlus => '+ New rule';

  @override
  String applyTo(String period) {
    return 'Apply to $period';
  }

  @override
  String get applyHint =>
      'Adds entries of the active rules. Ones already added aren\'t doubled.';

  @override
  String get ruleFixed => 'fixed';

  @override
  String get ruleOff => 'off';

  @override
  String get households => 'Households';

  @override
  String get newHouseholdPlus => '+ New household';

  @override
  String membersOf(String name) {
    return 'Members · $name';
  }

  @override
  String youMark(String name) {
    return '$name (you)';
  }

  @override
  String get owner => 'owner';

  @override
  String get invitePerson => 'Invite someone';

  @override
  String get more => 'More';

  @override
  String get renameHousehold => 'Rename';

  @override
  String get householdName => 'Household name';
}
