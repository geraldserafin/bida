# Model kopert i współdzielenia

Opis nowego modelu danych i zachowania aplikacji. Zastępuje podział na **przestrzenie** i **okresy**. Jest ustalony przed kodem; zmiany w nim idą razem ze zmianami w kodzie.

## Idea w jednym akapicie

Każdy użytkownik ma własną pulę pieniędzy: wpisuje **przychody**, a z nich **zasila koperty**. Koperta może mieć **subkoperty** (jeden poziom). Wydatki obniżają saldo koperty, zasilenia je podnoszą, a saldo **toczy się** z miesiąca na miesiąc. Kopertę top-level można **współdzielić**: dodani użytkownicy zasilają ją ze swoich pul, każdy widzi, ile włożył on i ile włożyli inni, a nie widzi cudzych pozostałych koper. Nie ma przestrzeni ani okresów.

## Pojęcia

| Pojęcie | Znaczenie |
|---|---|
| **Przychód** | Wpis „wpłynęło X zł" użytkownika (data, kwota, notatka). Jedyne miejsce, skąd pieniądze wchodzą do aplikacji. |
| **Pula** | Przychody użytkownika minus jego zasilenia kopert top-level. To „nieprzydzielone". |
| **Koperta** | Nazwa, kolor, ikona, właściciel. Top-level albo subkoperta (`parent_id`), maksymalnie dwa poziomy. |
| **Zasilenie** | Wpis „użytkownik U przeznacza X zł na kopertę K" (data, kwota, może być ujemne = wycofanie). |
| **Przypisanie** | Zasilenie **subkoperty**: użytkownik dzieli część swojego zasilenia rodzica między subkoperty. Nie rusza jego puli. |
| **Wydatek** | Kwota z koperty (top-level albo sub), data, notatka, autor. |
| **Członek** | Użytkownik dodany do koperty top-level (rola `owner` lub `member`). Subkoperty dziedziczą członków rodzica. |

## Salda

Wszystko liczone do wybranego dnia (domyślnie dziś), więc saldo przechodzi między miesiącami.

- **Subkoperta**: Σ przypisań − Σ wydatków.
- **Koperta top-level, wolne saldo**: Σ zasileń − Σ przypisań do jej subkopert − Σ wydatków zapisanych bezpośrednio na niej.
- **Koperta top-level, razem**: wolne saldo + salda subkopert.
- **Pula użytkownika**: Σ jego przychodów − Σ jego zasileń kopert top-level.

Reguły spójności:

