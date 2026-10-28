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
  String get addExpense => 'Add expense';

  @override
  String get envelopes => 'Envelopes';

  @override
  String get noEnvelopes => 'No envelopes yet.';

  @override
  String get income => 'Income';

  @override
  String get spent => 'Spent';

  @override
  String get overAllocated => 'Over-allocated';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get noEnvelopesForExpense =>
      'You have no envelopes yet. Add one before saving an expense.';

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
  String get spendingOverTime => 'Spending over time';

  @override
  String get notEnoughData => 'Not enough data yet.';

  @override
  String get newRule => 'New rule';

  @override
  String get editRule => 'Edit rule';

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
  String get history => 'History';

  @override
  String get all => 'All';

  @override
  String get dateRange => 'Date range';

  @override
  String get noMatchingExpenses => 'No expenses match the filters.';

  @override
  String get newExpense => 'New expense';

  @override
  String get dashboard => 'Dashboard';

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
  String get enterCode => 'Enter the 6-digit code';

  @override
  String get signInAction => 'Sign in';

  @override
  String get useOtherEmail => 'Use another address';

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
  String get addEnvelope => 'Add envelope';

  @override
  String get addIncome => 'Add income';

  @override
  String get addSubEnvelope => 'Add sub-envelope';

  @override
  String get allocate => 'Allocate';

  @override
  String get allocated => 'Allocated';

  @override
  String get allocationDeleted => 'Allocation deleted';

  @override
  String get allocations => 'Allocations';

  @override
  String get available => 'Available';

  @override
  String get balance => 'Balance';

  @override
  String balanceOfEnvelope(String envelope) {
    return 'Balance of $envelope';
  }

  @override
  String canTakeBack(String amount) {
    return 'Can take back: $amount';
  }

  @override
  String get deleteAllocation => 'Delete allocation';

  @override
  String deleteAllocationConfirm(String amount) {
    return 'Delete the allocation of $amount?';
  }

  @override
  String get deleteEnvelope => 'Delete envelope';

  @override
  String deleteEnvelopeConfirm(String name) {
    return 'Delete “$name” with its sub-envelopes, expenses and allocations? The money put into it goes back to the pool.';
  }

  @override
  String get deleteIncome => 'Delete income';

  @override
  String deleteIncomeConfirm(String amount) {
    return 'Delete the income of $amount?';
  }

  @override
  String get editEnvelope => 'Edit envelope';

  @override
  String get editIncome => 'Edit income';

  @override
  String get envelopeDeleted => 'Envelope deleted';

  @override
  String get firstDayOfMonthHint => 'Budget months start on this day';

  @override
  String get freeInEnvelope => 'Free in envelope';

  @override
  String get fromEarlierMonths => 'From earlier months';

  @override
  String get incomeDeleted => 'Income deleted';

  @override
  String get incomeNoteHint => 'e.g. Salary';

  @override
  String get incomes => 'Income';

  @override
  String get manageEnvelopes => 'Manage envelopes';

  @override
  String monthLine(String income, String allocated) {
    return 'Income $income · allocated $allocated';
  }

  @override
  String get months => 'Months';

  @override
  String get needEnvelopeFirst => 'Add an envelope first.';

  @override
  String get newEnvelope => 'New envelope';

  @override
  String get nextMonth => 'Next month';

  @override
  String get noAllocations => 'Nothing allocated yet.';

  @override
  String get noIncomes =>
      'No income yet. Add your first payday, then split it between envelopes.';

  @override
  String get noMonthsYet => 'No months yet.';

  @override
  String get noParent => 'None (top-level envelope)';

  @override
  String notEnoughMoney(String amount) {
    return 'Not enough money. Available: $amount.';
  }

  @override
  String get parentEnvelope => 'Parent envelope';

  @override
  String parentFreeCaption(String parent, String amount) {
    return 'Free in “$parent”: $amount';
  }

  @override
  String poolCaption(String amount) {
    return 'Unallocated: $amount';
  }

  @override
  String get previousMonth => 'Previous month';

  @override
  String get subEnvelopes => 'Sub-envelopes';

  @override
  String get takeBack => 'Take back';

  @override
  String get accept => 'Accept';

  @override
  String get alreadyMember =>
      'This address already belongs to a member of the envelope.';

  @override
  String get approve => 'Approve';

  @override
  String get awaitingAnswer => 'Waiting for an answer';

  @override
  String get awaitingApproval => 'Accepted, waiting for approval';

  @override
  String get decline => 'Decline';

  @override
  String get formerMember => 'Former member';

  @override
  String get invitationAccepted =>
      'Invitation accepted. An owner of the envelope still has to approve you.';

  @override
  String invitationBanner(String inviter, String envelope) {
    return '$inviter invites you to the envelope “$envelope”';
  }

  @override
  String get invitations => 'Invitations';

  @override
  String invitationSent(String email) {
    return 'Invitation sent to $email';
  }

  @override
  String get invite => 'Invite';

  @override
  String get inviteByEmail => 'Invite by e-mail';

  @override
  String get lastOwner =>
      'An envelope needs at least one owner. Make somebody else an owner first.';

  @override
  String get leave => 'Leave';

  @override
  String get leaveEnvelope => 'Leave the envelope';

  @override
  String leaveEnvelopeConfirm(String name) {
    return 'Leave “$name”? The money you put into it and your expenses in it stay.';
  }

  @override
  String get leftEnvelope => 'You left the envelope';

  @override
  String get limitReached =>
      'Limit reached: an envelope has up to 10 people, and you can send 10 invitations an hour.';

  @override
  String get makeMember => 'Make member';

  @override
  String get makeOwner => 'Make owner';

  @override
  String get members => 'Members';

  @override
  String membersOf(String name) {
    return 'Members · $name';
  }

  @override
  String get notShareable =>
      'Only a top-level envelope can be shared; sub-envelopes go with it.';

  @override
  String get reject => 'Turn down';

  @override
  String get remove => 'Remove';

  @override
  String get removeMember => 'Remove from the envelope';

  @override
  String removeMemberConfirm(String name) {
    return 'Remove $name from the envelope? The money they put in and their expenses stay in it.';
  }

  @override
  String get revokeInvitation => 'Revoke the invitation';

  @override
  String get role => 'Role';

  @override
  String get roleExplained =>
      'An owner manages the envelope and its members. A member adds expenses and puts in their own money.';

  @override
  String get roleMember => 'Member';

  @override
  String get roleOwner => 'Owner';

  @override
  String sharedWith(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people',
      one: 'only you',
    );
    return '$_temp0';
  }

  @override
  String get someone => 'Somebody';

  @override
  String get whoPutHowMuch => 'Who put how much';

  @override
  String get you => 'You';

  @override
  String youWith(String name) {
    return '$name (you)';
  }

  @override
  String get addPending => 'Add';

  @override
  String get appliedNothing => 'Everything is up to date';

  @override
  String appliedSummary(String parts) {
    return 'Added: $parts.';
  }

  @override
  String countAllocations(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count allocations',
      one: '$count allocation',
    );
    return '$_temp0';
  }

  @override
  String countExpenses(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count expenses',
      one: '$count expense',
    );
    return '$_temp0';
  }

  @override
  String countIncomes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count incomes',
      one: '$count income',
    );
    return '$_temp0';
  }

  @override
  String get dayOfMonth => 'Day of the month';

  @override
  String get editAllocationRule => 'Edit allocation rule';

  @override
  String get editIncomeRule => 'Edit recurring income';

  @override
  String everyMonthOn(int day) {
    return 'Every month on the $day.';
  }

  @override
  String get newAllocationRule => 'New allocation rule';

  @override
  String get newIncomeRule => 'New recurring income';

  @override
  String get noAllocationRules =>
      'No allocation rules. Add how much goes into an envelope every month, e.g. 1000 zł into Home.';

  @override
  String get noRecurringIncomes =>
      'No recurring income. Add a salary that comes in on the same day every month.';

  @override
  String pendingTitle(String parts) {
    return 'To add this month: $parts';
  }

  @override
  String skippedAllocations(int count) {
    return 'Allocations skipped for lack of money in the envelope: $count.';
  }

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
  String get unallocatedToEnvelopes => 'Not in any envelope';

  @override
  String get addIncomeShort => '+ Income';

  @override
  String get addExpenseShort => '+ Expense';

  @override
  String get soloSubtitle => 'Solo · just you';

  @override
  String get wizardStartTitle => 'Let\'s set up your budget';

  @override
  String get wizardStartBody =>
      'Five short steps: envelopes, sharing, income, bills and putting the money into envelopes.';

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
  String get currencyPln => 'PLN – złoty';

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
  String get wizardWhoTitle => 'Who will use the envelopes?';

  @override
  String get soloTitle => 'Just me · Solo';

  @override
  String get soloBody => 'A private budget. You can share it later.';

  @override
  String get multiTitle => 'With others · shared envelopes';

  @override
  String get multiBody =>
      'Everyone sees the same data. You\'ll say who each entry is for.';

  @override
  String get inviteHint => 'their@address.com';

  @override
  String get send => 'Send';

  @override
  String get wizardIncomeTitle => 'Where does the money come from?';

  @override
  String wizardIncomeBody(String period) {
    return 'This month: $period. Mark a salary as recurring – it is added every month when you apply the rules.';
  }

  @override
  String get newIncome => 'New income';

  @override
  String get incomeNameHint => 'e.g. Salary';

  @override
  String get addIncomeAction => 'Add income';

  @override
  String get wizardBillsTitle => 'Bills that come back every month';

  @override
  String get wizardBillsBody =>
      'Fixed ones like rent and variable ones like electricity. “Apply” adds them to every month.';

  @override
  String get addRecurringExpense => '+ Add a recurring expense';

  @override
  String get wizardEnvelopesTitle => 'Split the income into envelopes';

  @override
  String get wizardEnvelopesBody =>
      'How much money to put into each envelope. Amounts of recurring bills are filled in.';

  @override
  String fromRecurring(String amount) {
    return 'recurring: $amount';
  }

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
  String get saveIncome => 'Save income';

  @override
  String get incomeAdded => 'Income added';

  @override
  String get recurringMark => 'recurring';

  @override
  String get noTransactions => 'No expenses this month.';

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
  String get ruleOff => 'off';

  @override
  String get more => 'More';

  @override
  String get enterIncome => 'Enter your income';

  @override
  String get envelopesTab => 'Envelopes';

  @override
  String get newEnvelopePlus => '+ New envelope';

  @override
  String get addEnvelopePlus => '+ Add envelope';

  @override
  String get sharingPerEnvelope =>
      'An envelope can be shared with other people: open it and go to “Members”.';

  @override
  String sharedEnvelopes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count shared envelopes',
      one: '1 shared envelope',
    );
    return '$_temp0';
  }

  @override
  String get allocatedThisMonth => 'Put into envelopes this month';

  @override
  String get incomeGoesToPool =>
      'The money goes to the pool, from which you put it into envelopes.';

  @override
  String get recurringIncomeHint =>
      'The income shows up every month on this day when you apply the recurring rules.';

  @override
  String get recurringIncomeAdded => 'Recurring income added';

  @override
  String get wizardStartersTitle => 'What do you spend money on?';

  @override
  String get wizardStartersBody =>
      'Every kind of spending is an envelope. Untick the ones you don\'t need – you can add more at any time.';

  @override
  String get starterEnvelopes => 'Envelopes to start with';

  @override
  String get shareWhichEnvelope => 'Which envelope to share?';

  @override
  String invitedPeople(String emails) {
    return 'Invited: $emails. They get access once they accept and you approve.';
  }

  @override
  String get monthIncome => 'Income this month';

  @override
  String get repeatMonthly => 'Repeat every month';

  @override
  String get repeatMonthlyHint =>
      'These amounts go into the envelopes every month (allocation rules).';
}
