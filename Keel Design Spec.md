# Keel — Design Spec

Oct 28, 2026 · @Sav4ner

## Vision

Keel is a personal ledger first and a budgeting tool second: every shilling is a double-entry journal line, budgets are plans laid over that ledger, and a projection engine reads both to show where you will stand in 1, 5 or 10 years. It replaces the hard-coded 50/30/20 sheet with a strategy engine, tracks loans with real amortization, and adds savings, investment and "breathing room" projections.

The name: a keel is the part of a ship that keeps it upright and on course in rough water, which is what the app does for your finances through loans, price swings and lean months.

Design principles:

- **Strategies are data, not code.** 50/30/20 becomes one built-in among several, and you can build your own.
- **The ledger is the single source of truth.** The dashboard, loans, savings and lending screens are views over it.
- **Money is integer minor units** (KSh 1 = 100 cents). Rounding rules are explicit and tested.
- **Projections state their assumptions** and show scenarios and ranges, never one "will be" number.
- **Local-first.** The full app runs offline on a SQLite file; the API added later only syncs.

## Accounting vocabulary

The UI, code and reports use standard accounting terms, so "Needs" and "Savings" become labels on top of precise concepts rather than the concepts themselves.

| Term | Meaning | In this app |
| --- | --- | --- |
| Asset | Something you own that has value | Co-op, Loop, StanChart, Etica balances; money lent out (receivable) |
| Liability | Something you owe | Loan balances, unpaid bills |
| Equity (net worth) | Assets minus liabilities | Headline net worth figure |
| Income | Inflow that increases equity | Salary (gross), interest, dividends |
| Expense | Outflow that decreases equity | Rent, fuel, interest paid, gifts |
| Chart of accounts | The full list of ledger accounts, grouped by type | Seeded from your categories and bank accounts |
| Journal entry | One transaction: two or more lines, debits equal credits | Every payday, payment and transfer |
| Ledger | All journal lines grouped by account | Account detail and statement screens |
| Trial balance | Sum of debits and credits across the ledger, must be equal | Integrity check shown in settings |
| Period | An accounting window, here one calendar month | Budget month; can be closed to lock history |
| Budget vs actual | Plan compared with posted results | Variance report per category |
| Variance | Actual minus budget; favourable or unfavourable by account type | Colour and sign follow expense or income direction |
| Accrual vs cash basis | Record when earned or owed, versus when money moves | Cash for daily spending; accrual for loan interest |
| Amortization | Splitting each loan instalment into principal and interest | Loan schedule |
| Contingency reserve | Cash held for shocks | Emergency fund, targeted in months of essential cost |
| Sinking fund | Regular set-aside for a known future cost | Car service, insurance, annual fees |
| Liquidity | How quickly an asset becomes spendable cash | Tags per account: instant, days, locked |
| Reconciliation | Matching ledger balance to the bank statement | Per-account reconcile screen |

Gross-to-net pay is modelled as deductions on a payslip: statutory items such as PAYE, NSSF, SHIF and the housing levy, plus the loan deduction. Rates and thresholds are user-editable settings, not hard-coded, because they change.

## Ledger model

Every transaction is a journal entry whose debits equal its credits, which makes net worth, loan balances and lending balances fall out of the data instead of being typed in separately.

The five account types and their normal balances:

| Type | Increases with | Examples |
| --- | --- | --- |
| Asset | Debit | Co-op Bank, Loop Wallet, StanChart, Etica, Loans Receivable |
| Liability | Credit | Loan Payable |
| Equity | Credit | Opening Balance, retained surplus |
| Income | Credit | Salary, Interest Income |
| Expense | Debit | House Rent, Fuel, Interest Expense, Gifting |

The accounting equation the app enforces: assets = liabilities + equity, where equity includes income minus expenses to date.

How your real events post:

| Event | Debit | Credit |
| --- | --- | --- |
| Salary, gross 100,000, with 25,000 loan deduction | Bank 75,000; Loan Payable (principal part) and Interest Expense (interest part) 25,000 in total | Salary Income 100,000 |
| Pay rent | House Rent | Bank |
| Move money to Etica | Etica Investments | Co-op Bank |
| Lend to your sister, expecting repayment | Loans Receivable (sister) | Wallet |
| She repays | Wallet | Loans Receivable (sister) |
| Gift or support you will not recover | Gifting or Family Support expense | Wallet |
| Debt written off | Bad Debt Expense | Loans Receivable |

Rules:

- **Immutable postings.** A posted entry is never edited. A correction is a reversing entry plus a new one, which keeps an audit trail and makes later sync conflict-free.
- **Budgets live outside the ledger.** A budget plan references accounts and categories; it never creates journal lines.
- **Closed periods.** Closing a month locks its entries and stores its opening and closing balances.
- **Enforcement.** SQL cannot check balance across rows, so the repository checks it inside one database transaction, and a trial-balance check runs on app start.
- **Currency.** KES only at first, but every amount stores a currency code so a second currency does not need a migration.

The 50/30/20 buckets are not accounts. They are a classification layer: each expense or savings account carries a `bucket` tag that strategies read.

## Strategy engine

A strategy is a declarative document that turns a month's income into an allocation plan and says how to judge the result. Built-ins and user strategies use the same format, so the engine has no special case for 50/30/20.

Your spreadsheet actually mixes two ideas, and the engine separates them:

- **Allocation rules** decide how money is split (rent fixed, other categories as % of the flexible base).
- **Benchmarks** judge the outcome (is Needs near 50% of income?). They only report; they never move money. Benchmarks measure share by each account's classification tag (needs, wants, savings), not by bucket, so rent in a "fixed" bucket still counts as a need.

A strategy has a base, an ordered list of buckets, and optional benchmarks:

