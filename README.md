# MoneyMan

**Track every Money. Own your money.**

A complete, production-grade, **fully offline** personal finance app for Android built with Flutter.
No login. No bank sync. No servers. Every number you see comes from a local SQLite ledger that
never leaves your phone.

<p>
  <img alt="Flutter" src="https://img.shields.io/badge/Flutter-3.24-02569B?logo=flutter&logoColor=white">
  <img alt="Dart" src="https://img.shields.io/badge/Dart-3.5-0175C2?logo=dart&logoColor=white">
  <img alt="Platform" src="https://img.shields.io/badge/Android-6.0%2B-3DDC84?logo=android&logoColor=white">
  <img alt="Offline" src="https://img.shields.io/badge/offline--first-SQLite-916CFF">
  <img alt="License" src="https://img.shields.io/badge/license-MIT-black">
</p>

---

## Download the APK

**Direct link:** https://github.com/Rajdeep189/MentalistMoney/releases/download/v1.0.0/MoneyMan-1.0.0.apk

1. Open **[Releases](../../releases/latest)** (or the direct link above).
2. Download `MoneyMan-1.0.0.apk` (~63 MB, universal APK for arm64 / armv7 / x86_64).
3. On your phone allow **Install unknown apps** for the browser or file manager you used.
4. Open the downloaded file → **Install**.

The APK is built automatically by GitHub Actions on every push (see
`.github/workflows/build-apk.yml`). It is a release build signed with the debug key so it can be
sideloaded; swap in your own keystore before publishing to the Play Store.

---

## The three commands

```bash
flutter pub get
flutter run
flutter build apk --release
```

`flutter build apk --release` writes `build/app/outputs/flutter-apk/app-release.apk`.

Requirements: Flutter 3.24+ (Dart 3.4+), Android SDK 34, Java 17.

---

## What is inside

### Five tabs, one ledger

| Tab | What it does |
| --- | --- |
| **Home** | Safe-to-Spend hero card, month summary, budget progress, spending donut, upcoming bills, net worth, quick actions, smart insights. Cards can be reordered and hidden in *Appearance → Dashboard cards*. |
| **Transactions** | Grouped by day, swipe to edit/delete, multi-select bulk actions (move category/account, delete), full-text search, filters (type, account, category, tags, amount range, payment method, date range), recurring rules, CSV/PDF export. |
| **Budgets** | Weekly/monthly/yearly/custom budgets, overall or per-category, rollover and carry-forward, projected spend, daily allowance, category breakdown, daily bar chart, threshold alerts. |
| **Goals** | Savings goals with contributions, linked account, monthly target, deadline countdown, progress ring, auto-created savings transactions. |
| **Stats** | 14+ chart types: category donut, daily bars, income-vs-expense trend, month-by-month grouped bars, category ranking, calendar heatmap, per-account spending, previous-period comparison, year-over-year, cash-flow, fixed-vs-variable, forecast, insights and largest transactions. |

### Everything else that ships

- **Accounts** — cash, bank, credit card (limit / statement / due day / available credit), wallet,
  investment, loan and custom accounts; grouped by type; archive instead of delete.
- **Transfers** — between any two accounts, optional fee (booked as its own expense). Transfers are
  **excluded** from income, expense and budget math, and never inflate your reports.
- **Net worth** — assets minus liabilities, live from account balances.
- **Categories** — 16 seeded expense and 7 income categories, drag-to-reorder, favourite, merge,
  archive, per-category monthly budget, icon/colour picker.
- **Add transaction sheet** — calculator pad, type switch, account, category, date/time, payment
  method (UPI, Cash, Card…), tags, note, receipt photo, recurring toggle, duplicate detection.
- **Bills** — due dates, reminders scheduled one day before and on the day (9:00 AM), auto-created
  transactions when marked paid, skip/snooze, monthly commitment total, **bill calendar**.
- **Bill splitting** — groups, members, equal/percent/exact/shares splits, per-member balances and
  the fewest possible settlement suggestions, shareable summary.
- **Achievements** — seeded badges with live progress recomputed from your data.
- **Reports** — branded PDF (Poppins, violet accents, optional premium footer), CSV export, and a
  premium **custom report builder** with range and section pickers.
- **Import** — CSV import with automatic column detection, manual mapping, live preview, duplicate
  skipping and per-row error reporting.
