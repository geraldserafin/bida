# User stories – Money Planner

Stan apki **dziś** (przegląd kodu `apps/mobile`). Opisuje, co użytkownik faktycznie może zrobić.
Sekcje 1–8 opisują apkę jednoosobową. Konta, logowanie i wspólne budżety opisują sekcje 9–11 (stan na ich wprowadzenie; patrz `ARCHITECTURE.md`, „Konta i sesje" oraz „Wspólne budżety").

Oznaczenia: 🌐 = po przejściu na backend wymaga endpointu · 📱 = zostaje lokalnie w apce.

Pojęcia: **okres** (np. „Lipiec 2026", z dochodem), **kategoria** (np. Jedzenie), **koperta** (split = kwota zaplanowana na kategorię w okresie), **wydatek** (zapisany na kopercie).

---

## 1. Okresy (planowanie budżetu)

- **US-1.1** Jako użytkownik tworzę nowy okres: podaję nazwę, zakres dat i dochód. 🌐
  - Nazwa i dochód są wymagane.
  - Domyślny zakres wynika z ustawienia „pierwszy dzień miesiąca" (📱/🌐 ustawienie).
- **US-1.2** Przy tworzeniu okresu dzielę dochód na kategorie (kwota na kopertę). 🌐
  - Widzę na bieżąco kwotę „nieprzydzieloną".
  - Przy przekroczeniu dochodu dostaję ostrzeżenie „przydzieliłeś więcej niż zarabiasz" (nie blokuje zapisu).
  - Koperty z kwotą 0 nie są tworzone.
- **US-1.3** Mogę wstępnie wypełnić plan sumami z moich wydatków cyklicznych. 🌐
- **US-1.4** Mogę dodać nową kategorię bez wychodzenia z ekranu tworzenia okresu. 🌐
- **US-1.5** Mogę edytować dochód i kwoty kopert bieżącego okresu. 🌐
  - Kwota > 0: koperta zostaje utworzona/zaktualizowana.
  - Kwota = 0: koperta znika, **chyba że ma już wydatki** – wtedy zostaje z planem 0, żeby historia się nie zepsuła.
- **US-1.6** Widzę listę wszystkich okresów z podsumowaniem (zaplanowane / wydane) i przełączam się na wybrany. 🌐 (wybór okresu – 📱)
- **US-1.7** Mogę usunąć okres po potwierdzeniu; znikają razem z nim koperty i wydatki. 🌐
  - Jeśli usunę bieżący okres, dashboard przełącza się na najnowszy pozostały.
- **US-1.8** Apka pamięta, który okres ostatnio oglądałem. 📱

## 2. Dashboard (ekran główny)

- **US-2.1** Widzę dochód, sumę zaplanowaną, wydaną, pozostałą i nieprzydzieloną dla wybranego okresu. 🌐
- **US-2.2** Widzę wykres kołowy planu (podział na kategorie). 🌐
- **US-2.3** Widzę wykres „zaplanowane vs wydane" per kategoria oraz paski postępu kopert; przekroczone koperty są oznaczone. 🌐
- **US-2.4** Przełączam okres z nagłówka dashboardu. 🌐
- **US-2.5** Gdy nie mam żadnego okresu, widzę pusty stan z przyciskiem „utwórz okres". 📱
- **US-2.6** Z dashboardu szybko przechodzę do: dodania wydatku, edycji planu, reguł cyklicznych, szczegółów kategorii. 📱

## 3. Wydatki

- **US-3.1** Dodaję wydatek: kwota, kategoria (koperta), data i godzina, opcjonalna notatka. 🌐
  - Kwota przyjmuje przecinek i kropkę.
- **US-3.2** Jeśli kategorii nie ma jeszcze w tym okresie, mogę ją od razu dodać jako nową kopertę (plan 0) i wydać z niej. 🌐
- **US-3.3** Edytuję istniejący wydatek. 🌐
- **US-3.4** Usuwam wydatek po potwierdzeniu. 🌐
- **US-3.5** Widzę szczegóły kategorii w okresie: plan, wydane, zostało, wykres liniowy wydatków i listę wydatków kategorii. 🌐

## 4. Historia transakcji

- **US-4.1** Widzę wszystkie wydatki wybranego okresu pogrupowane po dniach, od najnowszych. 🌐
- **US-4.2** Filtruję po kategorii. 🌐
- **US-4.3** Filtruję po zakresie dat oraz godzin w ciągu dnia. 🌐
- **US-4.4** Oglądam szczegóły starszego okresu (podsumowanie + kategorie + transakcje). 🌐
- **US-4.5** Z historii otwieram wydatek do edycji/usunięcia (→ 3.3, 3.4). 📱

## 5. Kategorie

- **US-5.1** Widzę listę swoich kategorii (alfabetycznie, bez rozróżniania wielkości liter). 🌐
- **US-5.2** Dodaję kategorię: nazwa, kolor, ikona. 🌐
- **US-5.3** Edytuję kategorię; zmiana widoczna we wszystkich okresach. 🌐
- **US-5.4** Usuwam kategorię. 🌐
  - Zablokowane, jeśli jest użyta w jakiejkolwiek kopercie (dowolny okres) – dostaję komunikat.

## 6. Wydatki cykliczne

- **US-6.1** Widzę listę reguł (kategoria, kwota, częstotliwość tygodniowa/miesięczna, notatka, aktywna). 🌐
- **US-6.2** Dodaję, edytuję i usuwam regułę. 🌐
  - Usunięcie reguły nie kasuje wydatków, które już wygenerowała.
- **US-6.3** Włączam/wyłączam regułę bez usuwania. 🌐
- **US-6.4** Jednym przyciskiem „zastosuj" dodaję do bieżącego okresu wydatki z aktywnych reguł. 🌐
  - Reguła, która już została użyta w tym okresie, nie dubluje się.
  - Jeśli brakuje koperty dla kategorii reguły, powstaje z planem równym kwocie reguły.
  - Dostaję informację, ile wydatków dodano.

## 7. Ustawienia i dane

- **US-7.1** Zmieniam motyw: ciemny / jasny / systemowy. 📱
- **US-7.2** Ustawiam pierwszy dzień miesiąca budżetowego (1–28). 📱 → 🌐 gdy ustawienia mają być współdzielone
- **US-7.3** Eksportuję wydatki do CSV (`Period,Category,Amount,Date,Note`). 🌐
- **US-7.4** Importuję wydatki z CSV. 🌐
  - Brakujące okresy i kategorie są tworzone po nazwie.
  - Duplikaty (ta sama koperta, kwota, dzień, notatka) są pomijane.
  - Widzę, ile zaimportowano, a ile pominięto.
- **US-7.5** Mogę zrobić pełny zrzut danych (okresy, kategorie, koperty, wydatki, reguły) i go odtworzyć; przed odtworzeniem widzę podgląd (ile okresów/wydatków lokalnie vs w kopii) i zapisuje się lokalny snapshot bezpieczeństwa. 🌐
- **US-7.6** Synchronizuję dane przez zaszyfrowany plik w repo na GitHubie (token + hasło): wypychanie (ostatni zapis wygrywa) i pobieranie. 🌐 – **do usunięcia po przejściu na serwer**
- **US-7.7** Widzę ekran „o aplikacji". 📱
- **US-7.8** Apka jest po polsku i angielsku. 📱

## 8. Blokada aplikacji (lokalna)

- **US-8.1** Ustawiam PIN; PIN jest przechowywany tylko jako solony hash PBKDF2. 📱
- **US-8.2** Po włączeniu blokady muszę podać PIN przy wejściu do apki. 📱
- **US-8.3** Zmieniam i wyłączam PIN. 📱
- **US-8.4** Włączam odblokowanie biometryczne, jeśli urządzenie je obsługuje. 📱

---

## 9. Konto i logowanie

- **US-9.1** Loguję się adresem e-mail: dostaję mail z kodem i linkiem, bez hasła. 🌐
- **US-9.2** Loguję się kontem Google. 🌐
- **US-9.3** Zostaję zalogowany na urządzeniu, a wylogowanie kończy sesję od razu. 🌐
- **US-9.4** Przy pierwszym logowaniu powstaje moja przestrzeń osobista. 🌐

## 10. Przestrzenie: osobista i wspólne

Każdy ma jedną **przestrzeń osobistą** (tylko dla niego) i może należeć do dowolnej liczby **przestrzeni wspólnych**.

- **US-10.1** Mam jedną przestrzeń osobistą. Nie mogę z niej wyjść, usunąć jej ani nikogo do niej zaprosić. 🌐
- **US-10.2** Zakładam przestrzeń wspólną (nazwa, waluta); zostaję jej właścicielem. 🌐
- **US-10.3** Przełączam się między przestrzeniami z nagłówka ekranu; apka pamięta wybraną i bieżący okres osobno dla każdej. 📱
- **US-10.4** Przy pierwszym uruchomieniu wybieram, czego używam: osobistego, wspólnego czy obu, i apka otwiera się w wybranej przestrzeni. 📱
- **US-10.5** Jako właściciel zapraszam osobę adresem e-mail, wybierając jej rolę. Zaproszenie wygasa po 14 dniach i mogę je cofnąć. 🌐
- **US-10.6** Zapraszana osoba widzi zaproszenie po zalogowaniu tym adresem i je przyjmuje albo odrzuca. Przyjęcie czeka na zatwierdzenie przez właściciela, dopiero potem osoba zostaje członkiem. 🌐
- **US-10.7** Widzę członków przestrzeni, ich role i oczekujące zaproszenia. 🌐
- **US-10.8** Jako właściciel zmieniam role, usuwam członków i zatwierdzam albo odrzucam przyjęte zaproszenia. 🌐
- **US-10.9** Mogę wyjść ze wspólnej przestrzeni. Ostatni właściciel nie może, dopóki nie przekaże roli albo nie usunie przestrzeni. 🌐
- **US-10.10** Mogę usunąć wspólną przestrzeń, jeśli jestem w niej sam; w przeciwnym razie najpierw usuwam pozostałych. 🌐
- **US-10.11** Przy wydatku widzę, kto go dodał, i filtruję „tylko moje". Po odejściu autora widzę „były członek". 🌐
- **US-10.12** Ustawiam swoją nazwę, którą widzą inni członkowie. 🌐
- **US-10.13** Gdy usunięto mnie z przestrzeni, którą miałem wybraną, apka przełącza mnie na inną i mówi dlaczego. 📱

**Uprawnienia we wspólnej przestrzeni**

| | właściciel | członek |
| --- | --- | --- |
| widzi wszystkie dane, eksportuje | tak | tak |
| dodaje, edytuje i usuwa wydatki (także cudze) | tak | tak |
| tworzy i edytuje okresy, kategorie, plan i reguły cykliczne | tak | tak |
| usuwa okres lub kategorię | tak | nie |
| zmienia nazwę i walutę przestrzeni | tak | nie |
| zaprasza, zatwierdza, zmienia role, usuwa członków | tak | nie |
| odtwarza dane z kopii (zastępuje wszystko) | tak | nie |
| usuwa przestrzeń (gdy jest w niej sam) | tak | nie |
| wychodzi z przestrzeni | tak (nie ostatni właściciel) | tak |

## 11. Wpłaty na wspólny budżet

Wspólny okres zachowuje **zaplanowany dochód** (liczba ustawiana przez właściciela, jak dziś). **Wpłaty** to stan faktyczny: kto, ile i kiedy wpłacił.

- **US-11.1** We wspólnym okresie widzę „wpłacono X z Y" i podział na osoby. 🌐
- **US-11.2** Dodaję wpłatę (swoją, albo bez autora, np. gotówka od kogoś): kwota w walucie okresu, data, opcjonalna notatka. 🌐
- **US-11.3** Usuwam wpłatę, którą dodałem; właściciel usuwa każdą. 🌐
- **US-11.4** *(etap 2, portfel)* W planie osobistym mam kopertę „Dom (wspólny)" dla każdej wspólnej przestrzeni, w której jestem. Wydatek z niej to wpłata na wspólny budżet i tworzy ją po stronie wspólnej. 🌐
- **US-11.5** *(etap 2)* Zmiana i usunięcie takiego wydatku zmienia i usuwa wpłatę. Wpłata po stronie wspólnej jest tylko do odczytu. 🌐
- **US-11.6** *(etap 2)* Gdy wspólny okres nie obejmuje daty wpłaty, dostaję komunikat, że trzeba go najpierw utworzyć. 🌐
- **US-11.7** *(etap 2)* Gdy waluty się różnią, podaję kwotę w obu (jak przy wydatku w obcej walucie). 🌐
- **US-11.8** *(etap 2)* Po wyjściu z przestrzeni moja koperta „wspólna" staje się zwykła, tylko do odczytu, a stare wpłaty zostają jako historia. 🌐

### Przypadki brzegowe (decyzje)

- Edycja planu okresu przez dwie osoby naraz: druga dostaje błąd 409 (okres ma wersję) zamiast po cichu nadpisać zmiany. 🌐
- Zaproszenie na adres, który już jest członkiem, daje błąd; ponowne zaproszenie tego samego adresu odświeża rolę i termin.
- Literówka w adresie: przyjęcie zaproszenia nie daje dostępu bez zatwierdzenia przez właściciela.
- Limity: 10 członków na przestrzeń, 20 przestrzeni na użytkownika, 10 zaproszeń na godzinę.
- Zapłaciłem za wspólny rachunek z własnych pieniędzy: na razie jako wpłata plus wydatek; automatyczny zwrot odłożony.
- Rozliczanie „kto komu ile winien" nie jest celem aplikacji.

---

## Co z tego wynika dla backendu (bez użytkowników)

Backend na start obsługuje **jednego, anonimowego właściciela danych**: US z oznaczeniem 🌐 w sekcjach 1–7 (poza 7.6).
Sekcja 8 i motyw/język zostają w apce.

Obliczenia, które muszą być po stronie serwera, bo dziś siedzą w SQL/`PlannerState`:
- sumy planned/spent/remaining/unallocated (US-2.1, 1.6)
- edycja planu z zachowaniem kopert z wydatkami (US-1.5)
- idempotentne stosowanie reguł cyklicznych (US-6.4)
- blokada usunięcia kategorii w użyciu (US-5.4)
- import CSV z deduplikacją (US-7.4)

Szczegółowa lista endpointów: `BACKEND.md` (sekcje o auth i `userId` odkładamy na później).
