# Local Money Planner — Build Plan (Flutter)

## 1. Concept

A **planner**, not just a tracker:

1. You enter **income** for a period (e.g. a month).
2. You **split** that income across categories/goals (rent, food, savings, fun, etc.) — this is your plan.
3. As the period goes on, you log **actual spending** against each split.
4. The app shows you, per category: *planned vs. spent vs. remaining*, plus overall charts.

Think "envelope budgeting" — each category is a virtual envelope you fill at the start of the period and draw from as you spend.

---

## 2. Core Data Model

Four main entities, stored in SQLite (via `sqflite`):

### `periods`
One row per planning period (e.g. "July 2026").
| field | type | notes |
|---|---|---|
| id | int (PK) | |
| name | text | e.g. "July 2026" |
| start_date | date | |
| end_date | date | |
| income | real | total income entered for this period |

### `categories`
Reusable across periods (Rent, Food, Transport, Savings, Fun, etc.)
| field | type | notes |
|---|---|---|
| id | int (PK) | |
| name | text | |
| color | text | hex code, used in charts |
| icon | text | optional icon key |

### `splits`
The "plan" — how much of a period's income is allocated to each category.
| field | type | notes |
|---|---|---|
| id | int (PK) | |
| period_id | int (FK) | |
| category_id | int (FK) | |
| planned_amount | real | how much was allocated |

### `expenses`
Actual spending logged against a split.
| field | type | notes |
|---|---|---|
| id | int (PK) | |
| split_id | int (FK) | which envelope this draws from |
| amount | real | |
| date | date | |
| note | text | optional |
| recurring_id | int, nullable | FK to `recurring_rules`, if generated automatically |

### `recurring_rules`
For your "re-entering" recurring transactions.
| field | type | notes |
|---|---|---|
| id | int (PK) | |
| category_id | int (FK) | |
| amount | real | |
| frequency | text | monthly / weekly |
| note | text | e.g. "Rent" |
| active | bool | |

---

## 3. Screens

1. **Home / Current Period Dashboard**
   - Income for the period, total planned, total spent, total remaining
   - **Unallocated** figure (income minus currently active splits) — this is what grows when a category is deleted or shrinks when you allocate more
   - Pie chart: planned split by category
   - Bar/progress bars: spent vs. planned per category (this is the heart of the app)

2. **New Period Setup**
   - Enter income
   - Add/adjust category splits — allowed to exceed income, but show a clear warning (e.g. "You've allocated $X more than your income") rather than blocking
   - Option to pre-fill from recurring rules

3. **Category Detail**
   - Planned amount, spent so far, remaining
   - List of expenses logged against it
   - Line chart: spending over time within the period

4. **Add Expense**
   - Pick category/split, amount, date, note
   - Quick-add from recurring rules

5. **Recurring Rules**
   - List/add/edit recurring income or expense templates

6. **History / Past Periods**
   - List of past periods, tap to view read-only summary + charts

7. **Settings**
   - PIN/biometric lock setup
   - GitHub sync (connect repo, manual "Sync now" button, last synced timestamp)
   - Manage categories

8. **Lock Screen**
   - PIN entry or biometric prompt, shown on app launch/resume

**Persistent balance:** the current period's remaining balance should be visible on every screen, not just the Dashboard — e.g. a slim sticky bar/header showing "Remaining: $X" that stays on screen while you navigate between Add Expense, Category Detail, etc. Worth building as a small shared widget early on so every screen can just drop it in.

---

## 4. Charts (using `fl_chart`)

- **Pie chart** — planned split by category (Dashboard)
- **Stacked/grouped bar chart** — planned vs. spent per category (Dashboard)
- **Line chart** — cumulative spending over the period, per category or overall (Category Detail)
- **Trend line** — remaining balance over time across periods (optional, later)

---

## 5. Security: PIN/Biometric + Encrypted Sync

- **Local unlock:** use `local_auth` for biometric, plus a PIN fallback stored as a salted hash (never plaintext) using `crypto` package.
- **Data at rest:** encrypt the JSON export before it ever touches GitHub.
  - Use `encrypt` package (AES) with a key derived from your PIN or a separate passphrase (e.g. via PBKDF2).
  - Store the encrypted blob as `data.enc` in your private repo — GitHub only ever sees ciphertext.
- **Sync flow:**
  1. On sync: read local SQLite → export to JSON → encrypt → push `data.enc` to GitHub via REST API.
  2. On other device: pull `data.enc` → decrypt with passphrase → import into local SQLite.
- Keep your GitHub token in `flutter_secure_storage`, never hardcoded.

**Decision: same PIN used for both unlock and sync encryption.** One thing to remember. Just make sure the PIN is long enough (4-digit is fine for unlock convenience, but since it's also your encryption key, consider requiring 6+ digits, or running it through PBKDF2 with a decent iteration count before deriving the AES key — that adds real resistance even if the PIN itself is short).

---

## 6. Suggested Build Order (Phases)

**Phase 1 — Local core (no sync, no lock yet)**
- Data model + SQLite setup
- New Period screen (income + splits)
- Add Expense screen
- Dashboard with planned vs. spent (numbers only, no charts yet)

**Phase 2 — Charts**
- Add `fl_chart`, wire up pie chart + progress bars on Dashboard
- Line chart on Category Detail

**Phase 3 — Recurring rules**
- Recurring rules CRUD
- "Pre-fill from recurring" on New Period setup
- Auto-generate expense entries from active rules

**Phase 4 — Security**
- PIN setup + local_auth biometric
- Lock screen on launch/resume

**Phase 5 — GitHub sync**
- Encrypt/decrypt JSON export
- GitHub REST API read/write
- Manual "Sync now" button + last-synced indicator
- Conflict handling: last-write-wins is fine for a solo app — flag if you want anything smarter later

**Phase 6 — Polish**
- History/past periods view
- Category management UI
- Edge cases: over-allocated splits, deleting categories with existing expenses, etc.

---

## 7. Key Packages

| Purpose | Package |
|---|---|
| Local database | `sqflite` |
| Charts | `fl_chart` |
| HTTP (GitHub API) | `http` |
| Encryption | `encrypt`, `crypto` |
| Secure token storage | `flutter_secure_storage` |
| Biometric/PIN | `local_auth` |
| State management | `provider` or `riverpod` (either is fine for this app size) |

---

## 8. Category Deletion Behavior

**Decision:** when a category is deleted mid-period, its **unspent planned amount is freed back into "unallocated" funds** for that period — it becomes available to re-split into other categories, rather than being reassigned automatically or silently archived.

- The `split` row for that category is removed (or marked inactive).
- Any `expenses` already logged against it stay in the database for historical accuracy (so past periods/charts still show correct totals) — they just no longer belong to an active split.
- The period's dashboard should show a clear "Unallocated: $X" figure so you can see what's free to re-split at any time, not just when a category is deleted.
- Deleting a category doesn't delete its past history globally — only removes it as an option for *future* splits, unless you also choose to purge it everywhere (a separate, more destructive action worth keeping behind a confirmation).