- **Backup** — single-file JSON export and merge-or-replace restore.
- **Settings** — theme (system/light/dark), 7 accent colours, 5 theme packs, text size, density,
  amount display, currency, language (English/हिन्दी), date format, first day of week, month start,
  default account/category/type/payment method, haptics, notifications (budget, bills, goals, daily,
  weekly), biometric/PIN lock, auto-lock timer, privacy (hide amounts, block screenshots),
  dashboard layout.
- **Design system** — 8-point spacing scale, 20 dp screen padding, 22 dp card radius, 16 dp field and
  button radius, 48 dp minimum touch targets, tabular figures for every amount, count-up and
  staggered fade animations, chart draw-in, original liquid-glass surfaces and CustomPainter
  illustrations (no stock assets, nothing borrowed from any other app).

---

## Architecture

```
lib/
├── main.dart                  # boot: warm SQLite, init notifications, runApp
├── app.dart                   # MaterialApp, theme mode, text scale, root routing
├── core/
│   ├── theme/                 # colours, type scale, spacing, radius, ThemeData, theme packs
│   ├── utils/                 # money formatting & parsing, calculator engine, smart engine,
│   │                          # validators, icon registry
│   └── l10n/l10n.dart         # English + Hindi strings
├── data/
│   ├── db/app_database.dart   # schema, migrations, seeds, demo data, change notifier
│   ├── models/                # every entity + serialisation + derived getters
│   └── repositories/          # 12 repositories, hand-written SQL, no codegen
├── providers/app_providers.dart  # the whole Riverpod graph
├── services/                  # notifications, biometrics, secure screen, receipts
├── widgets/                   # design-system widgets (cards, fields, charts, sheets…)
└── screens/                   # splash, onboarding, setup, lock, shell, home, transactions,
                               # accounts, categories, budgets, goals, stats, bills, splits,
                               # notifications, achievements, premium, profile, settings, io
```

**State management:** Riverpod. A single `revisionProvider` (backed by a `ValueNotifier` inside the
database) is watched by every data provider, so one `INSERT` anywhere invalidates exactly the
screens that read that data — no manual refresh plumbing.

**Money:** every amount is an **integer number of paise**. No doubles touch currency arithmetic.

**Offline-first:** `sqflite` is the only source of truth. There is no HTTP client in the dependency
list and no analytics, ads or crash-reporting SDK.

---

## Database schema (20 tables)

`settings`, `accounts`, `categories`, `transactions`, `tags`, `transaction_tags`, `budgets`,
`budget_categories`, `goals`, `goal_contributions`, `bills`, `recurring_rules`, `attachments`,
`split_groups`, `split_members`, `split_expenses`, `split_shares`, `settlements`, `achievements`,
`user_profile`.

Highlights:

- `transactions` stores `amount` (paise, always positive), `type` (`income` / `expense` /
  `transfer`), `account_id`, optional `to_account_id` for transfers, `category_id`, `date`,
  `payment_method`, `note`, `recurring_rule_id`, `attachment_path`, `created_at`, `updated_at`.
- `budget_categories` maps many categories to one budget; `budgets.account_id` scopes a budget to a
  single account.
- `split_shares.value` means percent ×100 (of 1 %), a share weight, or paise for exact splits,
  depending on `split_expenses.split_method`; `equal` stores no share rows.
- All money columns are `INTEGER`, all dates are epoch milliseconds, all booleans are `0`/`1`.

Seeding happens in one transaction on first launch: default categories, the 20 achievement
definitions, and a starter Cash account. **Demo data is only inserted if you tap "Explore with demo
data" during onboarding.**

---

## Money rules enforced in code

```
Safe to Spend = Monthly budget − Spent this month − Upcoming fixed bills − Planned savings
Net worth     = Σ asset balances − Σ liability balances
Savings rate  = (income − expense) / income
```

- Transfers move money between accounts and are excluded from income, expense, budgets, category
  totals and reports.
- Credit cards count as **liabilities**: their balance is money owed, and available credit is
  `limit − outstanding`.
- Budget spend ignores transactions of type `transfer`, and honours the budget's category/account
  scope plus any rollover carried in from the previous period.
- Split expenses are tracked separately and never touch account balances or budgets.

---

## Free vs Premium

