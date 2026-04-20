# Expense Tracker App

A high-fidelity, Material 3 Expense Tracker application built with Flutter using the **MVVM (Model-View-ViewModel)** architecture and **Provider** for state management. This app allows users to track their income and expenses with local data persistence.

## 🚀 Features

- **Dashboard**: Visualize your `Total Balance`, `Income`, and `Expenses` in a premium, high-contrast dashboard.
- **Transaction Management**: Add new transactions (Income/Expense) with titles, amounts, and custom dates.
- **Dynamic List**: View all your recent transactions with intuitive color coding (Green for Income, Red for Expense).
- **Delete Functionality**: Easily remove transactions from the history.
- **Local Persistence**: All data is securely stored on your device using `SharedPreferences`, ensuring it persists across app restarts.
- **Material 3 Design**: Modern UI/UX with smooth transitions, dark mode aesthetics, and custom UI components.

## 🛠️ Architecture

This project strictly follows the **MVVM** pattern:

- **Models**: Defines the `Transaction` data structure and handles JSON serialization.
- **ViewModels (Providers)**: Contains all business logic, summary calculations, and data persistence logic.
- **Views**: The UI layer built with Material 3 widgets, clean separation from business logic.

## 📦 Tech Stack

- **Framework**: `Flutter`
- **State Management**: `Provider`
- **Local Storage**: `SharedPreferences`
- **Utilities**: `intl` (Date Formatting), `uuid` (Unique ID Generation)

## 📸 Design Preview

The app features a sophisticated dark theme with:
- Glassmorphism-style balance cards.
- Elevated Material 3 transaction items.
- Responsive button designs and interactive form inputs.

## 🛠️ Getting Started

### Prerequisites

- Flutter SDK Installed
- Android Studio / VS Code with Flutter extension
- An Emulator or Physical Device

### Installation

1. **Clone the repository**:
   ```bash
   git clone "https://github.com/Roman-Dewan/Expense-Tracker.git"
   ```

2. **Navigate to the project directory**:
   ```bash
   cd expense_tracker
   ```

3. **Install dependencies**:
   ```bash
   flutter pub get
   ```

4. **Run the application**:
   ```bash
   flutter run
   ```

## 📄 License

This project is open-source and available under the [MIT License](LICENSE).