```json
{
  "schemaVersion": 1,
  "name": "Commitments first, then weights",
  "base": "net_after_loan",
  "buckets": [
    { "key": "fixed",   "label": "Fixed commitments", "order": 1,
      "rule": { "type": "fixed_amounts" } },
    { "key": "needs",   "label": "Needs",   "order": 2,
      "rule": { "type": "percent_of_remaining", "value": 0.55 },
      "benchmark": { "kind": "max", "target": 0.50, "tolerancePp": 3 } },
    { "key": "wants",   "label": "Wants",   "order": 3,
      "rule": { "type": "percent_of_remaining", "value": 0.25 },
      "benchmark": { "kind": "max", "target": 0.30, "tolerancePp": 3 } },
    { "key": "savings", "label": "Savings", "order": 4,
      "rule": { "type": "remainder" },
      "benchmark": { "kind": "min", "target": 0.20, "tolerancePp": 3 } }
  ],
  "categories": [
    { "account": "House Rent", "bucket": "fixed", "amountMinor": 1100000 },
    { "account": "Fuel",       "bucket": "needs", "weight": 19.1 },
    { "account": "Upkeep",     "bucket": "needs", "weight": 15.9 }
  ]
}
```

**Bases** (what "100%" means): gross income; net pay after statutory deductions; net after the loan deduction (what your sheet uses); or the flexible base (net minus fixed commitments). With several income streams, gross and net are summed across them, using either expected or reliable income. The choice matters, as the worked example in the next section shows.

**Rule types**, evaluated in `order`, each drawing from what is left:

| Rule | Amount | Use |
| --- | --- | --- |
| `percent_of_base` | value × base | Classic percentage splits |
| `percent_of_remaining` | value × (base minus everything allocated earlier) | Waterfalls such as fixed first, then split the rest |
| `fixed_amounts` | Sum of the per-category amounts | Rent, subscriptions, loan instalments |
| `target_months` | months × average essential monthly cost, spread to a deadline | Emergency fund top-up |
| `goal_contribution` | (target − balance) ÷ months left | Sinking funds and savings goals |
| `remainder` | Base minus all other buckets | Zero-based budgeting and pay-yourself-first |

Each rule may carry `min` and `max` clamps (for example, savings at least KSh 5,000).

**Within a bucket**, categories share the bucket's amount by `weight` (your 19.1%, 15.9% figures become weights that need not sum to 100) or take fixed amounts. A category can set `rollover: true`, so unspent money carries into the next month, which gives envelope behaviour.

**Rounding.** All math runs in integer cents. Each amount is floored, then leftover cents go to the largest fractional remainders, ties broken by `order`. Allocations always sum exactly to the base, which removes the KSh 6 gap in your sheet.

**Benchmark status** for a bucket's actual share of the base: on track, watch (outside target but within tolerance) or off track. `max` flags overspend, `min` flags underfunding, `range` flags both.

Building your own strategy in the editor:

1. Start from a built-in (copy) or blank.
2. Choose the base.
3. Add buckets and give each a rule, in order.
4. Map accounts or categories to buckets and set weights or amounts.
5. Add optional benchmarks.
6. Watch the live preview against this month's real income and fix validation errors.
7. Save, which creates a new version.

Validation blocks saving when: percentage rules exceed 100% with no remainder bucket; there is more than one `remainder`; a category belongs to no bucket or two; a `min` exceeds its `max`; or fixed amounts exceed the base in the preview.

Built-in strategies are read-only and copied on edit. Each monthly budget stores the strategy ID, its version and a snapshot of its inputs, so a past month always recomputes to the same numbers. Strategies export and import as `.json`. The format has no scripting or expressions, so a file from someone else cannot run code.

## Built-in strategies

Seven templates and a blank Custom strategy ship with the app, each expressed in the strategy format above. All are copyable and editable.

| Strategy | Exact rule | Suits |
| --- | --- | --- |
| 50/30/20 | Base: take-home pay. Needs 50% (including minimum loan payments), Wants 30%, Savings 20% (including debt payments above the minimum). Popularised by Elizabeth Warren and Amelia Warren Tyagi in *All Your Worth* (2005). | A first budget, or a sanity check |
| 70/20/10 | Living costs 70%, Savings 20%, Debt repayment or giving 10%. A common variant with no single canonical source, so treat the numbers as defaults. | Higher living costs, lower savings capacity |
| Pay yourself first | Savings = fixed % or amount, taken first (default 20%). The `remainder` is free to spend. | People who overspend when the plan is detailed |
| Zero-based | Every shilling gets a category; the plan is complete only when unallocated = 0. | Tight, detail-oriented control |
| Envelope | Each category has a monthly amount and a `rollover` balance. Overspending must be covered by moving money from another envelope. | Variable spending such as fuel and dates |
| Commitments first | Fixed amounts first (rent, loan), then weights over the flexible base, with 50/30/20 as a benchmark only. This is your current spreadsheet. | Your current workflow |
| Kakeibo | Set the savings target first, then spend across four groups: Survival, Optional, Culture, Extra. A month-end reflection asks what came in, what you wanted to save, what you spent and what to improve. Originates with Hani Motoko (1904). | Mindful spending habits |
| Custom | Built in the strategy editor. | Anything else |

Debt avalanche and snowball are not budget strategies. They decide the order of extra loan payments, so they live in the loan section.

### Why the base matters

Using your Budget sheet's income of 100,000 gross and a 25,000 loan deduction, the same 50/30/20 gives different amounts depending on the base:

| Variant | Base | Needs | Wants | Savings |
| --- | --- | --- | --- | --- |
| Original rule: loan is a minimum payment, so a Need | 100,000 | 50,000 (25,000 is the loan) | 30,000 | 20,000 |
| Your sheet: base is net after the loan | 75,000 | 37,500 | 22,500 | 15,000 |

On the original rule only 25,000 of Needs is left for rent, fuel, upkeep and shopping. On your sheet's variant there is 37,500. The app asks you to choose the base when you pick a strategy, and shows this comparison.

