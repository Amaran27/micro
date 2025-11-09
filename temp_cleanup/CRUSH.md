# Micro Flutter Development Guide

## Commands

### Build & Development
```bash
# Install dependencies
flutter pub get

# Run code generation (JSON serialization, etc.)
dart run build_runner build

# Run the app
flutter run

# Build for release (Android)
flutter build apk --release

# Build for iOS (macOS only)
flutter build ios --release
```

### Testing & Analysis
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/widget_test.dart

# Run tests with coverage
flutter test --coverage

# Static analysis
flutter analyze

# Lint checking
dart analyze --fatal-infos
```

## Code Style Guidelines

### Dart/Flutter Conventions
- Use `flutter_lints` for code style compliance
- Prefer single quotes for strings
- Use camelCase for variables and functions
- Use PascalCase for classes and types
- Use snake_case for files and directories
- Order imports: dart, flutter, third-party, local
- Use final wherever possible
- Prefer const for compile-time constants

### Architecture Patterns
- Follow Clean Architecture: domain/presentation/infrastructure/data layers
- Use Riverpod for state management with ConsumerWidget/ConsumerStatefulWidget
- Implement interfaces for all major services (I prefixed)
- Use Repository pattern for data access
- Place business logic in use cases

### Error Handling
- Use custom exceptions extending AppException
- Log errors with logger instance
- Never use print() - use logger instead
- Handle async errors with try-catch blocks
- Use Result types for operations that can fail

### Testing Standards
- Write unit tests for business logic
- Use widget tests for UI components
- Mock dependencies with mocktail
- Test coverage target: >80%
- Arrange-Act-Assert pattern in tests

### Security & Performance
- Use flutter_secure_storage for sensitive data
- Validate all user inputs
- Implement proper permission handling
- Optimize for battery and memory usage
- Use workmanager for background tasks