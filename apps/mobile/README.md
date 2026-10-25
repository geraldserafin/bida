<div align="center">

# 💰 Money Planner

**An envelope-budgeting app that helps you _plan_ your money — not just track it.**

Put your income into envelopes, then watch what is left in each of them as you
log real spending. What is left carries over to the next month.

[![Flutter](https://img.shields.io/badge/Flutter-3.44-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.12-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Platforms](https://img.shields.io/badge/platforms-Android%20%7C%20iOS%20%7C%20Windows-informational)](#)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

</div>

---

## ✨ The idea

Most finance apps are *trackers* — they tell you where your money went after it's
gone. Money Planner is a **planner**. It's built around **envelope budgeting**:

1. **Add your income** when it comes in — it lands in a pool of unallocated money.
2. **Put money into envelopes** — Rent, Food, Savings, Fun… An envelope can have
   sub-envelopes (Rent → Utilities, say).
3. **Log spending** against an envelope. Its balance drops.
4. See, per envelope and overall: **what was available, what was spent, what is
   left** — with charts. Whatever is left rolls over into the next month.

Took too much out of the pool? It goes negative and the app tells you, but it
never blocks you: an expense is a fact and has to be recordable.

## 📱 Screenshots

_These show the earlier, period-based version of the app._

<div align="center">
<table>
<tr>
<td align="center" width="25%">
<img src="docs/screenshots/dashboard.jpg" width="220" alt="Dashboard: income, planned total, unallocated amount, and a donut chart of the split"><br>
Dashboard
</td>
<td align="center" width="25%">
<img src="docs/screenshots/plan-vs-expenses.jpg" width="220" alt="Plan vs spent bar chart and the envelope list"><br>
Plan vs. spent
</td>
<td align="center" width="25%">
<img src="docs/screenshots/category-detail.jpg" width="220" alt="Category detail: planned/spent/remaining, spending-over-time chart, expense list"><br>
Category detail
</td>
<td align="center" width="25%">
<img src="docs/screenshots/history.jpg" width="220" alt="History: filterable log of all expenses"><br>
History
</td>
</tr>
</table>
</div>

## 🎯 Features

| | |
|---|---|
| 🧧 **Envelope budgeting** | Put income into envelopes and sub-envelopes; spend from them; balances roll over |
| 📊 **Visual insight** | Donut chart of where the money is, available-vs-spent bars, spending-over-time line charts |
| 🔁 **Recurring rules** | Templates for regular expenses (rent, subscriptions) that add themselves to the month with one tap |
| 🧮 **Unallocated tracking** | Always know how much income is still free to put into envelopes |
| 📅 **Months** | Step through months with the arrows; a list shows every month so far. The month can start on any day from 1 to 28 |
| 🧭 **Bottom navigation** | Pulpit (dashboard) · Historia · Miesiące · Ustawienia, one tap away |
| 🕓 **History** | Expenses of the month grouped by day, filtered by envelope, dates and time |
| 🔐 **Local security** | PIN + biometric unlock (`local_auth`) |
| ☁️ **Server-backed** | Your data lives on the Money Planner API, so it survives a lost phone and is the base for sharing a budget |

## 🏗️ Architecture

The app is a client of the Money Planner API (`apps/api` in the monorepo). It
needs the server: there is no local copy of the data, and a failed request
shows why and offers to try again.

```
lib/
├── main.dart                 # Entry point
├── app.dart                  # MaterialApp: providers, theming, routing
├── models/                   # What the UI works with (pure Dart)
│   ├── envelope.dart         # a pot of money; top-level or a sub-envelope
│   ├── allocation.dart, income.dart, expense.dart, recurring_rule.dart
│   ├── budget_month.dart     # the days a month covers (any first day)
│   ├── envelope_progress.dart, overview.dart, month_summary.dart
│   └── transaction.dart      # an expense with its envelope
├── data/                     # Everything that talks to the backend
│   ├── planner_repository.dart  # the one entry point, in the app's terms
│   ├── mappers.dart          # API types <-> models
│   ├── money.dart            # grosze <-> złoty
│   ├── api_client.dart       # Dio setup, API_URL
│   ├── api_exception.dart    # failures the UI can react to
│   └── legacy_migrator.dart  # one-off: old local database -> server
├── state/
│   ├── planner_state.dart    # envelopes, the month on screen, totals (Provider)
│   └── app_settings.dart     # theme, first day of month (on the device)
├── widgets/                  # shared widgets (error view, remote data, …)
└── screens/                  # dashboard, envelope detail, funding, incomes, months, history, settings, …
```

**Layers.** Screens only talk to `PlannerState`; the state talks to
`PlannerRepository`, the only place that knows about HTTP. The repository uses
the generated client in `packages/api-client-dart`, so requests and responses
are typed and cannot drift from the API. Models use whole units (zł) and
`DateTime`; the API uses minor units and ISO strings, and `data/mappers.dart`
is where they meet.

**Money.** Amounts are integers in grosze on the wire (12.34 zł is 1234) and
doubles in złoty in the app. There is one currency, the złoty.

**Months.** A month is just a range of days (`BudgetMonth`), starting on the
day set in Settings. The server computes what is in each envelope over that
range (`GET /overview`); balances roll over, so a month shows what was left
from before, what came in, what was spent and what is left now.

**Failures.** Repository methods throw `ApiException` (unreachable, not found,
conflict, invalid, server). Screens run changes through `attempt(...)`, which
shows a message and lets the user retry, and show fetched data through
`RemoteData`, which has a spinner, an error view with a retry button, and the
data.

**Moving old data.** The first version kept everything in a local SQLite
database. On launch, `LegacyMigrator` uploads that database once (to
`POST /import/legacy`) when the server is still empty, then renames the file
to `money_planner.db.migrated`. It never overwrites data the server already
has, and keeps the file if anything goes wrong so the next launch can retry.

## 🔒 Security model

- **Unlock** — biometric via `local_auth`, with a PIN fallback stored as a
  **salted hash** (never plaintext). This only guards the app on the device;
  The server has its own sign-in (an e-mail code or link, or Google), and the
  session is kept in secure storage on a phone and in a cookie in a browser.
- The PIN hash and a few preferences live in `flutter_secure_storage`.

## 🛠️ Tech stack

| Concern | Package |
|---|---|
| Backend client | `bida_api_client` (generated from the API contract), `dio` |
| Charts | `fl_chart` |
| State management | `provider` |
| Secure storage | `flutter_secure_storage` |
| Biometric / PIN | `local_auth`, `crypto` |
| Date & currency formatting | `intl` |
| Reading the old local database | `sqflite` (+ `sqflite_common_ffi` for desktop) |

## 🚀 Getting started

From the repository root, `devenv shell` and `devenv up` start Postgres, the
API, the docs and the web app on <http://localhost:8080>. `start-mobile` starts
the emulator (if it is not running) and runs the phone app on it. To run the
app by hand:

```bash
cd apps/mobile
flutter pub get
flutter run --dart-define=API_URL=http://10.0.2.2:3000   # Android emulator
```

`10.0.2.2` is the host machine as seen from the Android emulator (the default).
Use the machine's address on a real device. Debug builds allow plain HTTP.

Run the checks:

```bash
flutter analyze
flutter test
```

> **Windows note:** running the app on the Windows desktop target requires
> [Developer Mode](https://learn.microsoft.com/windows/apps/get-started/enable-your-device-for-development)
> enabled (for plugin symlink support). Android/iOS builds need Android
> Studio / Xcode set up respectively.

## 🗺️ Roadmap

- [x] **Phase 0** — Project scaffold, data model, SQLite schema
- [x] **Phase 1** — New Period & Add Expense screens, numeric dashboard, category detail with expense history
- [x] **Phase 2** — Charts (pie split, planned-vs-spent bars, spending-over-time line)
- [x] **Phase 3** — Recurring rules: templates, pre-fill new periods, auto-generate expenses
- [x] **Phase 4** — PIN (salted PBKDF2) + biometric lock screen, Settings security section
- [x] **Phase 5** — Encrypted GitHub sync (replaced by the API: data now lives on the server)
- [x] **Phase 6** — Read-only History view (past periods + charts), bottom navigation bar, edge-case polish
- [x] **Phase 7** — Accounts and sign-in (e-mail code, Google), data on the server
- [x] **Phase 8** — Envelope model: income and a pool, envelopes with sub-envelopes, allocations, balances that roll over, months instead of periods (see `docs/ENVELOPE_MODEL.md`)
- [ ] **Phase 9** — Shared envelopes

**Extras already in:** custom envelopes with icon/color picker · full Polish localization (`pl`) with zł currency · month switcher · bottom navigation bar.

## 🤝 Contributing

This is a personal/portfolio project, but issues and suggestions are welcome —
open an issue to start a conversation.

## 📄 License

Released under the [MIT License](LICENSE).
