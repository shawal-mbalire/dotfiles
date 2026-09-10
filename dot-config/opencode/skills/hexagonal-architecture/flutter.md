# Flutter/Dart — Hexagonal Architecture Guide

Flutter/Dart-specific setup, tooling, code examples, and testing patterns for hexagonal architecture. See [SKILL.md](./SKILL.md) for core architecture principles.

## Project Setup

### Initialize with flutter

```bash
flutter create my_project
cd my_project
mkdir -p lib/domain/models lib/domain/ports lib/domain/workflows lib/domain/errors
mkdir -p lib/infra lib/adapters
mkdir -p test/unit test/integration test/fixtures
```

### pubspec.yaml

```yaml
name: my_project
description: Hexagonal architecture Flutter app
version: 1.0.0+1
publish_to: 'none'

environment:
  sdk: '>=3.2.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  geolocator: ^13.0
  flutter_riverpod: ^2.5
  get_it: ^8.0
  http: ^1.2
  shared_preferences: ^2.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0
  mocktail: ^1.0
  integration_test:
    sdk: flutter
```

### analysis_options.yaml

```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    prefer_const_constructors: true
    prefer_const_declarations: true
    avoid_print: false
    require_trailing_commas: true
```

### Justfile

```just
set dotenv-load

default:
    @just --list

run:
    flutter run

logs:
    flutter logs

test:
    flutter test

test-unit:
    flutter test test/unit/

test-integration:
    flutter test integration_test/

test-coverage:
    flutter test --coverage
    genhtml coverage/lcov.info -o coverage/html
    open coverage/html/index.html

lint:
    flutter analyze

format:
    dart format .

build-apk:
    flutter build apk --release

build-ios:
    flutter build ios --release

clean:
    flutter clean
    rm -rf build/ .dart_tool/

get:
    flutter pub get
```

## Code Example (Location Tracking)

### Domain

```dart
// domain/models/coordinates.dart
class Coordinates {
  final double lat;
  final double lng;

  const Coordinates({required this.lat, required this.lng});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Coordinates && lat == other.lat && lng == other.lng;

  @override
  int get hashCode => lat.hashCode ^ lng.hashCode;
}

// domain/errors/location_errors.dart
class InvalidCoordinatesError implements Exception {
  final String message;
  InvalidCoordinatesError([this.message = 'Invalid coordinates']);
}

class LocationServiceDisabledError implements Exception {
  final String message;
  LocationServiceDisabledError([this.message = 'Location services disabled']);
}

// domain/ports/location_port.dart
abstract class LocationPort {
  Future<Coordinates> getCurrentLocation();
}

// domain/ports/logger_port.dart
abstract class LoggerPort {
  void info(String message);
  void error(String message);
}

// domain/ports/time_port.dart
abstract class TimePort {
  int nowMs();
  int elapsedMs(int startMs);
}

// domain/ports/storage_port.dart
abstract class StoragePort {
  Future<void> save(String key, String value);
  Future<String?> read(String key);
}

// domain/ports/lifetime_port.dart
enum ExitReason { normal, userExit, crash, timeout, shutdown }

abstract class LifetimePort {
  void registerCleanup(void Function() handler);
  void onExit(void Function(ExitReason reason) handler);
  ExitReason getExitReason();
  bool isShuttingDown();
}

// domain/workflows/track_location_workflow.dart
import '../ports/location_port.dart';
import '../ports/logger_port.dart';
import '../ports/time_port.dart';
import '../models/coordinates.dart';
import '../errors/location_errors.dart';
import '../constants.dart';

class TrackLocationWorkflow {
  final LocationPort locationPort;
  final LoggerPort logger;
  final TimePort time;

  TrackLocationWorkflow(this.locationPort, this.logger, this.time);

  Future<Coordinates> execute() async {
    final start = time.nowMs();
    logger.info('Tracking location');
    final coords = await locationPort.getCurrentLocation();
    if (coords.lat == invalidCoordinateSentinel &&
        coords.lng == invalidCoordinateSentinel) {
      throw InvalidCoordinatesError();
    }
    final elapsed = time.elapsedMs(start);
    logger.info('Location tracked in ${elapsed}ms');
    return coords;
  }
}
```

### Domain Constants Pattern

