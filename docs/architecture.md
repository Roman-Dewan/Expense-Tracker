# Vault - System Architecture

## 1. Architectural Overview

Vault is architected around the **Model-View-ViewModel (MVVM)** pattern combined with an **Offline-First Repository Pattern**. All user interface operations interact exclusively with the local storage tier (SQLite), ensuring sub-millisecond response times and uninterrupted usability regardless of network availability. The remote tier (Supabase) serves as a cloud replica and backup medium that is synchronized on-demand.

```
       ┌────────────────────────────────────────────────────────┐
       │                       View Tier                        │
       │   Dashboard  |  Analytics  |  History  |  Budgets      │
       │   ExportDialog | CloudImportExportDialog | AuthScreens │
       └───────────────────────────┬────────────────────────────┘
                                   │ Consumer / Listenable
                                   ▼
       ┌────────────────────────────────────────────────────────┐
       │                     ViewModel Tier                     │
       │      ExpenseProvider       │       AuthProvider        │
       │  (State, Calculations)     │   (Session, User State)   │
       └─────────────┬─────────────────────────────┬────────────┘
                     │                             │
                     ▼                             ▼
       ┌────────────────────────────┐ ┌─────────────────────────┐
       │       Repository Tier      │ │      Service Tier       │
       │  DatabaseHelper (SQLite)   │ │  ExportService (SAF)    │
       │  - Transactions, Budgets   │ │  ImportService (Files)  │
       │  - Accounts, Categories    │ │  AuthService (Supabase) │
       └─────────────┬──────────────┘ └────────────┬────────────┘
                     │                             │
                     │  Manual Sync Payload        │
                     ▼                             ▼
       ┌────────────────────────────────────────────────────────┐
       │                    Cloud Sync Engine                   │
       │  - Date Range Filtering     - Delta Computation        │
       │  - Upsert Batching          - Conflict Resolution      │
       └───────────────────────────┬────────────────────────────┘
                                   │ HTTPS / TLS 1.3
                                   ▼
       ┌────────────────────────────────────────────────────────┐
       │                Supabase Remote Backend                 │
       │    PostgreSQL (RLS)  │  GoTrue Auth  │  Storage        │
       └────────────────────────────────────────────────────────┘
```

---

## 2. Component Layers

### 2.1 View Layer (UI)
- Built using Flutter Material 3 widgets with strict adherence to `AppTheme` (custom dark palette).
- Reactive UI subscribing to ViewModels through `Provider` / `Consumer`.
- Displays modal dialogs for:
  - Statement Export (`ExportDialog`) with date range picker & format selector.
  - Cloud Import/Export (`CloudImportExportDialog`) with date range selection and progress indicators.
  - File Import (`ImportDialog`).

### 2.2 ViewModel Layer
- **`ExpenseProvider`**:
  - Manages active UI state, loaded transactions, active category filters, selected month/date range, and balance computations.
  - Dispatches CRUD operations to `DatabaseHelper`.
  - Coordinates with `ExportService` and `CloudSyncService`.
- **`AuthProvider`**:
  - Exposes `User? currentUser`, `bool isAuthenticated`, `bool isLoading`.
  - Manages sign in, sign up, Google sign in, and sign out workflows.
  - Listens to Supabase `onAuthStateChange` to broadcast session renewals or expirations.

### 2.3 Repository Layer (Local Data Tier)
- **`DatabaseHelper`**:
  - Singleton managing SQLite database (`vault_ledger.db` / `expense_tracker_advanced.db`).
  - Thread-safe transaction handling with parameterized SQL queries.
  - Tagged with `user_id` on all rows to enforce tenant separation when multiple accounts use the app.
  - Tracks `updated_at` timestamps for idempotent delta synchronization.

### 2.4 Service Layer
- **`ExportService`**:
  - Generates byte buffers for PDF, Excel (`.xlsx`), and CSV formats.
  - Integrates with `FilePicker.platform.saveFile` on Desktop and Android Storage Access Framework (SAF) to let users specify destination path and name.
- **`ImportService`**:
  - Ingests file formats (CSV, Excel, JSON) and converts them into normalized model entities.
- **`AuthService`**:
  - Wraps `SupabaseClient.auth` methods (`signInWithPassword`, `signUp`, `signInWithIdToken`, `signOut`).
  - Manages native `GoogleSignIn` token retrieval.
