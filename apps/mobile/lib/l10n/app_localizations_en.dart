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
  String get envelopes => 'Envelopes';

  @override
  String get spent => 'Spent';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get noEnvelopesForExpense =>
      'You have no envelopes yet. Add one before saving an expense.';

  @override
  String get envelope => 'Envelope';

  @override
  String get amount => 'Amount';

  @override
  String get enterAmount => 'Enter an amount';

  @override
  String get date => 'Date';

  @override
  String get saveExpense => 'Save expense';

  @override
  String get editExpense => 'Edit expense';

  @override
  String get name => 'Name';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get deleteExpense => 'Delete expense';

  @override
  String deleteExpenseConfirm(String amount) {
    return 'Delete this expense of $amount?';
  }

  @override
  String get cancel => 'Cancel';

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
  String get theme => 'Theme';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeLight => 'Light';

  @override
  String get themeAuto => 'Auto';

  @override
  String get about => 'About';

  @override
  String get history => 'History';

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
  String get manageEnvelopes => 'Manage envelopes';

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
  String get addExpenseShort => '+ Expense';

  @override
  String get wizardStartTitle => 'Let\'s set up your budget';

  @override
  String get wizardStartBody =>
      'Five short steps: envelopes, sharing, income, bills and putting the money into envelopes.';

  @override
  String get wizardStart => 'Let\'s start';

  @override
  String get descriptionOptional => 'Description (optional)';

  @override
  String get descriptionHint => 'e.g. groceries';

  @override
  String get addRule => 'Add a rule';

  @override
  String get allEnvelopes => 'All envelopes';

  @override
  String get allPeriods => 'All periods';

  @override
  String get anyAuthor => 'Any author';

  @override
  String get appliedToTodo => 'It did not fit and went to the to-do list.';

  @override
  String applyAllExpenses(String name) {
    return 'Apply all recurring expenses: $name';
  }

  @override
  String get applyEstimateHint => 'Enter the real amount.';

  @override
  String get applyNow => 'Apply now';

  @override
  String get archive => 'Archive';

  @override
  String get archived => 'archived';

  @override
  String byAuthor(String name) {
    return 'By $name';
  }

  @override
  String get carryIn => 'Unspent from the previous period';

  @override
  String get changeLog => 'Change log';

  @override
  String get chooseHousehold => 'Choose a household';

  @override
  String get closedCarried => 'Went on to the next period';

  @override
  String get closedCarriedHint =>
      'This money is now in the current period, shared by everybody.';

  @override
  String get closedNothingCarried => 'Nothing went on this time.';

  @override
  String get closedOk => 'Great';

  @override
  String get closedPeriod => 'Closed';

  @override
  String get closedPutIn => 'Put in';

  @override
  String get closedSpent => 'Spent';

  @override
  String closedTitle(String name) {
    return 'Period closed: $name';
  }

  @override
  String comparedToPrevious(String delta) {
    return 'vs previous: $delta';
  }

  @override
  String get confirm => 'Confirm';

  @override
  String correctionBody(String amount) {
    return 'After this correction the wallet goes $amount below zero. Take the missing amount back from a household, or keep the minus until the next income?';
  }

  @override
  String get correctionKeepMinus => 'Keep the minus';

  @override
  String get correctionTitle => 'The wallet goes below zero';

  @override
  String correctionWithdrawFrom(String name) {
    return 'Take back from $name';
  }

  @override
  String get currentPeriod => 'Current';

  @override
  String get currentPeriodEnd => 'End of the current period';

  @override
  String get currentPeriodEndHint => 'Not before today';

  @override
  String get cycle => 'Periods';

  @override
  String cycleEveryWeeks(int weeks) {
    String _temp0 = intl.Intl.pluralLogic(
      weeks,
      locale: localeName,
      other: 'every $weeks weeks',
      one: 'every week',
    );
    return '$_temp0';
  }

  @override
  String cycleFromDay(String day) {
    return 'from $day';
  }

  @override
  String get cycleManual => 'Manual';

  @override
  String get cycleManualHint =>
      'You set the end; a new period lasts as long as the one before.';

  @override
  String get cycleMonthly => 'Monthly';

  @override
  String cycleMonthlyFrom(int day) {
    return 'monthly from day $day';
  }

  @override
  String get cycleWeeks => 'Every N weeks';

  @override
  String dashboardRangeLabel(String from, String to) {
    return 'Households $from – $to';
  }

  @override
  String get dashboardShows => 'The dashboard shows';

  @override
  String get dateAndTime => 'Date and time';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountBody =>
      'Your wallet, incomes and rules go. Your positive shares stay in the households as nobody\'s money. Type your e-mail address to confirm.';

  @override
  String get deleteHousehold => 'Delete household';

  @override
  String deleteHouseholdConfirm(String name) {
    return 'Delete “$name” with its envelopes and expenses? Positive shares go back to the wallets.';
  }

  @override
  String get deleteHouseholdHint => 'Not while anybody has a negative share.';

  @override
  String get deleteRule => 'Delete rule';

  @override
  String get deleteRuleConfirm => 'What the rule has made stays.';

  @override
  String get email => 'E-mail address';

  @override
  String get envelopeHasExpensesTitle => 'The envelope has expenses';

  @override
  String get errAlreadyMember => 'That person is a member already.';

  @override
  String get errCannotUndo => 'This change can no longer be undone.';

  @override
  String get errConfirmationMismatch => 'The address does not match.';

  @override
  String get errDateOutsidePeriod =>
      'The date has to be in the current period and not later than now.';

  @override
  String get errDuplicateEnvelope =>
      'There is an envelope with this name already.';

  @override
  String get errEnvelopeHasExpenses =>
      'An envelope with expenses cannot be deleted – archive it; its expenses stay in the history.';

  @override
  String get errInvalidPeriodEnd =>
      'The end cannot be before today or run into the next period.';

  @override
  String get errLastEnvelope =>
      'A household needs at least one active envelope.';

  @override
  String get errLastOwner =>
      'A household needs at least one owner. Give the role to somebody else first.';

  @override
  String get errMemberFrozen =>
      'You are frozen in this household: even out your share to spend again.';

  @override
  String errNegativeShare(String list) {
    return 'A negative share has to be evened out first: $list';
  }

  @override
  String get errNextPeriodOpen => 'The next period is open already.';

  @override
  String errNotEnoughMoney(String amount) {
    return 'Not enough money. Available: $amount.';
  }

  @override
  String get errPeriodClosed =>
      'The period is closed: only the title of an expense can change.';

  @override
  String get errPeriodNotCurrent =>
      'Money is spent only from the current period.';

  @override
  String get errPlanBelowSpent => 'A plan cannot be lower than what was spent.';

  @override
  String get errWalletNegative =>
      'The wallet is below zero – transfers wait for the next income.';

  @override
  String get estimated => 'estimated';

  @override
  String get estimatedExpenseRule => 'Estimated amount (to confirm)';

  @override
  String get estimatedIncome => 'Estimated (to confirm)';

  @override
  String get estimatedIncomeRule =>
      'Estimated: goes in with its estimate on the day';

  @override
  String get estimatedSpent => 'of it estimated';

  @override
  String everyWeeksFrom(int weeks, String day) {
    String _temp0 = intl.Intl.pluralLogic(
      weeks,
      locale: localeName,
      other: 'every $weeks weeks',
      one: 'every week',
    );
    return '$_temp0 from $day';
  }

  @override
  String get expense => 'Expense';

  @override
  String get firstPeriodEnd => 'End of the first period';

  @override
  String get forAnybody => 'For anybody';

  @override
  String forMember(String name) {
    return 'for $name';
  }

  @override
  String get forWhom => 'For whom';

  @override
  String get forWhomNobody => 'Not set';

  @override
  String get forWhomShared => 'Shared';

  @override
  String get forecast => 'Forecast to the end of the period';

  @override
  String get forecastBalance => 'Projected balance';

  @override
  String get forecastRecurring => 'of it recurring';

  @override
  String get forecastSpent => 'Projected spending';

  @override
  String freeMoney(String amount) {
    return 'Free: $amount';
  }

  @override
  String get freeMoneyLabel => 'Free money';

  @override
  String get freeze => 'Freeze';

  @override
  String get frequency => 'How often';

  @override
  String get frozen => 'frozen';

  @override
  String get household => 'Household';

  @override
  String get householdSettings => 'Household settings';

  @override
  String householdSpentInRange(String amount) {
    return 'Spent: $amount';
  }

  @override
  String get householdTab => 'Household';

  @override
  String get invitationPending => 'Waiting for an answer';

  @override
  String invitationTo(String name) {
    return 'Invitation to “$name”';
  }

  @override
  String invitedBy(String name) {
    return 'From $name';
  }

  @override
  String leaveBody(String name) {
    return 'You leave “$name”. Take your shares back to the wallet? Otherwise they stay in the household as nobody\'s money.';
  }

  @override
  String get leaveHousehold => 'Leave household';

  @override
  String get leaveKeepShares => 'Leave them';

  @override
  String get leaveWithdraw => 'Take them back';

  @override
  String leftAmount(String amount) {
    return '$amount left';
  }

  @override
  String leftInPlan(String name) {
    return 'Left in the plan of “$name”';
  }

  @override
  String get logEmpty => 'No changes in the open periods.';

  @override
  String get monthly => 'Monthly';

  @override
  String monthlyOnDay(int day) {
    return 'monthly on day $day';
  }

  @override
  String get negativeShareHint =>
      'A negative share: this person spent more than they put in.';

  @override
  String get newHousehold => 'New household';

  @override
  String get nextPeriod => 'Next';

  @override
  String get noExpensesForFilters => 'No expenses for the chosen filters';

  @override
  String get noExpensesInPeriod => 'No expenses in this period.';

  @override
  String get nobodysMoney => 'Nobody\'s money';

  @override
  String get openNextPeriod => 'Open the next period';

  @override
  String get periods => 'Periods';

  @override
  String get piggyBalance => 'Piggy bank balance';

  @override
  String planOf(String name) {
    return 'Plan: $name';
  }

  @override
  String planRaised(String amount) {
    return 'The plan went up by $amount out of free money.';
  }

  @override
  String planRecurringPart(String amount) {
    return 'Of it from recurring expenses: $amount';
  }

  @override
  String get plansExceedBalance =>
      'The plans exceed the balance of the household';

  @override
  String get plansTotal => 'Plans in total';

  @override
  String get rangeCustom => 'A range of days';

  @override
  String get rangeMonth => 'The current month';

  @override
  String get rangePeriod => 'The period of the chosen household';

  @override
  String recurringInPlan(String amount) {
    return 'recurring $amount';
  }

  @override
  String get recurringIntro =>
      'They run on their own when the app starts: incomes, then transfers, then expenses.';

  @override
  String returnedFrom(String name) {
    return 'Share given back: $name';
  }

  @override
  String get revoke => 'Revoke';

  @override
  String roleConfirm(String name) {
    return 'Change the role of $name?';
  }

  @override
  String get ruleExpense => 'Expense';

  @override
  String get ruleIncome => 'Income';

  @override
  String get ruleTransfer => 'Transfer';

  @override
  String get rulesExpenses => 'Recurring expenses';

  @override
  String get rulesIncomes => 'Incomes into the wallet';

  @override
  String get rulesTransfers => 'Transfers into households';

  @override
  String shareOf(String amount) {
    return 'share $amount';
  }

  @override
  String get shares => 'Shares';

  @override
  String stepBring(String amount) {
    return 'Bring $amount from the wallet';
  }

  @override
  String stepBringAndRaise(String amount) {
    return 'Bring $amount and raise the plan';
  }

  @override
  String stepNotEnoughBody(String amount) {
    return 'There is only $amount in the piggy bank.';
  }

  @override
  String get stepNotEnoughTitle => 'Not enough in the piggy bank';

  @override
  String stepPlanTooSmallBody(String amount) {
    return 'The plan of the envelope is $amount short and there is no free money.';
  }

  @override
  String get stepPlanTooSmallTitle => 'The plan has to go up';

  @override
  String get stepRaiseOnly => 'Only raise the plan';

  @override
  String stepWalletNegativeBody(String amount) {
    return 'The wallet goes below zero: $amount. No transfers until the next income.';
  }

  @override
  String get stepWalletNegativeConfirm => 'Confirm the minus';

  @override
  String get stepWalletNegativeTitle => 'The wallet is short';

  @override
  String get takeOwner => 'Take the owner role';

  @override
  String get thisPeriod => 'This period';

  @override
  String get titleOptional => 'Title (optional)';

  @override
  String get toNextPeriod => 'to the next period';

  @override
  String get toNextPeriodHint =>
      'To the next period (e.g. pay on the 28th for the next month)';

  @override
  String get todoAddExpense => 'Add the expense';

  @override
  String get todoConfirmAmount => 'Confirm the amount';

  @override
  String get todoDismiss => 'Leave it';

  @override
  String get todoDo => 'Do it';

  @override
  String todoExpenseEstimate(String what, String amount) {
    return 'Estimated expense “$what”: $amount. Confirm the real amount before the period ends.';
  }

  @override
  String todoExpenseMissed(String what, String amount) {
    return '“$what” ($amount) fell in a period that has closed.';
  }

  @override
  String todoExpenseNotFit(String what, String amount) {
    return 'The recurring expense “$what” ($amount) does not fit the plan or the balance.';
  }

  @override
  String todoIncomeEstimate(String what, String amount) {
    return 'The income “$what” went in with its estimate $amount. Correct it.';
  }

  @override
  String get todoTitle => 'To do';

  @override
  String get todoTransfer => 'Transfer';

  @override
  String todoTransferNoMoney(String what, String amount) {
    return 'The recurring transfer “$what” ($amount) did not go: the wallet was short.';
  }

  @override
  String get transfer => 'Transfer';

  @override
  String get transferFromWallet => 'Transfer from the wallet';

  @override
  String transferHint(String amount) {
    return 'In the wallet: $amount';
  }

  @override
  String transferTo(String name) {
    return 'Transfer: $name';
  }

  @override
  String get transfers => 'Transfers';

  @override
  String get unarchive => 'Bring back';

  @override
  String get undo => 'Undo';

  @override
  String get unfreeze => 'Unfreeze';

  @override
  String get usedUnconfirmed =>
      'Part of the transfer came from unconfirmed incomes.';

  @override
  String get wallet => 'Wallet';

  @override
  String get walletBalance => 'Wallet balance';

  @override
  String get walletEmpty => 'Nothing here yet. Add the first income.';

  @override
  String get walletNegativeHint =>
      'The wallet is below zero: transfers come back after the next income.';

  @override
  String walletUnconfirmed(String amount) {
    return 'of it unconfirmed: $amount';
  }

  @override
  String get walletUnconfirmedLabel => 'of it unconfirmed';

  @override
  String get weekly => 'Every N weeks';

  @override
  String get withdraw => 'Withdraw';

  @override
  String get withdrawHint =>
      'At most your share and at most what is in the piggy bank.';

  @override
  String withdrawalFrom(String name) {
    return 'Withdrawal: $name';
  }

  @override
  String get withdrawals => 'Withdrawals';

  @override
  String get wizardDoneBody =>
      'All set. You can invite others later in “Members”.';

  @override
  String get wizardDoneTitle => 'Done';

  @override
  String get wizardFinish => 'To the dashboard';

  @override
  String get wizardHouseholdBody =>
      'A household holds envelopes and periods – for you alone or several people.';

  @override
  String get wizardHouseholdTitle => 'Your household';

  @override
  String wizardStep(int step, int total) {
    return 'Step $step of $total';
  }

  @override
  String get wizardTitle => 'Getting started';

  @override
  String wizardTransferBody(String amount) {
    return 'How much of the wallet ($amount) goes into the current period?';
  }

  @override
  String get wizardTransferTitle => 'Transfer to the household';

  @override
  String get wizardEnvelopesTitle => 'Envelopes';

  @override
  String get wizardEnvelopesBody =>
      'Pick the first envelopes. You can change them later.';

  @override
  String get wizardIncomeTitle => 'The first income';

  @override
  String get wizardIncomeBody =>
      'How much do you have to hand out? It goes into your private wallet.';

  @override
  String get yourName => 'Your name';

  @override
  String get yourNameHint => 'Other members of your households see it.';

  @override
  String get addEnvelope => 'Add envelope';

  @override
  String get editEnvelope => 'Edit envelope';

  @override
  String get editIncome => 'Correct income';

  @override
  String get deleteIncome => 'Delete income';

  @override
  String deleteIncomeConfirm(String amount) {
    return 'Delete the income of $amount?';
  }

  @override
  String get editRule => 'Edit rule';

  @override
  String get makeOwner => 'Make owner';

  @override
  String get removeMember => 'Remove';

  @override
  String removeMemberConfirm(String name) {
    return 'Remove $name? A positive share goes back to their wallet.';
  }

  @override
  String get roleOwner => 'owner';

  @override
  String get roleMember => 'member';

  @override
  String get invite => 'Invite';

  @override
  String get send => 'Send';

  @override
  String get accept => 'Accept';

  @override
  String get decline => 'Decline';

  @override
  String get members => 'Members';

  @override
  String get formerMember => 'former member';

  @override
  String get later => 'Later';

  @override
  String get next => 'Next';

  @override
  String get income => 'Income';

  @override
  String get addIncome => 'Add income';

  @override
  String get addIncomeShort => '+ Income';

  @override
  String get recurringIncomeName => 'Recurring income';

  @override
  String get recurringIncome => 'Repeat every month';

  @override
  String recurringIncomeOn(int day) {
    return 'Every month on day $day';
  }

  @override
  String openNextConfirm(String date) {
    return 'The next period starts on $date. The plans of the envelopes are copied from the current one, and you can transfer into it now.';
  }

  @override
  String get previousPeriodTooltip => 'Previous period';

  @override
  String get nextPeriodTooltip => 'Next period';

  @override
  String piggyBalanceShort(String amount) {
    return 'Piggy bank balance: $amount · tap for details';
  }

  @override
  String get changePlan => 'Change the plan';

  @override
  String get appliedDone => 'Applied.';

  @override
  String get appliedNothing =>
      'Nothing to apply in this period – the next occurrence comes later.';

  @override
  String wholeIncomeOf(String name) {
    return 'All of “$name”';
  }

  @override
  String get transferHowMuch => 'How much to transfer';

  @override
  String get fixedAmount => 'A fixed amount';

  @override
  String get wholeIncomeHint =>
      'Each time this income comes in, all of it goes on into the household on the same day. An estimated income goes on only once you confirm its real amount.';

  @override
  String get deleteIncomeRuleConfirm =>
      'What the rule has made stays. The transfers that follow this income are deleted too.';

  @override
  String get editPlan => 'Edit the plan';

  @override
  String get savePlan => 'Save the plan';

  @override
  String get periodPlan => 'The plan of the period';

  @override
  String planBalanceOf(String amount) {
    return 'Piggy bank balance: $amount';
  }

  @override
  String spentAmount(String amount) {
    return '$amount spent';
  }

  @override
  String freeToPlan(String amount) {
    return '$amount is waiting to be planned.';
  }

  @override
  String get everythingPlanned => 'All the money is planned.';

  @override
  String get tapEnvelopeToSpend => 'Tap an envelope to add an expense to it.';

  @override
  String wizardEnvelopesChosen(int count) {
    return 'Chosen: $count · tap to choose or leave out';
  }

  @override
  String expensesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count expenses',
      one: '1 expense',
      zero: 'no expenses',
    );
    return '$_temp0';
  }

  @override
  String get filters => 'Filters';

  @override
  String filtersActive(int count) {
    return 'Filters ($count)';
  }

  @override
  String get clearFilters => 'Clear';

  @override
  String get showResults => 'Show';

  @override
  String get author => 'Added by';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get signedInLabel => 'Signed in';
}
