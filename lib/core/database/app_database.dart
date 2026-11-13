import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static const _dbName = 'keel.db';
  static const _dbVersion = 17;

  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), _dbName);
    return openDatabase(path,
        version: _dbVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE budget_plans ADD COLUMN is_template INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE budget_plans ADD COLUMN template_name TEXT');
      await db.execute('ALTER TABLE budget_lines ADD COLUMN notes TEXT');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS strategy_buckets (
          id TEXT PRIMARY KEY,
          strategy_id TEXT NOT NULL,
          name TEXT NOT NULL,
          target_pct INTEGER NOT NULL DEFAULT 0,
          account_ids TEXT NOT NULL DEFAULT ''
        )
      ''');
    }
    if (oldVersion < 4) {
      await db.execute(
          "ALTER TABLE strategy_buckets ADD COLUMN account_weights TEXT NOT NULL DEFAULT ''");
    }
    if (oldVersion < 5) {
      await db.execute(
          "ALTER TABLE journal_entries ADD COLUMN tags TEXT NOT NULL DEFAULT ''");
    }
    if (oldVersion < 6) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS projects (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          description TEXT,
          type TEXT NOT NULL,
          status TEXT NOT NULL DEFAULT 'planning',
          budget_minor INTEGER NOT NULL DEFAULT 0,
          revenue_target_minor INTEGER,
          currency TEXT NOT NULL DEFAULT 'KES',
          funding_account_id TEXT,
          asset_account_id TEXT,
          start_date TEXT NOT NULL,
          end_date TEXT,
          tags TEXT NOT NULL DEFAULT '',
          created_at TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS project_entries (
          project_id TEXT NOT NULL,
          journal_entry_id TEXT NOT NULL,
          PRIMARY KEY (project_id, journal_entry_id),
          FOREIGN KEY (project_id) REFERENCES projects(id)
        )
      ''');
    }
    if (oldVersion < 7) {
      await db.execute('ALTER TABLE journal_entries ADD COLUMN payee TEXT');
      await db.execute('ALTER TABLE journal_entries ADD COLUMN notes TEXT');
      await db.execute('ALTER TABLE journal_entries ADD COLUMN location TEXT');
      await db.execute('ALTER TABLE journal_lines ADD COLUMN memo TEXT');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS entry_attachments (
          id TEXT PRIMARY KEY,
          entry_id TEXT NOT NULL,
          file_path TEXT NOT NULL,
          file_name TEXT NOT NULL,
          mime_type TEXT,
          created_at TEXT NOT NULL,
          FOREIGN KEY (entry_id) REFERENCES journal_entries(id)
        )
      ''');
    }
    if (oldVersion < 8) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS contacts (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          phone TEXT,
          email TEXT,
          notes TEXT,
          relationship TEXT NOT NULL DEFAULT 'other',
          created_at TEXT NOT NULL
        )
      ''');
      await db.execute('ALTER TABLE journal_entries ADD COLUMN contact_id TEXT');
    }
    if (oldVersion < 9) {
      await db.execute('ALTER TABLE projects ADD COLUMN asset_id TEXT');
    }
    if (oldVersion < 10) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS asset_attachments (
          id TEXT PRIMARY KEY,
          asset_id TEXT NOT NULL,
          file_path TEXT NOT NULL,
          file_name TEXT NOT NULL,
          mime_type TEXT,
          created_at TEXT NOT NULL,
          FOREIGN KEY (asset_id) REFERENCES assets(id)
        )
      ''');
    }
    if (oldVersion < 13) {
      await db.execute(
          'ALTER TABLE holdings ADD COLUMN annual_rate_bp INTEGER');
      await db.execute(
          "ALTER TABLE holdings ADD COLUMN compounding_freq TEXT NOT NULL DEFAULT 'none'");
      await db.execute(
          'ALTER TABLE holdings ADD COLUMN maturity_date TEXT');
    }
    if (oldVersion < 14) {
      // Add updated_at and deleted_at to all tables for incremental sync
      const tables = [
        'accounts', 'journal_entries', 'journal_lines', 'budget_plans',
        'budget_lines', 'strategies', 'strategy_buckets', 'loans',
        'loan_events', 'income_streams', 'assets', 'holdings',
        'holding_lots', 'contacts', 'projects', 'project_entries',
        'entry_attachments', 'asset_attachments', 'period_snapshots',
      ];
      final now = DateTime.now().toUtc().toIso8601String();
      for (final t in tables) {
        try {
          await db.execute(
            "ALTER TABLE $t ADD COLUMN updated_at TEXT NOT NULL DEFAULT '$now'");
        } catch (_) {} // column may already exist
        try {
          await db.execute(
            'ALTER TABLE $t ADD COLUMN deleted_at TEXT');
        } catch (_) {}
      }
      // settings table uses key as PK, no id — add updated_at only
      try {
        await db.execute(
          "ALTER TABLE settings ADD COLUMN updated_at TEXT NOT NULL DEFAULT '$now'");
      } catch (_) {}
    }
    if (oldVersion < 15) {
      await db.execute('ALTER TABLE income_streams ADD COLUMN frequency_unit TEXT');
      await db.execute('ALTER TABLE income_streams ADD COLUMN frequency_interval INTEGER');
      await db.execute("ALTER TABLE income_streams ADD COLUMN payment_mode TEXT NOT NULL DEFAULT 'regular'");
    }
    if (oldVersion < 16) {
      await db.execute('ALTER TABLE accounts ADD COLUMN overdraft_limit_minor INTEGER');
      await db.execute("ALTER TABLE loans ADD COLUMN rate_period TEXT NOT NULL DEFAULT 'annual'");
    }
    if (oldVersion < 17) {
      await db.execute('ALTER TABLE tariffs ADD COLUMN account_id TEXT NOT NULL DEFAULT \'\'');
      await db.execute('ALTER TABLE tariffs ADD COLUMN fee_account_id TEXT');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE accounts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        currency TEXT NOT NULL DEFAULT 'KES',
        liquidity TEXT NOT NULL DEFAULT 'instant',
        is_active INTEGER NOT NULL DEFAULT 1,
        overdraft_limit_minor INTEGER,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE journal_entries (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL,
        description TEXT NOT NULL,
        reference TEXT,
        payee TEXT,
        notes TEXT,
        location TEXT,
        contact_id TEXT,
        period TEXT NOT NULL,
        is_locked INTEGER NOT NULL DEFAULT 0,
        tags TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE journal_lines (
        id TEXT PRIMARY KEY,
        entry_id TEXT NOT NULL,
        account_id TEXT NOT NULL,
        amount_minor INTEGER NOT NULL,
        currency TEXT NOT NULL DEFAULT 'KES',
        side TEXT NOT NULL,
        memo TEXT,
        FOREIGN KEY (entry_id) REFERENCES journal_entries(id),
        FOREIGN KEY (account_id) REFERENCES accounts(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE budget_plans (
        id TEXT PRIMARY KEY,
        period TEXT NOT NULL,
        strategy_id TEXT NOT NULL,
        strategy_version INTEGER NOT NULL,
        base_amount_minor INTEGER NOT NULL,
        currency TEXT NOT NULL DEFAULT 'KES',
        is_template INTEGER NOT NULL DEFAULT 0,
        template_name TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE budget_lines (
        id TEXT PRIMARY KEY,
        plan_id TEXT NOT NULL,
        account_id TEXT NOT NULL,
        bucket TEXT NOT NULL,
        planned_minor INTEGER NOT NULL,
        currency TEXT NOT NULL DEFAULT 'KES',
        rollover_minor INTEGER NOT NULL DEFAULT 0,
        notes TEXT,
        FOREIGN KEY (plan_id) REFERENCES budget_plans(id),
        FOREIGN KEY (account_id) REFERENCES accounts(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE strategies (
        id TEXT PRIMARY KEY,
        version INTEGER NOT NULL,
        name TEXT NOT NULL,
        is_builtin INTEGER NOT NULL DEFAULT 0,
        definition TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE loans (
        id TEXT PRIMARY KEY,
        direction TEXT NOT NULL,
        counterparty TEXT NOT NULL,
        principal_minor INTEGER NOT NULL,
        currency TEXT NOT NULL DEFAULT 'KES',
        interest_method TEXT NOT NULL,
        annual_rate_bp INTEGER NOT NULL,
        rate_period TEXT NOT NULL DEFAULT 'annual',
        term_months INTEGER NOT NULL,
        disbursement_date TEXT NOT NULL,
        first_due_date TEXT NOT NULL,
        instalment_minor INTEGER NOT NULL,
        is_salary_deducted INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'active',
        account_id TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (account_id) REFERENCES accounts(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE loan_events (
        id TEXT PRIMARY KEY,
        loan_id TEXT NOT NULL,
        type TEXT NOT NULL,
        date TEXT NOT NULL,
        amount_minor INTEGER NOT NULL,
        currency TEXT NOT NULL DEFAULT 'KES',
        note TEXT,
        FOREIGN KEY (loan_id) REFERENCES loans(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE income_streams (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        account_id TEXT NOT NULL,
        frequency TEXT NOT NULL,
        frequency_unit TEXT,
        frequency_interval INTEGER,
        payment_mode TEXT NOT NULL DEFAULT 'regular',
        amount_minor INTEGER NOT NULL,
        reliable_amount_minor INTEGER,
        currency TEXT NOT NULL DEFAULT 'KES',
        is_active INTEGER NOT NULL DEFAULT 1,
        start_date TEXT,
        end_date TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (account_id) REFERENCES accounts(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE assets (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        class TEXT NOT NULL,
        acquisition_date TEXT NOT NULL,
        cost_minor INTEGER NOT NULL,
        currency TEXT NOT NULL DEFAULT 'KES',
        ownership_share_bp INTEGER NOT NULL DEFAULT 10000,
        current_value_minor INTEGER,
        valuation_date TEXT,
        valuation_source TEXT,
        depreciation_method TEXT,
        annual_rate_bp INTEGER,
        salvage_minor INTEGER NOT NULL DEFAULT 0,
        linked_loan_id TEXT,
        insurance_expiry TEXT,
        status TEXT NOT NULL DEFAULT 'in_use',
        location TEXT,
        notes TEXT,
        holding_id TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (linked_loan_id) REFERENCES loans(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE holdings (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        institution TEXT NOT NULL,
        account_id TEXT NOT NULL,
        currency TEXT NOT NULL DEFAULT 'KES',
        liquidity TEXT NOT NULL DEFAULT 'days',
        is_active INTEGER NOT NULL DEFAULT 1,
        current_price_minor INTEGER,
        annual_rate_bp INTEGER,
        compounding_freq TEXT NOT NULL DEFAULT 'none',
        maturity_date TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (account_id) REFERENCES accounts(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE holding_lots (
        id TEXT PRIMARY KEY,
        holding_id TEXT NOT NULL,
        date TEXT NOT NULL,
        units REAL NOT NULL,
        price_minor INTEGER NOT NULL,
        fees_minor INTEGER NOT NULL DEFAULT 0,
        currency TEXT NOT NULL DEFAULT 'KES',
        lot_type TEXT NOT NULL DEFAULT 'purchase',
        FOREIGN KEY (holding_id) REFERENCES holdings(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE savings_goals (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        target_minor INTEGER,
        currency TEXT NOT NULL DEFAULT 'KES',
        target_date TEXT,
        account_id TEXT NOT NULL,
        monthly_contribution_minor INTEGER,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        FOREIGN KEY (account_id) REFERENCES accounts(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE tariffs (
        id TEXT PRIMARY KEY,
        provider TEXT NOT NULL,
        account_id TEXT NOT NULL DEFAULT '',
        fee_account_id TEXT,
        channel TEXT NOT NULL,
        operation TEXT NOT NULL,
        effective_from TEXT NOT NULL,
        effective_to TEXT,
        tiers TEXT NOT NULL,
        tax_rate_bp INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE period_snapshots (
        id TEXT PRIMARY KEY,
        period TEXT NOT NULL UNIQUE,
        opening_net_worth_minor INTEGER NOT NULL,
        closing_net_worth_minor INTEGER NOT NULL,
        currency TEXT NOT NULL DEFAULT 'KES',
        is_locked INTEGER NOT NULL DEFAULT 0,
        closed_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE strategy_buckets (
        id TEXT PRIMARY KEY,
        strategy_id TEXT NOT NULL,
        name TEXT NOT NULL,
        target_pct INTEGER NOT NULL DEFAULT 0,
        account_ids TEXT NOT NULL DEFAULT '',
        account_weights TEXT NOT NULL DEFAULT ''
      )
    ''');

    await db.execute('''
      CREATE TABLE entry_attachments (
        id TEXT PRIMARY KEY,
        entry_id TEXT NOT NULL,
        file_path TEXT NOT NULL,
        file_name TEXT NOT NULL,
        mime_type TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (entry_id) REFERENCES journal_entries(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE projects (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        type TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'planning',
        budget_minor INTEGER NOT NULL DEFAULT 0,
        revenue_target_minor INTEGER,
        currency TEXT NOT NULL DEFAULT 'KES',
        funding_account_id TEXT,
        asset_account_id TEXT,
        start_date TEXT NOT NULL,
        end_date TEXT,
        tags TEXT NOT NULL DEFAULT '',
        asset_id TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE contacts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        notes TEXT,
        relationship TEXT NOT NULL DEFAULT 'other',
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE project_entries (
        project_id TEXT NOT NULL,
        journal_entry_id TEXT NOT NULL,
        PRIMARY KEY (project_id, journal_entry_id),
        FOREIGN KEY (project_id) REFERENCES projects(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE asset_attachments (
        id TEXT PRIMARY KEY,
        asset_id TEXT NOT NULL,
        file_path TEXT NOT NULL,
        file_name TEXT NOT NULL,
        mime_type TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (asset_id) REFERENCES assets(id)
      )
    ''');

    // Indexes for common queries
    await db.execute('CREATE INDEX idx_journal_lines_entry ON journal_lines(entry_id)');
    await db.execute('CREATE INDEX idx_journal_lines_account ON journal_lines(account_id)');
    await db.execute('CREATE INDEX idx_journal_entries_period ON journal_entries(period)');
    await db.execute('CREATE INDEX idx_loan_events_loan ON loan_events(loan_id)');
    await db.execute('CREATE INDEX idx_holding_lots_holding ON holding_lots(holding_id)');
  }

  Future<void> close() async => _db?.close();
}
