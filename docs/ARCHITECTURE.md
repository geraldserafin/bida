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

## Waluty

- **Kwota to liczba całkowita w jednostce mniejszej waluty** (`amountMinor`): 12,34 PLN to `1234`, 500 JPY to `500`. Liczbę miejsc po przecinku podaje `exponentOf(currency)` z kontraktu (`CURRENCY_EXPONENTS`).
- **Kody walut to enum w kontrakcie** (`Currency`, ISO 4217). Dodanie waluty to jedna linia w `currency.ts`. Baza sprawdza tylko kształt (`^[A-Z]{3}$`), więc nowa waluta nie wymaga migracji.
- **Okres ma walutę**, a wszystkie jego kwoty (dochód, koperty, wydatki) są w niej. Dzięki temu `planned − spent` zawsze ma sens.
- **Waluta domyślna** to ustawienie przestrzeni (`defaultCurrency`). Podstawia się automatycznie przy tworzeniu okresu i reguły cyklicznej, ale każde żądanie może podać inną.
- **Wydatek w innej walucie niż okres** zapisuje kwotę w walucie okresu (`amountMinor`, to ona liczy się do koperty) oraz to, co faktycznie zapłacono: `originalAmountMinor` i `originalCurrency` (oba null albo oba ustawione). Kursy wpisuje użytkownik, a konwersji nie liczymy. Podanie waluty okresu jest traktowane jak zwykły wydatek.
- **Reguła cykliczna ma walutę** i jest stosowana tylko do okresów w tej samej walucie.
- **Eksport i CSV** niosą walutę (kolumna `Currency`), a kwoty są formatowane i czytane według jej miejsc po przecinku.
- Okresów w różnych walutach nie sumujemy.

## Przestrzenie

- **Przestrzeń (`space`) to właściciel danych.** Kategorie, okresy, koperty, wydatki i reguły należą do dokładnie jednej przestrzeni (`space_id` w każdej tabeli). To ona, a nie użytkownik, jest kluczem własności. Współdzielenie budżetu będzie więc oznaczać wspólną przestrzeń z kilkoma członkami, bez scalania danych.
- Po instalacji istnieje jedna przestrzeń domyślna (`DEFAULT_SPACE_ID`). Konta i członkostwo dojdą później i nie zmienią reszty modelu.
- **Wybór przestrzeni.** Middleware `SpaceContext` czyta nagłówek `X-Space-Id`, a bez niego używa przestrzeni domyślnej. Dostarcza serwis `CurrentSpace`. Tu później wejdzie sprawdzanie członkostwa zalogowanego użytkownika. Nagłówka nie ma w parametrach endpointów, jest opisany w opisie API.
- **Zapytania.** Każde zapytanie repozytorium filtruje po `space_id` z `CurrentSpace`. Typ `InSpace<A, E>` oznacza efekt, który działa w przestrzeni bieżącego żądania, więc kompilator pilnuje, że nie da się wywołać repozytorium poza żądaniem.
- Same przestrzenie (lista, tworzenie, edycja) nie są ograniczone do przestrzeni, bo to one są najemcami. `GET /spaces/current` zwraca przestrzeń żądania.
- **Eksport, import i CSV** działają na przestrzeni żądania. Import zastępuje dane tylko tej przestrzeni.
- Testy uruchamiają się jako żądania w przestrzeni domyślnej (`TestSpace`, `TestSpaceContext`), a izolację między przestrzeniami sprawdza `spaces.test.ts`.

## Klient Dart

Z `Api` generujemy klienta Dart, żeby aplikacje w monorepo nie pisały zapytań ręcznie.

```
Api (Effect) → openapi.json → generator → packages/api-client-dart → zależność path
```