1. Przypisanie do subkoperty nie może przekroczyć tego, co ten sam użytkownik zasilił rodzica i jeszcze nie przypisał. Serwer odrzuca takie żądanie (409).
2. Wycofanie zasilenia nie może zejść poniżej tego, co ten użytkownik już przypisał subkopertom, ani poniżej wolnego salda koperty.
3. **Ujemne saldo i ujemna pula są dozwolone** (ostrzeżenie w apce, brak blokady): wydatek jest faktem i trzeba go móc zapisać.
4. Miesiąc (zakres dat wg ustawienia „pierwszy dzień miesiąca") jest tylko **widokiem**: zasilenia i wydatki z zakresu, saldo na koniec zakresu. Nie jest encją, więc znikają okresy, wersje planu i konflikt `PeriodChanged`.

## Co widzi użytkownik

**Ekran główny** liczy wyłącznie to, co dotyczy użytkownika:

- przychody, **moje zasilenia** kopert, nieprzydzielone (pula),
- **moje wydatki** (te, które sam zapisał, na dowolnej kopercie),
- listę kopert, do których należy. Dla własnej koperty postęp to jej saldo; dla współdzielonej pokazuje saldo całej koperty i znaczek „wspólna".

Wydatek zapisany przez kogoś innego na współdzielonej kopercie nie zmniejsza mojej puli ani mojego „wydane": moje pieniądze opuściły pulę w chwili zasilenia, a ile ostatecznie wydano, widać w kopercie.

**Wejście we współdzieloną kopertę** pokazuje dodatkowo:

- ile **ja** przeznaczam na kopertę i na każdą jej subkopertę,
- ile przeznacza **każdy z pozostałych członków** na kopertę i na każdą subkopertę (kto ile włożył),
- razem: zasilenia, wydatki, saldo; wydatki z autorem.

Użytkownik z jedną kopertą i bez współdzielenia widzi aplikację prawie tak jak przed współdzieleniem.

## Współdzielenie

- **Zaproszenie** po adresie e-mail do koperty top-level. Przepływ jak dotąd: zaproszony → zaakceptowane przez zapraszanego → zatwierdzone przez właściciela koperty. Limity: 10 członków koperty, 10 zaproszeń na godzinę.
- **Uprawnienia.** Właściciel: członkowie i zaproszenia, edycja i usuwanie koperty oraz subkopert. Członek: widzi kopertę, dodaje wydatki (swoje edytuje i usuwa), zasila i przypisuje **ze swojego** zasilenia. Nikt nie edytuje cudzych zasileń.
- **Prywatność.** Członek widzi kopertę (i subkoperty), jej członków, zasilenia i wydatki w niej. Nie widzi niczego poza nią: ani innych kopert właściciela, ani przychodów, ani puli.
- **Wyjście z koperty.** Zasilenia zostają (to wspólne pieniądze). Apka ostrzega i pozwala najpierw wycofać wolną część. Wydatki zostają z autorem. Właściciel nie może wyjść, dopóki nie przekaże koperty innemu członkowi.
- **Usunięcie koperty** (tylko właściciel, z potwierdzeniem) usuwa jej wydatki i zasilenia, więc pieniądze wracają do pul osób, które je wkładały.
- **404 zamiast 403** dla koperty, której użytkownik nie widzi.

## Dane (szkic)

```
users(id, email, name, …)                         -- bez zmian
incomes(id, user_id, amount_minor, date, note)
envelopes(id, owner_id, parent_id NULL, name, color, icon)
envelope_members(envelope_id, user_id, role)      -- tylko koperty top-level
allocations(id, envelope_id, user_id, amount_minor, date, note)
expenses(id, envelope_id, created_by, amount_minor, date, note)
invitations(…)                                    -- jak dziś, wskazuje kopertę
recurring_expenses(…)                             -- jak dziś, wskazuje kopertę
```

- Każda koperta top-level ma wiersz w `envelope_members` (właściciel z rolą `owner`), więc dostęp to jedno zapytanie. Subkoperta dziedziczy dostęp po `parent_id`.
- Głębokość ograniczona w bazie: rodzic musi być top-level (kontrola w serwisie, nie tylko w UI).
- Kategorie jako osobny byt znikają: nazwa, kolor i ikona leżą na kopercie.
- Kwoty w groszach, PLN. Wielowalutowość (kwoty w obcej walucie) odkładamy poza ten model.

## Migracja istniejących danych

Dane są tylko jednego użytkownika (przestrzeń domyślna, przejmowana przez `CLAIM_EMAIL`):

- kategoria z kopertami → koperta top-level; koperta okresu → zasilenie z datą początku okresu,
- dochód okresu → przychód z datą początku okresu,
- wydatki → wydatki na odpowiedniej kopercie, reguły cykliczne → na kopercie,
- tabele `spaces`, `memberships`, `periods`, `contributions` znikają po przeniesieniu.

## Etapy

1. **Rdzeń.** Przychody, koperty z subkopertami, zasilenia i przypisania, wydatki, salda toczące się, widok miesiąca; migracja; usunięcie przestrzeni i okresów; przepisanie ekranów. Bez współdzielenia.
2. **Współdzielenie.** Członkowie koperty, zaproszenia, role, widok „kto ile włożył", wyjście i usuwanie.
3. **Automaty.** Cykliczne przychody (np. wypłata) i reguły podziału („co miesiąc X zł na Dom"), cykliczne wydatki na nowym modelu, ekran zbiorczy i polerka.

Każdy etap to osobny branch i PR do `main`.

## Otwarte, na później

Archiwizacja zamkniętych kopert (wyjazd), szybkie dodanie wydatku, przeniesienie własności koperty, powiadomienia o wydatkach we wspólnej kopercie, wielowalutowość.
