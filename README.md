# Shared Expense Splitter

A lightweight **Flutter** Android app for tracking shared household expenses with roommates or friends.

Perfect for personal use — enter expenses, see who paid, and get a clear balance summary. Everything is stored **locally** on the device. No accounts, no backend, no cloud sync.

---

## Features

- **Dashboard** – Group name, total expenses, and simple balance overview
- **People** – Add / remove participants by name
- **Add Expense** – Title, amount, payer, and selected participants (equal split)
- **Expense History** – List of all expenses with delete option
- Local persistence (data survives app restarts)
- Clean, neutral Material Design UI
- Amounts always shown with two decimal places

---

## Screens

1. **Dashboard** – Overview of total shared expenses and per-person balances  
2. **People** – Manage the list of participants  
3. **Add Expense** – Create a new shared expense  
4. **Expense History** – View and delete past expenses  

---

## Tech Stack

- **Flutter** + **Dart**
- **shared_preferences** for local storage
- **uuid** for unique IDs
- **intl** for date formatting
- Material 3 design
- Android only (as scoped)

---

## Getting Started

### Prerequisites

- Flutter SDK (3.16 or later recommended)
- Android Studio / VS Code with Flutter extensions
- An Android device or emulator

### Setup

```bash
# Clone the repository
git clone https://github.com/zunaidhasan/shared-expense-splitter.git
cd shared-expense-splitter

# If platform folders are missing (android/), generate them:
flutter create . --platforms=android

# Get dependencies
flutter pub get

# Run on a connected device or emulator
flutter run
```

### Build a release APK

```bash
flutter build apk --release
```

The APK will be available at:  
`build/app/outputs/flutter-apk/app-release.apk`

---

## Project Structure

```
lib/
├── main.dart                 # App entry point + theme
├── models/
│   ├── person.dart           # Participant model
│   └── expense.dart          # Expense model
├── services/
│   └── storage_service.dart  # Local persistence + balance calculation
└── screens/
    ├── home_screen.dart      # Bottom navigation host
    ├── dashboard_screen.dart # Totals + balances
    ├── people_screen.dart    # Add / remove participants
    ├── add_expense_screen.dart # Create new expense
    └── history_screen.dart   # Expense list + delete
```

---

## How Balances Work

- Each expense is split **equally** among the selected participants.
- The person who paid is credited the full amount.
- The balance for each person = (amount they paid) − (their share of all expenses they participated in).
- **Positive balance** = others owe them money.
- **Negative balance** = they owe money to the group.

---

## Scope & Limitations

This is a small **personal-use MVP**. It intentionally does **not** include:

- Multiple groups
- Cloud synchronization / multi-device access
- User accounts or authentication
- Payment transfers or bank connections
- Receipt scanning
- Currency conversion
- Complex charts or debt settlement optimization
- iOS support / App Store publishing

---

## License

This project was created as a freelance deliverable. You are free to use and modify the source code for personal or commercial purposes.

---

**Built with Flutter** 💙
