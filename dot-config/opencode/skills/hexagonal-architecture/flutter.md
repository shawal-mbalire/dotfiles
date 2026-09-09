# Flutter/Dart — Hexagonal Architecture Guide

Flutter/Dart-specific code examples and patterns for hexagonal architecture. See [SKILL.md](./SKILL.md) for core architecture principles.

## Platform Justfile

```just
# flutter-app/justfile
set dotenv-load

run:
    flutter run

logs:
    flutter logs

test:
    flutter test

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

test-integration:
    flutter test integration_test/
```

## Code Example (Location Tracking)

```dart
// domain/models/Coordinates.dart
class Coordinates {
  final double lat;
  final double lng;
  Coordinates({required this.lat, required this.lng});
}

// domain/constants.dart
const double invalidCoordinateSentinel = 0.0;
const double degreesToRadians = 0.017453292519943295;
const double maxLatitude = 90.0;
const double maxLongitude = 180.0;

// domain/ports/LocationPort.dart
abstract class LocationPort {
  Future<Coordinates> getCurrentLocation();
}

// domain/ports/LoggerPort.dart
abstract class LoggerPort {
  void info(String message);
  void error(String message);
}

// domain/workflows/TrackLocationWorkflow.dart
import '../ports/LocationPort.dart';
import '../ports/LoggerPort.dart';
import '../models/Coordinates.dart';
import '../constants.dart';

class TrackLocationWorkflow {
  final LocationPort locationPort;
  final LoggerPort logger;

  TrackLocationWorkflow(this.locationPort, this.logger);

  Future<Coordinates> execute() async {
    logger.info('Tracking location');
    final coords = await locationPort.getCurrentLocation();
    if (coords.lat == invalidCoordinateSentinel &&
        coords.lng == invalidCoordinateSentinel) {
      throw Exception('Invalid coordinates');
    }
    return coords;
  }
}

// infra/config.dart
import 'dart:io';

class AppConfig {
  static String get geolocatorApiKey => Platform.environment['GEOLOCATOR_API_KEY'] ?? '';
  static String get logLevel => Platform.environment['LOG_LEVEL'] ?? 'info';
}

// infra/logging.dart
import '../domain/ports/LoggerPort.dart';
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

// adapters/GeolocatorAdapter.dart (Driven Adapter)
import 'package:geolocator/geolocator.dart';
import '../domain/ports/LocationPort.dart';
import '../domain/models/Coordinates.dart';

class GeolocatorAdapter implements LocationPort {
  @override
  Future<Coordinates> getCurrentLocation() async {
    final pos = await Geolocator.getCurrentPosition();
    return Coordinates(lat: pos.latitude, lng: pos.longitude);
  }
}

// adapters/LocationNotifier.dart (Driving Adapter)
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/workflows/TrackLocationWorkflow.dart';
import '../domain/models/Coordinates.dart';

final locationProvider = AsyncNotifierProvider<LocationNotifier, Coordinates>(LocationNotifier.new);

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

## Structured Logging

```dart
// adapters/structured_logger.dart
import 'dart:convert';
import '../domain/ports/LoggerPort.dart';

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
    stderr.writeln(jsonEncode({
      'level': 'error',
      'request_id': _requestId,
      'event': event,
      ...?data,
      'timestamp': DateTime.now().toIso8601String(),
    }));
  }
}
```

## Testing

### Shared Fixtures

```dart
// test/fixtures/fakes.dart
import 'package:your_app/domain/ports/LocationPort.dart';
import 'package:your_app/domain/ports/LoggerPort.dart';
import 'package:your_app/domain/models/Coordinates.dart';

class FakeLocationPort implements LocationPort {
  Coordinates? locationToReturn;
  int getCurrentLocationCount = 0;

  @override
  Future<Coordinates> getCurrentLocation() async {
    getCurrentLocationCount++;
    return locationToReturn ?? Coordinates(lat: 0, lng: 0);
  }

  void reset() {
    locationToReturn = null;
    getCurrentLocationCount = 0;
  }
}

class FakeLoggerPort implements LoggerPort {
  final List<String> messages = [];
  int infoCount = 0;

  @override
  void info(String message) {
    messages.add('[INFO] $message');
    infoCount++;
  }

  @override
  void error(String message) => messages.add('[ERROR] $message');

  void reset() {
    messages.clear();
    infoCount = 0;
  }
}

// test/fixtures/factories.dart
import 'package:your_app/domain/models/Coordinates.dart';

class CoordinatesFactory {
  static Coordinates create({double lat = 40.7128, double lng = -74.0060}) {
    return Coordinates(lat: lat, lng: lng);
  }

  static Coordinates createInvalid() {
    return Coordinates(lat: 0, lng: 0);
  }
}
```

### Unit Tests

```dart
// test/unit/track_location_use_case_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:your_app/domain/workflows/TrackLocationWorkflow.dart';
import 'package:your_app/fixtures/fixtures.dart';

void main() {
  group('TrackLocationWorkflow', () {
    late FakeLocationPort locationPort;
    late FakeLoggerPort logger;
    late TrackLocationWorkflow workflow;

    setUp(() {
      locationPort = FakeLocationPort();
      logger = FakeLoggerPort();
      workflow = TrackLocationWorkflow(locationPort, logger);
    });

    tearDown(() {
      locationPort.reset();
      logger.reset();
    });

    test('returns coordinates when valid', () async {
      locationPort.locationToReturn = CoordinatesFactory.create(
        lat: 40.7128,
        lng: -74.0060,
      );

      final result = await workflow.execute();

      expect(result.lat, 40.7128);
      expect(result.lng, -74.0060);
      expect(logger.infoCount, 1);
      expect(locationPort.getCurrentLocationCount, 1);
    });

    test('throws exception for zero coordinates', () async {
      locationPort.locationToReturn = CoordinatesFactory.createInvalid();

      expect(() => workflow.execute(), throwsException);
    });

    test('logs tracking message', () async {
      locationPort.locationToReturn = CoordinatesFactory.create();

      await workflow.execute();

      expect(logger.messages.length, 1);
      expect(logger.messages.first, contains('Tracking location'));
    });
  });
}
```
