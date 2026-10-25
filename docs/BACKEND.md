# Backend – spis funkcji do zrobienia

Źródło: przegląd kodu `apps/mobile/lib` (ekrany, `PlannerState`, `PlannerRepository`, serwisy).
Dziś cała apka jest lokalna: SQLite + `flutter_secure_storage` + ręczny sync szyfrowanym plikiem na GitHubie.
Cel: dane i logika na serwerze, apka tylko klient.

> **Zakres etapu 1:** bez kont i logowania – jeden anonimowy właściciel danych. Sekcja 2 (auth) i kolumny `userId` są odłożone na później. Co użytkownik może robić w apce: `USER_STORIES.md`.

## 0. Decyzje do podjęcia przed kodowaniem

| Temat    | Stan dziś                     | Propozycja                                                            |
| -------- | ----------------------------- | --------------------------------------------------------------------- |
| Konta    | brak, jedno urządzenie        | rejestracja/logowanie, każdy zasób należy do usera                    |
| ID       | autoinkrement `INTEGER`       | UUID (v7) – klient może tworzyć rekordy offline                       |
| Kwoty    | `REAL` (double)               | liczby całkowite w groszach (`amountMinor`) – bez błędów zaokrągleń   |
| Daty     | ISO bez strefy (czas lokalny) | `Instant` UTC + osobno data kalendarzowa (`YYYY-MM-DD`) dla okresów   |
| Offline  | działa w pełni bez sieci      | do ustalenia: online-only (prościej) vs offline-first z kolejką zmian |
| Baza     | –                             | Postgres (+ migracje), np. `@effect/sql-pg`                           |
| Usuwanie | twarde                        | soft delete (`deletedAt`), jeśli ma być sync offline                  |

## 1. Model danych (tabele)

Przeniesione 1:1 z lokalnego SQLite, plus `userId` w każdej tabeli.
- `users` – id, email, passwordHash, createdAt
- `settings` – userId, themeMode, firstDayOfMonth (1–28), locale
- `periods` – id, userId, name, startDate, endDate, income
- `categories` – id, userId, name, color (hex), icon?
- `splits` (koperty) – id, periodId, categoryId, plannedAmount
- `expenses` – id, splitId, amount, date (z godziną), note?, recurringId?
- `recurring_rules` – id, userId, categoryId, amount, frequency (`weekly|monthly`), note?, active

Reguły integralności z apki, które muszą zostać na serwerze:
- kategoria **w użyciu** (ma split w jakimkolwiek okresie) nie może być usunięta → `409`
- usunięcie okresu kasuje kaskadowo splity i wydatki
- jedna koperta na kategorię w okresie (`UNIQUE(periodId, categoryId)`)
- `firstDayOfMonth` tylko 1–28; kwoty wydatków > 0

## 2. Konto i autoryzacja

Zastępuje lokalny `AuthService` tam, gdzie chodzi o tożsamość. **PIN i biometria zostają lokalne** (blokada ekranu apki, `LockGate`) – to nie jest logowanie do serwera.
- `POST /auth/register`
- `POST /auth/login` → access token + refresh token
- `POST /auth/refresh`
- `POST /auth/logout`
- `GET  /me`, `PATCH /me` (email, hasło)
- `DELETE /me` – usunięcie konta i wszystkich danych (RODO)
- middleware: wszystkie pozostałe endpointy wymagają tokenu; filtrowanie po `userId`
- (opcjonalnie) reset hasła mailem

## 3. Ustawienia użytkownika

Dziś `AppSettings` w secure storage. Przenieść to, co ma sens między urządzeniami:
- `GET /settings`, `PUT /settings` – `firstDayOfMonth`, `themeMode`
- Zostaje lokalnie: PIN, biometria, ostatnio wybrany okres (UI)

## 4. Kategorie (`CategoriesScreen`, `CategoryEditor`)

- `GET    /categories`
- `POST   /categories`
- `PATCH  /categories/{id}` (nazwa, kolor, ikona)
- `DELETE /categories/{id}` → `409`, gdy w użyciu
- Pierwszy start: **domyślny zestaw kategorii** dla nowego konta (dziś ich tworzenie jest po stronie apki – sprawdzić `category_visuals`/seed)

## 5. Okresy i plan (`NewPeriodScreen`, `PeriodsScreen`, dashboard)

- `GET    /periods` – lista, najnowsze pierwsze
- `GET    /periods/current` – najnowszy po `startDate`
- `POST   /periods` – tworzy okres **razem ze splitami** w jednej transakcji (`name, startDate, endDate, income, planned: {categoryId: amount}`); pomija kwoty ≤ 0
- `GET    /periods/{id}` – okres + podsumowanie (`planned, spent, remaining, unallocated`)
- `PUT    /periods/{id}/plan` – edycja dochodu i alokacji (logika z `editCurrentPeriodPlan`):
  - kwota > 0 → utwórz/zaktualizuj split
  - kwota = 0 → usuń split, **chyba że ma wydatki** – wtedy zostaje z `planned = 0`
- `DELETE /periods/{id}` – kaskadowo
- `GET    /periods/summaries` – podsumowanie wszystkich okresów (planned/spent), do ekranu listy
- Podpowiedź planu nowego okresu z reguł cyklicznych (`plannedFromRecurring`) – może być liczona po stronie klienta z `GET /recurring-rules`, albo `GET /periods/plan-suggestion`
- „Wybrany okres" (`current_period_id`) – stan UI, zostaje na kliencie