```dart
// domain/constants.dart

// Static constants: fixed business knowledge, never change per deployment
const double invalidCoordinateSentinel = 0.0;
const double degreesToRadians = 0.017453292519943295;
const double maxLatitude = 90.0;
const double maxLongitude = 180.0;
const int maxLocationHistory = 100;

// Configurable constants: injected from infra/config
class DomainConstants {
  final int maxRetryCount;
  final int requestTimeoutMs;
  final double accuracyThreshold;

  const DomainConstants({
    required this.maxRetryCount,
    required this.requestTimeoutMs,
    required this.accuracyThreshold,
  });
}

// domain/workflows/track_location_workflow.dart (using constants)
import '../constants.dart';
import '../errors/location_errors.dart';

class TrackLocationWorkflow {
  final LocationPort locationPort;
  final LoggerPort logger;

  TrackLocationWorkflow(this.locationPort, this.logger);

  Future<Coordinates> execute() async {
    final coords = await locationPort.getCurrentLocation();
    if (coords.lat == invalidCoordinateSentinel &&
        coords.lng == invalidCoordinateSentinel) {
      throw InvalidCoordinatesError();
    }
    return coords;
  }
}

// infra/config.dart (loading configurable constants)
import 'dart:io';
import '../domain/constants.dart';

class InfraConfig {
  static DomainConstants loadDomainConstants() {
    return DomainConstants(
      maxRetryCount: int.parse(Platform.environment['MAX_RETRY_COUNT'] ?? '3'),
      requestTimeoutMs: int.parse(Platform.environment['REQUEST_TIMEOUT_MS'] ?? '30000'),
      accuracyThreshold: double.parse(Platform.environment['ACCURACY_THRESHOLD'] ?? '10.0'),
    );
  }
}
```

### Infrastructure

```dart
// infra/config.dart
import 'dart:io';

class AppConfig {
  static String get geolocatorApiKey => Platform.environment['GEOLOCATOR_API_KEY'] ?? '';
  static String get logLevel => Platform.environment['LOG_LEVEL'] ?? 'info';
  static String get storageKey => Platform.environment['STORAGE_KEY'] ?? 'location_data';
}

// infra/logging.dart
import '../domain/ports/logger_port.dart';
import 'dart:developer' as developer;

class DeveloperLogger implements LoggerPort {
  @override
  void info(String message) {
    developer.log(message, level: 0);
  }

  @override
  void error(String message) {
    developer.log(message, level: 1000);
  }
}

// adapters/coordinates_mappings.dart (Pure helpers — no I/O, trivial to test)
import '../domain/models/coordinates.dart';

class CoordinatesDto {
  final double latitude;
  final double longitude;
  CoordinatesDto({required this.latitude, required this.longitude});
}

Coordinates coordinatesFromDto(CoordinatesDto dto) {
  return Coordinates(lat: dto.latitude, lng: dto.longitude);
}

CoordinatesDto coordinatesToDto(Coordinates coords) {
  return CoordinatesDto(latitude: coords.lat, longitude: coords.lng);
}

// test/unit/coordinates_mappings_test.dart (Test pure helpers — no mocks needed)
import 'package:flutter_test/flutter_test.dart';
import 'package:your_app/adapters/coordinates_mappings.dart';
import 'package:your_app/domain/models/coordinates.dart';

void main() {
  test('converts coordinates to dto', () {
    final coords = Coordinates(lat: 40.7128, lng: -74.0060);
    final dto = coordinatesToDto(coords);
    expect(dto.latitude, 40.7128);
    expect(dto.longitude, -74.0060);
  });

  test('converts dto to coordinates', () {
    final dto = CoordinatesDto(latitude: 40.7128, longitude: -74.0060);
    final coords = coordinatesFromDto(dto);
    expect(coords.lat, 40.7128);
    expect(coords.lng, -74.0060);
  });
}

// adapters/system_time_adapter.dart
import '../domain/ports/time_port.dart';

class SystemTimeAdapter implements TimePort {
  @override
  int nowMs() {
    return DateTime.now().millisecondsSinceEpoch;
  }

  @override
  int elapsedMs(int startMs) {
    return nowMs() - startMs;
  }
}

// adapters/mock_time_adapter.dart (for testing)
import '../domain/ports/time_port.dart';

class MockTimeAdapter implements TimePort {
  int _currentMs = 1000;

  @override
  int nowMs() => _currentMs;

  @override
  int elapsedMs(int startMs) => _currentMs - startMs;

  void advanceMs(int ms) => _currentMs += ms;
}

// adapters/app_lifetime_adapter.dart
import '../domain/ports/lifetime_port.dart';
import 'package:flutter/material.dart';

class AppLifetimeAdapter implements LifetimePort {
  final List<void Function()> _cleanupHandlers = [];
  final List<void Function(ExitReason)> _exitHandlers = [];
  ExitReason _exitReason = ExitReason.normal;
  bool _shuttingDown = false;

  @override
  void registerCleanup(void Function() handler) {
    _cleanupHandlers.add(handler);
  }

  @override
  void onExit(void Function(ExitReason reason) handler) {
    _exitHandlers.add(handler);
  }

  @override
  ExitReason getExitReason() => _exitReason;

  @override
  bool isShuttingDown() => _shuttingDown;

  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      _triggerExit(ExitReason.userExit);
    } else if (state == AppLifecycleState.detached) {
      _triggerExit(ExitReason.shutdown);
    }
  }

  void _triggerExit(ExitReason reason) {
    _shuttingDown = true;
    _exitReason = reason;
    for (final handler in _exitHandlers) {
      handler(reason);
    }
    for (final handler in _cleanupHandlers) {
      handler();
    }
  }
}

// adapters/mock_lifetime_adapter.dart (for testing)
import '../domain/ports/lifetime_port.dart';

class MockLifetimeAdapter implements LifetimePort {
  final List<void Function()> _cleanupHandlers = [];
  final List<void Function(ExitReason)> _exitHandlers = [];
  ExitReason _exitReason = ExitReason.normal;
  bool _shuttingDown = false;
  int cleanupCount = 0;

  @override
  void registerCleanup(void Function() handler) {
    _cleanupHandlers.add(handler);
  }

  @override
  void onExit(void Function(ExitReason reason) handler) {
    _exitHandlers.add(handler);
  }

  @override
  ExitReason getExitReason() => _exitReason;

  @override
  bool isShuttingDown() => _shuttingDown;

  void triggerExit(ExitReason reason) {
    _shuttingDown = true;
    _exitReason = reason;
    for (final handler in _exitHandlers) {
      handler(reason);
    }
    for (final handler in _cleanupHandlers) {
      handler();
      cleanupCount++;
    }
  }
}

// infra/service_locator.dart
import 'package:get_it/get_it.dart';
import '../domain/ports/location_port.dart';
import '../domain/ports/logger_port.dart';
import '../domain/ports/storage_port.dart';
import '../adapters/geolocator_adapter.dart';
import '../adapters/shared_preferences_adapter.dart';
import 'logging.dart';

final getIt = GetIt.instance;

void setupServiceLocator() {
  getIt.registerLazySingleton<LoggerPort>(() => DeveloperLogger());
  getIt.registerLazySingleton<LocationPort>(() => GeolocatorAdapter());
  getIt.registerLazySingleton<StoragePort>(() => SharedPreferencesAdapter());
}
```