### Borrowing from existing tools

The aim is to copy ideas and file formats, not code. Check each project's licence before reusing any source; Firefly III and GnuCash are copyleft, so their code cannot simply be folded into a closed app.

| Tool | Idea worth borrowing |
| --- | --- |
| YNAB | Zero-based planning and goal types (target by date); the "age of money" metric as a liquidity-health number |
| Actual Budget | Local-first design: SQLite on the device, a sync server later, and envelope rollover |
| Firefly III | Rules engine for auto-categorizing imported transactions, piggy banks for goals, recurring transactions |
| GnuCash | Standard chart of accounts, scheduled transactions, loan amortization assistant |
| Beancount / ledger-cli | Plain-text double-entry as an export format, so your data is never locked in |

## Loan tracking

A loan is a contract (terms) that generates an expected schedule, while the ledger holds the actual payments; the difference between the two is arrears, prepayment or a rate change. The same entity covers money you owe (your 25,000 deduction) and money you lend (your sister, friends), with a `direction` field.

Terms stored per loan: lender or borrower, principal, interest method, rate, term, disbursement date, first due date, frequency, instalment (computed or overridden), fees, and whether it is deducted at source from salary.

### Interest methods

| Method | How interest is charged | Typical source |
| --- | --- | --- |
| Reducing balance (default) | Rate applies to the outstanding balance each period | Banks, SACCOs |
| Flat rate | Rate applies to the original principal for the whole term | Some digital and asset-finance lenders |
| Fixed fee | A one-off percentage fee for a short term | Mobile and short-term loans |

Reducing balance, with monthly rate i = annual rate ÷ 12, term n months and principal P:

```latex
A = \frac{P\,i}{1-(1+i)^{-n}}, \qquad I_k = \operatorname{round}(B_{k-1}\,i), \qquad \text{Principal}_k = A - I_k, \qquad B_k = B_{k-1} - \text{Principal}_k
```

The last instalment is adjusted to clear the balance, which absorbs cent-rounding drift. If the rate is 0, A = P ÷ n.

Worked example (illustrative, not your loan): KSh 300,000 at 14% a year over 24 months gives an instalment of 14,403.86. Month 1 is interest 3,500.00 and principal 10,903.86, leaving a balance of 289,096.14. Total interest over the term is about 45,692.76.

Flat-rate loans are shown with their **effective rate**, found by solving for the periodic rate j that equates the instalments to the principal, then converting to an annual rate. A 10% flat charge on 100,000 over 12 months works out to about 19.5% a year effective, which is how the app lets you compare it with a reducing-balance offer:

```latex
P = A\,\frac{1-(1+j)^{-n}}{j}, \qquad \text{EAR} = (1+j)^{12}-1
```

### Events and what-ifs

The schedule is regenerated from an event list, so it is never hand-edited: disbursement, instalment paid, prepayment, rate change, fee, penalty and top-up or refinance.

- **Prepayment** offers two choices: keep the instalment and shorten the term, or keep the term and lower the instalment. In the example above, prepaying 50,000 after month 6 while keeping the instalment leaves 13.8 payments instead of 18 and saves roughly KSh 10,500 in interest.
- **Settlement quote**: outstanding principal plus interest accrued to the chosen date plus any early-settlement fee.
- **Arrears**: any scheduled instalment with no matching payment past its due date, with penalty interest computed by the loan's own rule.

### Accounting entries

| Event | Debit | Credit |
| --- | --- | --- |
| Loan received | Bank (net of fees); Loan Fees Expense | Loan Payable |
| Instalment paid | Loan Payable (principal); Interest Expense | Bank, or Salary Income if deducted at source (see Ledger model) |
| Prepayment | Loan Payable | Bank |
| Month-end between due dates | Interest Expense | Interest Payable (accrual) |
| Money lent out | Loans Receivable | Wallet |
| Written off | Bad Debt Expense | Loans Receivable |

On the balance sheet the part of principal due within 12 months is a current liability, and the rest is non-current.

### Metrics and payoff order

- **Debt-to-income (DTI)** = monthly debt payments ÷ gross monthly income. On your Budget sheet that is 25,000 ÷ 100,000 = 25%. The warning threshold is a setting; 36% is a common lender rule of thumb.
- **Deduction ceiling.** Kenyan employment law limits total salary deductions to two thirds of wages (Employment Act, section 19). Confirm the current wording before relying on a warning built from it.
- **Multiple loans.** The app simulates the *avalanche* order (highest rate first, least total interest) and the *snowball* order (smallest balance first, quickest closed loans), and shows total interest and payoff date for each, so you choose with the numbers in front of you.

Lending out keeps your existing rule: safe to lend = max(0, min(unallocated, family cap minus already committed)). Each loan or gift is logged with expected-back date, partial repayments, status (outstanding, partial, repaid, written off) and notes.

## Net worth and asset register

Net worth is assets minus liabilities at a date, computed from the ledger, so cars, tractors and land count the moment they are recorded as assets. The register holds the details a ledger line cannot: what the asset is, what it cost, how it is valued, what is owed against it.

```latex
\text{Net worth} = \sum \text{asset balances} - \sum \text{liability balances}
\qquad
\text{Equity in an asset} = \text{value} - \text{linked loan balance}
```

The app shows three figures:

- **Total net worth:** everything.
- **Liquid net worth:** liquid assets minus liabilities due within 12 months.
- **Equity by asset:** value minus its linked loan, so a financed car shows what you actually own of it.

### Asset classes