## 6. Koperty i postęp (dashboard, `CategoryDetailScreen`)

- `GET /periods/{id}/progress` – lista `{category, split, spent, planned, remaining}` (dziś `categoryProgress`; agregat liczony w SQL `SUM`)
- `POST /periods/{id}/envelopes` – szybkie dodanie koperty (`quickAddEnvelope`): tworzy kategorię + split z `planned = 0` w jednej transakcji, zwraca `splitId`
- Dane do wykresów (pie planned, planned vs spent, linia wydatków w kategorii): wystarczą `progress` + wydatki koperty; osobne endpointy tylko jeśli wyjdzie za ciężko

## 7. Wydatki (`AddExpenseScreen`, `HistoryScreen`, `PeriodDetailScreen`)

- `POST   /expenses` – `splitId, amount, date, note?`
- `GET    /splits/{id}/expenses` – wydatki koperty, od najnowszych
- `PATCH  /expenses/{id}`
- `DELETE /expenses/{id}`
- `GET    /periods/{id}/transactions` – wydatki okresu z dołączoną kategorią, `ORDER BY date DESC, id DESC`
  - filtry z ekranu Historia po stronie serwera: `categoryId`, `from`, `to` (data + godzina), paginacja (`limit`, `cursor`)
- Walidacja: split musi należeć do usera

## 8. Wydatki cykliczne (`RecurringRulesScreen`, `RecurringEditor`)

- `GET    /recurring-rules`
- `POST   /recurring-rules`
- `PATCH  /recurring-rules/{id}` (w tym `active`)
- `DELETE /recurring-rules/{id}` – wydatki już wygenerowane zostają (`recurringId → NULL`)
- `POST   /periods/{id}/recurring/apply` – generuje wydatek dla każdej aktywnej reguły, która nie była jeszcze użyta w tym okresie (idempotentne); tworzy split, jeśli brak (planned = kwota reguły); zwraca liczbę dodanych
- Do rozważenia: **automatyczne** naliczanie cron-em zamiast ręcznego przycisku (dziś tylko ręcznie)

## 9. Import / eksport / backup (`SettingsScreen`, `BackupScreen`)

Zastępuje ręczny sync przez GitHub (`GitHubSyncService`, `SyncManager`, `CryptoService`, `SyncSetupScreen`) – po przejściu na serwer te pliki i ekrany można usunąć.
- `GET  /export` – pełny zrzut danych usera (JSON, ten sam kształt co dziś `exportData`: `periods, categories, recurring_rules, splits, expenses`)
- `POST /import` – zastąpienie wszystkich danych zrzutem, w jednej transakcji; najpierw dry-run/podgląd (liczby wierszy: okresy, wydatki – jak `RestorePreview`)
- `GET  /export.csv` – CSV `Period,Category,Amount,Date,Note`
- `POST /import/csv` – import CSV z dopasowaniem okresów/kategorii po nazwie (tworzy brakujące), **pomija duplikaty** (ta sama koperta + kwota + dzień + notatka), zwraca `{imported, skipped}`
- **Migracja z lokalnej bazy**: jednorazowy `POST /import` z istniejącego `money_planner.db` przy pierwszym logowaniu
- Szyfrowanie po stronie klienta (passphrase) – decyzja: zostaje (zero-knowledge) czy rezygnujemy na rzecz TLS + szyfrowania na dysku

## 10. Synchronizacja (jeśli offline-first)

- `GET  /sync?since=<cursor>` – zmiany od ostatniego sync
- `POST /sync` – paczka zmian z klienta (upsert/delete po UUID)
- Rozwiązywanie konfliktów: dziś last-write-wins; zostawić tak albo `updatedAt` per rekord
- Pole `updatedAt` / `deletedAt` we wszystkich tabelach

## 11. Infrastruktura backendu

- Kontrakt w `packages/api-contract` (kolejne grupy: `auth`, `periods`, `categories`, `expenses`, `recurring`, `export`) → Swagger w `apps/docs` generuje się sam
- Spójny model błędów: `401` brak tokenu, `404` nie ma/nie twoje, `409` konflikt (kategoria w użyciu), `422` walidacja
- Migracje bazy, seed dla dev
- Konfiguracja przez env (`DATABASE_URL`, `JWT_SECRET`, `PORT`)
- Testy: logika planu (`PUT /plan`), idempotencja `recurring/apply`, import CSV
- Deployment: hosting API, `docs.bida.com` dla Swaggera, HTTPS (apka ma teraz tylko cleartext w debug manifeście)

## 12. Zmiany po stronie apki (żeby ten backend miał z kim gadać)

- Warstwa `ApiClient` (`http` jest już w zależnościach) zamiast `PlannerRepository`/sqflite
- Ekran logowania/rejestracji przed `LockGate`
- Obsługa błędów sieci i stanów ładowania w `PlannerState`
- Usunięcie `database_helper`, `sqflite*`, `github_sync_service`, `sync_manager`, `crypto_service`, `sync_setup_screen` po migracji
- Adres API z `--dart-define=API_URL=...` (już jest w `server_status_banner.dart`)

## Proponowana kolejność

1. Baza + migracje + użytkownicy + auth (sekcje 0, 1, 2)
2. Kategorie, okresy, splity, `progress` (4–6) – wystarczy do działającego dashboardu
3. Wydatki + historia (7)
4. Reguły cykliczne (8)
5. Import/eksport i migracja z lokalnej bazy (9)
6. Sync offline, jeśli w ogóle potrzebny (10)
