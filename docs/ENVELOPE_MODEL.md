# Model kopert i współdzielenia

Model danych i zachowania aplikacji. Zastąpił podział na **przestrzenie** i **okresy**. Działa także współdzielenie kopert i reguły cykliczne. Plan dalszych prac: [ROADMAP.md](ROADMAP.md), etap 9.

## Idea w jednym akapicie

Każdy użytkownik ma własną pulę pieniędzy: wpisuje **wpływy**, a z nich **przydziela pieniądze do kopert**. Koperta może mieć **podkoperty** (jeden poziom). Wydatki obniżają saldo koperty, przydziały je podnoszą, a saldo **toczy się** z miesiąca na miesiąc. Kopertę top-level można **współdzielić**: dodani użytkownicy przydzielają do niej pieniądze ze swoich pul, każdy widzi, ile włożył on i ile włożyli inni, a nie widzi cudzych pozostałych kopert. Nie ma przestrzeni ani okresów.

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

Wydatek zapisany przez kogoś innego we wspólnej kopercie nie zmniejsza mojej puli ani mojego „wydane": moje pieniądze opuściły pulę w chwili przydziału, a ile ostatecznie wydano, widać w kopercie. Saldo wspólnej koperty jest saldem całej koperty (pieniądze wszystkich), z ikoną grupy i liczbą osób.

Wejście we wspólną kopertę pokazuje dodatkowo kartę „Kto ile włożył": ile **ja** włożyłem do koperty i do każdej podkoperty oraz ile **każdy z pozostałych członków** (od początku, netto po wycofaniach). Ekran „Członkowie" pokazuje osoby z rolami, a właścicielowi także otwarte zaproszenia.

## Współdzielenie

- **Zaproszenie** po adresie e-mail do koperty top-level (podkoperty idą razem z nią). Przepływ: zaproszony → akceptuje → właściciel koperty zatwierdza i dopiero wtedy osoba dostaje dostęp. Zaproszenie ważne 14 dni; to samo zaproszenie można odnowić z inną rolą. Limity: 10 członków koperty (z otwartymi zaproszeniami), 10 zaproszeń na godzinę. Zaproszenie jest zawsze widoczne w aplikacji (zaproszony widzi je na pulpicie po zalogowaniu tym adresem i odpowiada tam, a właściciel zatwierdza w „Członkach"). Do tego idzie mail do drugiej strony, ale to dodatek: gdy poczta nie działa, zaproszenie i tak przechodzi.
- **Uprawnienia.** Właściciel (może być kilku): członkowie, role i zaproszenia, edycja i usuwanie koperty oraz podkopert, edycja i usuwanie cudzych wydatków. Członek: widzi kopertę, dodaje wydatki (swoje edytuje i usuwa), przydziela i przypisuje **ze swojego** przydziału, zabiera z koperty tylko tyle, ile sam włożył. Nikt nie edytuje cudzych przydziałów.
- **Prywatność.** Członek widzi kopertę (i podkoperty), jej członków, przydziały i wydatki w niej. Nie widzi niczego poza nią: ani innych kopert właściciela, ani wpływów, ani puli.
- **Wyjście z koperty.** Przydziały zostają (to wspólne pieniądze), więc apka ostrzega i pozwala najpierw wycofać wolną część. Wydatki zostają z autorem, reguły cykliczne wychodzącego z tej koperty znikają. Ostatni właściciel nie może wyjść ani zostać zdegradowany (409 `LastOwner`): najpierw trzeba zrobić właścicielem kogoś innego, a gdy koperta jest sama, usunąć ją.
- **Usunięcie koperty** (tylko właściciel, z potwierdzeniem) usuwa jej wydatki i przydziały, więc pieniądze wracają do pul osób, które je wkładały.

**Kopie zapasowe.** Eksport i import JSON obejmują tylko koperty, w których użytkownik jest sam (z regułami do nich i jego cyklicznymi wpływami). Wspólnych nie ma w kopii i import ich nie zastępuje, bo należą do kilku osób. CSV zawiera własne wydatki użytkownika także ze wspólnych kopert.

## Reguły cykliczne

Trzy rodzaje reguł, wszystkie własne (widzi je tylko ich autor):

- **Wydatek cykliczny**: kwota na kopercie (np. czynsz), co tydzień albo co miesiąc.
- **Wpływ cykliczny**: kwota, która wpada co miesiąc w tym samym dniu (wypłata).
- **Reguła podziału**: kwota, która co miesiąc w tym samym dniu trafia z puli do koperty, np. 1 000 zł do Domu. Dla podkoperty to podział tego, co użytkownik włożył do rodzica.

Dzień miesiąca to 1–28, więc każdy miesiąc (nawet taki, który zaczyna się 20.) go zawiera.

**Nic nie dzieje się samo.** Reguły są stosowane do miesiąca na ekranie przyciskiem „zastosuj" (w Regułach cyklicznych) albo „Dodaj" na pulpicie, gdzie karta pokazuje, co jest do dodania. Stosowanie dodaje po kolei: wpływy, potem przydziały, potem wydatki, i można je wołać wielokrotnie: reguła daje jeden wpis na miesiąc (unikalny indeks po regule i pierwszym dniu miesiąca). Przydziały do kopert głównych idą przed przydziałami do podkopert, żeby podkoperta miała z czego brać. Przydział, którego koperta nie przyjmie (za mało środków w rodzicu albo użytkownik już jej nie widzi), jest **pominięty i policzony**, a reszta idzie dalej. Wpis, który reguła zrobiła, zostaje po jej usunięciu.

## Dane

```
users(id, email, name, …)
incomes(id, user_id, amount_minor, received_on, note)
envelopes(id, owner_id, parent_id NULL, name, color, icon)
envelope_members(envelope_id, user_id, role)      -- tylko koperty top-level
allocations(id, envelope_id, user_id, amount_minor, made_on, note)
expenses(id, envelope_id, created_by, amount_minor, spent_at, note, recurring_id, recurring_month)
recurring_rules(id, user_id, envelope_id, amount_minor, frequency, note, active)
recurring_incomes(id, user_id, amount_minor, day_of_month, note, active)
allocation_rules(id, user_id, envelope_id, amount_minor, day_of_month, note, active)
invitations(id, envelope_id, email, role, status, invited_by, accepted_by, expires_at)
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
2. **Współdzielenie (zrobione).** Członkowie koperty, zaproszenia, role, widok „kto ile włożył", wyjście i usuwanie.
3. **Automaty (zrobione).** Cykliczne wpływy (np. wypłata) i reguły podziału („co miesiąc X zł na Dom"), jedno „zastosuj" dla wszystkich reguł i podgląd tego, co czeka. Ekranem zbiorczym jest pulpit: sumuje wszystkie koperty, także wspólne, i pozwala wejść w każdą.

Całość idzie jedną gałęzią i jednym PR-em do `main`.

## Otwarte, na później

Archiwizacja zamkniętych kopert (wyjazd), szybkie dodanie wydatku, automatyczne stosowanie reguł bez przycisku (potrzebny harmonogram po stronie serwera), powiadomienia o wydatkach we wspólnej kopercie, wielowalutowość.
