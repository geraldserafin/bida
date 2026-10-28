# User stories – Money Planner

Co użytkownik może zrobić w aplikacji **dziś**. Model, na którym to stoi: [ENVELOPE_MODEL.md](ENVELOPE_MODEL.md). Współdzielenie kopert opisują historie w sekcji 9.

Oznaczenia: 🌐 = wymaga endpointu · 📱 = zostaje lokalnie w apce.

Pojęcia: **wpływ** (pieniądze, które weszły, np. wypłata), **pula** (wpływy, które nie trafiły jeszcze do żadnej koperty), **koperta** (np. Dom) z opcjonalnymi **podkopertami** (np. Czynsz), **przydział** (pieniądze włożone do koperty albo z niej zabrane), **wydatek** (zapisany na kopercie), **miesiąc** (zakres dni, na który patrzymy).

---

## 1. Wpływy i pula

- **US-1.1** Dodaję wpływ: kwota, dzień, opcjonalna notatka. To jedyny sposób, w jaki pieniądze trafiają do aplikacji. 🌐
- **US-1.2** Widzę listę wpływów od najnowszego, edytuję je i usuwam po potwierdzeniu. 🌐
- **US-1.3** Widzę pulę, czyli wpływy minus to, co włożyłem do kopert. Pula poniżej zera jest dozwolona; apka pokazuje wtedy „Przydzielono za dużo". 🌐

## 2. Koperty i podkoperty

- **US-2.1** Tworzę kopertę: nazwa, ikona, kolor. 🌐
- **US-2.2** Tworzę podkopertę w kopercie, np. Czynsz w Domu. Głębiej nie, tylko jeden poziom. 🌐
- **US-2.3** Edytuję nazwę, ikonę i kolor koperty. Miejsca w drzewie nie zmieniam. 🌐
- **US-2.4** Usuwam kopertę po potwierdzeniu. Znikają razem z nią podkoperty, wydatki i przydziały; przydzielone pieniądze wracają do puli. 🌐
- **US-2.5** Przy zapisywaniu wydatku mogę od razu dodać nową kopertę. 🌐
- **US-2.6** Zarządzam kopertami z jednego ekranu (Ustawienia → Zarządzaj kopertami): dodaję, edytuję, usuwam i dodaję podkoperty. 📱

## 3. Przydziały

- **US-3.1** Wkładam pieniądze z puli do koperty: kwota, dzień, notatka. Pula maleje, saldo koperty rośnie. 🌐
- **US-3.2** Zabieram pieniądze z koperty z powrotem do puli. Nie wolno zabrać więcej, niż w kopercie jest wolne; dostaję komunikat z kwotą, którą mogę zabrać (409 `NotEnoughMoney`). 🌐
- **US-3.3** Dzielę to, co włożyłem do koperty, między jej podkoperty (przydział do podkoperty). Nie ruszam przy tym puli i nie mogę przypisać więcej, niż włożyłem do rodzica. 🌐
- **US-3.4** Widzę listę przydziałów koperty (i jej podkopert) i usuwam własny przydział. Usunięcie nie przejdzie, jeśli koperta nie ma już tych pieniędzy. 🌐

## 4. Miesiąc i pulpit

- **US-4.1** Pulpit pokazuje jeden miesiąc: wpływy, przydzielone do kopert, wydane i pulę. 🌐
- **US-4.2** Przełączam miesiące strzałkami w nagłówku albo z listy miesięcy. Domyślnie jest miesiąc, w którym jest dziś. 🌐
- **US-4.3** Saldo koperty **przechodzi** z miesiąca na miesiąc: to, co zostało, jest „otwarciem" następnego. Koperta pokazuje saldo, ile było dostępne w miesiącu (otwarcie plus przydzielone) i ile wydano. 🌐
- **US-4.4** Koperta z podkopertami pokazuje sumę wszystkiego, co w niej jest, oraz wolną część, która nie jest przypisana do podkopert. 🌐
- **US-4.5** Widzę wykres podziału dostępnych środków i wykres „dostępne a wydane" per koperta; przekroczone koperty są oznaczone. 🌐
- **US-4.6** Gdy nie mam jeszcze nic, pulpit prowadzi mnie: dodaj wpływ, dodaj kopertę. 📱
- **US-4.7** Początek miesiąca budżetowego (1–28) ustawiam w Ustawieniach; wszystkie miesiące liczą się od tego dnia. 📱
- **US-4.8** Lista miesięcy pokazuje każdy miesiąc od pierwszej aktywności do dziś: wpływy, przydzielone, wydane. Tapnięcie otwiera go na pulpicie. 🌐

