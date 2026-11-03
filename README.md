# mentalist — premium offline-first expense manager

`mentalist` is a Flutter (Dart) Android expense manager inspired by Paisa and
top-tier FinTech apps. It combines a **neumorphic / claymorphic** warm-beige
light UI with **3D skeuomorphic wallet cards**, a **perforated receipt** activity
feed, a **floating pill dock** with a glowing neon active state, **dark-mode
analytics** (consistency heatmap, streaks, glowing "Bia Analysis" card) and
**frosted-glass invoice** sheets. Everything runs **100% offline** on a local
SQLite database (sqflite) — no account, no network, no tracking.

## Screens (feature map)

| Step | Screen | What it does |
| ---- | ------ | ------------ |
| 1 | **Home** (`lib/ui/screens/home_screen.dart`) | Total balance + 7-day mini bar chart, horizontally scrollable carousel of 3D wallet cards (bank / credit card / cash) with parallax + tilt, and today's activity rendered as a perforated receipt with colorful tags and split avatars. |
| 2 | **+ button** (`lib/ui/sheets/add_transaction_sheet.dart`) | Spring-animated bottom sheet: amount, expense/income/transfer segmented control, circular category icons, account chips, tags, and a **Bill Splitter** toggle that divides the amount across contacts. |
| 3 | **Stats** (`lib/ui/screens/analytics_screen.dart`) | Deep dark mode: GitHub-style **Consistency heatmap**, **Current / Longest streak** counters with flame icons, fl_chart weekly spending bars, and a glowing **Bia Analysis** card whose insights are computed locally from your data. |
| 4 | **Bills** (`lib/ui/screens/bills_screen.dart` + `lib/ui/sheets/invoice_detail_sheet.dart`) | Active subscriptions and pending bills. Tapping an unpaid bill opens a **frosted-glass (BackdropFilter)** sheet with the itemized invoice and a floating **Approve & Pay** button that marks it paid and logs the expense. |
| 5 | **Budgets** (`lib/ui/screens/budgets_screen.dart`) | Neon savings-goal card + per-category budget cards with animated progress bars; a red **90% alert** state appears when a category nears its limit. |

## Project structure

```
lib/
  main.dart                     # entry point (provider bootstrap)
  app.dart                      # MaterialApp + theme
  core/
    theme/app_colors.dart       # palette (neumorphic beige + dark analytics)
    theme/app_theme.dart        # Inter typeface, light theme engine
    constants/app_categories.dart
    utils/format.dart           # INR (en_IN) money + date formatting
    utils/spring_sheet.dart     # easeOutBack spring bottom sheets
  data/
    models/                     # Transaction, Account, Budget, Subscription/InvoiceItem
    db/database_helper.dart     # sqflite schema + CRUD (offline-first)
  providers/app_provider.dart   # state + analytics (heatmap, streaks, Bia insights)
  ui/
    widgets/                    # NeumorphicCard, ReceiptPaper (CustomPaint zigzag),
                                # Skeuomorphic3DCard (Matrix4 tilt/parallax), FloatingPillNavBar,
                                # HeatmapCalendar, MiniBarChart, CategoryIcon, NeonProgressBar…
    screens/                    # home, analytics (dark), bills, budgets, root_scaffold
    sheets/                     # add_transaction_sheet, invoice_detail_sheet (frosted glass)
assets/icon/                    # premium launcher icon (app_icon.png, app_icon_foreground.png)
android/                        # full Android scaffolding incl. gradle wrapper
```

## Build the release APK

Prerequisites: Flutter SDK (stable) + Android Studio / Android SDK + a JDK 17.

```bash
# 1. Get dependencies
flutter pub get

# 2. Generate the premium launcher icon (mipmaps + adaptive icon)
dart run flutter_launcher_icons

# 3. (Optional) preview on a device/emulator with hot reload
flutter run

# 4. Build the release APK
flutter build apk --release

# 5. Output file
ls -lh build/app/outputs/flutter-apk/app-release.apk

# 6. Install on a connected device
adb install build/app/outputs/flutter-apk/app-release.apk
```

> If `android/local.properties` or the Gradle wrapper is missing on a fresh
> clone, run `flutter create --project-name mentalist --platforms=android .`
> once — it restores platform scaffolding without touching `lib/`.

For a signed Play-Store build, create a keystore and add a `signingConfig` in
`android/app/build.gradle` (currently it signs with the debug key so
`flutter run --release` works out of the box).

## Notes

- **Offline-first:** all data lives in `mentalist.db` (sqflite) in the app's
  private documents directory. Demo data is seeded deterministically on first
  launch so charts/heatmaps/streaks are populated immediately.
- **Currency:** INR (₹) with Indian digit grouping via `intl` (`en_IN`).
- **Animations:** `BouncingScrollPhysics` (iOS-style) on all scroll views,
  `Curves.easeOutBack` spring bottom sheets, `Hero` transitions (FAB, balance,
  invoice icons), and `Matrix4` perspective tilts + parallax on the wallet
  carousel.
