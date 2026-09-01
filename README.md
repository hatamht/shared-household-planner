# Shared Household Planner

A single-user household planning application built with Flutter. Manage shared expenses, household calendar, and shopping lists with a clean, offline-first experience.

## Features (V1.0)

- **Split Bills**: Track and manage shared household expenses
- **Shared Calendar**: Plan household events and activities
- **Shopping List**: Collaborative shopping list management

## Tech Stack

- **Framework**: Flutter 3.13.0+
- **Language**: Dart 3.1.0+
- **State Management**: BLoC (Business Logic Component)
- **Architecture**: Clean Architecture pattern
- **Database**: SQLite (local storage)
- **Testing**: Mockito + Flutter Test
- **Target Platforms**: Android, iOS (Desktop support possible)

## Prerequisites

- **Flutter SDK**: >= 3.0
- **Dart SDK**: >= 3.0
- **Android Studio** (for Android emulator) or **Xcode** (for iOS simulator)
- **Git**

## Installation

### 1. Clone the repository

```bash
git clone https://github.com/hatamht/shared-household-planner.git
cd shared-household-planner
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Generate code (if using build_runner)

```bash
flutter pub run build_runner build
```

## Running the Application

### On Android Emulator

```bash
flutter run -d emulator-5554
```

### On iOS Simulator

```bash
flutter run -d iphone
```

### On Device

```bash
flutter run
```

## Project Structure

```
lib/
├── main.dart                          # Application entry point
├── features/                          # Feature modules (Clean Architecture)
│   ├── split_bills/                   # Bill splitting feature
│   │   ├── data/                      # Data layer (repositories, models)
│   │   ├── domain/                    # Domain layer (entities, use cases)
│   │   └── presentation/              # Presentation layer (UI, BLoC)
│   ├── calendar/                      # Calendar feature
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   └── shopping_list/                 # Shopping list feature
│       ├── data/
│       ├── domain/
│       └── presentation/
├── core/                              # Shared code and utilities
│   ├── database/                      # SQLite database setup
│   ├── network/                       # Network services (if needed)
│   ├── theme/                         # App theme and styles
│   ├── constants/                     # App constants
│   └── di/                            # Dependency injection (GetIt)
test/                                  # Unit and widget tests
integration_test/                      # Integration tests
```

## Architecture Pattern

The application follows **Clean Architecture** with clear separation of concerns:

```
Presentation Layer (UI)
       ↓ (BLoC)
Domain Layer (Business Logic)
       ↓ (Use Cases)
Data Layer (Repositories, Models)
       ↓
External Layer (Database, API)
```

### Layer Responsibilities

- **Presentation**: Flutter UI, BLoC state management, widgets
- **Domain**: Business rules, entities, use cases
- **Data**: API calls, repository implementations, database models
- **External**: SQLite database, file storage

## Development Guidelines

### Code Style

- Follow Dart style guide and Flutter best practices
- Use meaningful variable and function names
- Keep functions small and focused

### State Management (BLoC)

Each feature should follow the BLoC pattern:

```
feature/
├── data/
│   ├── datasources/
│   ├── models/
│   └── repositories/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
└── presentation/
    ├── bloc/
    ├── pages/
    └── widgets/
```

### Testing

- Write unit tests for domain logic using Mockito
- Write widget tests for UI components
- Aim for at least 80% code coverage

```bash
flutter test
```

### Dependency Injection

Use `get_it` for service locator pattern:

```dart
final getIt = GetIt.instance;

void setupServiceLocator() {
  getIt.registerSingleton<Database>(SQLiteDatabase());
  getIt.registerSingleton<BillRepository>(BillRepositoryImpl());
}
```

## Git Workflow

### Commit Conventions

```bash
git add .
git commit -m "feat: add split bills feature

- Implement BLoC for bill management
- Add SQLite models for bill storage
- Create UI for bill creation"
```

### Push to Remote

```bash
git push origin <branch-name>
```

## Database Setup

The app uses SQLite for local storage. Database initialization is handled automatically on first run:

```dart
// lib/core/database/database.dart
class SQLiteDatabase {
  static Future<Database> initializeDatabase() async {
    return openDatabase(
      join(await getDatabasesPath(), 'household_planner.db'),
      onCreate: (db, version) {
        // Create tables here
      },
      version: 1,
    );
  }
}
```

## Troubleshooting

### Flutter pub get fails

```bash
flutter pub get --verbose
flutter clean
flutter pub get
```

### Build issues on fresh clone

```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### iOS specific issues

```bash
cd ios
pod install --repo-update
cd ..
flutter run
```

## Contributing

1. Create a feature branch from `main`
2. Follow the commit conventions above
3. Submit a pull request with a clear description
4. Ensure all tests pass before merging

## License

This project is private and not licensed for external distribution.

## Support & Contact

For questions or issues, contact the development team via the project board.

---

**Last Updated**: September 2026  
**Version**: 1.0.0  
**Status**: Development