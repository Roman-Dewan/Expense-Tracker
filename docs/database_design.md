# Vault - Database Design & Schema Specification

## 1. Overview
Vault utilizes a dual-tier storage design:
1. **Local SQLite Database**: Operates as the zero-latency, offline-first primary store on the client device.
2. **Remote Supabase (PostgreSQL) Database**: Operates as the multi-tenant, cloud-persisted replica secured by PostgreSQL Row-Level Security (RLS).

All primary keys use **UUIDv4** strings generated on the client, ensuring collision-free generation offline before syncing to the cloud.

---

## 2. Local SQLite Database Schema

### 2.1 Table: `categories`
Stores expense and income categories with styling metadata.
```sql
CREATE TABLE categories (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    icon_code INTEGER NOT NULL,
    color_value INTEGER NOT NULL,
    type INTEGER NOT NULL,            -- 0: expense, 1: income
    user_id TEXT,                     -- Links to authenticated user
    updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX idx_categories_user ON categories (user_id);
```

### 2.2 Table: `accounts`
Stores payment accounts/wallets (Cash, Bank, Mobile Wallets).
```sql
CREATE TABLE accounts (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    type TEXT NOT NULL,                -- 'cash', 'bank', 'mobile_banking', 'credit_card'
    initial_balance REAL NOT NULL DEFAULT 0.0,
    icon_code INTEGER NOT NULL,
    color_value INTEGER NOT NULL,
    user_id TEXT,
    updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX idx_accounts_user ON accounts (user_id);
```

### 2.3 Table: `transactions`
Core ledger table containing income, expense, and transfer records.
```sql
CREATE TABLE transactions (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    amount REAL NOT NULL,
    date TEXT NOT NULL,                -- ISO 8601 string (e.g., '2026-10-15T14:30:00.000Z')
    category_id TEXT NOT NULL,
    account_id TEXT NOT NULL,
    type INTEGER NOT NULL,             -- 0: expense, 1: income, 2: transfer
    notes TEXT,
    user_id TEXT,
    updated_at TEXT NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE,
    FOREIGN KEY (account_id) REFERENCES accounts (id) ON DELETE CASCADE
);

CREATE INDEX idx_transactions_user_date ON transactions (user_id, date);
CREATE INDEX idx_transactions_category ON transactions (category_id);
CREATE INDEX idx_transactions_account ON transactions (account_id);
```

### 2.4 Table: `budgets`
Monthly spending limits assigned per category.
```sql
CREATE TABLE budgets (
    id TEXT PRIMARY KEY,
    category_id TEXT NOT NULL,
    month_year TEXT NOT NULL,          -- Format 'YYYY-MM' (e.g., '2026-10')
    amount_limit REAL NOT NULL,
    user_id TEXT,
    updated_at TEXT NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE
);

CREATE UNIQUE INDEX idx_budgets_user_cat_month ON budgets (user_id, category_id, month_year);
```

---

## 3. Remote Supabase (PostgreSQL) Schema

### 3.1 Extensions & Schemas
```sql
-- Ensure UUID extension is active
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
```

### 3.2 Profiles Table
Stores supplementary profile metadata linked directly to Supabase Auth (`auth.users`).
```sql
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT,
    avatar_url TEXT,
    currency_symbol TEXT DEFAULT '৳',
    currency_code TEXT DEFAULT 'BDT',
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Row-Level Security
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own profile"
    ON public.profiles FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
    ON public.profiles FOR UPDATE
    USING (auth.uid() = id);

-- Auto-create profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, full_name, avatar_url)
    VALUES (
        new.id,
        COALESCE(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'name', ''),
        COALESCE(new.raw_user_meta_data->>'avatar_url', new.raw_user_meta_data->>'picture', '')
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
```

### 3.3 Remote Tables: `categories`, `accounts`, `transactions`, `budgets`
```sql
-- 1. Categories
CREATE TABLE public.categories (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    icon_code INTEGER NOT NULL,
    color_value INTEGER NOT NULL,
    type INTEGER NOT NULL,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own categories"
    ON public.categories FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE INDEX idx_supabase_categories_user ON public.categories (user_id);


-- 2. Accounts
CREATE TABLE public.accounts (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    type TEXT NOT NULL,
    initial_balance NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    icon_code INTEGER NOT NULL,
    color_value INTEGER NOT NULL,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.accounts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own accounts"
    ON public.accounts FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE INDEX idx_supabase_accounts_user ON public.accounts (user_id);


-- 3. Transactions
CREATE TABLE public.transactions (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    amount NUMERIC(12, 2) NOT NULL,
    date TIMESTAMPTZ NOT NULL,
    category_id UUID NOT NULL,
    account_id UUID NOT NULL,
    type INTEGER NOT NULL,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own transactions"
    ON public.transactions FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE INDEX idx_supabase_transactions_user_date ON public.transactions (user_id, date DESC);


-- 4. Budgets
CREATE TABLE public.budgets (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    category_id UUID NOT NULL,
    month_year TEXT NOT NULL,
    amount_limit NUMERIC(12, 2) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    CONSTRAINT uq_budgets_user_cat_month UNIQUE (user_id, category_id, month_year)
);

ALTER TABLE public.budgets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own budgets"
    ON public.budgets FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);
```

---

## 4. Date-Range Synchronization Queries

### 4.1 Export / Backup Query (Local SQLite to Remote Supabase)
```sql
-- Fetch transactions in date interval
SELECT * FROM transactions
WHERE (user_id = ? OR user_id IS NULL)
  AND date >= '2026-10-01T00:00:00.000Z'
  AND date <= '2026-10-31T23:59:59.999Z';
```
Payload converted to JSON array and sent to Supabase:
```dart
await supabase.from('transactions').upsert(
  transactionsJson,
  onConflict: 'id',
);
```

### 4.2 Import / Restore Query (Remote Supabase to Local SQLite)
```dart
final response = await supabase
    .from('transactions')
    .select()
    .gte('date', startIso)
    .lte('date', endIso);
```
SQLite batch upsert executes inside a transaction:
```sql
INSERT INTO transactions (id, title, amount, date, category_id, account_id, type, notes, user_id, updated_at)
VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
ON CONFLICT(id) DO UPDATE SET
    title = excluded.title,
    amount = excluded.amount,
    date = excluded.date,
    category_id = excluded.category_id,
    account_id = excluded.account_id,
    type = excluded.type,
    notes = excluded.notes,
    updated_at = excluded.updated_at;
```

