// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get appTitle => 'PLNing';

  @override
  String get envelopes => 'Koperty';

  @override
  String get spent => 'Wydano';

  @override
  String get saveChanges => 'Zapisz zmiany';

  @override
  String get noEnvelopesForExpense =>
      'Nie masz jeszcze żadnych kopert. Dodaj kopertę, zanim zapiszesz wydatek.';

  @override
  String get envelope => 'Koperta';

  @override
  String get amount => 'Kwota';

  @override
  String get enterAmount => 'Podaj kwotę';

  @override
  String get date => 'Data';

  @override
  String get saveExpense => 'Zapisz wydatek';

  @override
  String get editExpense => 'Edytuj wydatek';

  @override
  String get name => 'Nazwa';

  @override
  String get save => 'Zapisz';

  @override
  String get delete => 'Usuń';

  @override
  String get deleteExpense => 'Usuń wydatek';

  @override
  String deleteExpenseConfirm(String amount) {
    return 'Usunąć ten wydatek na $amount?';
  }

  @override
  String get cancel => 'Anuluj';

  @override
  String get settings => 'Ustawienia';

  @override
  String get security => 'Bezpieczeństwo';

  @override
  String get appLock => 'Blokada aplikacji (PIN)';

  @override
  String get appLockSubtitle => 'Wymagaj PIN-u do otwarcia aplikacji';

  @override
  String get changePin => 'Zmień PIN';

  @override
  String get biometricUnlock => 'Odblokuj biometrią';

  @override
  String get setPin => 'Ustaw PIN';

  @override
  String get enterPin => 'Wprowadź PIN';

  @override
  String get confirmPin => 'Potwierdź PIN';

  @override
  String get pinTooShort => 'PIN musi mieć co najmniej 6 cyfr';

  @override
  String get pinsDontMatch => 'PIN-y nie są zgodne';

  @override
  String get wrongPin => 'Nieprawidłowy PIN';

  @override
  String get unlock => 'Odblokuj';

  @override
  String get unlockTitle => 'Wprowadź swój PIN';

  @override
  String get useBiometrics => 'Użyj biometrii';

  @override
  String get biometricReason => 'Uwierzytelnij, aby odblokować Money Planner';

  @override
  String get pinSaved => 'Zapisano PIN';

  @override
  String get lockDisabled => 'Blokada aplikacji wyłączona';

  @override
  String get general => 'Ogólne';

  @override
  String get appearance => 'Wygląd';

  @override
  String get theme => 'Motyw';

  @override
  String get themeDark => 'Ciemny';

  @override
  String get themeLight => 'Jasny';

  @override
  String get themeAuto => 'Auto';

  @override
  String get about => 'O aplikacji';

  @override
  String get history => 'Historia';

  @override
  String get newExpense => 'Nowy wydatek';

  @override
  String get dashboard => 'Pulpit';

  @override
  String get errorUnreachable =>
      'Brak połączenia z serwerem. Sprawdź internet i spróbuj ponownie.';

  @override
  String get errorNotFound =>
      'Tych danych już nie ma. Mogły zostać zmienione na innym urządzeniu.';

  @override
  String get errorConflict =>
      'Ta operacja koliduje z danymi, które już istnieją.';

  @override
  String get errorInvalid =>
      'Serwer nie przyjął tych wartości. Sprawdź, co zostało wpisane.';

  @override
  String get errorServer =>
      'Coś poszło nie tak po stronie serwera. Spróbuj ponownie za chwilę.';

  @override
  String get retry => 'Spróbuj ponownie';

  @override
  String get loadFailed => 'Nie udało się wczytać danych';

  @override
  String get errorUnauthorized => 'Sesja wygasła. Zaloguj się ponownie.';

  @override
  String get errorRateLimited =>
      'Za dużo prób. Poczekaj chwilę i spróbuj ponownie.';

  @override
  String get emailAddress => 'Adres e-mail';

  @override
  String get enterValidEmail => 'Podaj poprawny adres e-mail';

  @override
  String get sendCode => 'Wyślij kod';

  @override
  String codeSentTo(String email) {
    return 'Wysłaliśmy kod na $email. Wpisz go poniżej.';
  }

  @override
  String get enterCode => 'Wpisz 6-cyfrowy kod';

  @override
  String get signInAction => 'Zaloguj się';

  @override
  String get useOtherEmail => 'Użyj innego adresu';

  @override
  String get invalidCode => 'Kod jest zły albo wygasł.';

  @override
  String get account => 'Konto';

  @override
  String signedInAs(String email) {
    return 'Zalogowano jako $email';
  }

  @override
  String get signOut => 'Wyloguj';

  @override
  String get signOutConfirm => 'Wylogować z tego urządzenia?';

  @override
  String get signInWithGoogle => 'Kontynuuj z Google';

  @override
  String get googleSignInFailed =>
      'Logowanie przez Google nie udało się. Spróbuj ponownie albo użyj kodu z e-maila.';

  @override
  String get orSeparator => 'albo';

  @override
  String get manageEnvelopes => 'Zarządzaj kopertami';

  @override
  String get loginHeadline => 'Budżet domowy,\nwspólnie albo solo';

  @override
  String get loginSubtitle =>
      'Zaloguj się adresem e-mail – wyślemy kod. Bez hasła.';

  @override
  String get codeFieldLabel => 'Kod z e-maila (6 cyfr)';

  @override
  String get codeValidity => 'Kod jest ważny 15 minut. Nie dotarł?';

  @override
  String get resendShort => 'Wyślij ponownie';

  @override
  String get consent =>
      'Akceptuję informację o przetwarzaniu danych (e-mail, imię, dane budżetu).';

  @override
  String get consentRequired => 'Zaznacz zgodę, aby się zalogować.';

  @override
  String get recurringTab => 'Cykliczne';

  @override
  String get addExpenseShort => '+ Wydatek';

  @override
  String get wizardStartTitle => 'Ustawmy Twój budżet';

  @override
  String get wizardStartBody =>
      'Pięć krótkich kroków: koperty, wspólne koperty, wpłaty, rachunki i podział pieniędzy.';

  @override
  String get wizardStart => 'Zaczynamy';

  @override
  String get descriptionOptional => 'Opis (opcjonalnie)';

  @override
  String get descriptionHint => 'np. zakupy w Biedronce';

  @override
  String get addRule => 'Dodaj regułę';

  @override
  String get allEnvelopes => 'Wszystkie koperty';

  @override
  String get allPeriods => 'Wszystkie okresy';

  @override
  String get anyAuthor => 'Każdy autor';

  @override
  String get appliedToTodo =>
      'Nie zmieściło się – trafiło do „Do załatwienia”.';

  @override
  String applyAllExpenses(String name) {
    return 'Zastosuj wszystkie wydatki cykliczne: $name';
  }

  @override
  String get applyEstimateHint => 'Podaj rzeczywistą kwotę.';

  @override
  String get applyNow => 'Zastosuj teraz';

  @override
  String get archive => 'Archiwizuj';

  @override
  String get archived => 'w archiwum';

  @override
  String byAuthor(String name) {
    return 'Autor: $name';
  }

  @override
  String get carryIn => 'Niewydane z poprzedniego okresu';

  @override
  String get changeLog => 'Log zmian';

  @override
  String get chooseHousehold => 'Wybierz gospodarstwo';

  @override
  String get closedCarried => 'Przeszło do następnego okresu';

  @override
  String get closedCarriedHint =>
      'Te pieniądze są teraz w bieżącym okresie, wspólne dla wszystkich.';

  @override
  String get closedNothingCarried => 'Tym razem nic nie przeszło dalej.';

  @override
  String get closedOk => 'Super';

  @override
  String get closedPeriod => 'Zamknięty';

  @override
  String get closedPutIn => 'Wpłacono';

  @override
  String get closedSpent => 'Wydano';

  @override
  String closedTitle(String name) {
    return 'Okres zamknięty: $name';
  }

  @override
  String comparedToPrevious(String delta) {
    return 'vs poprzedni: $delta';
  }

  @override
  String get confirm => 'Potwierdź';

  @override
  String correctionBody(String amount) {
    return 'Po tej korekcie portfel zejdzie poniżej zera o $amount. Wycofać brakującą kwotę z gospodarstwa czy zostawić minus do następnego wpływu?';
  }

  @override
  String get correctionKeepMinus => 'Zostaw minus';

  @override
  String get correctionTitle => 'Portfel zejdzie poniżej zera';

  @override
  String correctionWithdrawFrom(String name) {
    return 'Wycofaj z: $name';
  }

  @override
  String get currentPeriod => 'Bieżący';

  @override
  String get currentPeriodEnd => 'Koniec bieżącego okresu';

  @override
  String get currentPeriodEndHint => 'Nie wcześniej niż dziś';

  @override
  String get cycle => 'Okresy';

  @override
  String cycleEveryWeeks(int weeks) {
    String _temp0 = intl.Intl.pluralLogic(
      weeks,
      locale: localeName,
      other: 'co $weeks tygodnia',
      many: 'co $weeks tygodni',
      few: 'co $weeks tygodnie',
      one: 'co tydzień',
    );
    return '$_temp0';
  }

  @override
  String cycleFromDay(String day) {
    return 'od $day';
  }

  @override
  String get cycleManual => 'Ręcznie';

  @override
  String get cycleManualHint =>
      'Koniec ustawiasz sam; nowy okres trwa tyle, co poprzedni.';

  @override
  String get cycleMonthly => 'Co miesiąc';

  @override
  String cycleMonthlyFrom(int day) {
    return 'co miesiąc od $day.';
  }

  @override
  String get cycleWeeks => 'Co N tygodni';

  @override
  String dashboardRangeLabel(String from, String to) {
    return 'Gospodarstwa $from – $to';
  }

  @override
  String get dashboardShows => 'Pulpit pokazuje';

  @override
  String get dateAndTime => 'Data i godzina';

  @override
  String get deleteAccount => 'Usuń konto';

  @override
  String get deleteAccountBody =>
      'Portfel, wpływy i reguły znikną. Twoje dodatnie udziały zostaną w gospodarstwach jako pieniądze niczyje. Wpisz swój adres e-mail, żeby potwierdzić.';

  @override
  String get deleteHousehold => 'Usuń gospodarstwo';

  @override
  String deleteHouseholdConfirm(String name) {
    return 'Usunąć „$name” razem z kopertami i wydatkami? Dodatnie udziały wrócą do portfeli.';
  }

  @override
  String get deleteHouseholdHint => 'Niemożliwe, dopóki ktoś ma ujemny udział.';

  @override
  String get deleteRule => 'Usuń regułę';

  @override
  String get deleteRuleConfirm => 'To, co reguła już dodała, zostanie.';

  @override
  String get email => 'Adres e-mail';

  @override
  String get envelopeHasExpensesTitle => 'Koperta ma wydatki';

  @override
  String get errAlreadyMember => 'Ta osoba już jest członkiem.';

  @override
  String get errCannotUndo => 'Tej zmiany nie da się już cofnąć.';

  @override
  String get errConfirmationMismatch => 'Adres się nie zgadza.';

  @override
  String get errDateOutsidePeriod =>
      'Data musi należeć do bieżącego okresu i nie być późniejsza niż teraz.';

  @override
  String get errDuplicateEnvelope => 'Koperta o tej nazwie już jest.';

  @override
  String get errEnvelopeHasExpenses =>
      'Koperty z wydatkami nie można usunąć – można ją zarchiwizować; wydatki zostaną w historii.';

  @override
  String get errInvalidPeriodEnd =>
      'Koniec nie może być wcześniejszy niż dziś ani nachodzić na następny okres.';

  @override
  String get errLastEnvelope =>
      'Gospodarstwo musi mieć co najmniej jedną aktywną kopertę.';

  @override
  String get errLastOwner =>
      'Gospodarstwo musi mieć co najmniej jednego właściciela. Najpierw nadaj tę rolę komuś innemu.';

  @override
  String get errMemberFrozen =>
      'Jesteś zamrożony w tym gospodarstwie: wyrównaj udział, żeby znów wydawać.';

  @override
  String errNegativeShare(String list) {
    return 'Najpierw trzeba wyrównać ujemny udział: $list';
  }

  @override
  String get errNextPeriodOpen => 'Następny okres jest już otwarty.';

  @override
  String errNotEnoughMoney(String amount) {
    return 'Za mało pieniędzy. Dostępne: $amount.';
  }

  @override
  String get errPeriodClosed =>
      'Okres jest zamknięty: można zmienić tylko tytuł wydatku.';

  @override
  String get errPeriodNotCurrent => 'Wydawać można tylko z bieżącego okresu.';

  @override
  String get errPlanBelowSpent =>
      'Plan nie może być niższy niż to, co już wydano.';

  @override
  String get errWalletNegative =>
      'Portfel jest na minusie – przelewy są zablokowane do następnego wpływu.';

  @override
  String get estimated => 'szacowany';

  @override
  String get estimatedExpenseRule => 'Kwota szacowana (do potwierdzenia)';

  @override
  String get estimatedIncome => 'Szacowany (do potwierdzenia)';

  @override
  String get estimatedIncomeRule =>
      'Szacowany: wejdzie z kwotą szacowaną w terminie';

  @override
  String get estimatedSpent => 'w tym szacowane';

  @override
  String everyWeeksFrom(int weeks, String day) {
    String _temp0 = intl.Intl.pluralLogic(
      weeks,
      locale: localeName,
      other: 'co $weeks tygodnia',
      many: 'co $weeks tygodni',
      few: 'co $weeks tygodnie',
      one: 'co tydzień',
    );
    return '$_temp0 od $day';
  }

  @override
  String get expense => 'Wydatek';

  @override
  String get firstPeriodEnd => 'Koniec pierwszego okresu';

  @override
  String get forAnybody => 'Dla kogokolwiek';

  @override
  String forMember(String name) {
    return 'dla: $name';
  }

  @override
  String get forWhom => 'Dla kogo';

  @override
  String get forWhomNobody => 'Nie podano';

  @override
  String get forWhomShared => 'Wspólne';

  @override
  String get forecast => 'Prognoza do końca okresu';

  @override
  String get forecastBalance => 'Przewidywane saldo';

  @override
  String get forecastRecurring => 'w tym cykliczne';

  @override
  String get forecastSpent => 'Przewidywane wydatki';

  @override
  String freeMoney(String amount) {
    return 'Wolne: $amount';
  }

  @override
  String get freeMoneyLabel => 'Wolne pieniądze';

  @override
  String get freeze => 'Zamroź';

  @override
  String get frequency => 'Jak często';

  @override
  String get frozen => 'zamrożony';

  @override
  String get household => 'Gospodarstwo';

  @override
  String get householdSettings => 'Ustawienia gospodarstwa';

  @override
  String householdSpentInRange(String amount) {
    return 'Wydano: $amount';
  }

  @override
  String get householdTab => 'Gospodarstwo';

  @override
  String get invitationPending => 'Czeka na odpowiedź';

  @override
  String invitationTo(String name) {
    return 'Zaproszenie do „$name”';
  }

  @override
  String invitedBy(String name) {
    return 'Zaprasza: $name';
  }

  @override
  String leaveBody(String name) {
    return 'Wychodzisz z „$name”. Wycofać swoje udziały do portfela? Jeśli nie, zostaną w gospodarstwie jako pieniądze niczyje.';
  }

  @override
  String get leaveHousehold => 'Wyjdź z gospodarstwa';

  @override
  String get leaveKeepShares => 'Zostaw w gospodarstwie';

  @override
  String get leaveWithdraw => 'Wycofaj do portfela';

  @override
  String leftAmount(String amount) {
    return 'zostało $amount';
  }

  @override
  String leftInPlan(String name) {
    return 'Zostało w planie „$name”';
  }

  @override
  String get logEmpty => 'Brak zmian w otwartych okresach.';

  @override
  String get monthly => 'Co miesiąc';

  @override
  String monthlyOnDay(int day) {
    return 'co miesiąc, $day.';
  }

  @override
  String get negativeShareHint =>
      'Ujemny udział: ta osoba wydała więcej, niż włożyła.';

  @override
  String get newHousehold => 'Nowe gospodarstwo';

  @override
  String get nextPeriod => 'Następny';

  @override
  String get noExpensesForFilters => 'Brak wydatków dla wybranych filtrów';

  @override
  String get noExpensesInPeriod => 'Brak wydatków w tym okresie.';

  @override
  String get nobodysMoney => 'Pieniądze niczyje';

  @override
  String get openNextPeriod => 'Otwórz następny okres';

  @override
  String get periods => 'Okresy';

  @override
  String get piggyBalance => 'Saldo skarbonki';

  @override
  String planOf(String name) {
    return 'Plan: $name';
  }

  @override
  String planRaised(String amount) {
    return 'Plan koperty podniósł się o $amount z wolnych pieniędzy.';
  }

  @override
  String planRecurringPart(String amount) {
    return 'W tym z wydatków cyklicznych: $amount';
  }

  @override
  String get plansExceedBalance => 'Plan przekracza saldo gospodarstwa';

  @override
  String get plansTotal => 'Suma planów';

  @override
  String get rangeCustom => 'Dowolny zakres dat';

  @override
  String get rangeMonth => 'Bieżący miesiąc';

  @override
  String get rangePeriod => 'Okres wybranego gospodarstwa';

  @override
  String recurringInPlan(String amount) {
    return 'cykliczne $amount';
  }

  @override
  String get recurringIntro =>
      'Wykonują się same przy otwarciu aplikacji: najpierw wpływy, potem przelewy, potem wydatki.';

  @override
  String returnedFrom(String name) {
    return 'Zwrot udziału: $name';
  }

  @override
  String get revoke => 'Odwołaj';

  @override
  String roleConfirm(String name) {
    return 'Zmienić rolę osoby $name?';
  }

  @override
  String get ruleExpense => 'Wydatek';

  @override
  String get ruleIncome => 'Wpływ';

  @override
  String get ruleTransfer => 'Przelew';

  @override
  String get rulesExpenses => 'Wydatki cykliczne';

  @override
  String get rulesIncomes => 'Wpływy do portfela';

  @override
  String get rulesTransfers => 'Przelewy do gospodarstw';

  @override
  String shareOf(String amount) {
    return 'udział $amount';
  }

  @override
  String get shares => 'Udziały';

  @override
  String stepBring(String amount) {
    return 'Dołóż $amount z portfela';
  }

  @override
  String stepBringAndRaise(String amount) {
    return 'Dołóż $amount i podnieś plan';
  }

  @override
  String stepNotEnoughBody(String amount) {
    return 'W skarbonce jest tylko $amount.';
  }

  @override
  String get stepNotEnoughTitle => 'Za mało w skarbonce';

  @override
  String stepPlanTooSmallBody(String amount) {
    return 'Brakuje $amount w planie koperty, a w skarbonce nie ma wolnych pieniędzy.';
  }

  @override
  String get stepPlanTooSmallTitle => 'Trzeba podnieść plan';

  @override
  String get stepRaiseOnly => 'Tylko podnieś plan';

  @override
  String stepWalletNegativeBody(String amount) {
    return 'Portfel zejdzie poniżej zera: będzie $amount. Do następnego wpływu nie zrobisz przelewu.';
  }

  @override
  String get stepWalletNegativeConfirm => 'Zatwierdź minus';

  @override
  String get stepWalletNegativeTitle => 'W portfelu brakuje pieniędzy';

  @override
  String get takeOwner => 'Odbierz rolę właściciela';

  @override
  String get thisPeriod => 'Ten okres';

  @override
  String get titleOptional => 'Tytuł (opcjonalnie)';

  @override
  String get toNextPeriod => 'na następny okres';

  @override
  String get toNextPeriodHint =>
      'Do następnego okresu (np. wypłata 28. na kolejny miesiąc)';

  @override
  String get todoAddExpense => 'Dodaj wydatek';

  @override
  String get todoConfirmAmount => 'Potwierdź kwotę';

  @override
  String get todoDismiss => 'Zostaw';

  @override
  String get todoDo => 'Zrób';

  @override
  String todoExpenseEstimate(String what, String amount) {
    return 'Wydatek szacowany „$what”: $amount. Potwierdź rzeczywistą kwotę do końca okresu.';
  }

  @override
  String todoExpenseMissed(String what, String amount) {
    return '„$what” ($amount) wypadł w okresie, który już się zamknął.';
  }

  @override
  String todoExpenseNotFit(String what, String amount) {
    return 'Wydatek cykliczny „$what” ($amount) nie mieści się w planie albo w saldzie.';
  }

  @override
  String todoIncomeEstimate(String what, String amount) {
    return 'Wpływ „$what” wszedł z kwotą szacowaną $amount. Skoryguj ją.';
  }

  @override
  String get todoTitle => 'Do załatwienia';

  @override
  String get todoTransfer => 'Przelej';

  @override
  String todoTransferNoMoney(String what, String amount) {
    return 'Przelew cykliczny „$what” ($amount) nie poszedł: w portfelu brakowało pieniędzy.';
  }

  @override
  String get transfer => 'Przelej';

  @override
  String get transferFromWallet => 'Przelew z portfela';

  @override
  String transferHint(String amount) {
    return 'W portfelu: $amount';
  }

  @override
  String transferTo(String name) {
    return 'Przelew: $name';
  }

  @override
  String get transfers => 'Przelewy';

  @override
  String get unarchive => 'Przywróć';

  @override
  String get undo => 'Cofnij';

  @override
  String get unfreeze => 'Odmroź';

  @override
  String get usedUnconfirmed =>
      'Przelew częściowo z niepotwierdzonych wpływów.';

  @override
  String get wallet => 'Portfel';

  @override
  String get walletBalance => 'Saldo portfela';

  @override
  String get walletEmpty => 'Nic tu jeszcze nie ma. Dodaj pierwszy wpływ.';

  @override
  String get walletNegativeHint =>
      'Portfel jest na minusie: przelewy wrócą po następnym wpływie.';

  @override
  String walletUnconfirmed(String amount) {
    return 'w tym niepotwierdzone: $amount';
  }

  @override
  String get walletUnconfirmedLabel => 'w tym niepotwierdzone';

  @override
  String get weekly => 'Co N tygodni';

  @override
  String get withdraw => 'Wycofaj';

  @override
  String get withdrawHint =>
      'Najwyżej Twój udział i najwyżej tyle, ile jest w skarbonce.';

  @override
  String withdrawalFrom(String name) {
    return 'Wycofanie: $name';
  }

  @override
  String get withdrawals => 'Wycofania';

  @override
  String get wizardDoneBody =>
      'Wszystko gotowe. Innych osób zaprosisz później w „Członkach”.';

  @override
  String get wizardDoneTitle => 'Gotowe';

  @override
  String get wizardFinish => 'Do pulpitu';

  @override
  String get wizardHouseholdBody =>
      'Gospodarstwo to wspólne miejsce na koperty i okresy – dla Ciebie albo kilku osób.';

  @override
  String get wizardHouseholdTitle => 'Twoje gospodarstwo';

  @override
  String wizardStep(int step, int total) {
    return 'Krok $step z $total';
  }

  @override
  String get wizardTitle => 'Na start';

  @override
  String wizardTransferBody(String amount) {
    return 'Ile z portfela ($amount) przelać do bieżącego okresu?';
  }

  @override
  String get wizardTransferTitle => 'Przelew do gospodarstwa';

  @override
  String get wizardEnvelopesTitle => 'Koperty';

  @override
  String get wizardEnvelopesBody =>
      'Wybierz startowe koperty. Dodasz i zmienisz je później.';

  @override
  String get wizardIncomeTitle => 'Pierwszy wpływ';

  @override
  String get wizardIncomeBody =>
      'Ile pieniędzy masz do rozdania? Trafią do Twojego prywatnego portfela.';

  @override
  String get yourName => 'Twoje imię';

  @override
  String get yourNameHint => 'Widzą je inni członkowie gospodarstw.';

  @override
  String get addEnvelope => 'Dodaj kopertę';

  @override
  String get editEnvelope => 'Edytuj kopertę';

  @override
  String get editIncome => 'Korekta wpływu';

  @override
  String get deleteIncome => 'Usuń wpływ';

  @override
  String deleteIncomeConfirm(String amount) {
    return 'Usunąć wpływ $amount?';
  }

  @override
  String get editRule => 'Edytuj regułę';

  @override
  String get makeOwner => 'Nadaj rolę właściciela';

  @override
  String get removeMember => 'Usuń z gospodarstwa';

  @override
  String removeMemberConfirm(String name) {
    return 'Usunąć $name? Dodatni udział wróci do portfela tej osoby.';
  }

  @override
  String get roleOwner => 'właściciel';

  @override
  String get roleMember => 'członek';

  @override
  String get invite => 'Zaproś';

  @override
  String get send => 'Wyślij';

  @override
  String get accept => 'Przyjmij';

  @override
  String get decline => 'Odrzuć';

  @override
  String get members => 'Członkowie';

  @override
  String get formerMember => 'były członek';

  @override
  String get later => 'Później';

  @override
  String get next => 'Dalej';

  @override
  String get income => 'Wpływ';

  @override
  String get addIncome => 'Dodaj wpływ';

  @override
  String get addIncomeShort => '+ Wpływ';

  @override
  String get recurringIncomeName => 'Wpływ cykliczny';

  @override
  String get recurringIncome => 'Powtarzaj co miesiąc';

  @override
  String recurringIncomeOn(int day) {
    return 'Co miesiąc, $day. dnia';
  }

  @override
  String openNextConfirm(String date) {
    return 'Następny okres zacznie się $date. Plany kopert skopiują się z bieżącego, a przelewać na niego możesz już teraz.';
  }

  @override
  String get previousPeriodTooltip => 'Poprzedni okres';

  @override
  String get nextPeriodTooltip => 'Następny okres';

  @override
  String piggyBalanceShort(String amount) {
    return 'Saldo skarbonki: $amount · dotknij, by zobaczyć szczegóły';
  }

  @override
  String get changePlan => 'Zmień plan';

  @override
  String get appliedDone => 'Zastosowano.';

  @override
  String get appliedNothing =>
      'Nic do zastosowania w tym okresie – następne wystąpienie jest później.';
}