## 5. Wydatki

- **US-5.1** Dodaję wydatek: kwota (przecinek albo kropka), koperta (też podkoperta), dzień i godzina, notatka. 🌐
- **US-5.2** Widzę saldo wybranej koperty, zanim zapiszę wydatek. Wydatek ponad saldo jest dozwolony (saldo wychodzi ujemne). 🌐
- **US-5.3** Edytuję wydatek, w tym przenoszę go do innej koperty. 🌐
- **US-5.4** Usuwam wydatek po potwierdzeniu. 🌐
- **US-5.5** Szczegóły koperty: saldo, dostępne, wydane, podkoperty, przydziały, wykres narastających wydatków i lista wydatków miesiąca. 🌐

## 6. Historia

- **US-6.1** Widzę wydatki miesiąca pogrupowane po dniach, od najnowszych. 🌐
- **US-6.2** Filtruję po kopercie. 🌐
- **US-6.3** Filtruję po zakresie dat i godzin. 📱
- **US-6.4** Z historii otwieram wydatek do edycji albo usunięcia (→ 5.3, 5.4). 📱

## 7. Wydatki cykliczne

- **US-7.1** Widzę reguły (koperta, kwota, tygodniowo albo miesięcznie, notatka, aktywna). 🌐
- **US-7.2** Dodaję, edytuję, wyłączam i usuwam regułę. Usunięcie nie kasuje wydatków, które już dodała. 🌐
- **US-7.3** Jednym przyciskiem „zastosuj" dodaję do miesiąca na ekranie wydatki z aktywnych reguł. Reguła, którą już zastosowałem dla tego miesiąca, nie dubluje się. Widzę, ile dodano. 🌐

- **US-7.4** Dodaję wpływ cykliczny (kwota, dzień miesiąca 1–28, notatka), np. wypłatę. 🌐
- **US-7.5** Dodaję regułę podziału: ile pieniędzy co miesiąc, w którym dniu, do której koperty (też podkoperty). 🌐
- **US-7.6** Wszystkie trzy rodzaje reguł mam w jednym ekranie z zakładkami (wydatki, wpływy, przydziały), edytuję je, wyłączam i usuwam; to, co reguła już dodała, zostaje. 🌐
- **US-7.7** „Zastosuj" dodaje do miesiąca na ekranie najpierw wpływy, potem przydziały, potem wydatki, każdy w dniu z reguły. Nic nie dubluje się przy ponownym zastosowaniu. 🌐
- **US-7.8** Przydział, którego koperta nie przyjmie (brakuje środków w kopercie nadrzędnej), jest pominięty i dostaję informację, ile takich było. 🌐
- **US-7.9** Pulpit pokazuje kartę „Do dodania w tym miesiącu" z liczbą wpływów, przydziałów i wydatków, które czekają, i przyciskiem „Dodaj". Gdy nic nie czeka, karty nie ma. 🌐

## 8. Ustawienia i dane

- **US-8.1** Zmieniam motyw: ciemny, jasny, systemowy. 📱
- **US-8.2** Eksportuję wydatki do CSV (`Envelope,Subenvelope,Amount,Date,Note`). 🌐
- **US-8.3** Importuję wydatki z CSV. Brakujące koperty (i podkoperty) są tworzone po nazwie, duplikaty pomijane, widzę ile zaimportowano i ile pominięto. 🌐
- **US-8.4** Pełna kopia danych (JSON): eksport, podgląd importu (ile jest teraz, ile w kopii) i import, który zastępuje moje dane. 🌐 Jest w API; aplikacja ma na razie tylko CSV.
- **US-8.5** Dane z pierwszej, offline'owej wersji aplikacji przenoszą się na serwer przy pierwszym uruchomieniu (okres → wpływ i przydziały, kategoria → koperta). 🌐
- **US-8.6** Apka jest po polsku. 📱

