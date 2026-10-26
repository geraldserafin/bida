# Architektura backendu

Dotyczy `apps/api` i `packages/api-contract`. Cel: jasny podział warstw, jedna odpowiedzialność na warstwę i struktura, która nie zamienia się w spaghetti, gdy domen przybywa.

## Założenia

- **Effect 4 wszędzie.** Serwisy to `Context.Service`, zależności to `Layer`, błędy są typowane w kanale `E`, funkcje mają spany (`Effect.fn`).
- **Czysty SQL przez `effect/sql`**, bez ORM-a. Sterownik: `@effect/sql-pg` (Postgres). Typy wyników pochodzą ze `Schema`, więc jedno źródło prawdy.
- **Vertical slices.** Folder na domenę, a nie folder na warstwę. Wszystko, co dotyczy kopert, leży w `modules/envelopes/`.
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

Moduły: `envelopes` (koperty, subkoperty i przydziały pieniędzy), `members` (członkowie i role), `invitations` (zaproszenia), `incomes` (przychody), `expenses`, `recurring`, `overview` (salda i historia miesięcy), `transfer` (eksport, import, CSV), `auth` (konta i sesje), `system` (health). Model danych opisuje [ENVELOPE_MODEL.md](ENVELOPE_MODEL.md).

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
// modules/incomes/incomes.module.ts
export const IncomesModule = IncomesService.layer.pipe(
  Layer.provide(IncomesRepository.layer),
)
export { IncomesService } from "./incomes.service.ts"
export { IncomesHttp } from "./incomes.http.ts"
```

Zależności między modułami są jawne i leżą w jednym miejscu:

```ts
// modules/expenses/expenses.module.ts
export const ExpensesModule = ExpensesService.layer.pipe(
  Layer.provide(ExpensesRepository.layer),
  Layer.provide(EnvelopesModule), // wykorzystuje EnvelopesService
)
```

Layery są memoizowane po referencji, więc moduł użyty przez kilka innych buduje się raz.

### Reguły zależności

1. Moduł importuje z innego modułu wyłącznie `*.module.ts` (serwis). Nigdy repozytorium, SQL ani tabele. Egzekwuje to reguła `noRestrictedImports` w Biome.
2. Graf zależności jest acykliczny: `envelopes ← members ← invitations` i `envelopes ← expenses ← recurring`, a `transfer` zależy od `envelopes` i `expenses`. `incomes` i `overview` nie zależą od żadnego modułu.
3. Gdy dwa moduły potrzebowałyby siebie nawzajem, cykl rozwiązuje baza, a nie kod. Przykład: usunięcie koperty kasuje jej wydatki, przydziały i reguły przez `FOREIGN KEY ... ON DELETE CASCADE`, więc `envelopes` nie zna `expenses` ani `recurring`.

### Składanie aplikacji

`main.ts` nie zawiera logiki. Składa moduły, handlery i platformę:

```ts
const Modules = Layer.mergeAll(EnvelopesModule, IncomesModule /* ... */)

