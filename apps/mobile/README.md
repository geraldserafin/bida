<div align="center">

# 💰 Money Planner

**An envelope-budgeting app that helps you _plan_ your money — not just track it.**

Plan your income across categories at the start of each period, then watch
*planned vs. spent vs. remaining* update as you log real spending.

[![Flutter](https://img.shields.io/badge/Flutter-3.44-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.12-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Platforms](https://img.shields.io/badge/platforms-Android%20%7C%20iOS%20%7C%20Windows-informational)](#)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

</div>

---

## ✨ The idea

Most finance apps are *trackers* — they tell you where your money went after it's
gone. Money Planner is a **planner**. It's built around **envelope budgeting**:

1. **Enter your income** for a period (e.g. July 2026).
2. **Split** that income across categories — Rent, Food, Savings, Fun… Each
   category is a virtual *envelope* you fill up front.
3. As the period goes on, **log spending** against each envelope.
4. See, per category and overall: **planned vs. spent vs. remaining** — with charts.

Delete a category mid-period? Its unspent allocation flows back into an
**Unallocated** pool, ready to re-split — while its past expenses stay on record
so your history is never distorted.

## 📱 Screenshots

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
| 🧧 **Envelope budgeting** | Allocate income to categories; spend against the plan |
| 📊 **Visual insight** | Pie chart of your split, progress bars for spent-vs-planned, spending-over-time line charts |
| 🔁 **Recurring rules** | Templates for regular income/expenses (rent, salary) that pre-fill new periods |
| 🧮 **Unallocated tracking** | Always know how much income is still free to assign |
| 📌 **Persistent balance bar** | Remaining balance stays visible on every screen |
| 🧭 **Bottom navigation** | Pulpit (dashboard) · Historia · Okresy · Ustawienia, one tap away |
| 🕓 **History** | Read-only summaries and charts for past periods |
| 🔐 **Local security** | PIN + biometric unlock (`local_auth`) |
| ☁️ **Encrypted sync** | Push an **AES-encrypted** blob to a private GitHub repo — the cloud only ever sees ciphertext |

## 🏗️ Architecture

A clean, layered structure that keeps domain, data, and UI separate:

```
lib/
├── main.dart                 # Entry point — boots the SQLite database
├── app.dart                  # MaterialApp: theming + routing
├── models/                   # Domain entities (pure Dart, no Flutter deps)
│   ├── period.dart
│   ├── category.dart
│   ├── split.dart            # the "plan": income → category allocation
│   ├── expense.dart
│   └── recurring_rule.dart
├── data/
│   └── database_helper.dart  # SQLite schema + connection (sqflite / ffi)
├── theme/
│   └── app_theme.dart        # Light & dark Material 3 themes
├── widgets/
│   └── remaining_balance_bar.dart   # shared sticky balance bar
└── screens/
    ├── dashboard/            # current-period overview + bottom nav (Pulpit)
    ├── history/              # read-only log of past expenses (Historia)
    ├── periods/              # period switcher (Okresy)
    ├── settings/             # security, sync, theme (Ustawienia)
    ├── period_setup/         # new period + income split
    ├── categories/           # category CRUD, icon/color picker
    ├── category_detail/      # planned/spent/remaining + charts per category
    ├── add_expense/          # log spending against a category
    ├── recurring/            # recurring income/expense rule templates
    └── lock/                 # PIN/biometric lock gate
```

### Data model

Five tables in SQLite, wired with foreign keys:

- **`periods`** — one row per planning period, holds total income
- **`categories`** — reusable envelopes (Rent, Food, …), with color + icon
- **`splits`** — the plan: how much of a period's income each category gets
- **`expenses`** — actual spending logged against a split
- **`recurring_rules`** — templates for repeating income/expenses

Expenses deliberately outlive their split so historical periods stay accurate
even after a category is removed.

## 🔒 Security model

- **Unlock** — biometric via `local_auth`, with a PIN fallback stored as a
  **salted hash** (never plaintext).
- **Sync** — data is exported to JSON, **encrypted with AES** (key derived from
  the PIN via PBKDF2), and only then pushed to GitHub as `data.enc`. The remote
  never sees anything but ciphertext.
- **Tokens** — the GitHub token lives in `flutter_secure_storage`, never in
  source. Local database files and secrets are `.gitignore`d.

## 🛠️ Tech stack

| Concern | Package |
|---|---|
| Local database | `sqflite` (+ `sqflite_common_ffi` for desktop) |
| Charts | `fl_chart` |
| State management | `provider` |
| HTTP / GitHub API | `http` |
| Encryption | `encrypt`, `crypto` |
| Secure token storage | `flutter_secure_storage` |
| Biometric / PIN | `local_auth` |
| Date & currency formatting | `intl` |

## 🚀 Getting started

**Prerequisites:** [Flutter](https://docs.flutter.dev/get-started/install) 3.44+
(bundles Dart 3.12).

```bash
git clone https://github.com/TheLis3k/MoneyPlaner.git
cd MoneyPlaner
flutter pub get
flutter run          # pick a device, or -d windows / -d chrome
```

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
- [x] **Phase 5** — Encrypted GitHub sync: AES + PBKDF2, push/pull `data.enc` via the GitHub API
- [x] **Phase 6** — Read-only History view (past periods + charts), bottom navigation bar, edge-case polish

🎉 **All planned phases are complete.**

**Extras already in:** custom categories with icon/color picker · full Polish localization (`pl`) with zł currency · period switcher · bottom navigation bar.

## 🤝 Contributing

This is a personal/portfolio project, but issues and suggestions are welcome —
open an issue to start a conversation.

## 📄 License

Released under the [MIT License](LICENSE).
