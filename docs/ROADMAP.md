# Roadmapa

Kolejność prac nad backendem. Szczegóły architektury: `ARCHITECTURE.md`, funkcje apki: `USER_STORIES.md`, lista endpointów: `BACKEND.md`.

Zasady: jeden pionowy slice naraz, każdy kończy się działającym endpointem z testami, a front przechodzi na backend moduł po module, bez jednego wielkiego przełączenia.

## Etap 1 – Fundament

- Postgres w devenv (`services.postgres`, `DATABASE_URL`)
- `platform/`: config, połączenie z bazą (`SqlClient`), migracje
- Konfiguracja testów (`vitest` + `@effect/vitest`)
- Reguła Biome zabraniająca importów między modułami poza `*.module.ts`
- Podział `apps/api/src` na `platform/` i `modules/`, `system` (health) jako pierwszy moduł

**Gotowe, gdy:** serwer startuje na bazie z uruchomionymi migracjami, a `GET /health` działa w nowej strukturze.

## Etap 2 – `categories` (wzorzec)

> Moduł zastąpiły koperty (etap 9): kategoria stała się kopertą. Wzorzec modułu został.

- Kontrakt: model, błędy, grupa endpointów (`US-5.x`)
- Migracja, repozytorium, serwis, handler, `categories.module.ts`
- Testy: serwis (fałszywe repo), repozytorium (prawdziwy Postgres), endpointy (`HttpApiTest`)

Najmniejszy moduł bez zależności. Na nim potwierdzamy, że architektura się sprawdza, zanim powielimy ją dla reszty.

## Etap 3 – Klient Dart

Robimy go już na module `categories`, żeby wcześnie wykryć problemy ze specyfikacją (Effect generuje OpenAPI 3.1).

1. **Spike:** wygenerować `openapi.json` i uruchomić `swagger_parser` na tym specu. Ocenić jakość wygenerowanych klas i klienta
2. Skrypt `openapi.json` w monorepo (zapis `OpenApi.fromApi(Api)`)
3. Paczka `packages/api-client-dart` z wygenerowanym kodem w repo
4. Sprawdzenie w CI, że wygenerowany kod jest aktualny
5. Podpięcie paczki w aplikacji Dart jako zależność `path` (patrz `ARCHITECTURE.md`)

**Gotowe, gdy:** aplikacja Dart importuje paczkę z `packages/` i wywołuje `GET /categories`.
**Plan B**, jeśli `swagger_parser` nie poradzi sobie z 3.1: inny generator albo konwersja specu do 3.0.

## Etap 4 – `budgets` (okresy i koperty)

> Zastąpione etapem 9: okresy zniknęły na rzecz miesięcy jako widoku i salda toczącego się.

Największa wartość dla użytkownika: po tym etapie działa dashboard.

- Okresy: tworzenie z podziałem na koperty w jednej transakcji, lista, szczegóły, usuwanie kaskadowe (`US-1.x`)
- Edycja planu z zachowaniem kopert, które mają wydatki (`PUT /periods/{id}/plan`)
- Podsumowanie okresu: planned / unallocated (`US-2.x`). `spent`, `remaining` i `progress` per kategoria wymagają wydatków, więc dochodzą w etapie 5 (moduł `expenses` zależy od `budgets`, nie odwrotnie)
- Szybkie dodanie koperty razem z kategorią
- Blokada usunięcia kategorii w użyciu (klucz obcy → `CategoryInUse`)

## Etap 5 – `expenses`

- Dodawanie, edycja, usuwanie wydatków (`US-3.x`)
- Historia okresu z filtrami: kategoria, daty, godziny, paginacja (`US-4.x`)
- Wydatki koperty do wykresów i szczegółów kategorii

## Etap 6 – `recurring`

- CRUD reguł cyklicznych (`US-6.1`–`6.3`)
- `apply` do bieżącego okresu: idempotentne, tworzy brakującą kopertę (`US-6.4`)
- Podpowiedź planu nowego okresu z reguł

## Etap 7 – `transfer`

- Eksport i import JSON z podglądem przed odtworzeniem
- Eksport i import CSV z deduplikacją (`US-7.3`–`7.5`)
- Jednorazowa migracja danych z lokalnej bazy aplikacji

## Etap 8 – Dalej

- Konta i logowanie przez link i kod z e-maila: zrobione (sesje)
- Logowanie przez Google: zrobione (token ID weryfikowany po stronie serwera)
- Zaproszenia i role: wspólne koperty (etap 9, część 2)
- Zarządzanie sesjami (lista urządzeń, wylogowanie ze wszystkich), usuwanie konta
- Pilnowanie zmian niekompatybilnych kontraktu (np. sprawdzanie diffa `openapi.json` w CI)
- Ewentualnie tryb offline i synchronizacja (decyzja po etapie 5)

## Etap 9 – Model kopert i współdzielenie

Przestrzenie i okresy ustępują kopertom z subkopertami, saldem toczącym się i (dalej) współdzielonymi kopertami. Model, reguły i widok użytkownika: [ENVELOPE_MODEL.md](ENVELOPE_MODEL.md). Całość idzie jedną gałęzią (`feat/envelopes`) i jednym PR-em; części są kolejnymi commitami.

**Część 1 – rdzeń (zrobione).**
- Przychody, koperty z subkopertami, przydziały (z regułami sald), wydatki, reguły cykliczne
- Przegląd: salda toczące się, pula, historia miesięcy (`GET /overview`, `/overview/months`)
- Migracja 0009 przenosi dane z przestrzeni i okresów; usunięte przestrzenie, okresy, kategorie
- Eksport, import i CSV na nowym modelu; import kopii z pierwszej, offline'owej wersji
- Aplikacja: pulpit miesiąca, szczegóły koperty, przydziały, wpływy, lista miesięcy, zarządzanie kopertami

**Część 2 – współdzielenie (zrobione).**
- Członkowie koperty top-level, zaproszenia po e-mailu (zaproszony → akceptuje → właściciel zatwierdza), role `owner` i `member`
- Widok „kto ile włożył" w kopercie i jej podkopertach
- Wyjście z koperty, zmiana ról (kilku właścicieli zamiast przekazywania własności), usuwanie

**Część 3 – automaty i polerka.**
- Cykliczne przychody (wypłata) i reguły podziału („co miesiąc X zł na Dom")
- Ekran zbiorczy dla wielu wspólnych kopert, archiwizacja zamkniętych kopert, szybkie dodanie wydatku

## Zależności między etapami

```
1 Fundament → 2 categories → 3 Klient Dart
                    └──────→ 4 budgets → 5 expenses → 6 recurring
                                              └──────→ 7 transfer
                                                       └──→ 9 koperty (zastępuje 2, 4, 5, 6, 7 nowym modelem)
```

Etap 3 można prowadzić równolegle z etapem 4.