| Class | Examples | Default valuation | Depreciates? |
| --- | --- | --- | --- |
| Cash and bank | Co-op, Loop, StanChart | Ledger balance | No |
| Investments | MMF, shares, T-bills, SACCO | Units × price, or balance | No |
| Vehicles | Car, motorbike | Cost model: cost less depreciation; market value can be recorded | Yes, reducing balance by default |
| Machinery | Tractor, equipment | Cost model, as vehicles | Yes; can be tagged income-producing |
| Land | Plots, farmland | Fair value model: revalued from estimates or valuations | No: land is not depreciated |
| Buildings | House, rental units | Cost model for the building, fair value for the land under it | Building only |
| Receivables | Money lent out | Outstanding balance, less any doubtful amount | No |
| Other | Livestock, jewellery, crops in the ground | Manual valuation | Optional |

Per asset the register stores: name, class, acquisition date, **cost including capitalised fees** (transfer, legal, stamp duty, delivery), ownership share (for jointly held land or inherited plots), current value with its date and source (own estimate, dealer quote, formal valuation), depreciation method, rate and salvage value, linked loan, insurance expiry, status (in use, sold, written off), location, notes and attached documents such as a logbook or title deed.

### Depreciation and valuation

Two methods, chosen per asset, with all rates and lives as settings and not fixed assumptions:

```latex
\text{Straight line: } \text{Dep}_{month} = \frac{\text{Cost} - \text{Salvage}}{\text{Life in months}}

\text{Reducing balance (annual rate } d\text{): } \text{Dep}_k = \text{NBV}_{k-1}\bigl(1-(1-d)^{1/12}\bigr)
```

Net book value (NBV) = cost minus accumulated depreciation. Two valuation policies exist, so the ledger and net worth always agree:

- **Cost model** (vehicles, machinery by default): the ledger carries NBV. Recording a dealer or market value posts an adjustment to match it, and depreciation continues from the new figure.
- **Fair value model** (land by default): each new valuation posts a revaluation entry, with the gain or loss in an unrealised-gains equity account.

| Event | Debit | Credit |
| --- | --- | --- |
| Buy a car for 1,200,000 with 20,000 transfer fees, paid from bank | Vehicles 1,220,000 | Bank 1,220,000 |
| Buy it with an asset-finance loan | Vehicles (cost + fees) | Loan Payable (amount financed); Bank (deposit and fees) |
| Monthly depreciation | Depreciation Expense | Accumulated Depreciation (reduces the asset) |
| Land revalued upward | Land | Unrealised Valuation Gains |
| Sell the tractor | Bank (proceeds); Accumulated Depreciation | Machinery (cost); Gain on Disposal, or a debit to Loss on Disposal |

The amounts in the first row are illustrative.

### Net worth over time and what drove it

Net worth is snapshotted at every period close and whenever an asset is revalued. A bridge report explains each month's change:

```latex
\Delta\text{Net worth} = (\text{Income} - \text{Expenses}) + \text{Unrealised gains} + \text{Revaluations}
```

Income minus expenses already includes depreciation, fees and interest. So you can see whether your wealth grew because you saved, because the land was revalued, or because markets rose, and how much of each.

### Other liabilities

Besides loans, the register tracks unpaid bills and credit balances, taxes due, and deposits you hold for others. **Contingent liabilities**, such as a loan you guaranteed for someone, are kept in a note register: they are not in net worth, but they appear on the balance sheet report as a disclosure and in the stress test.

## Multiple income streams and investments

Income and investments are lists, not single fields. Any number of each can exist, and budgets, projections and net worth sum across them.

### Income streams

Each stream is a record, so your salary, rent from a plot, tractor hire and a side job are tracked separately.

| Field | Purpose |
| --- | --- |
| Name and type | Salary, business, farming, rent, dividends or interest, side work, one-off |
| Deposit account | Where the money lands, which drives the payday transfer plan |
| Frequency and pattern | Monthly, weekly, irregular, or a month-by-month schedule for seasonal income such as harvests |
| Amount mode | Fixed, or variable with an expected amount and a reliable baseline |
| Payslip template | Gross, then deductions (statutory items, loan deduction, SACCO contributions), then net |
| Linked asset | Ties tractor hire or rent to the asset that earns it |
| Start and end dates | A contract that ends, or income that starts next year, flows into projections |

**Reliable vs variable income.** A strategy's base can be the sum of expected income or the sum of *reliable* income. The reliable amount of a variable stream defaults to the lowest of its last six months, and you can override it. Money above the baseline is a windfall and follows your windfall rule (for example 50% to savings, 30% to debt, 20% free), so a good month does not quietly raise your spending.

**Expected vs received.** Each stream posts an expected entry each period. When money arrives, the app matches it and shows the variance. Income earned but not yet paid, such as an invoice, sits in Income Receivable until it lands.

**Return on assets.** For a linked asset the app reports net yield, which is the stream's income minus the asset's running costs (fuel, repairs, insurance, depreciation) divided by the asset's value. A tractor that earns 40,000 a month and costs 30,000 to run shows its true margin.

### Investments

A holding is a record too, so any number can sit across Etica, a SACCO, T-bills and shares. Each holding keeps its lots (date, units, price, fees) so cost basis, realized gains and XIRR are exact. Portfolio views group by class, institution and liquidity, show allocation against a target mix, and flag when a class drifts beyond a tolerance. Contributions can be scheduled and are posted to the ledger as transfers, with fees (see the next section).

## Transaction fees

Every fee is its own journal line inside the same entry as the transaction, so the real cost of moving money appears in reports and balances reconcile to the bank.

Example with an illustrative 30 fee for moving 10,000 from Co-op to Loop: debit Loop 10,000, debit Bank and Mobile Charges 30, credit Co-op 10,030.

How each kind of fee is treated:

| Fee | Treatment |
| --- | --- |
| Transfer, withdrawal, mobile-money and bank charges | Expense, in the same entry |
| Excise duty or levy charged on the fee | A separate line or part of the fee, as the tariff says |
| Brokerage or platform fee when buying an investment | Added to the holding's cost basis |
| Fee when selling an investment | Deducted from proceeds, so it reduces the realized gain |
| Transfer fees, stamp duty and legal costs on an asset | Capitalised into the asset's cost |
| Loan processing fee or insurance | Expense when paid, or spread over the loan term as a setting |
| Monthly account or ledger fee | Expense, as a recurring entry |