| Feature | Free | Premium |
| --- | --- | --- |
| Accounts, transactions, categories | Unlimited | Unlimited |
| Budgets | 3 active | Unlimited |
| Goals | 2 active | Unlimited |
| Split groups | 1 | Unlimited |
| Charts | Core set | All 14+ |
| Custom report builder | — | Included |
| Year-over-year & forecasting | Locked preview | Full |
| Achievements | Progress only | Full cabinet |
| Theme packs | MoneyMan, Mono | All five |
| PDF reports | Standard | Branded |

Premium is activated per device from **Premium → Unlock Premium** (no store account, no network
call). Gate checks live in `widgets/premium_gate.dart` (`ensurePremium`) and `Locked` previews in
`widgets/premium_badge.dart`.

---

## Screen map

| Route | File |
| --- | --- |
| Splash / Boot | `screens/splash/splash_screen.dart` |
| Onboarding (4 pages + demo opt-in) | `screens/onboarding/onboarding_screen.dart` |
| First-run setup (name, currency, budgets) | `screens/setup/first_run_setup_screen.dart` |
| Lock gate (PIN + biometric) | `screens/common/lock_gate.dart` |
| Main shell (5 tabs + FAB) | `screens/shell/main_shell.dart` |
| Home dashboard | `screens/home/home_screen.dart`, `home_cards.dart` |
| Add/edit transaction sheet | `screens/transactions/add_transaction_sheet.dart` |
| Transaction detail | `screens/transactions/transaction_detail_screen.dart` |
| Filters / Search | `screens/transactions/filters_screen.dart`, `search_screen.dart` |
| Recurring rules | `screens/transactions/recurring_screen.dart` |
| Accounts / form / detail / transfer | `screens/accounts/*` |
| Categories / form / detail | `screens/categories/*` |
| Budgets / form / detail | `screens/budgets/*` |
| Goals / form / detail | `screens/goals/*` |
| Stats + charts + custom report | `screens/stats/*` |
| Bills / form / calendar | `screens/bills/*` |
| Bill splitting / create / detail | `screens/splits/*` |
| Alerts centre | `screens/notifications/notifications_screen.dart` |
| Achievements | `screens/achievements/achievements_screen.dart` |
| Premium | `screens/premium/premium_screen.dart` |
| Profile | `screens/profile/profile_screen.dart` |
| Settings hub + appearance/general/notifications/security/about | `screens/settings/*` |
| Export / CSV import / backup & restore | `screens/io/*` |

---

## Permissions used

| Permission | Why |
| --- | --- |
| `POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM`, `RECEIVE_BOOT_COMPLETED`, `VIBRATE`, `WAKE_LOCK` | Local bill/budget/goal reminders that survive a reboot |
| `USE_BIOMETRIC`, `USE_FINGERPRINT` | Optional app lock |
| `CAMERA`, `READ_MEDIA_IMAGES` | Optional receipt photo attached to a transaction |
| `READ/WRITE_EXTERNAL_STORAGE` (≤ API 32/29) | Reading a CSV you pick, writing exports |

There is no `INTERNET` permission in the release manifest usage and no network library in
`pubspec.yaml`.

---

## Testing checklist

- Onboarding → skip demo → empty states everywhere → add a transaction → Safe-to-Spend updates.
- Add a transfer between two accounts → income and expense must **not** change.
- Create 4 budgets as a free user → the 4th shows the Premium gate.
- Open a bill → mark paid → an expense appears with the bill's account/category.
- Import a CSV → map columns → duplicates are skipped.
- Export PDF → share sheet opens with the file.
- Toggle dark mode, accent, text size, compact density → every screen follows immediately.
- Enable biometric lock → background/foreground the app → lock gate appears.

---

## Tests

```bash
flutter test
```

CI runs 13 tests before every build:

- **Smoke tests** — rupee formatting, calculator precedence, Hindi localisation, light/dark theme
  extensions, and a widget tree that renders the design-system cards.
- **Database tests** (real SQLite via `sqflite_common_ffi`, in-memory) — schema creation, category
  and achievement seeds, balance effects of transactions, budget window maths, goal contributions,
  bill payments (recurring roll-forward vs one-time closure), split balances and settlement
  suggestions, recurring-rule materialisation, full-text search, amount filters and duplicate
  detection.

The same workflow then builds the release APK and publishes it to Releases.

---

## Licence

MIT. Fonts: Poppins (SIL Open Font License 1.1), bundled under `assets/fonts/`.
All illustrations and the app icon are original artwork generated for this project.
