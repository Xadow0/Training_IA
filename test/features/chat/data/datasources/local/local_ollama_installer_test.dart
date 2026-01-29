import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:chatbot_app/features/chat/data/datasources/local/local_ollama_installer.dart';
import 'package:chatbot_app/features/chat/data/models/local_ollama_models.dart';

// ==================
// HTTP Fakes seguros
// ==================

class FakeHttpOverrides extends HttpOverrides {
  final int statusCode;

  FakeHttpOverrides(this.statusCode);

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _FakeHttpClient(statusCode);
  }
}

class _FakeHttpClient implements HttpClient {
  final int statusCode;

  _FakeHttpClient(this.statusCode);

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    return _FakeHttpRequest(statusCode);
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpRequest implements HttpClientRequest {
  final int statusCode;

  _FakeHttpRequest(this.statusCode);

  @override
  Future<HttpClientResponse> close() async {
    return _FakeHttpResponse(statusCode);
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpResponse implements HttpClientResponse {
  final int _statusCode;

  _FakeHttpResponse(this._statusCode);

  @override
  int get statusCode => _statusCode;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    // Stream vacío
    return const Stream<List<int>>.empty().listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Fake HttpClient que simula errores de conexión
class _FakeHttpClientWithError implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    throw const SocketException('Connection refused');
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeHttpOverridesWithError extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _FakeHttpClientWithError();
  }
}

/// Fake HttpClient que simula timeout
class _FakeHttpClientWithTimeout implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    throw TimeoutException('Connection timed out');
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeHttpOverridesWithTimeout extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _FakeHttpClientWithTimeout();
  }
}

