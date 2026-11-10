# keel

A desktop-first personal finance application for macOS, built with Flutter.

Keel gives you a complete picture of your financial life — accounts, investments, loans, assets, income, budget, and net worth — in a single native macOS app.

---

## Features

- **Dashboard** — net worth hero card with 6-month sparkline, liquid cash, total debt, interest burden, savings rate
- **Accounts** — double-entry ledger with asset/liability/income/expense account types, balance history, transfers
- **Investments** — holdings across stocks, ETFs, unit trusts, money market, fixed deposits, treasury bills, SACCOs, pension; lot tracking, unrealised/realised gains, income recording
- **Loans** — borrowed and lent, amortisation schedules, payment tracking, interest calculations
- **Assets** — physical assets (vehicles, buildings, land, machinery) with depreciation and insurance tracking
- **Income** — income streams with frequency tracking, mark-as-received, YTD totals
- **Budget** — envelope budgeting with period plans, strategy allocation (50/30/20 etc.), rollover support
- **Net Worth** — full breakdown across cash, physical assets, investments, and liabilities
- **Projections** — net worth trajectory with income growth and expense assumptions
- **Reports** — PDF export of P&L, budget, loans, investments, and assets
- **Contacts** — track shared finances with people
- **Projects** — budget and track project spend
- **Settings** — keyboard shortcuts with live recording, appearance, data management

## Design principles

- **Desktop-first macOS** — native menu bar, transparent title bar, keyboard shortcuts, no bottom sheets
- **Offline-first** — all data lives locally in SQLite via Drift
- **Money as integer minor units** — all amounts stored as `int` in cents, no floating point
- **No borders, no tinted backgrounds** — clean, minimal UI
- **Responsive panels** — list panel 26% clamped 240–340px, sidebar 22% clamped 220–300px

## Tech stack

| Layer | Technology |
|---|---|
| UI | Flutter (macOS) |
| State management | flutter_bloc + freezed |
| Database | Drift (SQLite) |
| Dependency injection | get_it |
| Icons | Iconsax |
| PDF generation | printing + pdf |

## Project structure

```
lib/
├── core/
│   ├── database/        # Drift database
│   ├── di/              # Dependency injection
│   ├── router/          # go_router + shell scaffold
│   ├── shortcuts/       # Keyboard shortcut service
│   ├── theme/           # Colors, text styles, theme
│   └── widgets/         # Shared widgets (PageShell, ShimmerBox, responsive)
└── features/
    ├── accounts/
    ├── assets/
    ├── budget/
    ├── contacts/
    ├── dashboard/
    ├── income/
    ├── investments/
    ├── loans/
    ├── net_worth/
    ├── projections/
    ├── projects/
    ├── reports/
    ├── settings/
    ├── strategy/
    └── transactions/
```

Each feature follows clean architecture: `data/` → `domain/` → `presentation/`.

## Getting started

```bash
flutter pub get
flutter run -d macos
```

Requires Flutter 3.x with macOS desktop support enabled.

---

## Roadmap

### Phase 1 — Desktop (current)
- [x] Core financial modules
- [x] macOS native integration
- [x] Keyboard shortcuts
- [x] PDF reports
- [x] Shimmer loading states

### Phase 2 — Sync + Mobile companion
- [ ] Remote backend (Supabase / custom)
- [ ] Offline-first sync with conflict resolution
- [ ] Flutter mobile companion app (iOS + Android)
- [ ] Push notifications (loan due dates, budget alerts)
- [ ] Data import — CSV/OFX/QIF from banks
- [ ] Recurring transactions

The mobile companion will be a focused subset: quick transaction capture, dashboard glance, account balances, budget status, and income marking. The desktop app remains the primary surface for setup, analysis, and reporting.

---

## License

MIT