- **`CloudSyncService`**:
  - Coordinates manual cloud backup (Export to Supabase) and cloud restoration (Import from Supabase) across customizable date intervals.

---

## 3. Authentication Architecture & State Persistence

### 3.1 Auth Flow Diagram

```
                 Application Launch (main.dart)
                               │
                               ▼
                        [ AuthGate ]
                               │
                Has Valid Persisted Session?
                               │
                 ┌─────────────┴─────────────┐
                YES                          NO
                 │                           │
                 ▼                           ▼
        [ DashboardScreen ]            [ LoginScreen ]
                                             │
                                ┌────────────┴────────────┐
                                │                         │
                        Email / Password             Google Sign-In
                                │                         │
                     supabase.auth.signIn()     GoogleSignIn.signIn()
                                │                         │
                                │                 Get idToken / accessToken
                                │                         │
                                │              supabase.auth.signInWithIdToken()
                                │                         │
                                └────────────┬────────────┘
                                             │
                                      Success? (Auth Token Cached)
                                             │
                                             ▼
                                     [ DashboardScreen ]
```

### 3.2 Session Persistence
1. Supabase Flutter automatically caches the JWT access token and refresh token in platform-secure storage (`SharedPreferences` on Android, Keychain on iOS, Credential Locker on Windows).
2. On app launch, `AuthGate` reads `Supabase.instance.client.auth.currentSession`.
3. If an active session exists and is unexpired (or automatically refreshed via refresh token), `AuthGate` bypasses the authentication UI and presents `DashboardScreen`.
4. If no session exists or the user explicitly clicks **Sign Out** from `AppDrawer`, the session cache is wiped and `LoginScreen` is rendered.

---

## 4. Cloud Synchronization Architecture

### 4.1 Principles
1. **Explicit / Manual Trigger Only**: Cloud operations execute exclusively when the user initiates them (via Dashboard 1-Tap Sync or Drawer Cloud Import/Export).
2. **Deterministic Partitioning**: Every remote record belongs to a specific `user_id` enforced by PostgreSQL Row-Level Security (RLS).
3. **Date-Range Slicing**: Users can synchronize specific intervals (e.g., "October 2026", "Last 90 Days", or "All Time"), reducing bandwidth and execution time.

### 4.2 Sync Workflows

#### A. Cloud Export (Backup to Supabase)
1. **Selection**: User selects date range (`startDate` to `endDate`).
2. **Local Fetch**: `DatabaseHelper` queries all transactions, modified categories, accounts, and budgets within the range for the current `user_id`.
3. **Remote Upsert**: `CloudSyncService` batches records and executes `supabase.from('transactions').upsert(payload, onConflict: 'id')`.
4. **Result Reporting**: Shows total items uploaded with timestamp.

#### B. Cloud Import (Restore from Supabase)
1. **Selection**: User selects target date range and merge mode:
   - **Merge / Upsert**: Remote records overwrite existing records with matching IDs; new remote records are added; existing local records not in cloud remain intact.
   - **Replace Range**: Clears local records within `[startDate, endDate]` and inserts remote records verbatim.
2. **Remote Fetch**: `supabase.from('transactions').select().gte('date', start).lte('date', end)`.
3. **Local Transaction**: SQLite wraps the insertion/upsert in a database transaction (`db.transaction(...)`).
4. **UI Refresh**: ViewModels reload data and notify listeners.

---

## 5. File Export Architecture with User Location Selection

```
User initiates export (ExportDialog)
  │
  ├─► Selects: [Format: PDF/Excel/CSV] + [Range: Month OR Custom Date Range]
  │
  ├─► ViewModel computes records & generates binary payload (Uint8List)
  │
  ├─► Prompt Native Save Dialog:
  │     FilePicker.platform.saveFile(
  │       dialogTitle: 'Select destination folder to save statement',
  │       fileName: 'Vault_Report_2026_10.pdf',
  │       type: FileType.custom,
  │       allowedExtensions: ['pdf', 'xlsx', 'csv'],
  │     )
  │
  ├─► User selects location:
  │     ├─► User Confirms Path: File written directly to selected path.
  │     └─► User Cancels: Operation safely aborted without errors.
  │
  └─► Success notification with absolute file location.
```