const ApiRoutes = HttpApiBuilder.layer(Api).pipe(
  Layer.provide([SystemHttp, EnvelopesHttp /* ... */]),
  Layer.provide(Modules),
  Layer.provide(DbLive),
)
```

## Kontrakt (`packages/api-contract`)

- Zawiera tylko definicje: modele, błędy, endpointy. Nie zawiera kodu serwerowego, więc może go importować każdy klient.
- Struktura jest identyczna jak w `apps/api/src/modules`: folder na domenę.
- **Encje to `Model.Class`** z `effect/schema`. Jedna deklaracja pól daje warianty: wiersz bazy (`Entity`), `Entity.insert`, `Entity.update` oraz `Entity.json`, `Entity.jsonCreate`, `Entity.jsonUpdate` dla HTTP. Pola zarządzane przez serwer (`id`, `createdAt`, `updatedAt` oraz użytkownik: `ownerId`, `userId`, `createdBy`) nie wchodzą do wariantów `jsonCreate` i `jsonUpdate`.
- **Identyfikatory są brandowane** (`EnvelopeId`, `AllocationId`), żeby nie dało się pomylić ID różnych encji.
- Dokumentacja Swagger (`apps/docs`) jest generowana z `Api`, więc opisy endpointów (`OpenApi.annotations`) trzymamy w kontrakcie.

## Błędy

- **Błędy domenowe** (`EnvelopeNotFound`, `NotEnoughMoney`, walidacja) to `Schema.TaggedError` ze statusem HTTP (`httpApiStatus`). Mieszkają w kontrakcie, bo endpoint deklaruje je w `error`. Serwis zwraca je w kanale `E`.
- **Awarie infrastruktury** (baza niedostępna, błąd dekodowania wiersza) to defekty. Repozytorium robi `Effect.orDie`, nikt ich nie obsługuje po drodze, a na brzegu kończą jako `500`.
- Dzięki temu sygnatury serwisów zawierają wyłącznie błędy, które wywołujący może sensownie obsłużyć.

## Dane i baza

- **Zapytania**: `sql` (tagged template) w połączeniu z `SqlSchema.findAll/findOne/findOneOption`, które dekodują wynik przez `Schema`. Proste CRUD-y można wyprowadzić z modelu przez `SqlModel.makeRepository`.
- **Nazwy**: w TS camelCase, w SQL snake_case. Konwersję robi `PgClient` (`transformQueryNames` i `transformResultNames`).
- **Transakcje** zakładamy tylko w serwisie (`sql.withTransaction`), bo to on wie, co jest jedną operacją, np. „dodaj przydział po sprawdzeniu sald".
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

## Kwoty i daty

- **Kwota to liczba całkowita w groszach** (`amountMinor`): 12,34 zł to `1234`. Aplikacja ma jedną walutę, złotego, więc API nie niesie kodów walut (wielowalutowość odłożona, patrz [ENVELOPE_MODEL.md](ENVELOPE_MODEL.md)). Baza trzyma `bigint`, a repozytoria rzutują go na liczbę (`::float8`), bo sterownik zwraca `bigint` jako tekst.
- **Typy kwot** w `money.ts` kontraktu: `Money` (≥ 0), `PositiveMoney` (> 0), `NonZeroMoney` (przydział; ujemny zabiera pieniądze z koperty) i `Balance` (saldo, może być ujemne).
- **Przychody i przydziały mają dzień** (`IsoDate`, kolumna `date`, czytana jako tekst, żeby nie ruszać jej strefą czasową). **Wydatek ma chwilę** (`spent_at`, `timestamptz`).
- **Dzień wydatku zależy od strefy.** Zapytania o zakres dni (`GET /overview`) przyjmują `timeZone` (domyślnie `Europe/Warsaw`), a wydatek wpada w dzień, który miał w tej strefie. Lista wydatków (`GET /expenses`) filtruje po chwilach, więc klient sam przelicza dni na chwile.
- **Eksport i CSV** formatują kwoty z dwoma miejscami po przecinku.

## Koperty i pieniądze

Pełny opis zasad i widoku użytkownika: [ENVELOPE_MODEL.md](ENVELOPE_MODEL.md). Tu tylko to, co dotyczy kodu.

- **Właścicielem danych jest użytkownik**, nie osobna encja. Przychód ma `user_id`, koperta `owner_id`, przydział `user_id` (kto wpłacił), wydatek `created_by`, reguła cykliczna `user_id`. Nie ma kolumny najemcy w każdej tabeli.
- **Dostęp do koperty** daje wiersz w `envelope_members` (`role` = `owner` albo `member`) dla koperty top-level; subkoperta dziedziczy dostęp po `parent_id`. Zapytania łączą się przez `COALESCE(parent_id, id)`. Koperta, której użytkownik nie widzi, nie istnieje: 404 (`EnvelopeNotFound`). Widoczna, ale bez prawa zmiany: 403 (`Forbidden`).
- **Serwisy przyjmują `userId`** (`UserId`) jako pierwszy parametr, a handlery HTTP biorą go z `CurrentUser` (middleware `Authenticated`). Nie ma ukrytego kontekstu.
- **Uprawnienia wynikają z roli, nie z `owner_id`.** `owner_id` to twórca koperty. To, co wolno (edycja, usuwanie, podkoperty, zaproszenia, zmiana ról, usuwanie cudzych wydatków), zależy od roli w `envelope_members`; koperta może mieć kilku właścicieli.
- **Głębokość jest pilnowana w serwisie**: rodzic musi być kopertą top-level (`ParentMustBeTopLevel`). Baza pilnuje tylko `parent_id <> id`.
- **Salda nie są przechowywane.** Liczy je SQL z tabel `allocations` i `expenses`. Moduł `overview` czyta tabele innych modułów wprost, bo suma to pytanie o wszystkie naraz; to świadomy wyjątek od zasady o importach. Zakres dni dzieli sumy na „przed” (otwarcie) i „w zakresie”, a salda przechodzą między miesiącami.
- **Reguły przydziałów** (`EnvelopesService.checkChange`) są sprawdzane w transakcji, po zablokowaniu koperty top-level blokadą doradczą (`pg_advisory_xact_lock(hashtext(id))`), żeby dwa równoległe przydziały nie przekroczyły sald. Naruszenie to 409 `NotEnoughMoney` z `availableMinor`. Ujemna pula i ujemne saldo od wydatków są dozwolone.
- **Członkowie** (`members`): lista, zmiana roli, usunięcie i opuszczenie koperty to jedna operacja `remove` (właściciel usuwa każdego, każdy usuwa siebie), w transakcji pod blokadą doradczą na kopertę. Koperta zawsze ma co najmniej jednego właściciela (409 `LastOwner`), a członków może być `MAX_MEMBERS_PER_ENVELOPE` (10). Ktoś, kto odchodzi, zostawia przydziały i wydatki, a jego reguły cykliczne z tej koperty są kasowane. `GET /envelopes/{id}/contributions` zwraca sumę przydziałów per członek i per koperta (dla top-level także podkoperty).
- **Zaproszenia** (`invitations`) są do adresu e-mail, nie do linku: `invited` → `accepted` (zaproszony przyjął) → `approved` (właściciel zatwierdził, dopiero wtedy dostaje dostęp). Pozostałe końce (odrzucone, cofnięte, wygasłe po 14 dniach) zostają w tabeli. Jedno otwarte zaproszenie na adres i kopertę (unikalny indeks); ponowne zaproszenie odnawia je i ustawia nową rolę. Limity: 10 zaproszeń na godzinę na osobę i 10 członków (łącznie z otwartymi zaproszeniami). Mail dostaje zaproszony, a po przyjęciu właściciele; po zatwierdzeniu zaproszony. Zapraszać można tylko do koperty top-level (422 `NotShareable`).
- **Usuwanie** koperty kasuje kaskadą subkoperty, przydziały, wydatki i reguły (`ON DELETE CASCADE`).
- **Eksport i import** (`transfer`) dotyczą kopert, których użytkownik jest **jedynym członkiem**, razem z przychodami i regułami do nich. Koperty współdzielone nie wchodzą do kopii i import ich nie rusza, bo nie należą do niego samego. Eksport CSV zawiera za to własne wydatki użytkownika także ze współdzielonych kopert. Import zastępuje te dane w jednej transakcji i nadaje wszystkiemu nowe ID (ID są globalne, więc dokument może pochodzić od kogokolwiek). Opis ścieżek: [BACKEND.md](BACKEND.md).
- **Migracja 0009** przeniosła dane z przestrzeni i okresów do tego modelu (kategoria → koperta o tym samym ID, dochód okresu → przychód, plan okresu → przydział, oba z datą początku okresu). Przestrzeń bez członków (nieprzejęta przestrzeń domyślna) nie miała komu oddać danych i została usunięta.
- **Testy** idą przez prawdziwe serwisy na bazie testowej (`insertUser`, `resetDb`, `TestAuthenticated` z `platform/testing.ts`), bo reguły o pieniądzach, klucze obce i sumy są sednem. Czas w testach to `TestClock` zaczynający od 1970 roku.

## Konta i sesje

Bez haseł: użytkownik dowodzi, że ma dostęp do adresu e-mail.

- **Logowanie.** `POST /auth/magic-link` wysyła e-mail z linkiem i 6-cyfrowym kodem (zawsze 204, więc nie ujawnia, czy adres ma konto). Kod albo token z linku wymienia się na sesję (`/auth/magic-link/code`, `/auth/magic-link/token`). Pierwsze logowanie zakłada puste konto (bez kopert). Link i kod ważą 15 minut i działają raz; kod blokuje się po 5 złych próbach; jeden adres może zamówić 5 maili na godzinę. **Google:** aplikacja loguje się przez Google i wysyła `POST /auth/google` z tokenem ID. Serwer sam sprawdza go na `node:crypto` (`modules/auth/google.ts`): podpis RS256 względem kluczy Google (pobieranych z cache'owaniem), `iss`, `aud` (jeden z `GOOGLE_CLIENT_IDS`), `exp` i `email_verified`. **Przeglądarka** nie dostaje tokenu ID bez przycisku rysowanego przez Google, więc apka webowa używa własnego przycisku i okna zgody Google, które zwraca token dostępu; wysyła go na `POST /auth/google/access-token`. Serwer pyta Google (`tokeninfo`), dla kogo token wystawiono, i przyjmuje tylko nasz klient oraz zweryfikowany adres (token z cudzej aplikacji nie może nikogo zalogować), a imię bierze z `userinfo`. Tożsamość zapisuje się w tabeli `identities` (`provider`, `subject`), więc zmiana adresu w Google nie tworzy nowego konta, a konto z tym samym zweryfikowanym adresem to ta sama osoba.
- **Sesja to wiersz w tabeli `sessions`**, a jej token to 256 losowych bitów, w bazie trzymany tylko jako hash SHA-256. Wygasa po 30 dniach od ostatniego użycia, a `POST /auth/logout` kończy ją od razu. To nie jest JWT: serwer przy każdym żądaniu sprawdza sesję w bazie, więc unieważnienie działa natychmiast.
- **Przekazywanie sesji.** Apka mobilna wysyła `Authorization: Bearer` i trzyma token w secure storage. Przeglądarka dostaje ciasteczko `bida_session` (`HttpOnly`, `Secure`, `SameSite=Lax`), którego skrypty nie widzą; o wyborze decyduje pole `transport` (`token` albo `cookie`) przy logowaniu. Żądanie z ciasteczkiem, które coś zmienia, musi mieć nagłówek `Origin` z `CORS_ORIGINS`, inaczej obca strona mogłaby zmusić przeglądarkę do działania w imieniu użytkownika.
- **Middleware `Authenticated`** (kontrakt, `HttpApiSecurity`: bearer i cookie) dostarcza `CurrentUser`. Jego implementacja jest w module `auth`, a schematy trafiają do OpenAPI (przycisk Authorize w Swaggerze).
- **E-mail** wysyła `Mailer` (`platform/mailer.ts`, `nodemailer`). Bez `SMTP_URL` wiadomości trafiają tylko do logu, co jest przeznaczone do developmentu. Ustawienia: `SMTP_URL`, `MAIL_FROM`, `APP_URL`, `COOKIE_SECURE`, `CORS_ORIGINS`, `GOOGLE_CLIENT_IDS`.

## Walidacja i konwencje API

Zasada: zły input kończy się na brzegu odpowiedzią 400, a nie błędem bazy (500). Dlatego kontrakt sprawdza więcej, niż wymaga sam typ.

- **ID to UUID** (`Uuid` z `uuid.ts`, `Schema.isUUID`). Dotyczy ścieżek, query i body.
- **Daty kalendarzowe muszą istnieć** (`IsoDate` w `text.ts`): `2026-02-31` jest odrzucone.
- **Limity:** nazwy ≤ 200 znaków, notatki ≤ 1000, ikona ≤ 50 (`text.ts`), kwoty od 0 (albo od 1 dla wydatków) do `MAX_MINOR` = 10^12 groszy (`money.ts`), tablice w dokumencie importu mają maksimum (np. 200 000 przydziałów). Ciało żądania jest ucinane przy 8 MiB (`platform/http.ts`, przetestowane na prawdziwym serwerze).
- **Tworzenie zwraca 201** (`HttpApiSchema.status(201)`), usuwanie 204, błędy domenowe 404/409/422 z ciałem `{ _tag, ... }`. Zły input i nieoczekiwane awarie mają puste ciało (400 i 500), więc nic z wnętrza nie wycieka.
- **Edycja to `PUT`** z pełnym obiektem (nie `PATCH`, bo nie przyjmujemy częściowych zmian).
- **Nazwy w specu.** Schematy odpowiedzi mają `identifier`, a klasy błędów są nazywane przez `wire()` (`errors.ts`), żeby w OpenAPI nie pojawiało się `...Encoded`. `wire` zwraca ten sam schemat dla tej samej klasy, bo inaczej OpenAPI numeruje duplikaty (`EnvelopeNotFound_3`).
- **Równoległe `apply`** reguł cyklicznych jest serializowane blokadą doradczą Postgresa (`pg_advisory_xact_lock`) na użytkownika i zakres dni, więc drugie wywołanie czeka i nie dodaje nic. Baza pilnuje tego dodatkowo unikalnym indeksem (`recurring_id`, `recurring_month`).

Znane luki, celowo odłożone: limit żądań ogólnie (jest tylko limit maili logowania na adres), czyszczenie wygasłych kodów i sesji z bazy, listy bez paginacji (poza wydatkami).

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

- **Schematy w odpowiedziach i payloadach muszą mieć `identifier`** (`Envelope.json.annotate({ identifier: "Envelope" })`). Bez tego Effect wstawia schemat inline i generator tworzy osobną klasę dla każdego endpointu (`GetEnvelopesIdResponse`, `PostEnvelopesResponse`...). Z identyfikatorem powstaje jedna klasa `Envelope`.
- **Liczby całkowite jako `Schema.Int`**, nie `Schema.Number`. `Number` dopuszcza `Infinity` i `NaN`, więc w specu pojawia się `anyOf` i generator nie wyprowadza typu `int`.
- Brandowane ID są w specu zwykłym `string`, więc w Dart są `String`.
- Daty (`createdAt`, `updatedAt`) są w Dart na razie `String`, bo spec nie niesie informacji o formacie `date-time`.
- Nazwy metod pochodzą z `operationId` (`grupa.endpoint`), więc klient ma `api.envelopes.envelopesList()`. Powtórzenie nazwy grupy jest kosmetyczne.
- Błędy deklarowane w `error` trafiają do klas modeli (np. `EnvelopeNotFound`), ale klient zgłasza je jako `DioException` z kodem statusu i ciałem.
- Klasy z klienta (`Envelope`, `Expense`, `Income`...) kolidują nazwami z modelami w aplikacji mobilnej, więc tam importujemy klienta z prefiksem (`as api`).

## Jak dodać nową domenę

1. Kontrakt: `<module>/<entity>.model.ts`, `<module>.errors.ts`, `<module>.api.ts`, dopisać grupę w `Api.ts`.
2. Migracja w `platform/migrations/`.
3. Moduł: `repository` → `service` → `http` → `module`.
4. Dopisać `XxxModule` i `XxxHttp` w `main.ts`.
5. Testy serwisu i repozytorium.

## Stan na dziś

Działa pełny backend: konta i sesje (link i kod z e-maila, Google), koperty z subkopertami, przychody, przydziały, wydatki, reguły cykliczne, przegląd miesięcy z saldami toczącymi się, eksport, import i CSV. Aplikacja mobilna i webowa pracują na tym modelu. Koperty można współdzielić: członkowie z rolami `owner` i `member`, zaproszenia z zatwierdzaniem przez właściciela, widok „kto ile włożył". Dalsze plany (cykliczne wpływy, reguły podziału): [ROADMAP.md](ROADMAP.md).
