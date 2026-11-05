# API – spis endpointów

Skrót tego, co udostępnia serwer. Źródłem prawdy jest kontrakt (`packages/api-contract`). Z niego powstają Swagger (`docs.bida.maknet.com.pl`) i `openapi.json`. Model i zasady opisuje [MONEY_MODEL.md](MONEY_MODEL.md), a architekturę [ARCHITECTURE.md](ARCHITECTURE.md).

Wszystko poza `/health` i `/auth/*` wymaga zalogowanego użytkownika: nagłówka `Authorization: Bearer` albo ciasteczka sesji. Kwoty są liczbami całkowitymi w groszach. Błędy domenowe mają ciało `{ "_tag": "...", ... }`. Kod 409 oznacza regułę pieniędzy, a jego pola mówią, co można zrobić dalej.

## System i konto

| Endpoint | Opis |
|---|---|
| `GET /health` | czy serwer działa |
| `POST /auth/magic-link` | wysyła e-mail z linkiem i 6-cyfrowym kodem (zawsze 204) |
| `POST /auth/magic-link/code`, `/auth/magic-link/token` | wymieniają kod albo token z linku na sesję |
| `POST /auth/google`, `/auth/google/access-token` | logowanie przez Google |
| `GET /auth/me`, `POST /auth/logout` | zalogowany użytkownik; koniec sesji |
| `PUT /account` | ustawia imię |
| `POST /account/delete` | usuwa konto (F04); body zawiera adres e-mail jako potwierdzenie; 409 `NegativeShare` |

## Otwarcie aplikacji, „Do załatwienia”, pulpit

| Endpoint | Opis |
|---|---|
| `POST /sync` | wykonuje to, co należne, w kolejności: zamknięcie okresów, otwarcie nowych, wpływy, przelewy, wydatki cykliczne; idempotentny (F34) |
| `GET /summaries`, `POST /periods/:id/summary/seen` | podsumowania zamkniętych okresów jeszcze niewidziane (F35) |
| `GET /todo` | sprawy do decyzji: portfela użytkownika i jego gospodarstw |
| `POST /todo/:id/resolve` | potwierdza kwotę, wykonuje przelew albo dodaje wydatek (z `decision` i `correction`) |
| `POST /todo/:id/dismiss` | zostawia sprawę bez działania |
| `GET /overview?from&to` | portfel na dziś i gospodarstwa w zakresie dni (F38) |

## Portfel (F31)

| Endpoint | Opis |
|---|---|
| `GET /wallet` | saldo i „w tym niepotwierdzone” |
| `GET /wallet/entries` | historia: wpływy, przelewy, wycofania, zwroty |
| `POST /wallet/incomes` | wpływ pewny albo szacowany |
| `PUT /wallet/incomes/:id`, `POST /wallet/incomes/:id/confirm`, `POST /wallet/incomes/:id/remove` | korekta, potwierdzenie i usunięcie; minus tylko z `correction` (409 `WalletWouldGoNegative`) |

## Gospodarstwa i okresy (F05, F06, F16–F18, F23, F24, F32, F37)

| Endpoint | Opis |
|---|---|
| `GET /households`, `POST /households` | lista z saldem bieżącej skarbonki; nowe gospodarstwo z cyklem i kopertami |
| `GET`, `PUT`, `DELETE /households/:id` | odczyt; zmiana nazwy i usunięcie (tylko właściciel; usunięcie daje 409 `NegativeShare`) |
| `PUT /households/:id/cycle` | cykl okresów (właściciel) |
| `GET /households/:id/periods`, `POST /households/:id/periods/next` | okresy; otwarcie następnego |
| `GET /periods/:id?forWhom` | skarbonka: saldo, plany, wolne pieniądze, udziały, porównanie z poprzednim okresem, prognoza |
| `PUT /periods/:id/end` | koniec bieżącego okresu (właściciel, nie wcześniej niż dziś) |
| `GET /periods/:id/moves` | przelewy, wycofania, przeniesienie reszty |
| `POST /periods/:id/transfers`, `POST /periods/:id/withdrawals` | przelew z portfela i wycofanie do portfela (F32) |
| `GET /households/:id/log`, `POST /log/:id/undo` | log zmian otwartych okresów i cofnięcie zmiany |

## Członkowie i zaproszenia (F13, F14, F22, F36)

| Endpoint | Opis |
|---|---|
| `GET /households/:id/members` | członkowie z rolą, zamrożeniem i udziałem |
| `PUT /households/:id/members/:userId` | nadanie albo odebranie roli właściciela; zawsze zostaje co najmniej jeden właściciel |
| `DELETE /households/:id/members/:userId` | usunięcie członka; dodatni udział wraca do jego portfela, przy ujemnym 409 `NegativeShare` |
| `POST /households/:id/members/:userId/freeze`, `/unfreeze` | zamrożenie i odmrożenie |
| `POST /households/:id/leave` | wyjście; `withdraw` decyduje, czy udziały wracają do portfela |
| `POST`, `GET /households/:id/invitations`, `DELETE /households/:id/invitations/:invitationId` | zaproszenia (właściciel) |
| `GET /invitations`, `POST /invitations/:id/accept`, `/decline` | zaproszenia na mój adres; przyjęcie od razu robi członkiem |

## Koperty i plany (F11, F12, F19)

| Endpoint | Opis |
|---|---|
| `GET`, `POST /households/:id/envelopes` | koperty (także zarchiwizowane); nowa koperta |
| `PUT`, `DELETE /envelopes/:id` | zmiana; usunięcie tylko koperty bez wydatków |
| `POST /envelopes/:id/archive`, `/unarchive` | archiwizacja i przywrócenie |
| `PUT /periods/:id/plans/:envelopeId` | plan koperty w otwartym okresie |

## Wydatki (F08–F10, F28)

| Endpoint | Opis |
|---|---|
| `POST /households/:id/expenses` | dodaje wydatek; 409 `PlanTooSmall`, `NotEnoughInPeriod` albo `WalletWouldGoNegative` prowadzi przez kroki F08, ponowienie z `decision` |
| `GET`, `PUT`, `DELETE /expenses/:id` | odczyt, edycja (w zamkniętym okresie tylko tytuł), usunięcie |
| `GET /expenses` | historia z filtrami: gospodarstwo, okres, koperta, autor, „Dla kogo”, dni |

## Reguły cykliczne (F25–F27)

| Endpoint | Opis |
|---|---|
| `GET`, `POST /recurring-rules`, `PUT`, `DELETE /recurring-rules/:id` | wpływy, przelewy i wydatki cykliczne |
| `POST /recurring-rules/:id/apply` | wcześniejsze zastosowanie następnego wystąpienia |
| `POST /households/:id/recurring-rules/apply` | wszystkie wydatki cykliczne gospodarstwa w bieżącym okresie |