1. **Spec:** skrypt zapisuje `OpenApi.fromApi(Api)` do `openapi.json` i commitujemy go. Plik jest jedynym wejściem generatora i pokazuje zmiany kontraktu w diffie.
2. **Generator:** [`swagger_parser`](https://github.com/artflutter/swagger_parser). Czyta OpenAPI 3.1 i generuje klienta na `dio` + `retrofit` oraz klasy danych. Uruchamiany w devenv (Dart jest w toolchainie Fluttera).
3. **Paczka:** `packages/api-client-dart` (np. `bida_api_client`). **Wygenerowany kod jest commitowany**, żeby konsument nie musiał niczego generować.
4. **Regeneracja:** `pnpm gen:dart-client` zapisuje `openapi.json`, uruchamia `swagger_parser` i `build_runner` (pliki `.g.dart`) oraz formatuje kod. Ręczny `lib/bida_api_client.dart` tylko re-eksportuje wygenerowane `lib/src/export.dart`, a generator nadpisuje wyłącznie `lib/src`.
5. **Kontrola aktualności:** `pnpm check:dart-client` regeneruje klienta i sprawdza `git diff --exit-code`. Hook `pre-commit` uruchamia go, gdy w commicie zmienia się `packages/api-contract/src` lub `scripts`. Zmiana kontraktu bez zacommitowanego klienta nie przejdzie. Osobnego CI jeszcze nie ma.
6. **Dystrybucja:** paczka leży w monorepo, więc nie ma rejestru, publikowania ani tagów. Aplikacja Dart importuje ją przez zależność `path`:

   ```yaml
   dependencies:
     bida_api_client:
       path: ../../packages/api-client-dart
   ```

   Backend i klient zmieniają się w jednym commicie, więc kontrakt i jego konsument nie rozjeżdżają się wersjami.
7. **Zmiany niekompatybilne** (usunięty endpoint lub pole, zmieniony typ) wymagają w tym samym PR poprawienia aplikacji, która klienta używa. Osobne wersjonowanie paczki nie jest potrzebne.

### Wymagania wobec kontraktu

Wnioski ze spike'u na `swagger_parser` i OpenAPI 3.1 wygenerowanym przez Effect (działa, po spełnieniu poniższych):

- **Schematy w odpowiedziach i payloadach muszą mieć `identifier`** (`Category.json.annotate({ identifier: "Category" })`). Bez tego Effect wstawia schemat inline i generator tworzy osobną klasę dla każdego endpointu (`GetCategoriesIdResponse`, `PostCategoriesResponse`...). Z identyfikatorem powstaje jedna klasa `Category`.
- **Liczby całkowite jako `Schema.Int`**, nie `Schema.Number`. `Number` dopuszcza `Infinity` i `NaN`, więc w specu pojawia się `anyOf` i generator nie wyprowadza typu `int`.
- Brandowane ID są w specu zwykłym `string`, więc w Dart są `String`.
- Daty (`createdAt`, `updatedAt`) są w Dart na razie `String`, bo spec nie niesie informacji o formacie `date-time`.
- Nazwy metod pochodzą z `operationId` (`grupa.endpoint`), więc klient ma `api.categories.categoriesList()`. Powtórzenie nazwy grupy jest kosmetyczne.
- Błędy deklarowane w `error` trafiają do klas modeli (`CategoryNotFoundEncoded`), ale klient zgłasza je jako `DioException` z kodem statusu i ciałem.
- Klasa `Category` z klienta koliduje nazwą z modelem w aplikacji mobilnej, więc tam importujemy ją z prefiksem.

## Jak dodać nową domenę

1. Kontrakt: `<module>/<entity>.model.ts`, `<module>.errors.ts`, `<module>.api.ts`, dopisać grupę w `Api.ts`.
2. Migracja w `platform/migrations/`.
3. Moduł: `repository` → `service` → `http` → `module`.
4. Dopisać `XxxModule` i `XxxHttp` w `main.ts`.
5. Testy serwisu i repozytorium.

## Stan na dziś

Istnieje tylko `system` (`GET /health`), bez bazy i bez podziału na moduły. Pierwszym modułem do zbudowania jako wzorzec dla reszty jest `categories`.
