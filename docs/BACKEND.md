# API – spis endpointów

Skrót tego, co serwer udostępnia. Źródłem prawdy jest kontrakt (`packages/api-contract`), z którego powstaje Swagger (`docs.bida.maknet.com.pl`) i `openapi.json`. Model i zasady: [ENVELOPE_MODEL.md](ENVELOPE_MODEL.md), architektura: [ARCHITECTURE.md](ARCHITECTURE.md).

Wszystko poza `/health` i `/auth/*` wymaga zalogowanego użytkownika (nagłówek `Authorization: Bearer` albo ciasteczko sesji). Kwoty to liczby całkowite w groszach. Błędy domenowe mają ciało `{ "_tag": "...", ... }`.

## System i konto

| Endpoint | Opis |
|---|---|
| `GET /health` | czy serwer działa |
| `POST /auth/magic-link` | wysyła e-mail z linkiem i 6-cyfrowym kodem (zawsze 204) |
| `POST /auth/magic-link/code`, `/auth/magic-link/token` | wymieniają kod albo token z linku na sesję |
| `POST /auth/google`, `/auth/google/access-token` | logowanie przez Google (token ID z aplikacji, token dostępu z przeglądarki) |
| `GET /auth/me` | zalogowany użytkownik |
| `POST /auth/logout` | kończy sesję |

## Koperty

| Endpoint | Opis |
|---|---|
| `GET /envelopes` | wszystkie koperty użytkownika: top-level i subkoperty, po nazwie |
| `GET /envelopes/{id}` | jedna koperta (404, gdy jej nie widać) |
| `POST /envelopes` | tworzy kopertę; `parentId` ustawione = subkoperta (rodzic musi być top-level, inaczej 422 `ParentMustBeTopLevel`) |
| `PUT /envelopes/{id}` | zmienia nazwę, kolor i ikonę; miejsca w drzewie nie zmienia |
| `DELETE /envelopes/{id}` | usuwa kopertę z subkopertami, przydziałami, wydatkami i regułami; przydzielone pieniądze wracają do puli |

## Przydziały

| Endpoint | Opis |
|---|---|
| `GET /allocations?envelopeId&from&to` | przydziały koperty (dla top-level także jej subkopert), najnowsze pierwsze |
| `POST /allocations` | wkłada pieniądze do koperty; ujemna kwota zabiera je z powrotem |
| `PUT /allocations/{id}`, `DELETE /allocations/{id}` | zmiana i usunięcie własnego przydziału |

Przydział do subkoperty dzieli to, co użytkownik włożył do rodzica (nie rusza jego puli). Gdy koperta nie ma tylu pieniędzy albo przypisałoby się więcej, niż włożono do rodzica, odpowiedź to 409 `NotEnoughMoney` z `availableMinor`. Pula poniżej zera jest dozwolona.

## Przychody

| Endpoint | Opis |
|---|---|
| `GET /incomes?from&to` | przychody użytkownika, najnowsze pierwsze |
| `POST /incomes`, `PUT /incomes/{id}`, `DELETE /incomes/{id}` | dodanie, zmiana i usunięcie |

## Wydatki

| Endpoint | Opis |
|---|---|
| `POST /expenses` | dodaje wydatek do koperty (top-level albo sub) |
| `GET /expenses/{id}` | jeden wydatek |
| `PUT /expenses/{id}`, `DELETE /expenses/{id}` | zmiana i usunięcie; wolno autorowi i właścicielowi koperty, inaczej 403 |
| `GET /expenses?envelopeId&from&to&limit&offset` | lista, najnowsze pierwsze; `envelopeId` top-level obejmuje jej subkoperty; `from` włącznie, `to` wyłącznie (chwile ISO); domyślnie 50, najwyżej 200 |

## Reguły cykliczne

| Endpoint | Opis |
|---|---|
| `GET /recurring-rules` | własne reguły użytkownika |
| `POST /recurring-rules`, `PUT /recurring-rules/{id}`, `DELETE /recurring-rules/{id}` | zarządzanie; usunięcie nie kasuje wydatków, które reguła już dodała |
| `POST /recurring-rules/apply` | dodaje po jednym wydatku dla aktywnych reguł niezastosowanych jeszcze dla `from` (`{ from, to }`); można wołać wielokrotnie |

## Przegląd

| Endpoint | Opis |
|---|---|
| `GET /overview?from&to&timeZone` | przychód, to, co włożono do kopert i wydano w zakresie dni, pula na koniec zakresu oraz liczby każdej koperty (otwarcie, przydzielone, wydane, saldo, wolne) |
| `GET /overview/months?startDay&timeZone` | historia miesięcy od pierwszej aktywności do dziś, najnowsze pierwsze |

## Eksport i import

| Endpoint | Opis |
|---|---|
| `GET /export`, `POST /import/preview`, `POST /import` | pełna kopia danych użytkownika jako JSON; import zastępuje te dane w jednej transakcji i nadaje nowe ID |
| `GET /export.csv`, `POST /import/csv` | wydatki jako CSV `Envelope,Subenvelope,Amount,Date,Note`; import tworzy brakujące koperty po nazwie i pomija duplikaty (ta sama koperta, kwota, dzień i notatka) |
| `POST /import/legacy` | kopia z pierwszej, offline'owej wersji aplikacji (okres → przychód i przydziały, kategoria → koperta) |
