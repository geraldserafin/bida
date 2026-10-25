# Architektura backendu

Dotyczy `apps/api` i `packages/api-contract`. Cel: jasny podział warstw, jedna odpowiedzialność na warstwę i struktura, która nie zamienia się w spaghetti, gdy domen przybywa.

## Założenia

- **Effect 4 wszędzie.** Serwisy to `Context.Service`, zależności to `Layer`, błędy są typowane w kanale `E`, funkcje mają spany (`Effect.fn`).
- **Czysty SQL przez `effect/sql`**, bez ORM-a. Sterownik: `@effect/sql-pg` (Postgres). Typy wyników pochodzą ze `Schema`, więc jedno źródło prawdy.
- **Vertical slices.** Folder na domenę, a nie folder na warstwę. Wszystko, co dotyczy kategorii, leży w `modules/categories/`.
- **Kontrakt jest osobnym pakietem** i jedynym miejscem, w którym definiujemy kształt API.

## Struktura

```
packages/api-contract/src/
  Api.ts                         # HttpApi: składa grupy z modułów
  <module>/
    <entity>.model.ts            # Model.Class: encja + warianty db/json
    <module>.errors.ts           # błędy domenowe ze statusem HTTP
    <module>.api.ts              # HttpApiGroup: endpointy
    index.ts

apps/api/src/
  main.ts                        # composition root: składa Layery i startuje serwer
  platform/                      # infrastruktura współdzielona, bez logiki biznesowej
    config.ts                    #   Config (PORT, DATABASE_URL)
    db.ts                        #   SqlClient + uruchomienie migracji
    migrations/                  #   0001_nazwa.ts, 0002_nazwa.ts, ...
  modules/
    <module>/
      <module>.repository.ts     # SQL
      <module>.service.ts        # logika biznesowa
      <module>.http.ts           # HttpApiBuilder.group
      <module>.module.ts         # jedyny publiczny plik modułu
```

Planowane moduły: `categories`, `budgets` (okresy + koperty), `expenses`, `recurring`, `transfer` (import/eksport), `system` (health).

## Warstwy

Zależności idą w jedną stronę: `http → service → repository → SqlClient`.

| Warstwa | Plik | Odpowiada za | Nie wolno jej |
|---|---|---|---|
| HTTP | `*.http.ts` | przyjąć zdekodowane żądanie, wywołać serwis, oddać wynik. Błędy domenowe przepuszcza | SQL, reguł biznesowych, transakcji |
| Serwis | `*.service.ts` | reguły biznesowe, walidacja domenowa, transakcje, składanie wielu repozytoriów i serwisów innych modułów | znać HTTP i pisać SQL |
| Repozytorium | `*.repository.ts` | zapytania SQL, mapowanie wierszy na typy domenowe przez `Schema` | reguł biznesowych, transakcji, innych modułów |
| Platforma | `platform/*` | konfiguracja, połączenie z bazą, migracje | wiedzy o domenach |

Każda z warstw jest `Context.Service` z interfejsem i statycznym `layer`. Dzięki temu w testach podmieniamy implementację przez Layer, bez mocków.

## Moduł i `*.module.ts`

`*.module.ts` to jedyny plik, który wolno importować spoza modułu. Eksportuje Layer ze swoimi serwisami oraz handlery HTTP. Repozytorium jest wpinane prywatnie (`Layer.provide`, nie `provideMerge`), więc typ Layera wystawia tylko serwis.

```ts
// modules/categories/categories.module.ts
export const CategoriesModule = CategoriesService.layer.pipe(
  Layer.provide(CategoriesRepository.layer),
)
export { CategoriesService } from "./categories.service.ts"
export { CategoriesHttp } from "./categories.http.ts"
```

Zależności między modułami są jawne i leżą w jednym miejscu:

```ts
// modules/expenses/expenses.module.ts
export const ExpensesModule = ExpensesService.layer.pipe(
  Layer.provide(ExpensesRepository.layer),
  Layer.provide(BudgetsModule), // wykorzystuje BudgetsService
)
```

Layery są memoizowane po referencji, więc moduł użyty przez kilka innych buduje się raz.

### Reguły zależności

1. Moduł importuje z innego modułu wyłącznie `*.module.ts` (serwis). Nigdy repozytorium, SQL ani tabele. Egzekwuje to reguła `noRestrictedImports` w Biome.
2. Graf zależności jest acykliczny: `categories ← budgets ← expenses ← recurring`, a `transfer` zależy od wszystkich.
3. Gdy dwa moduły potrzebowałyby siebie nawzajem, cykl rozwiązuje baza, a nie kod. Przykład: usunięcie kategorii użytej w kopercie blokuje `FOREIGN KEY ... ON DELETE RESTRICT`, repozytorium mapuje błąd `ConstraintError` na `CategoryInUse`, a `categories` nie zna `budgets`.

