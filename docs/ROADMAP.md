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

Największa wartość dla użytkownika: po tym etapie działa dashboard.

- Okresy: tworzenie z podziałem na koperty w jednej transakcji, lista, szczegóły, usuwanie kaskadowe (`US-1.x`)
- Edycja planu z zachowaniem kopert, które mają wydatki (`PUT /periods/{id}/plan`)
- `progress` (planned / spent / remaining / unallocated) i podsumowania okresów (`US-2.x`)
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

- Konta, logowanie i `userId` w tabelach
- Deployment API oraz `docs.bida.com` (Swagger)
- Pilnowanie zmian niekompatybilnych kontraktu (np. sprawdzanie diffa `openapi.json` w CI)
- Ewentualnie tryb offline i synchronizacja (decyzja po etapie 5)

## Zależności między etapami

```
1 Fundament → 2 categories → 3 Klient Dart
                    └──────→ 4 budgets → 5 expenses → 6 recurring
                                              └──────→ 7 transfer
```

Etap 3 można prowadzić równolegle z etapem 4.
