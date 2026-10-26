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
  String get dashboardEmptyTitle => 'Tutaj mieszka Twój budżet kopertowy.';

  @override
  String get dashboardEmptyBody =>
      'Utwórz okres i podziel swój dochód, aby zacząć.';

  @override
  String get newPeriod => 'Nowy okres';

  @override
  String get addExpense => 'Dodaj wydatek';

  @override
  String get envelopes => 'Koperty';

  @override
  String get noEnvelopes => 'Nie przydzielono jeszcze żadnych kategorii.';

  @override
  String get income => 'Dochód';

  @override
  String get planned => 'Zaplanowano';

  @override
  String get spent => 'Wydano';

  @override
  String get unallocated => 'Nieprzydzielone';

  @override
  String get overAllocated => 'Przydzielono za dużo';

  @override
  String get remaining => 'Pozostało';

  @override
  String remainingIn(String period) {
    return 'Pozostało · $period';
  }

  @override
  String amountLeft(String amount) {
    return 'pozostało $amount';
  }

  @override
  String overBy(String amount) {
    return 'przekroczono o $amount';
  }

  @override
  String get periodName => 'Nazwa okresu';

  @override
  String get enterName => 'Podaj nazwę';

  @override
  String get start => 'Początek';

  @override
  String get end => 'Koniec';

  @override
  String get incomeForPeriod => 'Dochód w tym okresie';

  @override
  String get enterIncome => 'Podaj swój dochód';

  @override
  String get splitAcrossCategories => 'Podziel na kategorie';

  @override
  String overAllocationWarning(String amount) {
    return 'Przydzielono o $amount więcej niż wynosi dochód. Możesz mimo to kontynuować.';
  }

  @override
  String get createPeriod => 'Utwórz okres';

  @override
  String get editPlan => 'Edytuj plan';

  @override
  String get saveChanges => 'Zapisz zmiany';

  @override
  String get noEnvelopesForExpense =>
      'Ten okres nie ma jeszcze żadnych kopert. Dodaj kategorie do okresu, zanim zapiszesz wydatki.';

  @override
  String get envelope => 'Koperta';

  @override
  String get pickEnvelope => 'Wybierz kopertę';

  @override
  String get amount => 'Kwota';

  @override
  String get enterAmount => 'Podaj kwotę';

  @override
  String get date => 'Data';

  @override
  String get noteOptional => 'Notatka (opcjonalnie)';

  @override
  String get saveExpense => 'Zapisz wydatek';

  @override
  String get editExpense => 'Edytuj wydatek';

  @override
  String get categories => 'Kategorie';

  @override
  String get manageCategories => 'Zarządzaj kategoriami';

  @override
  String get newCategory => 'Nowa kategoria';

  @override
  String get editCategory => 'Edytuj kategorię';

  @override
  String get name => 'Nazwa';

  @override
  String get icon => 'Ikona';

  @override
  String get color => 'Kolor';

  @override
  String get save => 'Zapisz';

  @override
  String get delete => 'Usuń';

  @override
  String get addCategory => 'Dodaj kategorię';

  @override
  String get noCategories => 'Brak kategorii. Dodaj swoją pierwszą.';

  @override
  String get categoryInUse => 'Nie można usunąć kategorii używanej w okresie.';

  @override
  String get period => 'Okres';

  @override
  String get expenses => 'Wydatki';

  @override
  String get noExpenses => 'Brak wydatków w tej kopercie.';

  @override
  String get deleteExpense => 'Usuń wydatek';

  @override
  String deleteExpenseConfirm(String amount) {
    return 'Usunąć ten wydatek na $amount?';
  }

  @override
  String get cancel => 'Anuluj';

  @override
  String get expenseDeleted => 'Wydatek usunięty';

  @override
  String get plannedSplit => 'Podział planu';

  @override
  String get plannedVsSpent => 'Plan a wydatki';

  @override
  String get spendingOverTime => 'Wydatki w czasie';

  @override
  String get notEnoughData => 'Za mało danych.';

  @override
  String get recurringRules => 'Reguły cykliczne';

  @override
  String get newRule => 'Nowa reguła';

  @override
  String get editRule => 'Edytuj regułę';

  @override
  String get addRule => 'Dodaj regułę';

  @override
  String get category => 'Kategoria';

  @override
  String get note => 'Notatka';

  @override
  String get frequency => 'Częstotliwość';

  @override
  String get weekly => 'Tygodniowo';

  @override
  String get monthly => 'Miesięcznie';

  @override
  String get active => 'Aktywna';

  @override
  String get noRecurringRules =>
      'Brak reguł cyklicznych. Dodaj szablony dla stałych przychodów lub wydatków.';

  @override
  String get prefillFromRecurring => 'Wypełnij z reguł';

  @override
  String get applyRecurring => 'Dodaj cykliczne do okresu';

  @override
  String recurringApplied(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Dodano $count wydatku cyklicznego',
      many: 'Dodano $count wydatków cyklicznych',
      few: 'Dodano $count wydatki cykliczne',
      one: 'Dodano 1 wydatek cykliczny',
      zero: 'Wszystko jest już aktualne',
    );
    return '$_temp0';
  }

  @override
  String get needCategoryFirst => 'Najpierw dodaj kategorię.';

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
  String get dataSection => 'Dane';

  @override
  String get currency => 'Waluta';

  @override
  String get firstDayOfMonth => 'Pierwszy dzień miesiąca';

  @override
  String get theme => 'Motyw';

  @override
  String get themeDark => 'Ciemny';

  @override
  String get themeLight => 'Jasny';

  @override
  String get themeAuto => 'Auto';

  @override
  String get exportCsv => 'Eksportuj dane (CSV)';

  @override
  String get importCsv => 'Importuj z CSV';

  @override
  String importResult(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Zaimportowano $count wydatku',
      many: 'Zaimportowano $count wydatków',
      few: 'Zaimportowano $count wydatki',
      one: 'Zaimportowano 1 wydatek',
      zero: 'Brak wydatków do zaimportowania',
    );
    return '$_temp0';
  }

  @override
  String importSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: ', pominięto $count duplikatu',
      many: ', pominięto $count duplikatów',
      few: ', pominięto $count duplikaty',
      one: ', pominięto 1 duplikat',
    );
    return '$_temp0';
  }

  @override
  String get about => 'O aplikacji';

  @override
  String csvExported(String path) {
    return 'Wyeksportowano do $path';
  }

  @override
  String get today => 'Dziś';

  @override
  String get noteHint => 'np. Zakupy tygodniowe';

  @override
  String get addNew => 'Nowa';

  @override
  String remainingInCategory(String category) {
    return 'Pozostało w $category';
  }

  @override
  String get history => 'Historia';

  @override
  String get periods => 'Okresy';

  @override
  String get all => 'Wszystkie';

  @override
  String get dateRange => 'Zakres dat';

  @override
  String get noMatchingExpenses => 'Brak wydatków pasujących do filtrów.';

  @override
  String get yesterday => 'Wczoraj';

  @override
  String get noPeriodsYet => 'Brak okresów.';

  @override
  String get upcoming => 'Nadchodzące';

  @override
  String get currentSet => 'Bieżący';

  @override
  String get earlier => 'Wcześniejsze';

  @override
  String get newExpense => 'Nowy wydatek';

  @override
  String get deletePeriod => 'Usuń okres';

  @override
  String deletePeriodConfirm(String name) {
    return 'Usunąć „$name” i wszystkie jego dane?';
  }

  @override
  String get periodDeleted => 'Okres usunięty';

  @override
  String get dashboard => 'Pulpit';

  @override
  String periodRange(String start, String end) {
    return '$start – $end';
  }

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
  String get signInTitle => 'Zaloguj się';

  @override
  String get signInSubtitle =>
      'Podaj adres e-mail. Wyślemy Ci kod i link do zalogowania, nie ma hasła.';

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
  String get signInCode => 'Kod';

  @override
  String get enterCode => 'Wpisz 6-cyfrowy kod';

  @override
  String get signInAction => 'Zaloguj się';

  @override
  String get useOtherEmail => 'Użyj innego adresu';

  @override
  String get resendCode => 'Wyślij kod ponownie';

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
  String get householdTab => 'Gospodarstwo';

  @override
  String get incomes => 'Wpłaty';

  @override
  String get periodBalance => 'Saldo okresu';

  @override
  String get unallocatedToEnvelopes => 'Nierozdzielone na koperty';

  @override
  String get addIncomeShort => '+ Wpłata';

  @override
  String get addExpenseShort => '+ Wydatek';

  @override
  String get soloSubtitle => 'Solo · tylko Ty';

  @override
  String get previousPeriod => 'Poprzedni okres';

  @override
  String get nextPeriod => 'Następny okres';

  @override
  String get wizardStartTitle => 'Ustawmy Twój budżet';

  @override
  String get wizardStartBody =>
      'Pięć krótkich kroków: nazwa, domownicy, wpłaty, rachunki i koperty.';

  @override
  String get wizardStart => 'Zaczynamy';

  @override
  String stepOf(int step, int total) {
    return 'Krok $step z $total';
  }

  @override
  String get later => 'Później';

  @override
  String get next => 'Dalej';

  @override
  String get back => 'Wstecz';

  @override
  String get wizardNameTitle => 'Jak nazwiesz swoje gospodarstwo?';

  @override
  String get wizardNameBody =>
      'To może być „Dom”, „Mieszkanie na Woli” albo „Moje”. Później dodasz kolejne.';

  @override
  String get currencyPln => 'PLN – złoty';

  @override
  String get starterCategories =>
      'Dodamy kategorie na start – zmienisz je w każdej chwili';

  @override
  String get starterFood => 'Jedzenie';

  @override
  String get starterHousing => 'Mieszkanie i rachunki';

  @override
  String get starterTransport => 'Transport';

  @override
  String get starterHealth => 'Zdrowie';

  @override
  String get starterFun => 'Rozrywka';

  @override
  String get starterClothes => 'Ubrania';

  @override
  String get starterOther => 'Inne';

  @override
  String wizardWhoTitle(String name) {
    return 'Kto będzie korzystał z „$name”?';
  }

  @override
  String get soloTitle => 'Tylko ja · Solo';

  @override
  String get soloBody =>
      'Prywatny budżet. Możesz go później zamienić na wspólny.';

  @override
  String get multiTitle => 'Z domownikami · Multi';

  @override
  String get multiBody =>
      'Wszyscy widzą te same dane. Przy wpłatach i wydatkach wskażesz, kogo dotyczą.';

  @override
  String get inviteByEmail => 'Zaproś przez e-mail';

  @override
  String get inviteHint => 'adres@domownika.pl';

  @override
  String get send => 'Wyślij';

  @override
  String get sharingSoon =>
      'Wspólne gospodarstwa i zaproszenia będą dostępne wkrótce. Na razie budżet jest tylko Twój.';

  @override
  String get wizardIncomeTitle => 'Skąd przychodzą pieniądze?';

  @override
  String wizardIncomeBody(String period) {
    return 'Pierwszy okres: $period. Nieznaną kwotę wpisz szacunkowo – poprawisz ją, gdy wpłynie.';
  }

  @override
  String get newIncome => 'Nowa wpłata';

  @override
  String get fixedAmount => 'Stała';

  @override
  String get estimatedAmount => 'Szacunkowa';

  @override
  String get incomeNameHint => 'np. Pensja';

  @override
  String get addIncomeAction => 'Dodaj wpłatę';

  @override
  String get periodIncome => 'Dochód okresu';

  @override
  String get wizardBillsTitle => 'Rachunki, które wracają co miesiąc';

  @override
  String get wizardBillsBody =>
      'Stałe, jak czynsz, i zmienne, jak prąd. Przycisk „Zastosuj” doda je do każdego okresu.';

  @override
  String get addRecurringExpense => '+ Dodaj wydatek cykliczny';

  @override
  String get wizardEnvelopesTitle => 'Rozdziel dochód na koperty';

  @override
  String get wizardEnvelopesBody =>
      'Ile planujesz wydać w każdej kategorii w tym okresie. Kwoty z rachunków cyklicznych są już podpowiedziane.';

  @override
  String fromRecurring(String amount) {
    return 'cykliczne: $amount';
  }

  @override
  String get addCategoryPlus => '+ Dodaj kategorię';

  @override
  String get allocated => 'Rozdzielone';

  @override
  String get unallocatedShort => 'Nierozdzielone';

  @override
  String get wizardDone => 'Gotowe – przejdź do pulpitu';

  @override
  String get everyMonth => 'co miesiąc';

  @override
  String get everyWeek => 'co tydzień';

  @override
  String get descriptionOptional => 'Opis (opcjonalnie)';

  @override
  String get descriptionHint => 'np. zakupy w Biedronce';

  @override
  String get oneOff => 'Jednorazowa';

  @override
  String get recurringIncome => 'Cykliczna';

  @override
  String get recurringIncomeSoon => 'Wpłaty cykliczne będą dostępne wkrótce.';

  @override
  String incomeGoesTo(String period) {
    return 'Wpłata zwiększy dochód okresu $period.';
  }

  @override
  String get saveIncome => 'Zapisz wpłatę';

  @override
  String get incomeAdded => 'Dodano wpłatę';

  @override
  String get recurringMark => 'cykliczny';

  @override
  String get noTransactions => 'Brak wydatków w tym okresie.';

  @override
  String get newRulePlus => '+ Nowa reguła';

  @override
  String applyTo(String period) {
    return 'Zastosuj do: $period';
  }

  @override
  String get applyHint =>
      'Doda wpisy z aktywnych reguł. Już dodane się nie zdublują.';

  @override
  String get ruleFixed => 'stała';

  @override
  String get ruleOff => 'wyłączona';

  @override
  String get households => 'Gospodarstwa';

  @override
  String get newHouseholdPlus => '+ Nowe gospodarstwo';

  @override
  String membersOf(String name) {
    return 'Członkowie · $name';
  }

  @override
  String youMark(String name) {
    return '$name (ty)';
  }

  @override
  String get owner => 'właściciel';

  @override
  String get invitePerson => 'Zaproś osobę';

  @override
  String get more => 'Więcej';

  @override
  String get renameHousehold => 'Zmień nazwę';

  @override
  String get householdName => 'Nazwa gospodarstwa';
}