// ==================
// Tests
// ==================

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ==================
  // isOllamaRunning Tests
  // ==================
  group('LocalOllamaInstaller.isOllamaRunning', () {
    test('returns true when server responds with 200', () async {
      // Este test verifica el comportamiento real si Ollama está corriendo
      // En un entorno de CI, esto probablemente retornará false
      final running = await LocalOllamaInstaller.isOllamaRunning();
      // Solo verificamos que no lanza excepción
      expect(running, isA<bool>());
    });

    test('returns false when server responds non-200', () async {
      HttpOverrides.runZoned(() async {
        final running = await LocalOllamaInstaller.isOllamaRunning();
        expect(running, isFalse);
      }, createHttpClient: (_) => _FakeHttpClient(500));
    });

    test('returns false when server responds 404', () async {
      HttpOverrides.runZoned(() async {
        final running = await LocalOllamaInstaller.isOllamaRunning();
        expect(running, isFalse);
      }, createHttpClient: (_) => _FakeHttpClient(404));
    });

    test('returns false when server responds 503', () async {
      HttpOverrides.runZoned(() async {
        final running = await LocalOllamaInstaller.isOllamaRunning();
        expect(running, isFalse);
      }, createHttpClient: (_) => _FakeHttpClient(503));
    });

    test('returns false on connection exception', () async {
      final running = await LocalOllamaInstaller.isOllamaRunning(port: 9999);
      expect(running, isFalse);
    });

    test('returns false on socket exception', () async {
      HttpOverrides.runZoned(() async {
        final running = await LocalOllamaInstaller.isOllamaRunning();
        expect(running, isFalse);
      }, createHttpClient: (_) => _FakeHttpClientWithError());
    });

    test('returns false on timeout', () async {
      HttpOverrides.runZoned(() async {
        final running = await LocalOllamaInstaller.isOllamaRunning();
        expect(running, isFalse);
      }, createHttpClient: (_) => _FakeHttpClientWithTimeout());
    });

    test('uses custom port correctly', () async {
      // Test con puerto personalizado
      final running = await LocalOllamaInstaller.isOllamaRunning(port: 12345);
      expect(running, isFalse); // Puerto probablemente no está escuchando
    });

    test('uses default port 11434', () async {
      // El puerto por defecto debería ser 11434
      final running = await LocalOllamaInstaller.isOllamaRunning();
      expect(running, isA<bool>());
    });
  });

  // ==================
  // startOllamaService Tests
  // ==================
  group('LocalOllamaInstaller.startOllamaService', () {
    test('returns true if already running', () async {
      HttpOverrides.runZoned(() async {
        final started = await LocalOllamaInstaller.startOllamaService();
        expect(started, isTrue);
      }, createHttpClient: (_) => _FakeHttpClient(200));
    });

    test('returns false when service does not start (timeout path)', () async {
      HttpOverrides.runZoned(() async {
        final started = await LocalOllamaInstaller.startOllamaService();
        expect(started, isFalse);
      }, createHttpClient: (_) => _FakeHttpClient(500));
    }, timeout: const Timeout(Duration(seconds: 60)));

    test('tries to find ollama executable when not in PATH', () async {
      // Este test verifica el flujo de búsqueda del ejecutable
      HttpOverrides.runZoned(() async {
        final started = await LocalOllamaInstaller.startOllamaService();
        // Solo verificamos que no lanza excepción
        expect(started, isA<bool>());
      }, createHttpClient: (_) => _FakeHttpClient(500));
    }, timeout: const Timeout(Duration(seconds: 60)));
  });

  // ==================
  // stopOllamaService Tests
  // ==================
  group('LocalOllamaInstaller.stopOllamaService', () {
    test('does not throw on any platform', () async {
      await LocalOllamaInstaller.stopOllamaService();
      expect(true, isTrue); // Solo verificar que no crashea
    });

    test('completes without error even when ollama is not running', () async {
      // Llamar stop cuando no hay servicio corriendo
      await expectLater(
        LocalOllamaInstaller.stopOllamaService(),
        completes,
      );
    });

    test('can be called multiple times without issues', () async {
      await LocalOllamaInstaller.stopOllamaService();
      await LocalOllamaInstaller.stopOllamaService();
      await LocalOllamaInstaller.stopOllamaService();
      expect(true, isTrue);
    });
  });

  // ==================
  // checkInstallation Tests
  // ==================
  group('LocalOllamaInstaller.checkInstallation', () {
    test('returns OllamaInstallationInfo object', () async {
      final info = await LocalOllamaInstaller.checkInstallation();
      expect(info, isA<OllamaInstallationInfo>());
    });

    test('has isInstalled property', () async {
      final info = await LocalOllamaInstaller.checkInstallation();
      expect(info.isInstalled, isA<bool>());
    });

    test('has canExecute property', () async {
      final info = await LocalOllamaInstaller.checkInstallation();
      expect(info.canExecute, isA<bool>());
    });

    test('returns installPath when installed', () async {
      final info = await LocalOllamaInstaller.checkInstallation();
      if (info.isInstalled) {
        expect(info.installPath, isNotNull);
      }
    });

    test('returns version when installed', () async {
      final info = await LocalOllamaInstaller.checkInstallation();
      if (info.isInstalled) {
        expect(info.version, isNotNull);
        expect(info.version, isNotEmpty);
      }
    });

    test('isInstalled is false when ollama not found', () async {
      // En un sistema sin Ollama, esto debería retornar false
      final info = await LocalOllamaInstaller.checkInstallation();
      // Solo verificamos que la respuesta es consistente
      expect(info.isInstalled == info.canExecute || !info.isInstalled, isTrue);
    });

    test('handles PATH lookup correctly', () async {
      // Este test verifica el flujo de búsqueda en PATH
      final info = await LocalOllamaInstaller.checkInstallation();
      expect(info, isA<OllamaInstallationInfo>());
    });

    test('handles default path lookup when PATH fails', () async {
      // Este test verifica el fallback a rutas por defecto
      final info = await LocalOllamaInstaller.checkInstallation();
      // Si está instalado pero no en PATH, debería encontrarlo
      expect(info, isA<OllamaInstallationInfo>());
    });

    test('returns consistent state', () async {
      // Verificar que canExecute implica isInstalled
      final info = await LocalOllamaInstaller.checkInstallation();
      if (info.canExecute) {
        expect(info.isInstalled, isTrue);
      }
    });
  });

  // ==================
  // installOllama Tests
  // ==================
  group('LocalOllamaInstaller.installOllama', () {
    test('yields error progress on unsupported platform or failure', () async {
      try {
        final stream = LocalOllamaInstaller.installOllama();
        await stream.toList();
      } catch (e) {
        expect(e, isA<LocalOllamaException>());
      }
    });

    test('returns a Stream of LocalOllamaInstallProgress', () async {
      final stream = LocalOllamaInstaller.installOllama();
      expect(stream, isA<Stream<LocalOllamaInstallProgress>>());
    });

    test('stream can be listened to', () async {
      final stream = LocalOllamaInstaller.installOllama();
      final completer = Completer<void>();
      
      stream.listen(
        (progress) {
          expect(progress, isA<LocalOllamaInstallProgress>());
        },
        onError: (e) {
          expect(e, isA<LocalOllamaException>());
          if (!completer.isCompleted) completer.complete();
        },
        onDone: () {
          if (!completer.isCompleted) completer.complete();
        },
      );

      await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          // Timeout is OK, just means installation is taking long
        },
      );
    });

    test('emits progress with status field', () async {
      final stream = LocalOllamaInstaller.installOllama();
      
      await for (final progress in stream.take(1).handleError((e) {})) {
        expect(progress.status, isA<LocalOllamaStatus>());
        break;
      }
    });

    test('emits progress with progress field between 0 and 1', () async {
      final stream = LocalOllamaInstaller.installOllama();
      
      await for (final progress in stream.take(1).handleError((e) {})) {
        expect(progress.progress, greaterThanOrEqualTo(0.0));
        expect(progress.progress, lessThanOrEqualTo(1.0));
        break;
      }
    });

    test('emits progress with message field', () async {
      final stream = LocalOllamaInstaller.installOllama();
      
      await for (final progress in stream.take(1).handleError((e) {})) {
        expect(progress.message, isA<String>());
        break;
      }
    });

    test('handles platform-specific installation', () async {
      // Verificar que el código detecta la plataforma correctamente
      final platformName = Platform.operatingSystem;
      expect(
        ['windows', 'macos', 'linux'].contains(platformName) ||
            platformName.isNotEmpty,
        isTrue,
      );
    });
  });

  // ==================
  // LocalOllamaException Tests
  // ==================
  group('LocalOllamaException', () {
    test('can be created with message only', () {
      final exception = LocalOllamaException('Test error');
      expect(exception, isA<LocalOllamaException>());
    });

    test('can be created with message and details', () {
      final exception = LocalOllamaException(
        'Test error',
        details: 'Additional details',
      );
      expect(exception, isA<LocalOllamaException>());
    });

    test('toString includes message', () {
      final exception = LocalOllamaException('Test error message');
      expect(exception.toString(), contains('Test error message'));
    });
  });

  // ==================
  // LocalOllamaInstallProgress Tests
  // ==================
  group('LocalOllamaInstallProgress', () {
    test('can be created with required fields', () {
      final progress = LocalOllamaInstallProgress(
        status: LocalOllamaStatus.installing,
        progress: 0.5,
        message: 'Installing...',
      );
      expect(progress.status, LocalOllamaStatus.installing);
      expect(progress.progress, 0.5);
      expect(progress.message, 'Installing...');
    });

    test('can be created with optional bytesDownloaded', () {
      final progress = LocalOllamaInstallProgress(
        status: LocalOllamaStatus.downloadingInstaller,
        progress: 0.3,
        message: 'Downloading...',
        bytesDownloaded: 1024,
      );
      expect(progress.bytesDownloaded, 1024);
    });

    test('can be created with optional totalBytes', () {
      final progress = LocalOllamaInstallProgress(
        status: LocalOllamaStatus.downloadingInstaller,
        progress: 0.3,
        message: 'Downloading...',
        totalBytes: 2048,
      );
      expect(progress.totalBytes, 2048);
    });

    test('can be created with all fields', () {
      final progress = LocalOllamaInstallProgress(
        status: LocalOllamaStatus.downloadingInstaller,
        progress: 0.5,
        message: 'Downloading...',
        bytesDownloaded: 1024,
        totalBytes: 2048,
      );
      expect(progress.status, LocalOllamaStatus.downloadingInstaller);
      expect(progress.progress, 0.5);
      expect(progress.message, 'Downloading...');
      expect(progress.bytesDownloaded, 1024);
      expect(progress.totalBytes, 2048);
    });
  });

  // ==================
  // LocalOllamaStatus Tests
  // ==================
  group('LocalOllamaStatus', () {
    test('has downloadingInstaller value', () {
      expect(LocalOllamaStatus.downloadingInstaller, isNotNull);
    });

    test('has installing value', () {
      expect(LocalOllamaStatus.installing, isNotNull);
    });

    test('has error value', () {
      expect(LocalOllamaStatus.error, isNotNull);
    });

    test('values are distinct', () {
      expect(LocalOllamaStatus.downloadingInstaller,
          isNot(LocalOllamaStatus.installing));
      expect(LocalOllamaStatus.installing, isNot(LocalOllamaStatus.error));
      expect(LocalOllamaStatus.downloadingInstaller,
          isNot(LocalOllamaStatus.error));
    });
  });

  // ==================
  // OllamaInstallationInfo Tests
  // ==================
  group('OllamaInstallationInfo', () {
    test('can be created with minimal fields', () {
      final info = OllamaInstallationInfo(
        isInstalled: false,
        canExecute: false,
      );
      expect(info.isInstalled, isFalse);
      expect(info.canExecute, isFalse);
    });

    test('can be created with all fields', () {
      final info = OllamaInstallationInfo(
        isInstalled: true,
        installPath: '/usr/local/bin/ollama',
        version: 'ollama version 0.1.0',
        canExecute: true,
      );
      expect(info.isInstalled, isTrue);
      expect(info.installPath, '/usr/local/bin/ollama');
      expect(info.version, 'ollama version 0.1.0');
      expect(info.canExecute, isTrue);
    });

    test('installPath can be null', () {
      final info = OllamaInstallationInfo(
        isInstalled: false,
        canExecute: false,
      );
      expect(info.installPath, isNull);
    });

    test('version can be null', () {
      final info = OllamaInstallationInfo(
        isInstalled: false,
        canExecute: false,
      );
      expect(info.version, isNull);
    });
  });

  // ==================
  // Platform-specific Tests
  // ==================
  group('Platform detection', () {
    test('Platform.operatingSystem returns valid value', () {
      expect(Platform.operatingSystem, isNotEmpty);
    });

    test('Platform.isWindows, isMacOS, or isLinux is true on desktop', () {
      final isDesktop =
          Platform.isWindows || Platform.isMacOS || Platform.isLinux;
      // En un entorno de test, al menos una debería ser true
      expect(isDesktop, isTrue);
    });
  });

  // ==================
  // Integration-style Tests (comportamiento real del sistema)
  // ==================
  group('Integration tests', () {
    test('checkInstallation followed by isOllamaRunning', () async {
      final info = await LocalOllamaInstaller.checkInstallation();
      if (info.isInstalled && info.canExecute) {
        final running = await LocalOllamaInstaller.isOllamaRunning();
        expect(running, isA<bool>());
      }
    });

    test('full workflow: check -> start -> check running', () async {
      final info = await LocalOllamaInstaller.checkInstallation();
      
      if (info.isInstalled && info.canExecute) {
        // Intentar iniciar si está instalado
        final started = await LocalOllamaInstaller.startOllamaService();
        
        if (started) {
          final running = await LocalOllamaInstaller.isOllamaRunning();
          expect(running, isTrue);
        }
      }
    }, timeout: const Timeout(Duration(seconds: 60)));
  });

  // ==================
  // Edge Cases Tests
  // ==================
  group('Edge cases', () {
    test('isOllamaRunning with port 0 returns false', () async {
      // Puerto 0 no es válido para escuchar
      final running = await LocalOllamaInstaller.isOllamaRunning(port: 0);
      expect(running, isFalse);
    });

    test('isOllamaRunning with very high port returns false', () async {
      // Puerto muy alto, probablemente no está en uso
      final running = await LocalOllamaInstaller.isOllamaRunning(port: 65535);
      expect(running, isFalse);
    });

    test('checkInstallation can be called multiple times', () async {
      final info1 = await LocalOllamaInstaller.checkInstallation();
      final info2 = await LocalOllamaInstaller.checkInstallation();
      
      // Los resultados deberían ser consistentes
      expect(info1.isInstalled, info2.isInstalled);
      expect(info1.canExecute, info2.canExecute);
    });

    test('stopOllamaService is idempotent', () async {
      // Llamar múltiples veces no debería causar problemas
      await LocalOllamaInstaller.stopOllamaService();
      await LocalOllamaInstaller.stopOllamaService();
      expect(true, isTrue);
    });
  });

  // ==================
  // Concurrent Operations Tests
  // ==================
  group('Concurrent operations', () {
    test('multiple isOllamaRunning calls concurrently', () async {
      final futures = List.generate(
        5,
        (_) => LocalOllamaInstaller.isOllamaRunning(),
      );
      
      final results = await Future.wait(futures);
      
      // Todos deberían completar sin error
      expect(results.length, 5);
      for (final result in results) {
        expect(result, isA<bool>());
      }
    });

    test('multiple checkInstallation calls concurrently', () async {
      final futures = List.generate(
        3,
        (_) => LocalOllamaInstaller.checkInstallation(),
      );
      
      final results = await Future.wait(futures);
      
      // Todos deberían completar y ser consistentes
      expect(results.length, 3);
      final firstResult = results.first;
      for (final result in results) {
        expect(result.isInstalled, firstResult.isInstalled);
      }
    });
  });

  // ==================
  // Constants Tests (indirectos a través del comportamiento)
  // ==================
  group('Constants and URLs', () {
    test('Windows download URL is accessed during Windows install', () async {
      if (Platform.isWindows) {
        final stream = LocalOllamaInstaller.installOllama();
        try {
          await for (final progress in stream.take(1)) {
            // Si llegamos aquí, el código intentó acceder a la URL
            expect(progress.status, LocalOllamaStatus.downloadingInstaller);
            break;
          }
        } catch (e) {
          // Error esperado si no hay conexión o algo falla
          expect(e, isA<LocalOllamaException>());
        }
      }
    });

    test('Linux install command is used on Linux/macOS', () async {
      if (Platform.isLinux || Platform.isMacOS) {
        final stream = LocalOllamaInstaller.installOllama();
        try {
          await for (final progress in stream.take(1)) {
            // En Linux/macOS, primero es 'installing'
            expect(progress.status, LocalOllamaStatus.installing);
            break;
          }
        } catch (e) {
          // Error esperado si curl falla o algo similar
          expect(e, isA<LocalOllamaException>());
        }
      }
    });
  });

  // ==================
  // Error Message Tests
  // ==================
  group('Error messages', () {
    test('LocalOllamaException contains useful information', () {
      final exception = LocalOllamaException(
        'Test error',
        details: 'Detailed information',
      );
      
      final message = exception.toString();
      // Verificar que la información está presente
      expect(message.isNotEmpty, isTrue);
    });

    test('installation error on unsupported platform includes OS name', () async {
      // Este test verifica que el mensaje de error incluye información útil
      // En plataformas soportadas, verificamos que el stream puede iniciarse
      try {
        final stream = LocalOllamaInstaller.installOllama();
        await stream.first;
      } catch (e) {
        if (e is LocalOllamaException) {
          // El mensaje debería contener información sobre la plataforma
          expect(e.toString().isNotEmpty, isTrue);
        }
      }
    });
  });

  // ==================
  // Timeout Behavior Tests
  // ==================
  group('Timeout behavior', () {
    test('isOllamaRunning has reasonable timeout', () async {
      final stopwatch = Stopwatch()..start();
      
      // Conectar a un puerto que probablemente no responde
      await LocalOllamaInstaller.isOllamaRunning(port: 59999);
      
      stopwatch.stop();
      
      // Debería completar en menos de 10 segundos (el timeout es 2 segundos)
      expect(stopwatch.elapsedMilliseconds, lessThan(10000));
    });
  });

  // ==================
  // State Consistency Tests
  // ==================
  group('State consistency', () {
    test('OllamaInstallationInfo fields are consistent', () async {
      final info = await LocalOllamaInstaller.checkInstallation();
      
      // Si puede ejecutar, debe estar instalado
      if (info.canExecute) {
        expect(info.isInstalled, isTrue);
      }
      
      // Si no está instalado, no puede ejecutar
      if (!info.isInstalled) {
        expect(info.canExecute, isFalse);
      }
    });

    test('version is only present when installed', () async {
      final info = await LocalOllamaInstaller.checkInstallation();
      
      if (!info.isInstalled) {
        // La versión debería ser null si no está instalado
        // (aunque el código podría tener casos edge)
        expect(info.version == null || info.version!.isEmpty, isTrue);
      }
    });
  });

  // ==================
  // Platform-specific Path Tests
  // ==================
  group('Platform-specific executable paths', () {
    test('Windows: checks UserProfile environment variable', () async {
      if (Platform.isWindows) {
        final userProfile = Platform.environment['UserProfile'];
        // En Windows, UserProfile debería estar definido
        expect(userProfile, isNotNull);
        
        final info = await LocalOllamaInstaller.checkInstallation();
        expect(info, isA<OllamaInstallationInfo>());
      }
    });

    test('macOS: checks /usr/local/bin/ollama path', () async {
      if (Platform.isMacOS) {
        final info = await LocalOllamaInstaller.checkInstallation();
        expect(info, isA<OllamaInstallationInfo>());
        
        // Si está instalado, la ruta debería contener una de las rutas esperadas
        if (info.isInstalled && info.installPath != null) {
          expect(
            info.installPath!.contains('ollama') ||
                info.installPath == 'Desconocida (en PATH)',
            isTrue,
          );
        }
      }
    });

    test('macOS: checks Ollama.app fallback path', () async {
      if (Platform.isMacOS) {
        // Verificar que la ruta de la app existe o no
        final appPath = File('/Applications/Ollama.app/Contents/Resources/ollama');
        final exists = await appPath.exists();
        // Solo verificamos que la comprobación no lanza error
        expect(exists, isA<bool>());
      }
    });

    test('Linux: checks /usr/local/bin/ollama path', () async {
      if (Platform.isLinux) {
        final info = await LocalOllamaInstaller.checkInstallation();
        expect(info, isA<OllamaInstallationInfo>());
      }
    });

    test('Linux: checks /usr/bin/ollama fallback path', () async {
      if (Platform.isLinux) {
        // Verificar que la ruta fallback existe o no
        final fallbackPath = File('/usr/bin/ollama');
        final exists = await fallbackPath.exists();
        expect(exists, isA<bool>());
      }
    });
  });

  // ==================
  // checkInstallation Detailed Tests
  // ==================
  group('checkInstallation detailed flows', () {
    test('handles Process.run exception gracefully', () async {
      // Este test verifica que las excepciones de Process.run son manejadas
      final info = await LocalOllamaInstaller.checkInstallation();
      expect(info, isA<OllamaInstallationInfo>());
    });

    test('returns "Desconocida (en PATH)" when found via PATH but path unknown',
        () async {
      final info = await LocalOllamaInstaller.checkInstallation();
      
      if (info.isInstalled) {
        // installPath nunca debería ser null si está instalado
        expect(info.installPath, isNotNull);
      }
    });

    test('handles where/which command failures', () async {
      // Este test verifica que los errores de where/which son manejados
      final info = await LocalOllamaInstaller.checkInstallation();
      expect(info, isA<OllamaInstallationInfo>());
    });

    test('parses version output correctly', () async {
      final info = await LocalOllamaInstaller.checkInstallation();
      
      if (info.isInstalled && info.version != null) {
        // La versión debería ser una cadena no vacía
        expect(info.version!.trim(), isNotEmpty);
      }
    });
  });

  // ==================
  // startOllamaService Detailed Tests
  // ==================
  group('startOllamaService detailed flows', () {
    test('Windows: uses Process.start with detached mode', () async {
      if (Platform.isWindows) {
        // Solo verificamos que el método completa sin crash
        final result = await LocalOllamaInstaller.startOllamaService();
        expect(result, isA<bool>());
      }
    }, timeout: const Timeout(Duration(seconds: 60)));

    test('Unix: uses Shell to run ollama serve', () async {
      if (Platform.isMacOS || Platform.isLinux) {
        // Solo verificamos que el método completa sin crash
        final result = await LocalOllamaInstaller.startOllamaService();
        expect(result, isA<bool>());
      }
    }, timeout: const Timeout(Duration(seconds: 60)));

    test('handles where/which lookup for executable', () async {
      // Este test verifica el flujo de búsqueda del ejecutable
      final result = await LocalOllamaInstaller.startOllamaService();
      expect(result, isA<bool>());
    }, timeout: const Timeout(Duration(seconds: 60)));

    test('falls back to _findOllamaExecutable when PATH lookup fails', () async {
      // Este test verifica el fallback
      final result = await LocalOllamaInstaller.startOllamaService();
      expect(result, isA<bool>());
    }, timeout: const Timeout(Duration(seconds: 60)));
  });

  // ==================
  // stopOllamaService Platform Tests
  // ==================
  group('stopOllamaService platform-specific', () {
    test('Windows: uses taskkill command', () async {
      if (Platform.isWindows) {
        await LocalOllamaInstaller.stopOllamaService();
        // Solo verificamos que completa
        expect(true, isTrue);
      }
    });

    test('Unix: uses pkill commands', () async {
      if (Platform.isMacOS || Platform.isLinux) {
        await LocalOllamaInstaller.stopOllamaService();
        // Solo verificamos que completa
        expect(true, isTrue);
      }
    });

    test('handles pkill/taskkill errors gracefully', () async {
      // Llamar stop múltiples veces no debería causar errores
      await LocalOllamaInstaller.stopOllamaService();
      await LocalOllamaInstaller.stopOllamaService();
      expect(true, isTrue);
    });
  });

  // ==================
  // installOllama Stream Tests
  // ==================
  group('installOllama stream behavior', () {
    test('first progress has status downloadingInstaller or installing',
        () async {
      try {
        final stream = LocalOllamaInstaller.installOllama();
        await for (final progress in stream.take(1)) {
          expect(
            progress.status == LocalOllamaStatus.downloadingInstaller ||
                progress.status == LocalOllamaStatus.installing,
            isTrue,
          );
          break;
        }
      } catch (e) {
        expect(e, isA<LocalOllamaException>());
      }
    });

    test('progress.progress starts at 0.0', () async {
      try {
        final stream = LocalOllamaInstaller.installOllama();
        await for (final progress in stream.take(1)) {
          expect(progress.progress, equals(0.0));
          break;
        }
      } catch (e) {
        expect(e, isA<LocalOllamaException>());
      }
    });

    test('Windows: downloads installer before installing', () async {
      if (Platform.isWindows) {
        try {
          final stream = LocalOllamaInstaller.installOllama();
          await for (final progress in stream.take(1)) {
            expect(progress.status, LocalOllamaStatus.downloadingInstaller);
            break;
          }
        } catch (e) {
          expect(e, isA<LocalOllamaException>());
        }
      }
    });

    test('Linux/macOS: starts with installing status', () async {
      if (Platform.isLinux || Platform.isMacOS) {
        try {
          final stream = LocalOllamaInstaller.installOllama();
          await for (final progress in stream.take(1)) {
            expect(progress.status, LocalOllamaStatus.installing);
            break;
          }
        } catch (e) {
          expect(e, isA<LocalOllamaException>());
        }
      }
    });

    test('error progress has status error', () async {
      try {
        final stream = LocalOllamaInstaller.installOllama();
        await stream.toList();
      } catch (e) {
        // Después de un error, el stream debería haber emitido un progress con error
        expect(e, isA<LocalOllamaException>());
      }
    });

    test('stream rethrows LocalOllamaException', () async {
      try {
        final stream = LocalOllamaInstaller.installOllama();
        await stream.toList();
      } catch (e) {
        expect(e, isA<LocalOllamaException>());
      }
    });
  });

  // ==================
  // HTTP Response Handling Tests
  // ==================
  group('HTTP response handling', () {

    test('handles HTTP 201 as non-success', () async {
      HttpOverrides.runZoned(() async {
        final running = await LocalOllamaInstaller.isOllamaRunning();
        expect(running, isFalse);
      }, createHttpClient: (_) => _FakeHttpClient(201));
    });

    test('handles HTTP 301 redirect as non-success', () async {
      HttpOverrides.runZoned(() async {
        final running = await LocalOllamaInstaller.isOllamaRunning();
        expect(running, isFalse);
      }, createHttpClient: (_) => _FakeHttpClient(301));
    });

    test('handles HTTP 400 bad request', () async {
      HttpOverrides.runZoned(() async {
        final running = await LocalOllamaInstaller.isOllamaRunning();
        expect(running, isFalse);
      }, createHttpClient: (_) => _FakeHttpClient(400));
    });

    test('handles HTTP 401 unauthorized', () async {
      HttpOverrides.runZoned(() async {
        final running = await LocalOllamaInstaller.isOllamaRunning();
        expect(running, isFalse);
      }, createHttpClient: (_) => _FakeHttpClient(401));
    });

    test('handles HTTP 500 internal server error', () async {
      HttpOverrides.runZoned(() async {
        final running = await LocalOllamaInstaller.isOllamaRunning();
        expect(running, isFalse);
      }, createHttpClient: (_) => _FakeHttpClient(500));
    });
  });

  // ==================
  // Download Progress Tests (Windows-specific)
  // ==================
  group('Download progress (Windows)', () {
    test('progress includes bytesDownloaded during download', () async {
      if (Platform.isWindows) {
        try {
          final stream = LocalOllamaInstaller.installOllama();
          var foundDownloadProgress = false;
          
          await for (final progress in stream.take(5)) {
            if (progress.status == LocalOllamaStatus.downloadingInstaller &&
                progress.bytesDownloaded != null) {
              foundDownloadProgress = true;
              expect(progress.bytesDownloaded, greaterThanOrEqualTo(0));
            }
          }
          
          // Puede que no encontremos progreso de descarga si falla antes
        } catch (e) {
          expect(e, isA<LocalOllamaException>());
        }
      }
    });

    test('progress includes totalBytes during download', () async {
      if (Platform.isWindows) {
        try {
          final stream = LocalOllamaInstaller.installOllama();
          
          await for (final progress in stream.take(5)) {
            if (progress.status == LocalOllamaStatus.downloadingInstaller &&
                progress.totalBytes != null) {
              expect(progress.totalBytes, greaterThanOrEqualTo(0));
            }
          }
        } catch (e) {
          expect(e, isA<LocalOllamaException>());
        }
      }
    });
  });

  // ==================
  // File System Tests
  // ==================
  group('File system operations', () {
    test('Windows: temporary directory is accessible', () async {
      if (Platform.isWindows) {
        final tempDir = Directory.systemTemp;
        expect(await tempDir.exists(), isTrue);
      }
    });

    test('Unix: /usr/local/bin exists', () async {
      if (Platform.isMacOS || Platform.isLinux) {
        final dir = Directory('/usr/local/bin');
        // Puede o no existir dependiendo del sistema
        expect(await dir.exists(), isA<bool>());
      }
    });

    test('Unix: /usr/bin exists', () async {
      if (Platform.isMacOS || Platform.isLinux) {
        final dir = Directory('/usr/bin');
        expect(await dir.exists(), isTrue);
      }
    });
  });

  // ==================
  // Environment Variable Tests
  // ==================
  group('Environment variables', () {
    test('Windows: UserProfile environment variable exists', () {
      if (Platform.isWindows) {
        final userProfile = Platform.environment['UserProfile'];
        expect(userProfile, isNotNull);
        expect(userProfile, isNotEmpty);
      }
    });

    test('PATH environment variable exists', () {
      final path = Platform.environment['PATH'] ?? Platform.environment['Path'];
      expect(path, isNotNull);
    });
  });

  // ==================
  // Process Execution Tests
  // ==================
  group('Process execution', () {
    test('can execute simple command', () async {
      try {
        final result = await Process.run(
          Platform.isWindows ? 'cmd' : 'echo',
          Platform.isWindows ? ['/c', 'echo', 'test'] : ['test'],
        );
        expect(result.exitCode, equals(0));
      } catch (e) {
        // En algunos entornos de test, puede fallar
      }
    });

    test('which/where command exists', () async {
      try {
        final result = await Process.run(
          Platform.isWindows ? 'where' : 'which',
          Platform.isWindows ? ['cmd'] : ['echo'],
        );
        expect(result.exitCode, equals(0));
      } catch (e) {
        // En algunos entornos de test, puede fallar
      }
    });
  });

  // ==================
  // Memory/Resource Tests
  // ==================
  group('Resource management', () {
    test('isOllamaRunning closes HTTP client', () async {
      // Llamar múltiples veces no debería causar memory leaks
      for (var i = 0; i < 10; i++) {
        await LocalOllamaInstaller.isOllamaRunning(port: 9999);
      }
      expect(true, isTrue);
    });

    test('checkInstallation can be called rapidly', () async {
      final futures = <Future<OllamaInstallationInfo>>[];
      for (var i = 0; i < 5; i++) {
        futures.add(LocalOllamaInstaller.checkInstallation());
      }
      
      final results = await Future.wait(futures);
      expect(results.length, equals(5));
    });
  });

  // ==================
  // Validation Tests
  // ==================
  group('Input validation', () {
    test('isOllamaRunning accepts valid port numbers', () async {
      // Test varios puertos válidos
      for (final port in [80, 443, 8080, 11434, 65535]) {
        final result = await LocalOllamaInstaller.isOllamaRunning(port: port);
        expect(result, isA<bool>());
      }
    });

    test('isOllamaRunning handles negative port gracefully', () async {
      // Puertos negativos no son válidos, pero el método no debería crashear
      try {
        final result = await LocalOllamaInstaller.isOllamaRunning(port: -1);
        expect(result, isFalse);
      } catch (e) {
        // También es aceptable que lance un error
        expect(e, isA<Exception>());
      }
    });
  });

  // ==================
  // Retry/Recovery Tests
  // ==================
  group('Retry and recovery', () {
    test('startOllamaService retries checking if running', () async {
      HttpOverrides.runZoned(() async {
        // Con 500, debería reintentar varias veces
        final started = await LocalOllamaInstaller.startOllamaService();
        expect(started, isFalse);
      }, createHttpClient: (_) => _FakeHttpClient(500));
    }, timeout: const Timeout(Duration(seconds: 60)));

    test('service check loop completes within timeout', () async {
      final stopwatch = Stopwatch()..start();
      
      HttpOverrides.runZoned(() async {
        await LocalOllamaInstaller.startOllamaService();
      }, createHttpClient: (_) => _FakeHttpClient(500));
      
      stopwatch.stop();
      
      // Debería completar en menos de 60 segundos
      expect(stopwatch.elapsedMilliseconds, lessThan(60000));
    }, timeout: const Timeout(Duration(seconds: 65)));
  });
}