### Tariff engine

Tariffs are user-editable tables, because providers change them. The app does not claim any tariff as fact: it ships empty tables with example templates that you confirm against your provider's current schedule.

A tariff row has: provider, channel (mobile money, bank transfer, ATM, brokerage), operation, effective-from and effective-to dates, tiers by amount band, and taxes that apply to the fee. Each tier has a flat part, a percentage part, and optional minimum and maximum:

```latex
\text{fee} = \min\bigl(\max(\text{flat} + p\cdot\text{amount},\ \text{min}),\ \text{max}\bigr)
\qquad
\text{total charged} = \text{fee}\,(1+\text{tax rate})
```

Because effective dates are stored, an old transaction keeps the tariff that applied at the time.

### Entering and reconciling fees

- **Suggested fee.** When you enter a transfer, the fee is filled from the source account's tariff. You can overwrite it.
- **Enter the total instead.** Type the amount the statement shows leaving the account, and the app derives the fee.
- **Receive exactly X.** Choose the amount that must arrive, and the app finds the sending amount from the tariff.
- **Statement import.** When a statement shows a transfer and a separate charge line, a rule merges them into one entry.

### Fees in the payday plan and projections

The payday checklist lists every transfer with its fee and shows the month's total fee cost. The strategy decides who bears it: a *Bank and Mobile Charges* category in Needs (default), or deducted from the destination. Where a tariff is tiered, the app can suggest fewer, larger transfers when that is cheaper.

Projections include fees as a recurring cost, and investment returns are shown gross and net of fees. Reports include fees by provider, channel and month, and fee drag, which is fees paid as a share of the amount moved.

## Savings, investments and breathing room

"Breathing room" is defined as three measures, because each answers a different question. The dashboard headline is a setting; the default is runway.

| Measure | Formula | Answers |
| --- | --- | --- |
| Monthly free cash flow | Net income − (Needs + loan instalments + committed savings) | How much slack do I have this month? |
| Liquidity runway (months) | Liquid assets ÷ average monthly essential outflow | How long could I live with no income? |
| Projected runway at date T | Projected liquid assets at T ÷ projected essential monthly cost at T | Will my safety margin grow or shrink? |

Essential outflow means Needs plus all loan instalments. Liquid assets are accounts tagged *instant* or *days* in the chart of accounts.

### Savings goals

- **Emergency fund:** target = k × monthly essential outflow. Three to six months is the usual rule of thumb; k is a setting.
- **Sinking fund:** a target amount by a date, for known costs like car service or insurance. Required monthly set-aside = remaining amount ÷ months left, or the annuity payment below if the fund earns interest.
- **Open-ended savings:** no target, tracked by balance and growth.

The time-value formulas, with monthly rate i = (1 + effective annual rate)^(1/12) − 1, balance B0, monthly contribution PMT, n months and goal G (contributions at month end; multiply the annuity term by (1+i) for start-of-month):

```latex
FV = B_0(1+i)^n + PMT\,\frac{(1+i)^n-1}{i}

PMT = \frac{\bigl(G - B_0(1+i)^n\bigr)\,i}{(1+i)^n-1}

n = \frac{\ln\!\bigl((G\,i + PMT)/(B_0\,i + PMT)\bigr)}{\ln(1+i)}

\text{real return} = \frac{1+\text{nominal}}{1+\text{inflation}} - 1
```

Worked example with an illustrative 12% effective annual return: your tracker's 7,000 savings plus 10,000 emergency-fund deposit is 17,000 a month. After 12 months that is about KSh 214,990 (204,000 contributed). After 60 months it is about KSh 1,365,802 (1,020,000 contributed). Reaching 500,000 from zero takes about 26 months. The 12% is an assumption you set, not a promise.

### Investments

| Holding type | Valuation | Liquidity | Notes |
| --- | --- | --- | --- |
| Bank savings | Balance; interest posted as income | Instant |  |
| Money market fund | Balance or units × price | Days | Quote yield net of fees; withholding tax rate is a setting |
| Fixed deposit or treasury bill | Principal plus accrued interest to maturity | Locked until maturity | Early-exit penalty field |
| SACCO deposits and shares | Balance plus declared dividend or interest | Locked while a member | Dividend posted once a year |
| Unit trusts, stocks, ETFs | Units × latest price | Days | Cost basis per lot; prices typed in at first, a feed later through the API |
| Pension | Statement balance | Locked | Updated from statements |

Per holding the app shows value, cost basis, unrealized gain, realized gain on sales and a **money-weighted return (XIRR)**, which stays correct when deposits are irregular.

### Projection engine

A pure function takes the opening balance sheet, the monthly budget plan, every loan schedule, income assumptions (raises, bonuses by month), inflation per category and a return per holding. It returns a monthly series for 1 to 30 years: income, expenses, free cash flow, each asset, liabilities, net worth and runway.

- **Scenarios** are named override sets: Base, Conservative, Optimistic, or your own (for example, fuel inflation +15%, returns −3 points, income −20%).
- **Stress tests**: income stops for m months (the result is the month cash runs out), income falls x%, or a one-off cost arrives on a date.
- **Monte Carlo** (later phase): returns drawn each month from a lognormal distribution with the mean and volatility set per holding, 5,000 paths and a fixed seed so results repeat. Output is the P10, P50 and P90 net worth by date and the probability of reaching each goal by its deadline.
- **Present value** of future obligations at a user-set discount rate. A built-in check: the present value of a loan's remaining instalments at the loan's own rate equals its outstanding balance.

Every projection screen shows its assumptions beside the result and is labelled a projection, not a forecast.

## Graphs and reports

