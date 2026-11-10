# Keel

**A desktop-first personal finance application for macOS, built with Flutter.**

Keel gives you a complete picture of your financial life. Accounts, investments, loans, assets, income, budgets, and net worth, all in a single native macOS application. Data lives locally on your machine. No subscriptions, no cloud dependency, no tracking.

<br>

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Design Principles](#design-principles)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [Roadmap](#roadmap)
- [Contributing](#contributing)
- [License](#license)

<br>

## Overview

Most personal finance tools are either too simple (basic budgeting apps) or too complex (accounting software built for businesses). Keel sits in between. It is built for individuals who want serious financial visibility without the overhead of enterprise tooling.

The application is designed around three ideas:

1. **Your data belongs to you.** Everything is stored locally in SQLite. Nothing leaves your machine unless you choose to sync it.
2. **Desktop is the right surface for financial analysis.** Deep data entry, multi-panel layouts, keyboard shortcuts, and PDF reports are all first-class citizens.
3. **Correctness over convenience.** Money is stored as integer minor units (cents) throughout the entire stack. No floating point arithmetic, no rounding errors.

<br>

## Features

### Dashboard
Net worth hero card with a 6-month sparkline chart. At-a-glance metrics for liquid cash, total debt, interest burden, lent capital, and savings rate.

### Accounts
Double-entry ledger supporting asset, liability, income, and expense account types. Balance history, account transfers, and reconciliation.

### Investments
Holdings across stocks, ETFs, unit trusts, money market funds, fixed deposits, treasury bills, SACCOs, and pension schemes. Lot tracking with unrealised and realised gain calculations. Dividend and income recording.

### Loans
Borrowed and lent loan tracking. Amortisation schedule generation, payment event recording, and interest calculations via a dedicated loan engine.

### Assets
Physical asset tracking for vehicles, buildings, land, and machinery. Depreciation schedules, insurance expiry tracking, and project linkage.

### Income
Income stream management with frequency tracking (monthly, quarterly, annual). Mark-as-received workflow with YTD totals and payment history.

### Budget
Envelope budgeting with monthly period plans. Strategy allocation support (50/30/20 and custom ratios). Rollover support, template saving, and actual vs planned comparison.

### Net Worth
Full breakdown across cash and bank accounts, physical assets, investments, and liabilities. Asset allocation bar with percentage splits.

### Projections
Net worth trajectory modelling with configurable income growth rate, expense growth rate, and savings target. Loan payoff schedules factored in automatically.

### Reports
PDF export for profit and loss statements, budget summaries, loan schedules, investment portfolios, and asset registers. Built with Unicode font support for international characters.

### Contacts
Track shared finances with individuals. Record payments made and received, and link journal entries to contacts.

### Projects
Budget and track spend for discrete projects. Link physical assets to projects for cost attribution.

### Settings
Live keyboard shortcut recording with per-action customisation. Appearance settings and data management utilities.

<br>

## Design Principles

**Desktop-first macOS**
Native menu bar integration via `PlatformMenuBar`. Transparent title bar with `.fullSizeContentView`. Keyboard shortcuts throughout. No bottom sheets; dialogs are used instead. `HitTestBehavior.opaque` on all gesture detectors.

**Offline-first**
All data is stored locally in SQLite via Drift. The application is fully functional without a network connection. Sync is a Phase 2 concern and will be additive, not a replacement.

**Money as integer minor units**
All monetary values are stored and computed as `int` in the smallest currency unit (cents). There is no floating point arithmetic anywhere in the financial logic.

**Clean, minimal UI**
No card borders. No tinted selection backgrounds. No blur effects. Surfaces use flat colour only. The visual hierarchy is established through typography and spacing.

**Responsive panels**
List panel width is 26% of the window, clamped between 240px and 340px. Sidebar width is 22%, clamped between 220px and 300px. All panels adapt to window resize without hardcoded pixel values.

<br>

## Tech Stack

| Layer | Technology |
|---|---|
| UI framework | Flutter (macOS desktop) |
| State management | flutter_bloc + freezed |
| Local database | Drift (SQLite) |
| Dependency injection | get_it |
| Navigation | go_router |
| Icons | Iconsax |
| PDF generation | pdf + printing |
| Code generation | build_runner + freezed + drift |

<br>

## Project Structure

The repository follows a feature-first clean architecture. Each feature is self-contained with its own data, domain, and presentation layers.

```
lib/
├── core/
│   ├── database/           # Drift database definition and migrations
│   ├── di/                 # Dependency injection setup via get_it
│   ├── router/             # go_router configuration and shell scaffold
│   ├── shortcuts/          # Keyboard shortcut service and definitions
│   ├── theme/              # Colour palette, text styles, and theme data
│   └── widgets/            # Shared widgets: PageShell, ShimmerBox, responsive helpers
└── features/
    ├── accounts/           # Double-entry accounts and balance tracking
    ├── assets/             # Physical asset management
    ├── budget/             # Envelope budgeting and strategy allocation
    ├── contacts/           # Shared finance contact tracking
    ├── dashboard/          # Net worth overview and financial health metrics
    ├── income/             # Income stream management
    ├── investments/        # Investment holdings and lot tracking
    ├── loans/              # Loan management and amortisation engine
    ├── net_worth/          # Net worth breakdown and allocation
    ├── projections/        # Net worth trajectory modelling
    ├── projects/           # Project budgeting and spend tracking
    ├── reports/            # PDF report generation
    ├── settings/           # Application settings and shortcut configuration
    ├── strategy/           # Budget allocation strategy editor
    └── transactions/       # Journal entry viewer and quick capture
```

Each feature directory contains:

```
feature_name/
├── data/
│   ├── datasources/        # Local SQLite datasource implementations
│   ├── models/             # Data transfer objects and mappers
│   └── repositories/       # Repository implementations
├── domain/
│   ├── entities/           # Core business objects
│   ├── repositories/       # Repository interfaces
│   └── usecases/           # Single-responsibility use cases
└── presentation/
    ├── bloc/               # Cubit and state definitions (freezed)
    ├── pages/              # Top-level page widgets
    └── widgets/            # Feature-scoped reusable widgets
```

<br>

## Getting Started

### Prerequisites

- Flutter 3.x with macOS desktop support enabled
- Xcode 14 or later
- macOS 12 (Monterey) or later

Verify your Flutter setup:

```bash
flutter doctor
```

Ensure macOS is listed as an enabled platform. If not, run:

```bash
flutter config --enable-macos-desktop
```

### Installation

Clone the repository:

```bash
git clone https://github.com/levinkm/keel.git
cd keel
```

Install dependencies:

```bash
flutter pub get
```

Run the application:

```bash
flutter run -d macos
```

### Building for distribution

```bash
flutter build macos --release
```

The built application will be located at `build/macos/Build/Products/Release/keel.app`.

<br>

## Roadmap

### Phase 1 - Desktop (current)

- [x] Core financial modules (accounts, investments, loans, assets, income, budget)
- [x] macOS native integration (menu bar, title bar, window sizing)
- [x] Keyboard shortcut system with live recording
- [x] PDF report generation
- [x] Shimmer loading states across all pages
- [x] Responsive panel layout system

### Phase 2 - Sync and Mobile Companion

- [ ] Remote backend with Supabase
- [ ] Offline-first sync with last-write-wins conflict resolution
- [ ] Flutter mobile companion app for iOS and Android
- [ ] Push notifications for loan due dates and budget alerts
- [ ] Data import from CSV, OFX, and QIF bank export formats
- [ ] Recurring transaction automation

The mobile companion will be a focused subset of the desktop application. It will cover quick transaction capture, dashboard overview, account balances, budget status, and income marking. The desktop application remains the primary surface for setup, deep analysis, and reporting.

<br>

## Contributing

Contributions are welcome. Please open an issue before submitting a pull request so the change can be discussed first.

When contributing code:

- Follow the existing feature architecture (data / domain / presentation)
- Store all monetary values as `int` minor units
- Do not introduce floating point arithmetic into financial calculations
- Run `dart analyze` before submitting and ensure zero errors
- Match the existing UI patterns: no borders on cards, no tinted selection backgrounds

<br>

## License

Keel is licensed under the [MIT License](LICENSE).