### Adapters

```dart
// adapters/geolocator_adapter.dart (Driven Adapter)
import 'package:geolocator/geolocator.dart';
import '../domain/ports/location_port.dart';
import '../domain/models/coordinates.dart';
import '../errors/location_errors.dart';

class GeolocatorAdapter implements LocationPort {
  @override
  Future<Coordinates> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationServiceDisabledError();
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationServiceDisabledError('Location permission denied');
      }
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    return Coordinates(lat: position.latitude, lng: position.longitude);
  }
}

// adapters/shared_preferences_adapter.dart (Driven Adapter)
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/ports/storage_port.dart';

class SharedPreferencesAdapter implements StoragePort {
  @override
  Future<void> save(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  @override
  Future<String?> read(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }
}

// adapters/location_notifier.dart (Driving Adapter)
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/workflows/track_location_workflow.dart';
import '../domain/models/coordinates.dart';

final locationProvider = AsyncNotifierProvider<LocationNotifier, Coordinates>(
  LocationNotifier.new,
);

class LocationNotifier extends AsyncNotifier<Coordinates> {
  late final TrackLocationWorkflow _workflow;

  @override
  Future<Coordinates> build() async {
    _workflow = TrackLocationWorkflow(
      GetIt.I<LocationPort>(),
      GetIt.I<LoggerPort>(),
    );
    return await _workflow.execute();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _workflow.execute());
  }
}

// main.dart (Composition Root)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'infra/service_locator.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  setupServiceLocator();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Location Tracker')),
        body: const LocationView(),
      ),
    );
  }
}
```

## Lifecycle Hooks

### App Lifecycle

```dart
// main.dart
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Startup: initialize adapters
  final repo = FirestoreDocumentAdapter(projectId: config.projectId);

  // Register cleanup
  WidgetsBinding.instance.addObserver(AppLifecycleObserver(repo));

  runApp(MyApp(repo: repo));
}

class AppLifecycleObserver extends WidgetsBindingObserver {
  final FirestoreDocumentAdapter repo;

  AppLifecycleObserver(this.repo);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      // App going to background — flush pending writes
      repo.flush();
    }
    if (state == AppLifecycleState.detached) {
      // App being terminated — close connections
      repo.disconnect();
    }
  }
}
```

