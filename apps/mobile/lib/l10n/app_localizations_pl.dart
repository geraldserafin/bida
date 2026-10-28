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
  String get addExpense => 'Dodaj wydatek';

  @override
  String get envelopes => 'Koperty';

  @override
  String get noEnvelopes => 'Nie ma jeszcze żadnych kopert.';

  @override
  String get income => 'Wpływy';

  @override
  String get spent => 'Wydano';

  @override
  String get overAllocated => 'Przydzielono za dużo';

  @override
  String get saveChanges => 'Zapisz zmiany';

  @override
  String get noEnvelopesForExpense =>
      'Nie masz jeszcze żadnych kopert. Dodaj kopertę, zanim zapiszesz wydatek.';

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
  String get spendingOverTime => 'Wydatki w czasie';

  @override
  String get notEnoughData => 'Za mało danych.';

  @override
  String get newRule => 'Nowa reguła';

  @override
  String get editRule => 'Edytuj regułę';

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
  String get history => 'Historia';

  @override
  String get all => 'Wszystkie';

  @override
  String get dateRange => 'Zakres dat';

  @override
  String get noMatchingExpenses => 'Brak wydatków pasujących do filtrów.';

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
  String get addEnvelope => 'Dodaj kopertę';

  @override
  String get addIncome => 'Dodaj wpływ';

  @override
  String get addSubEnvelope => 'Dodaj podkopertę';

  @override
  String get allocate => 'Przydziel';

  @override
  String get allocated => 'Rozdzielone';

  @override
  String get allocationDeleted => 'Przydział usunięty';

  @override
  String get allocations => 'Przydziały';

  @override
  String get available => 'Dostępne';

  @override
  String get balance => 'Saldo';

  @override
  String balanceOfEnvelope(String envelope) {
    return 'Saldo koperty $envelope';
  }

  @override
  String canTakeBack(String amount) {
    return 'Do wycofania: $amount';
  }

  @override
  String get deleteAllocation => 'Usuń przydział';

  @override
  String deleteAllocationConfirm(String amount) {
    return 'Usunąć przydział na $amount?';
  }

  @override
  String get deleteEnvelope => 'Usuń kopertę';

  @override
  String deleteEnvelopeConfirm(String name) {
    return 'Usunąć „$name” razem z podkopertami, wydatkami i przydziałami? Przydzielone pieniądze wrócą do puli.';
  }

  @override
  String get deleteIncome => 'Usuń wpływ';

  @override
  String deleteIncomeConfirm(String amount) {
    return 'Usunąć wpływ na $amount?';
  }

  @override
  String get editEnvelope => 'Edytuj kopertę';

  @override
  String get editIncome => 'Edytuj wpływ';

  @override
  String get envelopeDeleted => 'Koperta usunięta';

  @override
  String get firstDayOfMonthHint => 'Od tego dnia liczy się miesiąc budżetowy';

  @override
  String get freeInEnvelope => 'Wolne w kopercie';

  @override
  String get fromEarlierMonths => 'Z poprzednich miesięcy';

  @override
  String get incomeDeleted => 'Wpływ usunięty';

  @override
  String get incomeNoteHint => 'np. Wypłata';

  @override
  String get incomes => 'Wpłaty';

  @override
  String get manageEnvelopes => 'Zarządzaj kopertami';

  @override
  String monthLine(String income, String allocated) {
    return 'Wpływy $income · przydzielono $allocated';
  }

  @override
  String get months => 'Miesiące';

  @override
  String get needEnvelopeFirst => 'Najpierw dodaj kopertę.';

  @override
  String get newEnvelope => 'Nowa koperta';

  @override
  String get nextMonth => 'Następny miesiąc';

  @override
  String get noAllocations => 'Nic jeszcze nie przydzielono.';

  @override
  String get noIncomes =>
      'Brak wpływów. Dodaj pierwszą wypłatę, a potem podziel ją na koperty.';

  @override
  String get noMonthsYet => 'Brak miesięcy.';

  @override
  String get noParent => 'Brak (koperta główna)';

  @override
  String notEnoughMoney(String amount) {
    return 'Za mało środków. Dostępne: $amount.';
  }

  @override
  String get parentEnvelope => 'Nadrzędna koperta';

  @override
  String parentFreeCaption(String parent, String amount) {
    return 'Wolne w „$parent”: $amount';
  }

  @override
  String poolCaption(String amount) {
    return 'Nieprzydzielone: $amount';
  }

  @override
  String get previousMonth => 'Poprzedni miesiąc';

  @override
  String get subEnvelopes => 'Podkoperty';

  @override
  String get takeBack => 'Wycofaj';

  @override
  String get accept => 'Przyjmij';

  @override
  String get alreadyMember => 'Ten adres należy już do członka koperty.';

  @override
  String get approve => 'Zatwierdź';

  @override
  String get awaitingAnswer => 'Czeka na odpowiedź';

  @override
  String get awaitingApproval => 'Przyjęte, czeka na zatwierdzenie';

  @override
  String get decline => 'Odrzuć';

  @override
  String get formerMember => 'Były członek';

  @override
  String get invitationAccepted =>
      'Przyjęto zaproszenie. Właściciel koperty musi jeszcze zatwierdzić Twoje dołączenie.';

  @override
  String invitationBanner(String inviter, String envelope) {
    return '$inviter zaprasza Cię do koperty „$envelope”';
  }

  @override
  String get invitations => 'Zaproszenia';

  @override
  String invitationSent(String email) {
    return 'Wysłano zaproszenie na $email';
  }

  @override
  String get invite => 'Zaproś';

  @override
  String get inviteByEmail => 'Zaproś przez e-mail';

  @override
  String get lastOwner =>
      'Koperta musi mieć co najmniej jednego właściciela. Najpierw zrób właścicielem kogoś innego.';

  @override
  String get leave => 'Opuść';

  @override
  String get leaveEnvelope => 'Opuść kopertę';

  @override
  String leaveEnvelopeConfirm(String name) {
    return 'Opuścić „$name”? Pieniądze, które do niej włożyłeś, i Twoje wydatki w niej zostają.';
  }

  @override
  String get leftEnvelope => 'Opuszczono kopertę';

  @override
  String get limitReached =>
      'Osiągnięto limit: do koperty można zaprosić do 10 osób, a wysłać do 10 zaproszeń na godzinę.';

  @override
  String get makeMember => 'Zmień na członka';

  @override
  String get makeOwner => 'Zrób właścicielem';

  @override
  String get members => 'Członkowie';

  @override
  String membersOf(String name) {
    return 'Członkowie · $name';
  }

  @override
  String get notShareable =>
      'Współdzielić można tylko kopertę główną; podkoperty idą razem z nią.';

  @override
  String get reject => 'Odrzuć';

  @override
  String get remove => 'Usuń';

  @override
  String get removeMember => 'Usuń z koperty';

  @override
  String removeMemberConfirm(String name) {
    return 'Usunąć $name z koperty? Pieniądze, które włożył, i jego wydatki zostają w kopercie.';
  }

  @override
  String get revokeInvitation => 'Cofnij zaproszenie';

  @override
  String get role => 'Rola';

  @override
  String get roleExplained =>
      'Właściciel zarządza kopertą i jej członkami. Członek dodaje wydatki i przydziela własne pieniądze.';

  @override
  String get roleMember => 'Członek';

  @override
  String get roleOwner => 'Właściciel';

  @override
  String sharedWith(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count osoby',
      many: '$count osób',
      few: '$count osoby',
      one: 'tylko Ty',
    );
    return '$_temp0';
  }

  @override
  String get someone => 'Ktoś';

  @override
  String get whoPutHowMuch => 'Kto ile włożył';

  @override
  String get you => 'Ty';

  @override
  String youWith(String name) {
    return '$name (Ty)';
  }

  @override
  String get addPending => 'Dodaj';

  @override
  String get appliedNothing => 'Wszystko jest już aktualne';

  @override
  String appliedSummary(String parts) {
    return 'Dodano: $parts.';
  }

  @override
  String countAllocations(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count przydziału',
      many: '$count przydziałów',
      few: '$count przydziały',
      one: '$count przydział',
    );
    return '$_temp0';
  }

  @override
  String countExpenses(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wydatku',
      many: '$count wydatków',
      few: '$count wydatki',
      one: '$count wydatek',
    );
    return '$_temp0';
  }

  @override
  String countIncomes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wpływu',
      many: '$count wpływów',
      few: '$count wpływy',
      one: '$count wpływ',
    );
    return '$_temp0';
  }

  @override
  String get dayOfMonth => 'Dzień miesiąca';

  @override
  String get editAllocationRule => 'Edytuj regułę podziału';

  @override
  String get editIncomeRule => 'Edytuj wpływ cykliczny';

  @override
  String everyMonthOn(int day) {
    return 'Co miesiąc, $day.';
  }

  @override
  String get newAllocationRule => 'Nowa reguła podziału';

  @override
  String get newIncomeRule => 'Nowy wpływ cykliczny';

  @override
  String get noAllocationRules =>
      'Brak reguł podziału. Dodaj, ile pieniędzy co miesiąc ma trafiać do koperty, np. 1000 zł do Domu.';

  @override
  String get noRecurringIncomes =>
      'Brak cyklicznych wpływów. Dodaj wypłatę, która wpada co miesiąc w tym samym dniu.';

  @override
  String pendingTitle(String parts) {
    return 'Do dodania w tym miesiącu: $parts';
  }

  @override
  String skippedAllocations(int count) {
    return 'Pominięto przydziały bez pokrycia w kopercie: $count.';
  }

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
  String get unallocatedToEnvelopes => 'Nierozdzielone na koperty';

  @override
  String get addIncomeShort => '+ Wpłata';

  @override
  String get addExpenseShort => '+ Wydatek';

  @override
  String get soloSubtitle => 'Solo · tylko Ty';

  @override
  String get wizardStartTitle => 'Ustawmy Twój budżet';

  @override
  String get wizardStartBody =>
      'Pięć krótkich kroków: koperty, wspólne koperty, wpłaty, rachunki i podział pieniędzy.';

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
  String get currencyPln => 'PLN – złoty';

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
  String get wizardWhoTitle => 'Kto będzie korzystał z kopert?';

  @override
  String get soloTitle => 'Tylko ja · Solo';

  @override
  String get soloBody =>
      'Prywatny budżet. Możesz go później zamienić na wspólny.';

  @override
  String get multiTitle => 'Z innymi · wspólne koperty';

  @override
  String get multiBody =>
      'Wszyscy widzą te same dane. Przy wpłatach i wydatkach wskażesz, kogo dotyczą.';

  @override
  String get inviteHint => 'adres@osoby.pl';

  @override
  String get send => 'Wyślij';

  @override
  String get wizardIncomeTitle => 'Skąd przychodzą pieniądze?';

  @override
  String wizardIncomeBody(String period) {
    return 'Ten miesiąc: $period. Wypłatę zaznacz jako cykliczną – co miesiąc doda się sama, gdy zastosujesz reguły.';
  }

  @override
  String get newIncome => 'Nowa wpłata';

  @override
  String get incomeNameHint => 'np. Pensja';

  @override
  String get addIncomeAction => 'Dodaj wpłatę';

  @override
  String get wizardBillsTitle => 'Rachunki, które wracają co miesiąc';

  @override
  String get wizardBillsBody =>
      'Stałe, jak czynsz, i zmienne, jak prąd. Przycisk „Zastosuj” doda je do każdego miesiąca.';

  @override
  String get addRecurringExpense => '+ Dodaj wydatek cykliczny';

  @override
  String get wizardEnvelopesTitle => 'Rozdziel dochód na koperty';

  @override
  String get wizardEnvelopesBody =>
      'Ile pieniędzy włożyć do każdej koperty. Kwoty z rachunków cyklicznych są już podpowiedziane.';

  @override
  String fromRecurring(String amount) {
    return 'cykliczne: $amount';
  }

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
  String get saveIncome => 'Zapisz wpłatę';

  @override
  String get incomeAdded => 'Dodano wpłatę';

  @override
  String get recurringMark => 'cykliczny';

  @override
  String get noTransactions => 'Brak wydatków w tym miesiącu.';

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
  String get ruleOff => 'wyłączona';

  @override
  String get more => 'Więcej';

  @override
  String get enterIncome => 'Podaj swój dochód';

  @override
  String get envelopesTab => 'Koperty';

  @override
  String get newEnvelopePlus => '+ Nowa koperta';

  @override
  String get addEnvelopePlus => '+ Dodaj kopertę';

  @override
  String get sharingPerEnvelope =>
      'Kopertę można udostępnić innym osobom: wejdź w nią i otwórz „Członkowie”.';

  @override
  String sharedEnvelopes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wspólnej koperty',
      many: '$count wspólnych kopert',
      few: '$count wspólne koperty',
      one: '1 wspólna koperta',
    );
    return '$_temp0';
  }

  @override
  String get allocatedThisMonth => 'Przydzielone w tym miesiącu';

  @override
  String get incomeGoesToPool =>
      'Wpłata trafi do puli, z której przydzielasz pieniądze do kopert.';

  @override
  String get recurringIncomeHint =>
      'Wpłata pojawi się co miesiąc tego dnia, gdy zastosujesz reguły cykliczne.';

  @override
  String get recurringIncomeAdded => 'Dodano wpłatę cykliczną';

  @override
  String get wizardStartersTitle => 'Na co wydajesz pieniądze?';

  @override
  String get wizardStartersBody =>
      'Każda kategoria wydatków to koperta. Odznacz te, których nie potrzebujesz – kolejne dodasz w każdej chwili.';

  @override
  String get starterEnvelopes => 'Koperty na start';

  @override
  String get shareWhichEnvelope => 'Którą kopertę udostępnić?';

  @override
  String invitedPeople(String emails) {
    return 'Zaproszeni: $emails. Dostaną dostęp, gdy przyjmą zaproszenie i je zatwierdzisz.';
  }

  @override
  String get monthIncome => 'Wpływy w miesiącu';

  @override
  String get repeatMonthly => 'Powtarzaj co miesiąc';

  @override
  String get repeatMonthlyHint =>
      'Te kwoty trafią do kopert w każdym miesiącu (reguły podziału).';
}
