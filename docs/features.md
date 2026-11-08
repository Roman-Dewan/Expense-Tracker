# Vault - Feature Specification

## 1. Executive Summary
**Vault** is an offline-first, privacy-conscious personal ledger and expense tracking application built with Flutter. Vault provides financial clarity through multi-wallet tracking, category-based budgets, dynamic visual analytics, and statement exports (PDF, Excel, CSV).

The architecture is built on an **offline-first** paradigm where all operations occur immediately against a local SQLite database, coupled with **on-demand, manual cloud synchronization** to Supabase for multi-device backup and restoration.

---

## 2. Core Feature Matrix

### 2.1 Offline-First Local Ledger
- **Zero Latency Operations**: All CRUD operations (transactions, accounts, categories, budgets) execute locally on SQLite without network dependency.
- **Multi-Account / Wallet Support**: Supports Cash, Bank Accounts, Mobile Wallets (bKash, Nagad, Rocket, etc.), and Credit Cards with real-time balance computation.
- **Custom Categorization**: Income and Expense categories with customizable icons and color coding.
- **Category Budgets**: Monthly spending limits with automated progress tracking and threshold alerts.
- **Interactive Analytics**: Monthly and category spending breakdowns powered by high-contrast `fl_chart` components.

---

### 2.2 Advanced Statement Export with Custom Date Range
- **Flexible Scope Selection**:
  - **Full Month**: Export all transactions belonging to a chosen calendar month.
  - **Custom Date Range**: Pick precise `Start Date` and `End Date` (e.g., Oct 5, 2026 – Oct 20, 2026) within or across months.
- **Calculated Metric Summaries**:
  - Total Income, Total Expenses, and Net Balance dynamically computed for the specified date interval.
  - Breakdown by payment account/wallet and category.
- **Multi-Format Export**:
  - **PDF Statement**: High-contrast, publication-quality document featuring summary header cards, transaction ledger tables, and categorized totals.
  - **Excel Spreadsheet (`.xlsx`)**: Formatted worksheet with structured headers, styled column widths, and raw numeric cells for spreadsheet calculations.
  - **CSV File (`.csv`)**: Clean RFC-4180 standard comma-separated text file compatible with third-party financial software.
- **User-Directed File Save Location**:
  - Prompts the user with a native file-picker dialog (`FilePicker.platform.saveFile` / Storage Access Framework) to choose the exact destination directory and filename prior to saving.
  - Eliminates silent background saves to default hidden directories.
  - Displays instant snackbar confirmation showing the chosen path.

---

### 2.3 File Data Import
- **Multi-Format Ingestion**: Import data directly from CSV, Excel (`.xlsx`), and JSON backup files.
- **Intelligent Field Mapping**: Auto-matches columns for Date, Title/Description, Amount, Category, Account, and Type (Income/Expense).
- **Collision & Duplicate Detection**: Uses transaction hashes/IDs to prevent double-counting previously recorded items.

---

### 2.4 Cloud Sync & Cloud Import/Export (Supabase)
- **Manual, User-Controlled Sync**:
  - Syncing is explicitly triggered by the user to avoid unmetered cellular data usage or battery drain.
- **1-Tap Dashboard Sync (Current Month)**:
  - Accessible directly on the Dashboard (AppBar or Month Navigation header).
  - Backs up current month's local modifications to Supabase or pulls missing remote entries.
- **Dedicated Cloud Import/Export (App Drawer)**:
  - **Cloud Export (Backup to Supabase)**:
    - User selects the date range to backup (Current Month, Last 3 Months, All Time, or Custom Date Range).
    - Previews record count before uploading.
    - Upserts records to the user's isolated partition in Supabase.
  - **Cloud Import (Restore from Supabase)**:
    - Queries remote Supabase records within the selected date range.
    - Offers merge strategies:
      - *Merge / Upsert*: Adds remote records and updates modified ones without deleting local-only records.
      - *Clean Replace Range*: Overwrites local records within the specified date range with remote cloud state.

---

### 2.5 Multi-User Authentication & Google Sign-In
- **Multi-Tenant Isolation**:
  - Multiple users can safely use the application on different devices or sequentially on the same device.
  - All database entities (transactions, categories, accounts, budgets) are strictly tagged with the authenticated user's `user_id`.
- **Authentication Providers**:
  - **Email & Password**: Secure registration and sign-in with client-side format validation and clear error feedback.
  - **Continue with Google**: One-tap sign-in utilizing `google_sign_in` SDK exchanged with Supabase Auth (`signInWithIdToken`).
- **Session Persistence & Auto-Login**:
  - Auth tokens and refresh credentials securely stored in device persistent storage.
  - On application startup, `AuthGate` inspects current session validity. Valid sessions bypass the login screen and land directly on `DashboardScreen`.
- **Theme-Aligned UI**:
  - Login and Registration views adhere strictly to `AppTheme`: deep dark background (`#0E0E12`), card surfaces (`#1A1A22`), accent purple (`#8B5CF6`), neon green highlights (`#10B981`), and sleek rounded input fields.
- **Account Management in Drawer**:
  - App Drawer displays user profile info (name, email, avatar).
  - One-tap secure Sign Out clearing session credentials.

---

### 2.6 Rebranding to "Vault"
- App display name updated to **Vault** across Android, iOS (`CFBundleDisplayName`), Flutter headers, drawers, dialogue modals, and exported statement templates.

