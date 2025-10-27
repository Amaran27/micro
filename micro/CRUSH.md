# Micro Flutter App Development Guide

## Build Commands
- `flutter pub get` - Install dependencies
- `flutter run` - Run app in debug mode
- `flutter build apk` - Build Android APK
- `build_android.bat` - Build debug APK and install/launch on device
- `install_apk.bat` - Install existing APK on connected device

## Testing Commands
- `flutter test` - Run all tests
- `flutter test test/widget_test.dart` - Run single test file
- `flutter test --coverage` - Generate coverage report
- `flutter test integration_test/` - Run integration tests

## Code Style Guidelines

### Import Organization
Group imports in this order:
1. Flutter/Dart SDK imports
2. External package imports  
3. Local package imports

### Naming Conventions
- **Classes**: PascalCase (e.g., `MicroApp`, `PermissionAuditor`)
- **Variables/Methods**: camelCase (e.g., `appRouter`, `initialize()`)
- **Constants**: SCREAMING_SNAKE_CASE (e.g., `APP_NAME`)
- **Files**: snake_case (e.g., `app_theme.dart`)

### Code Structure
- Follow Clean Architecture: lib/presentation/, lib/domain/, lib/data/, lib/infrastructure/
- Feature-based organization in lib/features/
- Use Riverpod for state management, Go Router for navigation
- 80-character line length (configured in flutter_gen)

### Model Classes
- Use `@JsonSerializable()` for JSON serialization
- Include `part` directives for generated files
- Extend Equatable for value equality
- Include proper `toString()` overrides

### Error Handling
- Use custom exceptions in lib/core/exceptions/
- Handle async errors with try-catch blocks
- Log errors using the centralized logger

### Dependencies
- Minimum Flutter 3.35.0+, Dart 3.9.0+
- Use flutter_lints for code quality
- Run code generation: `dart run build_runner build`