Each graph answers one question, and the chart type follows from it.

| Graph | Question it answers | Chart type | Source |
| --- | --- | --- | --- |
| Budget vs actual | Which categories are over or under plan? | Horizontal bars with a plan marker, status colour | Budget plan + ledger |
| Benchmark split | How close am I to the strategy's targets? | One 100% stacked bar for actual above one for target | Strategy benchmarks |
| Cash flow waterfall | Where did this month's income go? | Waterfall: income, deductions, loan, needs, wants, savings, unallocated | Ledger |
| Net worth over time | Am I getting richer? | Stacked area of assets with a liabilities line | Ledger snapshots |
| Loan balance | When will I be free of it, and what does it cost? | Balance line, principal vs interest stacked bars; second line for a prepayment what-if | Loan schedule |
| Savings projection | Will I reach my goal by the deadline? | Median line, P10–P90 band, goal line | Projection engine |
| Runway | How long could I cope without income? | Line of months of runway with threshold bands; sparkline on the dashboard | Ledger + projection |
| Category trend | Is a cost creeping up? | Small multiples with a 3-month moving average | Ledger |
| Savings rate | What share of income do I keep? | Line, monthly, with a 12-month average | Ledger |
| Receivables ageing | Who owes me and for how long? | Bars by age bucket: 0–30, 31–60, 61–90, 90+ days | Lending log |

Implementation notes:

- **Library.** `fl_chart` covers line, bar, stacked and scatter. The waterfall and the percentile band need a `CustomPainter`, or a stacked-bar trick for the waterfall.
- **Colour.** One fixed colour per classification (Needs royal blue, Wants violet, Savings teal) across every chart. Status colours never carry meaning alone; pair them with a label or icon.
- **Numbers.** Tabular figures, KSh formatting with thousands separators, negative values in a consistent style.
- **Drill-down.** Clicking any bar or point opens the underlying ledger lines.

Standard statements generated from the ledger for any period:

| Report | Content |
| --- | --- |
| Balance sheet | Assets, liabilities, net worth at a date, with current and non-current loan split |
| Income statement | Income minus expenses for the period, giving surplus or deficit |
| Cash flow statement | Opening cash, inflows, outflows, closing cash, grouped as operating, investing (savings and investments) and financing (loans) |
| Budget variance | Plan vs actual per category with favourable or unfavourable variance |
| Loan statement | Schedule, payments made, balance, interest to date |
| Trial balance | Debit and credit totals per account, which must match |

All reports export to PDF and CSV.

## Screens and navigation

A left sidebar holds twelve screens. Every screen is a view over the same ledger, so a number on one screen always matches the others.

| Screen | What you do there | Main content |
| --- | --- | --- |
| Dashboard | See the month at a glance | Net worth, free cash flow, runway, benchmark bars, upcoming dues, alerts |
| Net worth | Understand your wealth | Total, liquid and per-asset equity; history; the bridge of what changed it |
| Budget | Plan and track the month | Strategy picker, category lines, plan vs actual, rollovers |
| Transactions | Record and review | Ledger list, filters, quick add, statement import, reversal |
| Accounts | Manage where money sits | Balances, payday transfer checklist with fees, reconciliation |
| Income | Manage every income stream | Streams, expected vs received, payslip templates, windfall rule |
| Loans | Track what you owe and lend | Owed and lent tabs, schedule, prepayment what-if, lending capacity |
| Assets | Keep the register | Cars, tractors, land; valuations, depreciation, linked loans, insurance dates |
| Investments and goals | Grow money | Holdings, lots, XIRR, allocation vs target, goals and sinking funds |
| Projections | Look ahead | Scenarios, stress tests, fan chart, breathing room |
| Reports | Produce statements | Balance sheet, income statement, cash flow, variance, exports |
| Settings | Configure | Strategy library, tariffs, classifications, backup, security, later the sync account |

Actions available everywhere:

- **Quick add** (⌘N): one sheet for expense, income, transfer, loan payment, with the fee filled in.
- **Search and commands** (⌘K): jump to any screen, account, loan or asset, or run an action.
- **Period switcher:** move between months; closed months open read-only.
- **Privacy mode:** blurs amounts, for screen sharing or public places.
- **Alerts:** loan due dates, insurance expiry, a valuation older than a set age, a benchmark off track, runway below your threshold.
- **Undo** is a reversal entry, never a deletion.

## User flows

Fifteen flows cover everything the app does. Each one ends in a posted journal entry, a saved plan or a report, and posting is atomic: all lines are saved or none.

| Flow | Starts when | Steps | Ends with |
| --- | --- | --- | --- |
| 1. First-time setup | First launch | Welcome → accounts with opening balances → income streams → assets and loans (optional) → pick strategy → preview budget → starting net worth | Dashboard showing a real net worth |
| 2. Import from spreadsheet | Welcome screen or Settings | Choose My\_Budget.xlsx → map categories and accounts → review problems found (text numbers, broken formulas) → confirm | Accounts, categories and a draft strategy |
| 3. Record income | Pay arrives | Choose stream → see expected amount → enter gross and deductions → post | Income posted, variance shown, payday checklist opens |
| 4. Quick add | ⌘N | Type (expense, transfer, income) → amount → accounts → fee suggested → category → date → save | Entry posted, budget bar updates |
| 5. Correct a mistake | Open an entry | Edit opens a pre-filled copy → save | A reversal plus the corrected entry |
| 6. Payday transfers | Income posted | Review plan with fees → tick each transfer as done or pending | Money in the right accounts, fees posted |
| 7. Create or edit a strategy | Budget → strategy picker | Copy a built-in or start blank → base → buckets and rules → map categories → benchmarks → live preview → save | A new strategy version |
| 8. Add an asset | Assets → New | Class → cost and fees → how it was paid (cash or loan) → valuation and depreciation → insurance and documents → save | Acquisition entry, net worth updated |
| 9. Revalue or sell an asset | Asset detail | Record a value with source and date, or enter sale price and fees | Revaluation or disposal entry with gain or loss |
| 10. Take or give a loan | Loans → New | Direction → terms → schedule preview → account → save | Loan, schedule and due reminders |
| 11. Repay a loan | Due reminder | Matched instalment → confirm amount → optional prepayment with what-if → post | Balance, interest and schedule updated |
| 12. Add an investment | Investments → New | Holding → lot (units, price, fees) → source account → post; later update prices | Value, cost basis and XIRR updated |
| 13. Run a projection | Projections | Pick a scenario → set assumptions → read fan, runway and goals → save | A saved scenario |
| 14. Reconcile and close | Month end | Enter statement balance → match entries → resolve differences → close period | A locked month with a net worth snapshot |
| 15. Back up and restore | Settings | Export a file, or restore one → trial balance check | Data safe; later, sign in and sync |

