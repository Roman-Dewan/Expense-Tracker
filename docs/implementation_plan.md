# Vault - Implementation Plan & Engineering Roadmap

## Overview
This roadmap outlines the complete technical execution plan to implement all requested capabilities for **Vault**:
1. Specific Month with Date Range statement export.
2. User-directed Save Location dialog picker.
3. 1-Tap Dashboard current-month sync + App Drawer Cloud Import/Export with date-range selection.
4. Supabase Authentication with Google Sign-In, persistent session recovery, and multi-user isolation.
5. Strict Offline-First architecture with manual cloud sync.
6. Full app rebranding to "Vault".

---

## Phase Breakdown

### Phase 1: Rebranding & Base Alignment
- [x] Rename app display name from "Expense Tracker" to "Vault" in `lib/main.dart`, `lib/views/app_drawer.dart`, `lib/views/dashboard_screen.dart`, `ios/Runner/Info.plist`, and `android/app/src/main/AndroidManifest.xml`.
- [x] Update documentation titles and README headers.
- [ ] Rename default exported file naming prefix from `Expense_Report_` to `Vault_Report_`.

---

### Phase 2: Enhanced Export with Date Range Filter & Save Location Dialog
- [ ] **Data Model / Service Update (`ExportService`)**:
  - Add `startDate` and `endDate` parameters alongside `month`.
  - Filter transactions by exact datetime boundaries (`start 00:00:00` to `end 23:59:59.999`).
  - Update PDF, Excel, and CSV builders to display the selected date range in statement headers.
- [ ] **Location Picker Integration (`FilePicker.platform.saveFile`)**:
  - Replace hardcoded directory writes (`/storage/emulated/0/Download`) with an explicit file save prompt.
  - On Desktop and Android, trigger `FilePicker.platform.saveFile(...)` with pre-filled default file name (`Vault_Report_YYYY_MM_DD.ext`).
  - Fall back to Storage Access Framework / downloads directory if the user confirms, and gracefully handle user cancellation without showing error banners.
- [ ] **UI Update (`ExportDialog`)**:
  - Add date range selection toggles: "Full Month" vs "Custom Date Range within Month / Across Dates".
  - Date range picker using `showDateRangePicker(...)`.
  - Show selected save location preview in dialog prior to final export button press.

---

### Phase 3: Supabase & Google Authentication Integration
- [ ] **Dependencies (`pubspec.yaml`)**:
  - Add `supabase_flutter: ^2.18.3`.
  - Add `google_sign_in: ^7.2.0`.
  - Run `flutter pub get`.
- [ ] **Environment & Supabase Client Initialization**:
  - Create `lib/services/supabase_config.dart` storing project credentials (`supabaseUrl` and `supabaseAnonKey`) with clear instructions.
  - Initialize `Supabase.initialize(...)` in `lib/main.dart` before `runApp`.
- [ ] **Authentication Service (`AuthService`)**:
  - Implement `signInWithEmail(email, password)`.
  - Implement `signUpWithEmail(email, password, fullName)`.
  - Implement `signInWithGoogle()` using `GoogleSignIn` and `supabase.auth.signInWithIdToken(...)`.
  - Implement `signOut()`.
  - Expose `Stream<AuthState> get onAuthStateChange` and `User? get currentUser`.
- [ ] **Auth State Persistence & Routing (`AuthGate`)**:
  - Create `lib/views/auth/auth_gate.dart`:
    - Reads cached session immediately on startup.
    - If valid user exists -> loads `DashboardScreen`.
    - If no session -> loads `LoginScreen`.
- [ ] **Authentication UI Screens**:
  - `lib/views/auth/login_screen.dart`: Sleek dark theme login with email/password fields, "Continue with Google" button, and link to sign up.
  - `lib/views/auth/signup_screen.dart`: Registration screen with name, email, password, and validation.
- [ ] **Drawer Profile Header**:
  - Display user email/name and a "Sign Out" button in `AppDrawer`.

---

### Phase 4: Local Database Migration (SQLite Schema V2 for Multi-User)
- [ ] Update `DatabaseHelper`:
  - Upgrade SQLite database version from `1` to `2`.
  - Add `user_id TEXT` and `updated_at TEXT` columns to `transactions`, `categories`, `accounts`, and `budgets`.
  - Migration script in `onUpgrade` to preserve existing offline records while assigning them to active `user_id` upon sign-in.
  - Update queries to filter by active `user_id`.

---

### Phase 5: Cloud Sync Engine & Supabase Cloud Import/Export UI
- [ ] **Cloud Sync Service (`CloudSyncService`)**:
  - `backupTransactions({required DateTime startDate, required DateTime endDate})`:
    - Queries SQLite for transactions within range.
    - Upserts into Supabase `transactions` table with user RLS.
  - `restoreTransactions({required DateTime startDate, required DateTime endDate, bool mergeMode = true})`:
    - Queries Supabase for transactions within range.
    - Inserts / Upserts into local SQLite.
  - Sync metadata tracking (timestamp of last successful sync).
- [ ] **Dashboard 1-Tap Current Month Sync**:
  - Add sync icon button in Dashboard AppBar or next to month selector.
  - Shows spinning progress indicator and snackbar summary: "Current month synced (X uploaded, Y restored)".
- [ ] **App Drawer "Cloud Import / Export"**:
  - Add drawer item: `Cloud Backup & Restore` with cloud icon.
  - Opens `CloudImportExportDialog`:
    - Mode selector: "Cloud Export (Backup)" vs "Cloud Import (Restore)".
    - Date range selector: "Current Month", "Last 30 Days", "Year to Date", "Custom Date Range".
    - Record count preview.
    - Action confirmation with error and success status.

---

### Phase 6: Testing & Quality Assurance
- [ ] Verify offline isolation: app functions fully when disconnected from internet.
- [ ] Verify auth persistence: closing and reopening app keeps user logged in.
- [ ] Verify file export: file picker opens, file is saved to the selected folder, and opens cleanly in PDF reader / Excel.
- [ ] Run `flutter analyze` and `flutter test`.
- [ ] Verify `flutter build apk --debug`.

