# Model kopert i współdzielenia

Model danych i zachowania aplikacji. Zastąpił podział na **przestrzenie** i **okresy**. Część o współdzieleniu (rozdział „Współdzielenie") jest zaprojektowana, ale jeszcze nie wdrożona; reszta działa. Plan: [ROADMAP.md](ROADMAP.md), etap 9.

## Idea w jednym akapicie

Każdy użytkownik ma własną pulę pieniędzy: wpisuje **wpływy**, a z nich **przydziela pieniądze do kopert**. Koperta może mieć **podkoperty** (jeden poziom). Wydatki obniżają saldo koperty, przydziały je podnoszą, a saldo **toczy się** z miesiąca na miesiąc. Kopertę top-level będzie można **współdzielić**: dodani użytkownicy przydzielą do niej pieniądze ze swoich pul, każdy zobaczy, ile włożył on i ile włożyli inni, a nie zobaczy cudzych pozostałych kopert. Nie ma przestrzeni ani okresów.

## Pojęcia

| Pojęcie | Znaczenie |
|---|---|
| **Wpływ** | Wpis „wpłynęło X zł" użytkownika (dzień, kwota, notatka). Jedyne miejsce, skąd pieniądze wchodzą do aplikacji. |
| **Pula** | Wpływy użytkownika minus to, co przydzielił do kopert top-level. To „nieprzydzielone". |
| **Koperta** | Nazwa, kolor, ikona, właściciel. Top-level albo podkoperta (`parent_id`), maksymalnie dwa poziomy. |
| **Przydział** | Wpis „użytkownik U wkłada X zł do koperty K" (dzień, kwota, ujemna = zabranie z powrotem). |
| **Przydział do podkoperty** | Użytkownik dzieli część tego, co włożył do rodzica, między podkoperty. Nie rusza jego puli. |
| **Wydatek** | Kwota z koperty (top-level albo sub), chwila, notatka, autor. |
| **Członek** | Użytkownik dodany do koperty top-level (rola `owner` lub `member`). Podkoperty dziedziczą członków rodzica. |

## Salda

Wszystko liczone do wybranego dnia (domyślnie dziś), więc saldo przechodzi między miesiącami.

- **Podkoperta**: Σ przydziałów do niej − Σ jej wydatków.
- **Koperta top-level, razem**: Σ przydziałów do niej − Σ wydatków na niej i na jej podkopertach. To wszystkie pieniądze w kopercie (przydziały do podkopert są tylko przesunięciem wewnątrz).
- **Koperta top-level, wolne**: razem − salda podkopert. Tyle nie jest przypisane do żadnej podkoperty.
- **Pula użytkownika**: Σ jego wpływów − Σ jego przydziałów do kopert top-level.

W miesiącu (zakres dni) koperta ma cztery liczby: **otwarcie** (saldo przed pierwszym dniem), **przydzielone** (netto w zakresie), **wydane** i **saldo** na koniec zakresu. **Dostępne w miesiącu** to otwarcie plus przydzielone.

Reguły spójności:

1. Przydział do podkoperty nie może przekroczyć tego, co ten sam użytkownik włożył do rodzica i jeszcze nie przypisał podkopertom. Serwer odrzuca takie żądanie (409 `NotEnoughMoney`).
2. Zabranie pieniędzy z koperty top-level nie może zejść poniżej tego, co ten użytkownik już przypisał podkopertom, ani poniżej wolnego salda koperty. Z podkoperty: nie więcej, niż do niej przypisał i niż w niej jest. Ta sama reguła dotyczy edycji i usuwania przydziałów.
3. **Ujemne saldo i ujemna pula są dozwolone** (ostrzeżenie w apce, brak blokady): wydatek jest faktem i trzeba go móc zapisać.
4. Miesiąc (zakres dni wg ustawienia „pierwszy dzień miesiąca", 1–28) jest tylko **widokiem**. Nie jest encją, więc nie ma okresów, wersji planu ani konfliktów planu.

## Co widzi użytkownik

**Pulpit** liczy to, co dotyczy użytkownika, dla jednego miesiąca:

- wpływy, to, co przydzielił do kopert top-level (netto), wydane (to, co sam zapisał) i pulę,
- listę kopert top-level: saldo, ile wydano z ilu dostępnych, pasek postępu.

Szczegóły koperty: saldo, dostępne, wydane, wolne (gdy ma podkoperty), podkoperty z saldami, przydziały, wykres narastających wydatków i lista wydatków miesiąca. Przyciski „Przydziel" i „Wycofaj".

Po wdrożeniu współdzielenia wydatek zapisany przez kogoś innego we wspólnej kopercie nie zmniejszy mojej puli ani mojego „wydane": moje pieniądze opuściły pulę w chwili przydziału, a ile ostatecznie wydano, widać w kopercie. Wejście we wspólną kopertę pokaże dodatkowo, ile **ja** wkładam do niej i do każdej podkoperty oraz ile **każdy z pozostałych członków** (kto ile włożył).

## Współdzielenie (zaprojektowane, jeszcze nie wdrożone)

- **Zaproszenie** po adresie e-mail do koperty top-level. Przepływ: zaproszony → akceptuje → właściciel koperty zatwierdza. Limity: 10 członków koperty, 10 zaproszeń na godzinę.
- **Uprawnienia.** Właściciel: członkowie i zaproszenia, edycja i usuwanie koperty oraz podkopert. Członek: widzi kopertę, dodaje wydatki (swoje edytuje i usuwa), przydziela i przypisuje **ze swojego** przydziału. Nikt nie edytuje cudzych przydziałów.
- **Prywatność.** Członek widzi kopertę (i podkoperty), jej członków, przydziały i wydatki w niej. Nie widzi niczego poza nią: ani innych kopert właściciela, ani wpływów, ani puli.
- **Wyjście z koperty.** Przydziały zostają (to wspólne pieniądze). Apka ostrzega i pozwala najpierw wycofać wolną część. Wydatki zostają z autorem. Właściciel nie może wyjść, dopóki nie przekaże koperty innemu członkowi.
- **Usunięcie koperty** (tylko właściciel, z potwierdzeniem) usuwa jej wydatki i przydziały, więc pieniądze wracają do pul osób, które je wkładały.

Dziś każda koperta ma jednego członka: właściciela. Tabela `envelope_members` i sprawdzanie ról już działają, więc współdzielenie dokłada zaproszenia i widok „kto ile włożył".

## Dane

```
users(id, email, name, …)
incomes(id, user_id, amount_minor, received_on, note)
envelopes(id, owner_id, parent_id NULL, name, color, icon)
envelope_members(envelope_id, user_id, role)      -- tylko koperty top-level
allocations(id, envelope_id, user_id, amount_minor, made_on, note)
expenses(id, envelope_id, created_by, amount_minor, spent_at, note, recurring_id, recurring_month)
recurring_rules(id, user_id, envelope_id, amount_minor, frequency, note, active)
```

- Każda koperta top-level ma wiersz w `envelope_members` (właściciel z rolą `owner`), więc dostęp to jedno zapytanie. Podkoperta dziedziczy dostęp po `parent_id`.
- Głębokość pilnuje serwis: rodzic musi być top-level (422 `ParentMustBeTopLevel`).
- Kategorie jako osobny byt zniknęły: nazwa, kolor i ikona leżą na kopercie.
- Kwoty w groszach, PLN. Wielowalutowość (kwoty w obcej walucie) odłożona poza ten model.
- `recurring_month` to pierwszy dzień zakresu, dla którego reguła została zastosowana; unikalny indeks (`recurring_id`, `recurring_month`) gwarantuje, że reguła raz na zakres dodaje jeden wydatek.

## Migracja istniejących danych

Migracja `0009_create_envelope_model` przeniosła dane każdej przestrzeni do jej właściciela:

- kategoria → koperta top-level (to samo ID),
- plan okresu dla kategorii → przydział z dniem początku okresu,
- dochód okresu → wpływ z dniem początku okresu (notatka to nazwa okresu),
- wydatki → wydatki tej koperty, autorem jest właściciel; reguły cykliczne → reguły właściciela (kwoty w innych walutach niż PLN nie są przeliczane),
- tabele `spaces`, `memberships`, `periods`, `categories` zniknęły; przestrzeń bez członków (nieprzejęta przestrzeń domyślna) nie miała komu oddać danych i została usunięta.

Skutek uboczny nowej semantyki: to, co w starym okresie zostało nieodsunięte z planu, teraz przechodzi do następnych miesięcy jako saldo.

## Etapy

1. **Rdzeń (zrobione).** Wpływy, koperty z podkopertami, przydziały, wydatki, salda toczące się, widok miesiąca, migracja, usunięcie przestrzeni i okresów, nowe ekrany.
2. **Współdzielenie.** Członkowie koperty, zaproszenia, role, widok „kto ile włożył", wyjście i usuwanie.
3. **Automaty.** Cykliczne wpływy (np. wypłata) i reguły podziału („co miesiąc X zł na Dom"), ekran zbiorczy i polerka.

Całość idzie jedną gałęzią i jednym PR-em do `main`.

## Otwarte, na później

Archiwizacja zamkniętych kopert (wyjazd), szybkie dodanie wydatku, przeniesienie własności koperty, powiadomienia o wydatkach we wspólnej kopercie, wielowalutowość.