### Setup flow

&#91;embedded content: setup flow · 8 steps, 1 optional\]

Choosing the spreadsheet import at the first step fills accounts, income and categories and jumps straight to picking a strategy.

### Monthly cycle

&#91;embedded content: monthly cycle · 8 steps, loop\]

Closing the month is the step that locks history, so the loop only advances once reconciliation passes.

Rules every flow follows:

- Long flows (asset, loan, strategy) are wizards with a live preview and can be saved as drafts.
- Destructive actions ask for confirmation and offer a reversal instead of a delete.
- A closed period opens read-only; reopening needs a reason, which is logged.
- Empty screens say what to do next and link to the flow that fills them.
- Every form can be completed from the keyboard.

## Architecture and data model

The app has four layers. The domain core is pure Dart, so every financial rule is testable without Flutter, and the repository interfaces are the single seam where the Go API later replaces SQLite.

&#91;embedded content: app architecture · 4 layers, API added later\]

Dependencies point inward: screens call use cases, use cases use domain rules, and the data layer implements the interfaces the domain defines.

### Local first, API later

- **One repository interface per aggregate** (ledger, strategies, loans, holdings, goals). A Riverpod provider override swaps the SQLite implementation for the API one with no UI change.
- **Sync columns on every table from day one:** a time-ordered UUID `id`, `createdAt`, `updatedAt`, `deletedAt` for soft deletes, and `deviceId`. Adding them later means migrating every row.
- **Outbox table** of pending changes. Sync pushes batches with idempotency keys and pulls changes since a server cursor.
- **Conflict policy:** journal entries are append-only, so they cannot conflict. Strategies, budgets and settings use last-writer-wins by `updatedAt`, with the server as the clock authority. Loans sync their event list and regenerate the schedule.
- **Go service:** REST and JSON, Postgres, `sqlc` for typed queries, per-user accounts with short-lived access tokens and refresh tokens, TLS only.

### Main tables

| Table | Purpose | Key columns |
| --- | --- | --- |
| `accounts` | Chart of accounts | id, name, type, entity, classification (needs, wants, savings), liquidity, parent\_id, currency |
| `journal_entries` | One row per transaction | id, date, memo, period\_id, reverses\_id |
| `journal_lines` | Debit and credit rows | entry\_id, account\_id, side, amount\_minor |
| `periods` | Monthly windows | id, start, end, closed\_at, opening and closing balances |
| `strategies`, `strategy_versions` | Strategy documents | id, name, version, json, built\_in |
| `budget_plans` | One per month | month, strategy\_version\_id, inputs snapshot, computed allocations |
| `budget_lines` | Allocation per account | plan\_id, account\_id, amount\_minor, rollover\_in\_minor |
| `loans`, `loan_events`, `loan_schedule_lines` | Contract, events, cached schedule | direction, principal\_minor, method, rate, term; event type and date; due date, principal, interest, balance |
| `holdings`, `valuations` | Investments | type, account\_id, units, cost\_basis; date, price |
| `goals` | Savings goals | type, target\_minor, deadline, account\_id |
| `scenarios` | Projection overrides | name, overrides json |
| `settings`, `outbox` | Configuration, pending sync | key, value; entity, operation, payload |

Added by net worth, income and fees: `assets` (register fields, depreciation method, rate, salvage, linked loan\_id), `asset_valuations` (date, value, source), `income_sources` (type, deposit account, pattern, reliable baseline, payslip template, linked asset), `income_schedule` (month, expected amount), `fee_rules` and `fee_tiers` (provider, channel, operation, effective dates, tier bands, taxes), `contingent_liabilities` and `net_worth_snapshots` (date, total, liquid, per-class breakdown).

### macOS and Dart specifics

- **Packages:** `drift`, `riverpod`, `go_router`, `fl_chart`, `window_manager`, `local_auth`, `intl`, and `decimal` for rate arithmetic.
- **Money:** amounts are `int` minor units (64-bit on the desktop VM). Rates use `Decimal`, and each result is rounded once, half up, to the cent. The rule is documented and covered by tests.
- **Storage:** the database file sits in Application Support, with an export-to-file backup and optional SQLCipher encryption.
- **Sandbox entitlements:** keep the app sandbox on and add `com.apple.security.network.client` now for the future API, plus `com.apple.security.files.user-selected.read-write` for imports and exports.
- **Desktop feel:** sidebar navigation, a platform menu bar, keyboard shortcuts such as ⌘N for a new entry, and a Touch ID lock through `local_auth`.

## Roadmap and testing

Each phase ends with a gate you can check; the next phase does not start until it passes.