### Składanie aplikacji

`main.ts` nie zawiera logiki. Składa moduły, handlery i platformę:

```ts
const Modules = Layer.mergeAll(CategoriesModule, BudgetsModule /* ... */)

const ApiRoutes = HttpApiBuilder.layer(Api).pipe(
  Layer.provide([SystemHttp, CategoriesHttp /* ... */]),
  Layer.provide(Modules),
  Layer.provide(DbLive),
)
```

## Kontrakt (`packages/api-contract`)

- Zawiera tylko definicje: modele, błędy, endpointy. Nie zawiera kodu serwerowego, więc może go importować każdy klient.
- Struktura jest identyczna jak w `apps/api/src/modules`: folder na domenę.
- **Encje to `Model.Class`** z `effect/schema`. Jedna deklaracja pól daje warianty: wiersz bazy (`Entity`), `Entity.insert`, `Entity.update` oraz `Entity.json`, `Entity.jsonCreate`, `Entity.jsonUpdate` dla HTTP. Pola zarządzane przez serwer (`id`, `createdAt`, `updatedAt`) nie wchodzą do wariantów `jsonCreate` i `jsonUpdate`.
- **Identyfikatory są brandowane** (`CategoryId`, `PeriodId`), żeby nie dało się pomylić ID różnych encji.
- Dokumentacja Swagger (`apps/docs`) jest generowana z `Api`, więc opisy endpointów (`OpenApi.annotations`) trzymamy w kontrakcie.

## Błędy

- **Błędy domenowe** (`CategoryNotFound`, `CategoryInUse`, walidacja) to `Schema.TaggedError` ze statusem HTTP (`httpApiStatus`). Mieszkają w kontrakcie, bo endpoint deklaruje je w `error`. Serwis zwraca je w kanale `E`.
- **Awarie infrastruktury** (baza niedostępna, błąd dekodowania wiersza) to defekty. Repozytorium robi `Effect.orDie`, nikt ich nie obsługuje po drodze, a na brzegu kończą jako `500`.
- Dzięki temu sygnatury serwisów zawierają wyłącznie błędy, które wywołujący może sensownie obsłużyć.

## Dane i baza

- **Zapytania**: `sql` (tagged template) w połączeniu z `SqlSchema.findAll/findOne/findOneOption`, które dekodują wynik przez `Schema`. Proste CRUD-y można wyprowadzić z modelu przez `SqlModel.makeRepository`.
- **Nazwy**: w TS camelCase, w SQL snake_case. Konwersję robi `PgClient` (`transformQueryNames` i `transformResultNames`).
- **Transakcje** zakładamy tylko w serwisie (`sql.withTransaction`), bo to on wie, co jest jedną operacją, np. „utwórz okres z kopertami".
- **Migracje**: pliki TS w `platform/migrations/` o nazwie `NNNN_opis.ts`, uruchamiane przez `PgMigrator` przy starcie. Numeracja jest globalna, bo klucze obce wymagają kolejności między modułami. To jedyny element schematu, który nie leży w folderze modułu.
- **Konwencje danych**: ID jako UUID, kwoty jako liczby całkowite w groszach (`amount_minor`), znaczniki czasu jako `timestamptz` w UTC, daty kalendarzowe jako `date`.
- **Baza lokalnie**: Postgres z `devenv` (`services.postgres`), adres w `DATABASE_URL`.

## Testy

| Co | Jak |
|---|---|
| Serwis | z fałszywym Layerem repozytorium (in-memory) |
| Repozytorium | na prawdziwym Postgresie z migracjami |
| Handler / endpoint | przez cały `HttpApi` z `HttpApiTest.groups`, z podstawionym serwisem |

Runner: `vitest` z `@effect/vitest`.

## Jak dodać nową domenę

1. Kontrakt: `<module>/<entity>.model.ts`, `<module>.errors.ts`, `<module>.api.ts`, dopisać grupę w `Api.ts`.
2. Migracja w `platform/migrations/`.
3. Moduł: `repository` → `service` → `http` → `module`.
4. Dopisać `XxxModule` i `XxxHttp` w `main.ts`.
5. Testy serwisu i repozytorium.

## Stan na dziś

Istnieje tylko `system` (`GET /health`), bez bazy i bez podziału na moduły. Pierwszym modułem do zbudowania jako wzorzec dla reszty jest `categories`.
