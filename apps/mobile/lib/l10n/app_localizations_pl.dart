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
  String get signInAction => 'Zaloguj';

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
  String get signInWithGoogle => 'Zaloguj przez Google';

  @override
  String get googleSignInFailed =>
      'Logowanie przez Google nie udało się. Spróbuj ponownie albo użyj kodu z e-maila.';

  @override
  String get orSeparator => 'lub';
}