1. **Core library.** A pure-Dart package with Money, the ledger rules, the strategy engine and loan schedules, and no Flutter dependency. *Gate:* property tests pass (debits equal credits, allocations sum to the base, every loan balance reaches zero).
2. **Local app shell.** Theme, sidebar layout, drift schema with migrations, chart of accounts seeded from your categories and four bank accounts, and a one-time import from My\_Budget.xlsx. *Gate:* data survives a restart and the import reproduces your categories.
3. **Budget and strategies.** Built-in strategies, the editor, benchmarks, dashboard. *Gate:* the Commitments-first strategy reproduces your sheet's allocations to the cent, apart from the KSh 6 rounding gap.
4. **Transactions and loans.** Posting and reversal, fee tariffs, reconciliation, loan screens, lending log. *Gate:* a recorded instalment moves principal, interest and balance exactly as the schedule says.
5. **Savings, investments and projections.** Asset register with depreciation and revaluation, net worth screen and bridge, multiple income streams, goals, holdings, XIRR, projection engine, scenarios, stress tests, graphs. *Gate:* outputs match the worked examples in this document.
6. **Productivity.** Monte Carlo, M-Pesa and bank statement import, categorization rules, recurring entries, backup and export.
7. **API and sync.** Go service, outbox sync, authentication, then Windows and Linux builds.

Test layers:

- **Golden tests** built from your spreadsheet's current numbers and the worked examples above.
- **Property tests** for ledger balance, strategy sum-to-base and loan amortization, including random terms and prepayments.
- **Cross-checks**: present value of remaining instalments equals loan balance; projection output equals the closed-form formulas when volatility is zero; an asset depreciates to exactly its salvage value at the end of its life; fee tiers match hand-computed tariffs; net worth equals the sum of account balances at every period close.
- **Migration tests** that open a database from each earlier schema version.
- **Widget golden tests** for the dashboard and budget screens on macOS.

## Gaps, MVP scope and open decisions

Five gaps change the data model and are settled before phase 2; the rest can follow the first release. The first release is cut at phases 1 to 3 plus a basic net worth and assets screen.

### Additions that shape the schema

| Addition | Design |
| --- | --- |
| Personal and business books | An `entity` on accounts, income streams, assets and budgets (default: Personal). Each entity's books balance on their own. A transfer between entities posts two linked entries, a contribution in one book and a drawing in the other. Reports filter by entity, and a business view shows revenue, costs and profit, with seasonal months for farming. |
| Tax | An effective-dated tax profile (bands, reliefs, withholding rates), edited like fee tariffs. Transactions carry a tax treatment: taxable, exempt, withheld at source, deductible, or capital. A year-end estimate report and a deadline calendar sit on top. Sale of land or shares has fields for transfer and capital gains taxes, whose rates you confirm. The app gives estimates, not tax advice. |
| Insurance | A `policies` record: type, insurer, insured asset or person, premium, frequency, cover amount, renewal date, policy number, document. Premiums become recurring entries. A coverage-gap report lists assets with no policy, and the stress test reads cover amounts. |
| Recurring items and bills | A `recurring_rules` record: template entry, schedule (day of month, weekly, yearly), fixed or variable amount, auto-post or remind only. Loan instalments, premiums, sinking-fund contributions and subscriptions all generate occurrences. A bills calendar shows them by month, with macOS notifications at set lead times, and missed items are flagged. |
| Import pipeline | Parse (per-provider profile) → normalise (date, amount, balance, reference, counterparty) → dedupe (provider transaction code, else date + amount + reference) → match to planned entries (amount and date within a window) → apply rules (text or counterparty to category, merge fee lines) → review queue → post. Each import is a batch you can reverse whole. The statement's opening balance plus lines must equal its closing balance before posting. Parser profiles are data files, so adding a provider is not an app release. Start with CSV or XLSX; add PDF parsing later, since PDF statements are fragile. |

### Later additions

- **Financial independence number:** annual essential spending ÷ withdrawal rate. The rate is a setting, since any common rule of thumb is an assumption.
- **Distribution:** a Mac app outside the App Store needs Developer ID signing, notarization, a DMG and an update mechanism. This requires an Apple Developer Program account.
- **Encryption and recovery:** the SQLCipher key comes from a passphrase and is stored in the Keychain, and a recovery key is shown once at setup. Losing both the passphrase and the recovery key means losing the data, and the app says so.
- **Emergency access sheet:** a one-page PDF listing accounts, assets, loans, policies and where documents are kept, with no passwords.
- **Multi-currency:** amounts already carry a currency code; later add a rates table and revaluation entries.
- **Household sharing:** after the API exists, with owner and viewer roles and a separate entity per person.

### First release scope

| Capability | First release | Later |
| --- | --- | --- |
| Ledger, accounts, quick add with fees | Yes |  |
| Strategies: built-ins, editor, benchmarks | Yes |  |
| Budget plan vs actual, dashboard | Yes |  |
| Income streams | Yes | Windfall rule, expected vs received matching |
| Loans owed with schedule and prepayment what-if | Yes | Avalanche and snowball simulator |
| Asset register and net worth screen | Yes, with straight-line and reducing-balance depreciation | Bridge report, contingent liabilities |
| Spreadsheet import, backup and export | Yes |  |
| Savings goals | Yes | Sinking-fund suggestions |
| Projections | Deterministic with scenarios | Stress tests, Monte Carlo |
| Entities | Column in the schema, one entity in the UI | Entity switcher and business reports |
| Recurring items and bills | Basic recurring entries | Calendar and notifications |
| Statement import, tax, insurance, sync | No | Phases 6 and 7 |

### Decisions needed from you

1. Is any income or spending from a business that should stay separate, such as the tractor, farm or rent?
2. Which statements can you export, and in what format: M-Pesa, Co-op, StanChart, Etica?
3. Are you taxed through PAYE only, or do you also file for other income?
4. What are the terms of the 25,000 loan deduction (lender, principal, rate, term), and do you have other loans?
5. Are any assets held jointly or on an inherited title, so that an ownership share is needed?
6. Is this one user on one Mac for now?
7. Is the app for your own use only, or will others install it? This affects signing and distribution.