### Riverpod Lifecycle

```dart
// adapters/firestore_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firestoreProvider = Provider<FirestoreDocumentAdapter>((ref) {
  final adapter = FirestoreDocumentAdapter(projectId: 'my-project');

  // Cleanup when provider is disposed
  ref.onDispose(() {
    adapter.disconnect();
  });

  return adapter;
});
```

## Hard-Fail Patterns

```dart
// BAD: soft fail — returns null, hides the error
try {
  final result = await createDocument(content, repo, logger);
  return result;
} catch (_) {
  return null;
}

// GOOD: hard fail — throws with context
final result = await createDocument(content, repo, logger); // Throws on error

// BAD: generic assertion
expect(result, expected);

// GOOD: specific assertion with description
expect(result.status, DocumentStatus.PUBLISHED,
    reason: 'Expected PUBLISHED, got ${result.status}');

// BAD: generic exception
throw Exception('Invalid input');

// GOOD: specific error
throw EmptyContentError('Document content cannot be empty');
```

## Pure Functions in Domain

Domain workflows should be pure functions: same input → same output, no side effects. I/O happens in adapters only.

```dart
// BAD: impure — depends on external state
double calculateTotal(Cart cart) {
  final taxRate = getTaxRateFromDb(); // Hidden dependency!
  return cart.subtotal * (1 + taxRate);
}

// GOOD: pure — all dependencies injected
double calculateTotal(Cart cart, double taxRate) {
  return cart.subtotal * (1 + taxRate);
}

// Testing pure functions is trivial
test('calculates total with tax', () {
  final cart = Cart(subtotal: 20.0);
  expect(calculateTotal(cart, 0.08), 21.6);
});

test('calculates total with zero tax', () {
  final cart = Cart(subtotal: 20.0);
  expect(calculateTotal(cart, 0.0), 20.0);
});
// No mocks, no setup, no database — just input → output
```

## Structured Logging

```dart
// adapters/structured_logger.dart
import 'dart:convert';
import '../domain/ports/logger_port.dart';

class StructuredLogger implements LoggerPort {
  String? _requestId;

  void setRequestId(String id) => _requestId = id;

  @override
  void info(String event, {Map<String, dynamic>? data}) {
    print(jsonEncode({
      'level': 'info',
      'request_id': _requestId,
      'event': event,
      ...?data,
      'timestamp': DateTime.now().toIso8601String(),
    }));
  }

  @override
  void error(String event, {Map<String, dynamic>? data}) {
    print(jsonEncode({
      'level': 'error',
      'request_id': _requestId,
      'event': event,
      ...?data,
      'timestamp': DateTime.now().toIso8601String(),
    }));
  }
}

// Usage in adapters
logger.info('location_fetched', data: {'lat': coords.lat, 'lng': coords.lng});
logger.error('location_fetch_failed', data: {'error': e.toString()});
```

## Testing

### Shared Fixtures

```dart
// test/fixtures/fakes.dart
import 'package:your_app/domain/ports/location_port.dart';
import 'package:your_app/domain/ports/logger_port.dart';
import 'package:your_app/domain/ports/storage_port.dart';
import 'package:your_app/domain/models/coordinates.dart';

class FakeLocationPort implements LocationPort {
  Coordinates? locationToReturn;
  int getCurrentLocationCount = 0;
  Object? thrownError;

  @override
  Future<Coordinates> getCurrentLocation() async {
    getCurrentLocationCount++;
    if (thrownError != null) throw thrownError!;
    return locationToReturn ?? const Coordinates(lat: 0, lng: 0);
  }

  void reset() {
    locationToReturn = null;
    getCurrentLocationCount = 0;
    thrownError = null;
  }
}

class FakeLoggerPort implements LoggerPort {
  final List<String> messages = [];
  int infoCount = 0;
  int errorCount = 0;

  @override
  void info(String message) {
    messages.add('[INFO] $message');
    infoCount++;
  }

  @override
  void error(String message) {
    messages.add('[ERROR] $message');
    errorCount++;
  }

  void reset() {
    messages.clear();
    infoCount = 0;
    errorCount = 0;
  }
}

class FakeTimePort implements TimePort {
  int _currentMs = 1000;

  @override
  int nowMs() => _currentMs;

  @override
  int elapsedMs(int startMs) => _currentMs - startMs;

  void advanceMs(int ms) => _currentMs += ms;

  void reset() => _currentMs = 1000;
}

class FakeStoragePort implements StoragePort {
  final Map<String, String> data = {};

  @override
  Future<void> save(String key, String value) async {
    data[key] = value;
  }

  @override
  Future<String?> read(String key) async {
    return data[key];
  }
}

// test/fixtures/factories.dart
import 'package:your_app/domain/models/coordinates.dart';

class CoordinatesFactory {
  static Coordinates create({double lat = 40.7128, double lng = -74.0060}) {
    return Coordinates(lat: lat, lng: lng);
  }

  static Coordinates createInvalid() {
    return const Coordinates(lat: 0, lng: 0);
  }

  static Coordinates createRandom() {
    return Coordinates(
      lat: 40.0 + (DateTime.now().millisecond / 100),
      lng: -74.0 + (DateTime.now().millisecond / 100),
    );
  }
}
```

