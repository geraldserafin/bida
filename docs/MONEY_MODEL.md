# Model pieniędzy (SWS v0.5)

Dokument opisuje, jak działają pieniądze w aplikacji i jak to wygląda w kodzie. Źródłem wymagań jest Confluence BIDA:

- [SWS v0.5 – Portfel, gospodarstwa, okresy i koperty](https://pjwstk-team-ofw0yvnq.atlassian.net/wiki/spaces/BIDA/pages/1638401): model i ustalenia z rozdziału 14,
- [SWS 3.2](https://pjwstk-team-ofw0yvnq.atlassian.net/wiki/spaces/BIDA/pages/294949): karty F z kryteriami akceptacji,
- [SWS 3.1](https://pjwstk-team-ofw0yvnq.atlassian.net/wiki/spaces/BIDA/pages/294931): WO08, czyli wzory sald.

Ten model zastąpił poprzedni, oparty na kopertach z podkopertami, puli i saldach toczących się z miesiąca na miesiąc. Nie ma migracji danych. Bazę produkcyjną trzeba wyczyścić przed wdrożeniem (patrz [Wdrożenie](#wdrożenie)).

## Idea

Każda osoba ma prywatny **portfel**. Wpisuje do niego **wpływy**, a potem **przelewa** pieniądze do **gospodarstw**.

Gospodarstwo dzieli czas na **okresy**, na przykład miesiące. Każdy okres to osobna **skarbonka** z własnym saldem i z **planami kopert**. Wydatek zużywa plan swojej koperty i saldo skarbonki bieżącego okresu.

Po końcu okresu to, co zostało w skarbonce, przechodzi do następnego okresu jako **pieniądze niczyje**. Nic nie wraca do portfeli.

Udział każdej osoby w skarbonce to: jej przelewy − jej wycofania − jej wydatki ponad pieniądze niczyje.

## Pojęcia i wzory (WO08)

| Pojęcie | Wzór / zasada |
|---|---|
| Saldo portfela | wpływy − przelewy + wycofania (+ zwroty udziałów) |
| „w tym niepotwierdzone” | suma wpływów szacowanych |
| Saldo skarbonki | przelewy − wycofania + niewydane z poprzedniego okresu − wydatki |
| Plan koperty | część ręczna + część cykliczna (kwota reguły × liczba wystąpień w okresie) |
| Pozostała część planów | Σ po kopertach max(plan − wydane, 0) |
| Wolne pieniądze | saldo skarbonki − pozostała część planów; ujemne oznacza „Plan przekracza saldo gospodarstwa” |
| Udział | przelewy osoby − jej wycofania − oddane (wyjście) − jej wydatki ponad pieniądze niczyje |
| Pieniądze niczyje | niewydane z poprzedniego okresu + udziały oddane przy wyjściu |

Wszystkie kwoty są liczbami całkowitymi w groszach. Arytmetyka leży w czystym module `apps/api/src/modules/ledger/money.ts`, bez bazy, i ma testy jednostkowe w `ledger.test.ts`.

## Portfel (F31, F32)

- Portfel nie schodzi poniżej zera. Wyjątki są dwa:
  - wydatek zatwierdzony mimo pustego portfela (krok 3 z F08),
  - korekta wpływu w dół.
- Dopóki portfel jest na minusie, przelewy dają 409 `WalletNegative`.
- Przelew większy niż saldo portfela daje 409 `NotEnoughMoney`.
- Przelew opłacony niepotwierdzonymi pieniędzmi przechodzi. Odpowiedź ma wtedy `usedUnconfirmed: true` i aplikacja pokazuje ostrzeżenie.
- Wycofać można najwyżej `min(udział, saldo skarbonki)` (`withdrawableOf`).
- Korekta wpływu w dół, która robi minus, daje 409 `WalletWouldGoNegative`. Ponowne żądanie z `correction` wybiera jedno z dwóch:
  - `allowNegative`: minus zostaje do następnego wpływu,
  - `withdrawFromPeriodId`: brakująca kwota zostaje najpierw wycofana z tego okresu.
- Wpisy portfela (`wallet_entries`) są niezależne od gospodarstw. Usunięcie gospodarstwa nie zmienia więc salda portfela, a historia zachowuje nazwę gospodarstwa.

## Gospodarstwa i okresy (F05, F06, F24)

- Cykl okresów ma trzy rodzaje:
  - `monthly`: od dnia 1–31; dzień spoza krótszego miesiąca przypada na jego ostatni dzień,
  - `weeks`: co N tygodni od daty,
  - `manual`: nowy okres trwa tyle, co poprzedni.

  Domyślnie jest co miesiąc od 1., w strefie `Europe/Warsaw`. Kod leży w `ledger/cycle.ts`.
- Okresy nie mają dziur ani nie nakładają się, a obie daty okresu są włącznie. Dzień wydatku to dzień w strefie gospodarstwa (`localDay`).
- Otwarte są najwyżej dwa okresy: bieżący i następny. Następny otwiera dowolny członek przez `POST /households/:id/periods/next`. Gdy bieżący się skończy, następny otwiera się sam.
- Właściciel może przesunąć koniec bieżącego okresu przez `PUT /periods/:id/end`:
  - nie wcześniej niż dziś (422 `InvalidPeriodEnd`, `beforeToday`),
  - i wcześniej niż koniec następnego okresu (`overlapsNext`).

  Cykl przelicza się wtedy od nowego końca (`reanchor`). Następny okres zaczyna się dzień po nowym końcu, a jego pieniądze zostają w nim. Część cykliczna planów przelicza się w obu okresach.
- Zamknięty okres jest zamrożony. Wydatek da się w nim tylko przemianować; pozostałe zmiany dają 409 `PeriodClosed`.
- Wydawać można tylko z bieżącego okresu, i to z datą nie późniejszą niż teraz (422 `DateOutsidePeriod`). Następny okres służy tylko do planowania.

## Koperty i plany (F11, F12, F19)

- Koperty tworzą się w gospodarstwie, jako płaska lista bez podkopert. Nowe gospodarstwo dostaje 7 domyślnych kopert. Nazwa koperty jest unikalna bez względu na wielkość liter (409 `DuplicateEnvelopeName`).
- Kopertę z wydatkami archiwizuje się zamiast usuwać (409 `EnvelopeHasExpenses`). Archiwizacja obniża plan w otwartych okresach do kwoty już wydanej. Ostatniej aktywnej koperty nie da się usunąć ani zarchiwizować (409 `LastEnvelope`).
- Plan ustawia dowolny członek, jako jedną kwotę. Serwer odejmuje od niej część cykliczną, a resztę zapisuje jako część ręczną (`plans.manual_minor`). Plan nie może zejść poniżej kwoty wydanej (409 `PlanBelowSpent`). Suma planów może przekroczyć saldo skarbonki; wtedy `plansExceedBalance` w zestawieniu jest `true`.
- Przy otwarciu nowego okresu część ręczna kopiuje się z poprzedniego, a część cykliczna liczy się od nowa (`createPeriod`). Zmiana reguł, okresów albo kopert wywołuje `refreshPlans`.

## Wydatek i kroki z F08

`POST /households/:id/expenses` i `PUT /expenses/:id` przechodzą przez `fitOf` i `settle` w `ledger/money.ts`:

1. **Mieści się** w planie koperty i w saldzie: wydatek się zapisuje.
2. **Za mały plan, ale są wolne pieniądze**: plan podnosi się sam o brakującą kwotę. Odpowiedź ma wtedy `raisedPlanMinor`.
3. **Za mały plan i brak wolnych pieniędzy**: 409 `PlanTooSmall` z polami `planShortMinor`, `freeMinor`, `balanceMinor` i `transferMinor`. `transferMinor` to kwota, którą trzeba dołożyć z portfela.
4. **Plan wystarcza, ale saldo nie**: 409 `NotEnoughInPeriod` z polem `transferMinor`.
5. Ponowne żądanie niesie `decision: { raisePlan, transferMinor, allowNegativeWallet }`. Serwer w jednej transakcji robi przelew z portfela osoby, która dodaje wydatek, podnosi plan i zapisuje wydatek. Gdyby przelew zrobił minus w portfelu bez `allowNegativeWallet`, serwer odpowiada 409 `WalletWouldGoNegative`.

Plan podnosi się automatycznie tylko z bieżącej skarbonki. Edycja przechodzi te same kroki, a jako punkt odniesienia służy stan bez edytowanego wydatku. Usunięcie wydatku zwraca pieniądze do salda skarbonki.

Uprawnienia: autor zmienia swój wydatek, właściciel także cudze. Zamrożony członek nie wydaje (409 `MemberFrozen`). Pole „Dla kogo” (`member`, `shared` albo puste) służy tylko do filtrowania i nie zmienia udziałów.

## Udziały, wyjście, zamrożenie, usuwanie (F33, F36, F14, F06, F04)

- Wydatki zużywają najpierw pieniądze niczyje, w kolejności `spent_at`, potem `created_at`. Dopiero potem zużywają udział autora (`sharesOf`).
- Ujemny udział blokuje trzy rzeczy, zawsze z odpowiedzią 409 `NegativeShare` i listą osób, gospodarstw i kwot:
  - wyjście z gospodarstwa,
  - usunięcie członka przez właściciela,
  - usunięcie gospodarstwa i usunięcie konta.
- **Wyjście** (`POST /households/:id/leave`): `withdraw: true` wycofuje udziały do portfela, a `false` zostawia je jako pieniądze niczyje (ruch `forfeit`). Ostatni właściciel musi najpierw nadać rolę komuś innemu (409 `LastOwner`). Wyjście ostatniego członka usuwa gospodarstwo.
- **Usunięcie członka** przez właściciela zwraca jego dodatni udział do jego portfela (wpis `return`).
- **Zamrożenie**: właściciel może zamrozić członka. Zamrożony nie wydaje. Gdy jego udział we wszystkich otwartych okresach przestanie być ujemny, zostaje usunięty: po jego przelewie albo przy zamknięciu okresu.
- **Usunięcie gospodarstwa**: dodatnie udziały wracają do portfeli. Pieniądze niczyje przepadają razem z gospodarstwem.
- **Usunięcie konta** (`POST /account/delete`) wymaga wpisania adresu e-mail. Gospodarstwa, w których użytkownik był sam, znikają. W pozostałych jego dodatnie udziały zostają jako pieniądze niczyje, a jeśli był ostatnim właścicielem, rolę dostaje członek z najdłuższym stażem. Portfel, wpływy i reguły użytkownika znikają razem z kontem.

## Reguły cykliczne (F25, F26, F27)

Reguła ma rodzaj: `income` (do portfela), `transfer` (portfel → okres) albo `expense` (wydatek gospodarstwa, którego autorem jest twórca reguły). Harmonogram to `monthly` od dnia 1–31 albo `weeks`, czyli co N tygodni od daty. Reguła działa od `startsOn`.

- Szacowany wpływ wchodzi z kwotą szacowaną w swoim dniu. Trafia też do „Do załatwienia” (`income_estimate`), gdzie czeka na korektę.
- Przelew trafia do okresu swojego dnia albo, przy `target: next`, do okresu po nim. Następny okres otwiera się wtedy sam. Przelew do zamkniętego okresu trafia do bieżącego. Gdy w portfelu brakuje pieniędzy, przelew się nie wykonuje i trafia do `transfer_no_money`.
- Przelew może iść za regułą wpływu (`incomeRuleId`, migracja `0002_linked_transfer`). Nie ma wtedy własnej kwoty ani harmonogramu i nie stosuje się go ręcznie. Gdy wystąpienie wpływu staje się pewne, cała jego kwota przelewa się z tym samym dniem wystąpienia. Dzieje się tak, gdy wpływ wchodzi ze znaną kwotą (przy otwarciu aplikacji albo przy ręcznym zastosowaniu) albo gdy szacunek zostaje potwierdzony. Usunięcie reguły wpływu usuwa przelewy, które za nią idą.
- Wydatek cykliczny dolicza się do planu swojej koperty. Dodaje się w swoim dniu. Krok 2 z F08 działa przy tym sam. Wydatek, który się nie mieści, trafia do `expense_not_fit`. Wydatek szacowany zapisuje się od razu i czeka w `expense_estimate` na potwierdzenie, ale tylko do końca okresu. Po zamknięciu zostaje z kwotą szacowaną.
- Wystąpienie z okresu, który zamknął się, zanim ktoś otworzył aplikację, trafia do `expense_missed`. Można je dodać w bieżącym okresie.
- Wcześniejsze zastosowanie reguły: `POST /recurring-rules/:id/apply`. Wszystkie wydatki cykliczne gospodarstwa z bieżącego okresu: `POST /households/:id/recurring-rules/apply`.
- Każde wystąpienie zapisuje się w `rule_occurrences` ze stanem `done`, `todo` albo `missed`, i to przed wykonaniem. Unikalne indeksy po (`rule_id`, `occurrence_on`) na wydatkach, ruchach, wpływach i zadaniach dodatkowo gwarantują, że nic nie wykona się dwa razy.

## Otwarcie aplikacji (F34, F35)

Nic nie dzieje się w tle na serwerze. Aplikacja przy każdym starcie woła `POST /sync`. Endpoint w jednej transakcji, pod blokadami portfela i wszystkich gospodarstw użytkownika, robi kolejno:

1. zamyka okresy, które się skończyły. Reszta skarbonki przechodzi jako ruch `carry` do następnego okresu, wpisy logu zamkniętego okresu znikają, a sprawy dotyczące tego okresu są zamykane;
2. otwiera nowe okresy i kopiuje plany;
3. dodaje wpływy cykliczne użytkownika;
4. wykonuje przelewy cykliczne użytkownika;
5. dodaje wydatki cykliczne gospodarstw użytkownika.

Ponowne wywołanie nic nie zmienia, co sprawdza test `incomes, then transfers, then expenses; again it does nothing`. Kolejność kroków też jest sprawdzana: w teście przelew potrzebuje wpływu, a wydatek przelewu.

Odpowiedź zawiera liczbę spraw w „Do załatwienia” i podsumowania zamkniętych okresów, których użytkownik jeszcze nie widział. Każdy członek widzi podsumowanie raz, po `POST /periods/:id/summary/seen`.

Sprawy portfela (`user_id`) widzi tylko jego właściciel. Sprawy gospodarstwa widzą wszyscy członkowie. Sprawa załatwiona przez jedną osobę znika u wszystkich.

## Log zmian (F37)

`change_log` zapisuje zmiany w otwartych okresach: kto, co, kiedy, a do tego dane potrzebne do cofnięcia. Zapisywane są wydatki, plany, przelewy, wycofania, koperty i koniec okresu. Przy zamknięciu okresu jego wpisy są usuwane.

`POST /log/:id/undo` cofa zmianę, jeśli robi to osoba, która ma do niej prawo:

| Zmiana | Kto może cofnąć |
|---|---|
| Przelew, wycofanie | sama osoba |
| Wydatek | autor albo właściciel |
| Koniec okresu | właściciel |
| Plany, koperty | każdy członek |

Cofnięcie przechodzi te same walidacje co zwykła zmiana. Jeśli łamie regułę, serwer odpowiada 409, a zmiana nie jest cofana.

## Pulpit (F38)

`GET /overview?from&to` zwraca portfel na dziś i każde gospodarstwo z saldem i wolnymi pieniędzmi bieżącej skarbonki, a także kwotą wydaną w podanym zakresie dni. Zakres wybiera się w ustawieniach aplikacji: bieżący miesiąc, okres wybranego gospodarstwa albo dowolne daty. Wybór zapisuje się na urządzeniu (`AppSettings`).

## Dane

```
users, login_codes, sessions, identities           -- bez zmian
households(cycle_kind, cycle_day, cycle_weeks, cycle_anchor, time_zone)
household_members(role, frozen_at, joined_at)
invitations(household_id, email, role, status, expires_at)
periods(starts_on, ends_on, closed_at, carry_out_minor)
period_summary_seen(period_id, user_id)
envelopes(household_id, name, color, icon, position, archived_at)
plans(period_id, envelope_id, manual_minor, recurring_minor)
period_moves(kind: transfer|withdrawal|carry|forfeit, user_id NULL = niczyje, rule_id, occurrence_on)
expenses(period_id, envelope_id, created_by, author_name, spent_at, title,
         for_whom, for_whom_user_id, for_whom_name, estimated, rule_id, occurrence_on)
wallet_entries(kind: income|transfer|withdrawal|return, estimated, move_id, household_name)
recurring_rules(kind, user_id, household_id, envelope_id, frequency, day_of_month,
                every_weeks, anchor_on, starts_on, target, estimated, active)
rule_occurrences(rule_id, occurrence_on, outcome)
todo_items(kind, user_id | household_id, period_id, rule_id, ref_id, amount_minor)
change_log(household_id, period_id, action, entity_id, before, after, undone_at)
```

Jedna migracja bazowa: `apps/api/src/platform/migrations/0001_base.ts`. Salda nie są przechowywane; liczy je `ledger/money.ts` na podstawie ruchów, wydatków i planów jednego okresu. Wyjątkiem jest `carry_out_minor` zamkniętego okresu, bo ten okres jest zamrożony.

Równoległe zmiany porządkują blokady doradcze Postgresa na portfel (`w:<user>`) i gospodarstwo (`h:<household>`). Operacja bierze wszystkie potrzebne blokady naraz i w stałej kolejności (`store.lock`), więc dwie operacje nie zakleszczają się.

## Założenia do potwierdzenia

Dokumentacja nie rozstrzygnęła tych spraw. Przyjęliśmy poniższe ustalenia; każde da się zmienić w jednym miejscu kodu.

| # | Sprawa | Przyjęte | Gdzie w kodzie |
|---|---|---|---|
| 1 | F04 mówi o potwierdzeniu hasłem, a aplikacja nie ma haseł | potwierdzenie wpisaniem adresu e-mail konta | `account.service.ts` |
| 2 | Ujemny udział przy zamknięciu okresu | znika razem z okresem: reszta przechodzi jako niczyja, a udziały w nowym okresie liczą się od zera, więc zamrożony członek odpada najpóźniej przy zamknięciu | `closeDue`, `sharesOf` |
| 3 | Kolejność zużycia pieniędzy niczyich | chronologicznie według `spent_at`, potem `created_at`; edycja wcześniejszego wydatku może przesunąć udziały | `sharesOf` |
| 4 | Właściciel usuwa członka z dodatnim udziałem | udział wraca do portfela tej osoby, o ile jest w skarbonce; reszta staje się niczyja | `removeMember(..., "return")` |
| 5 | Cykl z ręcznym końcem | nowy okres trwa tyle, co poprzedni | `nextPeriod` |
| 6 | Co miesiąc od dnia 29–31 | w krótszym miesiącu okres zaczyna się ostatniego dnia | `dayInMonth` |
| 7 | Częstotliwość reguł | co miesiąc w dniu 1–31 albo co N tygodni od daty | `occurrences` |
| 8 | Zaproszenia | przyjęcie od razu robi członkiem (bez zatwierdzania przez właściciela), ważne 7 dni | `members.service.ts` |
| 9 | Przelew cykliczny na następny okres, gdy ten nie jest otwarty | `/sync` otwiera następny okres | `targetPeriod` |
| 10 | Usunięcie gospodarstwa | dodatnie udziały wracają do portfeli, pieniądze niczyje przepadają | `removeHousehold` |
| 11 | Migracje | `0001`–`0012` zastąpione przez `0001_base`; wymaga wyczyszczenia bazy razem z `effect_sql_migrations` | `wipe-database.sql` |
| 12 | Twórca reguły wydatku wychodzi z gospodarstwa | jego reguły w tym gospodarstwie się wyłączają | `deactivateRulesOf` |
| 13 | Wpływy portfela nie mają strefy gospodarstwa | dni liczą się w `Europe/Warsaw` | `walletToday` |
| 14 | Przelew „cały wpływ” przy wpływie szacowanym | czeka na potwierdzenie i przelewa prawdziwą kwotę; późniejsza edycja wpływu już niczego nie przelewa | `runLinked` |
| 15 | Reguła wpływu, za którą idzie przelew, zostaje usunięta | przelew też znika (nie zaczyna przelewać starej kwoty sam) | `ON DELETE CASCADE` |

## Wdrożenie

Baza produkcyjna musi być pusta, bo stare migracje mają te same numery co nowa. Operacja jest nieodwracalna, więc uruchamia ją człowiek, a nie aplikacja:

1. Zatrzymaj API.
2. Zrób kopię bazy: `pg_dump "$DATABASE_URL" -Fc -f bida-before-v05.dump`.
3. Wyczyść bazę: `psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -v wipe_confirmed=true -f apps/api/scripts/wipe-database.sql`. Bez `-v wipe_confirmed=true` skrypt nic nie robi.
4. Wdróż nowe API. Migrator przy starcie utworzy schemat z `0001_base`.
5. Zaktualizuj aplikację mobilną. Stara wersja nie zadziała z nowym API.
