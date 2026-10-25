# User stories – Money Planner

Stan apki **dziś** (przegląd kodu `apps/mobile`). Opisuje, co użytkownik faktycznie może zrobić.
Zakres na start: **jeden użytkownik, brak logowania i kont**. `userId` dojdzie do tabel później.

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