## 9. Współdzielenie koperty

- **US-9.1** Zapraszam kogoś do koperty (głównej, podkoperty idą razem z nią) adresem e-mail i wybieram rolę: właściciel albo członek. Zaproszony dostaje mail. 🌐
- **US-9.2** Po zalogowaniu tym adresem widzę zaproszenie na pulpicie i je przyjmuję albo odrzucam. Przyjęcie nie daje jeszcze dostępu: właściciel dostaje mail i musi mnie zatwierdzić. 🌐
- **US-9.3** Jako właściciel widzę członków i otwarte zaproszenia (czekające na odpowiedź i czekające na zatwierdzenie), zatwierdzam, cofam i odrzucam je. 🌐
- **US-9.4** Wspólna koperta jest na moim pulpicie z ikoną grupy i liczbą osób. Jej saldo to saldo całej koperty. 🌐
- **US-9.5** Do wspólnej koperty i jej podkopert przydzielam pieniądze ze swojej puli; mogę zabrać tylko tyle, ile sam włożyłem. Cudzych pieniędzy ani cudzych przydziałów nie ruszam. 🌐
- **US-9.6** W szczegółach wspólnej koperty widzę kartę „Kto ile włożył": ile włożyłem ja i ile każdy z pozostałych, do koperty i do każdej podkoperty. 🌐
- **US-9.7** Wydatek dodany przez inną osobę widzę w kopercie z jej autorem, ale nie zmniejsza on mojej puli ani mojego „wydane". Własne wydatki edytuję i usuwam; cudze tylko jako właściciel. 🌐
- **US-9.8** Jako właściciel zmieniam role członków (kilku właścicieli jest możliwych) i usuwam członków. Ostatniego właściciela nie można zdegradować ani usunąć. 🌐
- **US-9.9** Opuszczam kopertę po potwierdzeniu: tracę do niej dostęp, a pieniądze, które włożyłem, i moje wydatki zostają w niej. 🌐
- **US-9.10** Edytować i usuwać kopertę, dodawać do niej podkoperty może tylko właściciel; członek tych przycisków nie widzi. 🌐
- **US-9.11** Nie widzę niczego poza wspólną kopertą jej właściciela: ani jego innych kopert, ani wpływów, ani puli. 🌐

## 10. Konto

- **US-10.1** Loguję się adresem e-mail: dostaję kod i link, nie ma hasła. 🌐
- **US-10.2** Loguję się przez Google (aplikacja i przeglądarka). 🌐
- **US-10.3** Wylogowuję się; sesja kończy się na serwerze od razu. 🌐
- **US-10.4** Moje dane widzę tylko ja. 🌐

## 11. Blokada aplikacji (lokalna)

- **US-11.1** Ustawiam PIN (co najmniej 6 cyfr); jest przechowywany tylko jako solony hash PBKDF2. 📱
- **US-11.2** Po włączeniu blokady muszę podać PIN przy wejściu do apki. 📱
- **US-11.3** Zmieniam i wyłączam PIN. 📱
- **US-11.4** Włączam odblokowanie biometryczne, jeśli urządzenie je obsługuje. 📱

---

## Co liczy serwer

Obliczenia, które muszą być po stronie serwera, bo dotyczą pieniędzy i musi się zgadzać na każdym urządzeniu:
- pula i salda kopert, z przechodzeniem salda między miesiącami i sumowaniem podkopert (US-1.3, 4.1, 4.3, 4.4)
- reguły przydziałów: nie zabierzesz więcej, niż jest; nie przypiszesz więcej, niż włożyłeś do rodzica (US-3.2, 3.3, 3.4)
- historia miesięcy z podziałem na budżetowy początek miesiąca (US-4.8)
- idempotentne stosowanie reguł cyklicznych i podgląd tego, co czeka (US-7.3, 7.7, 7.9)
- uprawnienia i zasady „czyje to pieniądze" we wspólnej kopercie, zaproszenia z zatwierdzaniem, limity (US-9.x)
- import CSV z deduplikacją i import kopii z nowymi ID (US-8.3, 8.4)