### Unit Tests

```dart
// test/unit/track_location_workflow_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:your_app/domain/workflows/track_location_workflow.dart';
import 'package:your_app/domain/errors/location_errors.dart';
import 'package:your_app/fixtures/fixtures.dart';

void main() {
  group('TrackLocationWorkflow', () {
    late FakeLocationPort locationPort;
    late FakeLoggerPort logger;
    late FakeTimePort time;
    late TrackLocationWorkflow workflow;

    setUp(() {
      locationPort = FakeLocationPort();
      logger = FakeLoggerPort();
      time = FakeTimePort();
      workflow = TrackLocationWorkflow(locationPort, logger, time);
    });

    tearDown(() {
      locationPort.reset();
      logger.reset();
      time.reset();
    });

    test('returns coordinates when valid', () async {
      locationPort.locationToReturn = CoordinatesFactory.create(
        lat: 40.7128,
        lng: -74.0060,
      );

      final result = await workflow.execute();

      expect(result.lat, 40.7128);
      expect(result.lng, -74.0060);
      expect(logger.infoCount, 2);
      expect(locationPort.getCurrentLocationCount, 1);
    });

    test('throws exception for zero coordinates', () async {
      locationPort.locationToReturn = CoordinatesFactory.createInvalid();

      expect(
        () => workflow.execute(),
        throwsA(isA<InvalidCoordinatesError>()),
      );
    });

    test('logs tracking message', () async {
      locationPort.locationToReturn = CoordinatesFactory.create();

      await workflow.execute();

      expect(logger.messages.length, 1);
      expect(logger.messages.first, contains('Tracking location'));
    });

    test('propagates location service errors', () async {
      locationPort.thrownError = Exception('GPS unavailable');

      expect(
        () => workflow.execute(),
        throwsA(isA<Exception>()),
      );
    });
  });
}
```

### Integration Tests

```dart
// integration_test/location_flow_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:your_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Location Flow E2E', () {
    testWidgets('fetches and displays location', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Verify location is displayed
      expect(find.text('Tracking location'), findsOneWidget);

      // Wait for location to load
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify coordinates are shown
      expect(find.byType(CoordinatesDisplay), findsOneWidget);
    });

    testWidgets('handles location permission denied', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Verify error state is shown
      expect(find.text('Location permission denied'), findsOneWidget);
    });
  });
}
```

### E2E Tests

```dart
// test/e2e/location_workflow_e2e_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:your_app/domain/workflows/track_location_workflow.dart';
import 'package:your_app/fixtures/fixtures.dart';

void main() {
  group('Location Workflow E2E', () {
    late FakeLocationPort locationPort;
    late FakeLoggerPort logger;
    late TrackLocationWorkflow workflow;

    setUp(() {
      locationPort = FakeLocationPort();
      logger = FakeLoggerPort();
      workflow = TrackLocationWorkflow(locationPort, logger);
    });

    test('completes full location tracking flow', () async {
      // Setup
      locationPort.locationToReturn = CoordinatesFactory.create(
        lat: 37.7749,
        lng: -122.4194,
      );

      // Execute workflow
      final result = await workflow.execute();

      // Verify result
      expect(result.lat, 37.7749);
      expect(result.lng, -122.4194);

      // Verify logging
      expect(logger.infoCount, 1);
      expect(logger.messages.first, contains('Tracking location'));

      // Verify adapter was called exactly once
      expect(locationPort.getCurrentLocationCount, 1);
    });

    test('handles multiple sequential location fetches', () async {
      // First fetch
      locationPort.locationToReturn = CoordinatesFactory.create(lat: 40.0, lng: -74.0);
      final result1 = await workflow.execute();
      expect(result1.lat, 40.0);

      // Second fetch with different location
      locationPort.locationToReturn = CoordinatesFactory.create(lat: 34.0, lng: -118.0);
      final result2 = await workflow.execute();
      expect(result2.lat, 34.0);

      // Verify both were logged
      expect(logger.infoCount, 2);
    });
  });
}
```
