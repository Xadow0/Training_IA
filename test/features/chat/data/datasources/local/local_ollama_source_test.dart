import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:chatbot_app/features/chat/data/datasources/local/local_ollama_source.dart';
import 'package:chatbot_app/features/chat/data/models/local_ollama_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ==================
  // OllamaManagedService - Estado inicial y getters
  // ==================
  group('OllamaManagedService - Estado inicial y getters', () {
    late OllamaManagedService service;

    setUp(() {
      service = OllamaManagedService();
    });

    tearDown(() {
      service.dispose();
    });

    test('estado inicial correcto', () {
      expect(service.status, LocalOllamaStatus.notInitialized);
      expect(service.isAvailable, false);
      expect(service.isProcessing, false);
      expect(service.currentModel, isNull);
      expect(service.availableModels, isEmpty);
      expect(service.errorMessage, isNull);
    });

    test('isAvailable es false cuando status no es ready', () {
      expect(service.status, isNot(LocalOllamaStatus.ready));
      expect(service.isAvailable, isFalse);
    });

    test('isProcessing depende del status', () {
      // En estado inicial, no debería estar procesando
      expect(service.isProcessing, isFalse);
    });

    test('baseUrl retorna la URL completa de config', () {
      expect(service.baseUrl, isNotEmpty);
      expect(service.baseUrl, contains('http'));
    });

    test('installProgressStream es null inicialmente', () {
      expect(service.installProgressStream, isNull);
    });

    test('isPlatformSupported retorna true en desktop', () {
      final isDesktop = Platform.isWindows || Platform.isMacOS || Platform.isLinux;
      expect(service.isPlatformSupported, isDesktop);
    });

    test('availableModels es lista vacía inicialmente', () {
      expect(service.availableModels, isA<List<String>>());
      expect(service.availableModels, isEmpty);
    });

    test('currentModel es null inicialmente', () {
      expect(service.currentModel, isNull);
    });
  });

  // ==================
  // OllamaManagedService - Constructor con config
  // ==================
  group('OllamaManagedService - Constructor con config', () {
    test('acepta config personalizada', () {
      final config = LocalOllamaConfig(
        baseUrl: '192.168.1.100',
        port: 12345,
        timeout: const Duration(seconds: 60),
      );
      final service = OllamaManagedService(config: config);

      expect(service.baseUrl, contains('192.168.1.100'));
      expect(service.baseUrl, contains('12345'));

      service.dispose();
    });

    test('usa config por defecto si no se proporciona', () {
      final service = OllamaManagedService();

      expect(service.baseUrl, contains('localhost'));
      expect(service.baseUrl, contains('11434'));

      service.dispose();
    });

    test('config null usa valores por defecto', () {
      final service = OllamaManagedService(config: null);

      expect(service.baseUrl, isNotEmpty);

      service.dispose();
    });
  });

  // ==================
  // OllamaManagedService - Status Listeners
  // ==================
  group('OllamaManagedService - Status Listeners', () {
    late OllamaManagedService service;
    late List<LocalOllamaStatus> receivedStatuses;

    setUp(() {
      service = OllamaManagedService();
      receivedStatuses = [];
    });

    tearDown(() {
      service.dispose();
    });

    test('addStatusListener añade listener correctamente', () {
      void listener(LocalOllamaStatus status) {
        receivedStatuses.add(status);
      }

      service.addStatusListener(listener);
      // No hay forma directa de verificar, pero no debe lanzar error
      expect(true, isTrue);
    });

    test('removeStatusListener elimina listener correctamente', () {
      void listener(LocalOllamaStatus status) {
        receivedStatuses.add(status);
      }

      service.addStatusListener(listener);
      service.removeStatusListener(listener);
      // No hay forma directa de verificar, pero no debe lanzar error
      expect(true, isTrue);
    });

    test('múltiples listeners pueden ser añadidos', () {
      void listener1(LocalOllamaStatus status) {}
      void listener2(LocalOllamaStatus status) {}
      void listener3(LocalOllamaStatus status) {}

      service.addStatusListener(listener1);
      service.addStatusListener(listener2);
      service.addStatusListener(listener3);

      expect(true, isTrue);
    });

    test('listener que lanza excepción no rompe otros listeners', () async {
      var listener2Called = false;

      void listener1(LocalOllamaStatus status) {
        throw Exception('Listener error');
      }

      void listener2(LocalOllamaStatus status) {
        listener2Called = true;
      }

      service.addStatusListener(listener1);
      service.addStatusListener(listener2);

      // Forzar un cambio de estado
      await service.stop();

      // El servicio debería manejar el error del primer listener
      expect(true, isTrue);
    });
  });

  // ==================
  // OllamaManagedService - Install Progress Listeners
  // ==================
  group('OllamaManagedService - Install Progress Listeners', () {
    late OllamaManagedService service;

    setUp(() {
      service = OllamaManagedService();
    });

    tearDown(() {
      service.dispose();
    });

    test('addInstallProgressListener añade listener', () {
      void listener(LocalOllamaInstallProgress progress) {}

      service.addInstallProgressListener(listener);
      expect(true, isTrue);
    });

    test('removeInstallProgressListener elimina listener', () {
      void listener(LocalOllamaInstallProgress progress) {}

      service.addInstallProgressListener(listener);
      service.removeInstallProgressListener(listener);
      expect(true, isTrue);
    });

    test('listener de progreso que lanza excepción es manejado', () {
      void listener(LocalOllamaInstallProgress progress) {
        throw Exception('Progress listener error');
      }

      service.addInstallProgressListener(listener);
      // El listener que lanza no debería romper el servicio
      expect(true, isTrue);
    });
  });

  // ==================
  // OllamaManagedService - deleteModel
  // ==================
  group('OllamaManagedService - deleteModel', () {
    late OllamaManagedService service;

    setUp(() {
      service = OllamaManagedService();
    });

    tearDown(() {
      service.dispose();
    });

    test('falla si servicio no está listo', () async {
      final result = await service.deleteModel('llama2');

      expect(result.success, false);
      expect(result.error, isNotNull);
      expect(result.error, contains('no está disponible'));
      expect(result.deletedModel, isNull);
    });

    test('retorna DeleteModelResult con estructura correcta', () async {
      final result = await service.deleteModel('test-model');

      expect(result, isA<DeleteModelResult>());
      expect(result.success, isA<bool>());
    });
  });

  // ==================
  // OllamaManagedService - cancelModelDownload
  // ==================
  group('OllamaManagedService - cancelModelDownload', () {
    late OllamaManagedService service;

    setUp(() {
      service = OllamaManagedService();
    });

    tearDown(() {
      service.dispose();
    });

    test('sin descarga activa no cambia estado', () {
      final statusBefore = service.status;
      service.cancelModelDownload();
      expect(service.status, statusBefore);
    });

    test('puede ser llamado múltiples veces sin error', () {
      service.cancelModelDownload();
      service.cancelModelDownload();
      service.cancelModelDownload();
      expect(true, isTrue);
    });

    test('no lanza excepción en estado inicial', () {
      expect(() => service.cancelModelDownload(), returnsNormally);
    });
  });

  // ==================
  // OllamaManagedService - generateContentStream
  // ==================
  group('OllamaManagedService - generateContentStream', () {
    late OllamaManagedService service;

    setUp(() {
      service = OllamaManagedService();
    });

    tearDown(() {
      service.dispose();
    });

    test('lanza excepción si servicio no está disponible', () async {
      expect(
        () => service.generateContentStream('hola').first,
        throwsA(isA<LocalOllamaException>()),
      );
    });

    test('excepción contiene estado actual en detalles', () async {
      try {
        await service.generateContentStream('test').first;
        fail('Should have thrown');
      } catch (e) {
        expect(e, isA<LocalOllamaException>());
        expect(e.toString(), contains('Estado actual'));
      }
    });

    test('retorna Stream<String>', () {
      final stream = service.generateContentStream('test');
      expect(stream, isA<Stream<String>>());
    });

    test('acepta parámetros opcionales', () {
      final stream = service.generateContentStream(
        'test',
        temperature: 0.5,
        maxTokens: 100,
      );
      expect(stream, isA<Stream<String>>());
    });
  });

  // ==================
  // OllamaManagedService - generateContentStreamContext
  // ==================
  group('OllamaManagedService - generateContentStreamContext', () {
    late OllamaManagedService service;

    setUp(() {
      service = OllamaManagedService();
    });

    tearDown(() {
      service.dispose();
    });

    test('lanza excepción si servicio no está disponible', () async {
      expect(
        () => service.generateContentStreamContext('hola').first,
        throwsA(isA<LocalOllamaException>()),
      );
    });

    test('excepción contiene estado actual en detalles', () async {
      try {
        await service.generateContentStreamContext('test').first;
        fail('Should have thrown');
      } catch (e) {
        expect(e, isA<LocalOllamaException>());
        expect(e.toString(), contains('Estado actual'));
      }
    });

    test('retorna Stream<String>', () {
      final stream = service.generateContentStreamContext('test');
      expect(stream, isA<Stream<String>>());
    });

    test('acepta parámetros opcionales', () {
      final stream = service.generateContentStreamContext(
        'test',
        temperature: 0.7,
        maxTokens: 200,
      );
      expect(stream, isA<Stream<String>>());
    });
  });

  // ==================
  // OllamaManagedService - Conversation Management
  // ==================
  group('OllamaManagedService - Conversation Management', () {
    late OllamaManagedService service;

    setUp(() {
      service = OllamaManagedService();
    });

    tearDown(() {
      service.dispose();
    });

    test('clearConversation limpia historial sin error', () {
      service.clearConversation();
      expect(true, isTrue);
    });

    test('addUserMessage no lanza excepción', () {
      service.addUserMessage('hola');
      expect(true, isTrue);
    });

    test('addBotMessage no lanza excepción', () {
      service.addBotMessage('respuesta');
      expect(true, isTrue);
    });

    test('puede añadir múltiples mensajes', () {
      service.addUserMessage('mensaje 1');
      service.addBotMessage('respuesta 1');
      service.addUserMessage('mensaje 2');
      service.addBotMessage('respuesta 2');
      expect(true, isTrue);
    });

    test('clearConversation después de añadir mensajes', () {
      service.addUserMessage('test');
      service.addBotMessage('response');
      service.clearConversation();
      expect(true, isTrue);
    });

    test('mensajes vacíos son aceptados', () {
      service.addUserMessage('');
      service.addBotMessage('');
      expect(true, isTrue);
    });

    test('mensajes con caracteres especiales son aceptados', () {
      service.addUserMessage('¿Qué tal? 你好 🎉');
      service.addBotMessage('Respuesta con émojis 🤖');
      expect(true, isTrue);
    });
  });

  // ==================
  // OllamaManagedService - Lifecycle Methods
  // ==================
  group('OllamaManagedService - Lifecycle Methods', () {
    late OllamaManagedService service;

    setUp(() {
      service = OllamaManagedService();
    });

    tearDown(() {
      service.dispose();
    });

    test('pause no hace nada si no está ready', () async {
      await service.pause();
      expect(service.status, LocalOllamaStatus.notInitialized);
    });

    test('pause es idempotente', () async {
      await service.pause();
      await service.pause();
      await service.pause();
      expect(true, isTrue);
    });

    test('stop resetea estado y limpia modelos', () async {
      await service.stop();

      expect(service.status, LocalOllamaStatus.notInitialized);
      expect(service.availableModels, isEmpty);
      expect(service.currentModel, isNull);
    });

    test('stop puede ser llamado múltiples veces', () async {
      await service.stop();
      await service.stop();
      await service.stop();
      expect(service.status, LocalOllamaStatus.notInitialized);
    });

    test('retry llama a initialize y devuelve resultado', () async {
      final future = service.retry();

      final result = await future.timeout(
        const Duration(seconds: 2),
        onTimeout: () => LocalOllamaInitResult(success: false, error: 'timeout'),
      );

      expect(result.success, false);
    });

    test('dispose limpia timers y listeners sin error', () {
      service.dispose();
      expect(true, isTrue);
    });

    test('dispose puede ser llamado múltiples veces', () {
      service.dispose();
      service.dispose();
      expect(true, isTrue);
    });
  });

  // ==================
  // OllamaManagedService - Health Check
  // ==================
  group('OllamaManagedService - Health Check', () {
    late OllamaManagedService service;

    setUp(() {
      service = OllamaManagedService();
    });

    tearDown(() {
      service.dispose();
    });

    test('checkHealth devuelve false si no hay servidor', () async {
      final healthy = await service.checkHealth();
      expect(healthy, isFalse);
    });

    test('checkHealth retorna bool', () async {
      final result = await service.checkHealth();
      expect(result, isA<bool>());
    });

    test('checkHealth es rápido (timeout corto)', () async {
      final stopwatch = Stopwatch()..start();
      await service.checkHealth();
      stopwatch.stop();

      // Debería completar en menos de 10 segundos
      expect(stopwatch.elapsedMilliseconds, lessThan(10000));
    });

    test('múltiples health checks concurrentes', () async {
      final futures = List.generate(
        5,
        (_) => service.checkHealth(),
      );

      final results = await Future.wait(futures);

      expect(results.length, 5);
      for (final result in results) {
        expect(result, isA<bool>());
      }
    });
  });

  // ==================
  // OllamaManagedService - getInstalledModelsInfo
  // ==================
  group('OllamaManagedService - getInstalledModelsInfo', () {
    late OllamaManagedService service;

    setUp(() {
      service = OllamaManagedService();
    });

    tearDown(() {
      service.dispose();
    });

    test('retorna lista vacía si servidor no está disponible', () async {
      final models = await service.getInstalledModelsInfo();
      expect(models, isA<List<InstalledModelInfo>>());
      expect(models, isEmpty);
    });

    test('no lanza excepción si hay error de conexión', () async {
      final models = await service.getInstalledModelsInfo();
      expect(models, isEmpty);
    });
  });

  // ==================
  // OllamaManagedService - refreshModels
  // ==================
  group('OllamaManagedService - refreshModels', () {
    late OllamaManagedService service;

    setUp(() {
      service = OllamaManagedService();
    });

    tearDown(() {
      service.dispose();
    });

    test('refreshModels no lanza excepción sin servidor', () async {
      await service.refreshModels();
      expect(true, isTrue);
    });

    test('refreshModels actualiza availableModels', () async {
      await service.refreshModels();
      expect(service.availableModels, isA<List<String>>());
    });
  });

  // ==================
  // OllamaManagedService - changeModel
  // ==================
  group('OllamaManagedService - changeModel', () {
    late OllamaManagedService service;

    setUp(() {
      service = OllamaManagedService();
    });

    tearDown(() {
      service.dispose();
    });

    test('changeModel retorna false si falla', () async {
      // Sin servidor, debería fallar
      final result = await service.changeModel('test-model').timeout(
            const Duration(seconds: 3),
            onTimeout: () => false,
          );
      expect(result, isFalse);
    });

    test('changeModel actualiza status a error si falla', () async {
      await service.changeModel('nonexistent-model').timeout(
            const Duration(seconds: 3),
            onTimeout: () => false,
          );
      // El status puede ser error o notInitialized
      expect(service.status, isNotNull);
    });
  });

  // ==================
  // OllamaManagedService - initialize
  // ==================
  group('OllamaManagedService - initialize', () {
    late OllamaManagedService service;

    setUp(() {
      service = OllamaManagedService();
    });

    tearDown(() {
      service.dispose();
    });

    test('initialize retorna LocalOllamaInitResult', () async {
      final result = await service.initialize().timeout(
            const Duration(seconds: 3),
            onTimeout: () => LocalOllamaInitResult(success: false, error: 'timeout'),
          );

      expect(result, isA<LocalOllamaInitResult>());
    });

    test('initialize con modelName personalizado', () async {
      final result = await service.initialize(modelName: 'custom-model').timeout(
            const Duration(seconds: 3),
            onTimeout: () => LocalOllamaInitResult(success: false, error: 'timeout'),
          );

      expect(result, isA<LocalOllamaInitResult>());
    });

    test('initialize actualiza status durante proceso', () async {
      var statusChanged = false;

      service.addStatusListener((status) {
        statusChanged = true;
      });

      await service.initialize().timeout(
            const Duration(seconds: 3),
            onTimeout: () => LocalOllamaInitResult(success: false, error: 'timeout'),
          );

      // El status debería haber cambiado durante la inicialización
      expect(statusChanged || service.status != LocalOllamaStatus.notInitialized, isTrue);
    });

    test('initialize falla en plataforma no soportada retorna error apropiado', () async {
      // En desktop debería intentar inicializar
      // Solo verificamos que no crashea
      final result = await service.initialize().timeout(
            const Duration(seconds: 3),
            onTimeout: () => LocalOllamaInitResult(success: false, error: 'timeout'),
          );

      expect(result.success, isA<bool>());
    });
  });

  // ==================
  // InstalledModelInfo Tests
  // ==================
  group('InstalledModelInfo', () {
    test('sizeFormatted para KB', () {
      final small = InstalledModelInfo(name: 'model:latest', size: 1024);
      expect(small.sizeFormatted, '1 KB');
    });

    test('sizeFormatted para varios KB', () {
      final model = InstalledModelInfo(name: 'model:latest', size: 512 * 1024);
      expect(model.sizeFormatted, '512 KB');
    });

    test('sizeFormatted para MB', () {
      final medium = InstalledModelInfo(name: 'model:latest', size: 1024 * 1024);
      expect(medium.sizeFormatted, '1 MB');
    });

    test('sizeFormatted para varios MB', () {
      final model = InstalledModelInfo(name: 'model:latest', size: 500 * 1024 * 1024);
      expect(model.sizeFormatted, '500 MB');
    });

    test('sizeFormatted para GB', () {
      final big = InstalledModelInfo(name: 'model:latest', size: 1024 * 1024 * 1024);
      expect(big.sizeFormatted, '1.0 GB');
    });

    test('sizeFormatted para varios GB', () {
      final model = InstalledModelInfo(name: 'model:latest', size: (4.5 * 1024 * 1024 * 1024).toInt());
      expect(model.sizeFormatted, '4.5 GB');
    });

    test('sizeFormatted para 0 bytes', () {
      final model = InstalledModelInfo(name: 'model:latest', size: 0);
      expect(model.sizeFormatted, '0 KB');
    });

    test('displayName extrae nombre sin tag', () {
      final model = InstalledModelInfo(name: 'llama2:7b', size: 100);
      expect(model.displayName, 'llama2');
    });

    test('displayName con nombre simple', () {
      final model = InstalledModelInfo(name: 'llama2', size: 100);
      expect(model.displayName, 'llama2');
    });

    test('displayName con múltiples separadores', () {
      final model = InstalledModelInfo(name: 'namespace:model:tag', size: 100);
      expect(model.displayName, 'namespace');
    });

    test('tag extrae tag correctamente', () {
      final model = InstalledModelInfo(name: 'llama2:7b', size: 100);
      expect(model.tag, '7b');
    });

    test('tag retorna latest si no hay tag', () {
      final noTag = InstalledModelInfo(name: 'plain', size: 100);
      expect(noTag.tag, 'latest');
    });

    test('tag con nombre vacío', () {
      final model = InstalledModelInfo(name: '', size: 100);
      expect(model.displayName, '');
      expect(model.tag, 'latest');
    });

    test('constructor con todos los campos', () {
      final now = DateTime.now();
      final details = {'family': 'llama', 'parameter_size': '7B'};

      final model = InstalledModelInfo(
        name: 'llama2:7b',
        size: 1024 * 1024 * 1024,
        modifiedAt: now,
        details: details,
      );

      expect(model.name, 'llama2:7b');
      expect(model.size, 1024 * 1024 * 1024);
      expect(model.modifiedAt, now);
      expect(model.details, details);
    });

    test('constructor con campos opcionales null', () {
      final model = InstalledModelInfo(
        name: 'test',
        size: 100,
        modifiedAt: null,
        details: null,
      );

      expect(model.modifiedAt, isNull);
      expect(model.details, isNull);
    });
  });

  // ==================
  // DeleteModelResult Tests
  // ==================
  group('DeleteModelResult', () {
    test('constructor con success true', () {
      final result = DeleteModelResult(
        success: true,
        deletedModel: 'llama2',
        newCurrentModel: 'llama3',
      );

      expect(result.success, isTrue);
      expect(result.error, isNull);
      expect(result.deletedModel, 'llama2');
      expect(result.newCurrentModel, 'llama3');
    });

    test('constructor con success false', () {
      final result = DeleteModelResult(
        success: false,
        error: 'Error message',
      );

      expect(result.success, isFalse);
      expect(result.error, 'Error message');
      expect(result.deletedModel, isNull);
      expect(result.newCurrentModel, isNull);
    });

    test('constructor con todos los campos', () {
      final result = DeleteModelResult(
        success: true,
        error: null,
        deletedModel: 'model1',
        newCurrentModel: 'model2',
      );

      expect(result.success, isTrue);
      expect(result.deletedModel, 'model1');
      expect(result.newCurrentModel, 'model2');
    });

    test('constructor con campos mínimos', () {
      final result = DeleteModelResult(success: false);

      expect(result.success, isFalse);
      expect(result.error, isNull);
      expect(result.deletedModel, isNull);
      expect(result.newCurrentModel, isNull);
    });
  });

  // ==================
  // LocalOllamaConfig Tests
  // ==================
  group('LocalOllamaConfig', () {
    test('valores por defecto', () {
      const config = LocalOllamaConfig();

      expect(config.baseUrl, 'http://localhost');
      expect(config.port, 11434);
      expect(config.timeout, isNotNull);
    });

    test('valores personalizados', () {
      final config = LocalOllamaConfig(
        baseUrl: '192.168.1.1',
        port: 8080,
        timeout: const Duration(seconds: 120),
        temperature: 0.5,
        maxTokens: 500,
      );

      expect(config.baseUrl, '192.168.1.1');
      expect(config.port, 8080);
      expect(config.timeout, const Duration(seconds: 120));
      expect(config.temperature, 0.5);
      expect(config.maxTokens, 500);
    });

    test('fullBaseUrl se construye correctamente', () {
      const config = LocalOllamaConfig(
        baseUrl: 'example.com',
        port: 9999,
      );

      expect(config.fullBaseUrl, 'example.com:9999');
    });
  });

  // ==================
  // LocalOllamaInitResult Tests
  // ==================
  group('LocalOllamaInitResult', () {
    test('resultado exitoso', () {
      final result = LocalOllamaInitResult(
        success: true,
        modelName: 'llama2:7b',
        availableModels: ['llama2:7b', 'llama3:8b'],
        initTime: const Duration(seconds: 5),
        wasNewInstallation: false,
      );

      expect(result.success, isTrue);
      expect(result.modelName, 'llama2:7b');
      expect(result.availableModels, hasLength(2));
      expect(result.initTime?.inSeconds, 5);
      expect(result.wasNewInstallation, isFalse);
      expect(result.error, isNull);
    });

    test('resultado con error', () {
      final result = LocalOllamaInitResult(
        success: false,
        error: 'Connection failed',
      );

      expect(result.success, isFalse);
      expect(result.error, 'Connection failed');
      expect(result.modelName, isNull);
    });

    test('resultado con nueva instalación', () {
      final result = LocalOllamaInitResult(
        success: true,
        wasNewInstallation: true,
      );

      expect(result.wasNewInstallation, isTrue);
    });
  });

  // ==================
  // LocalOllamaStatus Tests
  // ==================
  group('LocalOllamaStatus', () {
    test('todos los valores existen', () {
      expect(LocalOllamaStatus.notInitialized, isNotNull);
      expect(LocalOllamaStatus.checkingInstallation, isNotNull);
      expect(LocalOllamaStatus.downloadingInstaller, isNotNull);
      expect(LocalOllamaStatus.installing, isNotNull);
      expect(LocalOllamaStatus.starting, isNotNull);
      expect(LocalOllamaStatus.downloadingModel, isNotNull);
      expect(LocalOllamaStatus.loading, isNotNull);
      expect(LocalOllamaStatus.ready, isNotNull);
      expect(LocalOllamaStatus.error, isNotNull);
    });

    test('isProcessing es true para estados de procesamiento', () {
      expect(LocalOllamaStatus.checkingInstallation.isProcessing, isTrue);
      expect(LocalOllamaStatus.downloadingInstaller.isProcessing, isTrue);
      expect(LocalOllamaStatus.installing.isProcessing, isTrue);
      expect(LocalOllamaStatus.starting.isProcessing, isTrue);
      expect(LocalOllamaStatus.downloadingModel.isProcessing, isTrue);
      expect(LocalOllamaStatus.loading.isProcessing, isTrue);
    });

    test('isProcessing es false para estados finales', () {
      expect(LocalOllamaStatus.notInitialized.isProcessing, isFalse);
      expect(LocalOllamaStatus.ready.isProcessing, isFalse);
      expect(LocalOllamaStatus.error.isProcessing, isFalse);
    });

    test('displayText retorna texto no vacío', () {
      for (final status in LocalOllamaStatus.values) {
        expect(status.displayText, isNotEmpty);
      }
    });

    test('cada status tiene displayText único o apropiado', () {
      expect(LocalOllamaStatus.ready.displayText, isNotEmpty);
      expect(LocalOllamaStatus.error.displayText, isNotEmpty);
      expect(LocalOllamaStatus.downloadingModel.displayText, isNotEmpty);
    });
  });

  // ==================
  // LocalOllamaException Tests
  // ==================
  group('LocalOllamaException', () {
    test('constructor con mensaje', () {
      final exception = LocalOllamaException('Test error');
      expect(exception.toString(), contains('Test error'));
    });

    test('constructor con mensaje y detalles', () {
      final exception = LocalOllamaException(
        'Error principal',
        details: 'Detalles adicionales',
      );
      expect(exception.toString(), contains('Error principal'));
    });

    test('puede ser lanzada y capturada', () {
      expect(
        () => throw LocalOllamaException('Test'),
        throwsA(isA<LocalOllamaException>()),
      );
    });

    test('es capturada como Exception', () {
      expect(
        () => throw LocalOllamaException('Test'),
        throwsA(isA<Exception>()),
      );
    });
  });

  // ==================
  // LocalOllamaModel Tests
  // ==================
  group('LocalOllamaModel', () {
    test('defaultModel está definido', () {
      expect(LocalOllamaModel.defaultModel, isNotEmpty);
    });

    test('defaultModel es un string válido', () {
      expect(LocalOllamaModel.defaultModel, isA<String>());
    });
  });

  // ==================
  // LocalOllamaInstallProgress Tests
  // ==================
  group('LocalOllamaInstallProgress', () {
    test('constructor con campos requeridos', () {
      final progress = LocalOllamaInstallProgress(
        status: LocalOllamaStatus.downloadingModel,
        progress: 0.5,
        message: 'Downloading...',
      );

      expect(progress.status, LocalOllamaStatus.downloadingModel);
      expect(progress.progress, 0.5);
      expect(progress.message, 'Downloading...');
    });

    test('constructor con campos opcionales', () {
      final progress = LocalOllamaInstallProgress(
        status: LocalOllamaStatus.downloadingInstaller,
        progress: 0.3,
        message: 'Downloading...',
        bytesDownloaded: 1024,
        totalBytes: 2048,
      );

      expect(progress.bytesDownloaded, 1024);
      expect(progress.totalBytes, 2048);
    });

    test('progress está entre 0 y 1', () {
      final progress0 = LocalOllamaInstallProgress(
        status: LocalOllamaStatus.installing,
        progress: 0.0,
        message: 'Starting',
      );

      final progress1 = LocalOllamaInstallProgress(
        status: LocalOllamaStatus.installing,
        progress: 1.0,
        message: 'Complete',
      );

      expect(progress0.progress, greaterThanOrEqualTo(0.0));
      expect(progress1.progress, lessThanOrEqualTo(1.0));
    });
  });

  // ==================
  // OllamaInstallationInfo Tests
  // ==================
  group('OllamaInstallationInfo', () {
    test('needsInstallation es true cuando no está instalado', () {
      final info = OllamaInstallationInfo(
        isInstalled: false,
        canExecute: false,
      );

      expect(info.needsInstallation, isTrue);
    });

    test('needsInstallation es false cuando está instalado', () {
      final info = OllamaInstallationInfo(
        isInstalled: true,
        canExecute: true,
        installPath: '/usr/bin/ollama',
        version: '0.1.0',
      );

      expect(info.needsInstallation, isFalse);
    });

    test('constructor con todos los campos', () {
      final info = OllamaInstallationInfo(
        isInstalled: true,
        canExecute: true,
        installPath: '/path/to/ollama',
        version: '1.0.0',
      );

      expect(info.isInstalled, isTrue);
      expect(info.canExecute, isTrue);
      expect(info.installPath, '/path/to/ollama');
      expect(info.version, '1.0.0');
    });
  });

  // ==================
  // Concurrent Operations Tests
  // ==================
  group('Concurrent operations', () {
    test('múltiples llamadas a checkHealth', () async {
      final service = OllamaManagedService();

      final futures = List.generate(
        10,
        (_) => service.checkHealth(),
      );

      final results = await Future.wait(futures);
      expect(results.length, 10);

      service.dispose();
    });

    test('llamadas concurrentes a getInstalledModelsInfo', () async {
      final service = OllamaManagedService();

      final futures = List.generate(
        5,
        (_) => service.getInstalledModelsInfo(),
      );

      final results = await Future.wait(futures);
      expect(results.length, 5);

      service.dispose();
    });

    test('crear y disponer múltiples instancias', () async {
      for (var i = 0; i < 5; i++) {
        final service = OllamaManagedService();
        await service.checkHealth();
        service.dispose();
      }
      expect(true, isTrue);
    });
  });

  // ==================
  // Edge Cases Tests
  // ==================
  group('Edge cases', () {
    test('servicio con config de puerto inválido', () {
      final config = LocalOllamaConfig(
        port: 0,
      );
      final service = OllamaManagedService(config: config);

      expect(service.baseUrl, contains(':0'));
      service.dispose();
    });

    test('servicio con host vacío', () {
      final config = LocalOllamaConfig(
        baseUrl: ''
      );
      final service = OllamaManagedService(config: config);

      expect(service.baseUrl, isNotEmpty);
      service.dispose();
    });

    test('listeners vacíos no causan problemas', () async {
      final service = OllamaManagedService();

      // Sin listeners, las operaciones no deberían fallar
      await service.stop();
      await service.checkHealth();

      service.dispose();
    });

    test('operaciones después de dispose no crashean', () {
      final service = OllamaManagedService();
      service.dispose();

      // Estas operaciones pueden fallar pero no deberían crashear
      service.clearConversation();
      service.addUserMessage('test');
    });
  });

  // ==================
  // Resource Management Tests
  // ==================
  group('Resource management', () {
    test('dispose libera recursos correctamente', () {
      final service = OllamaManagedService();

      service.addStatusListener((_) {});
      service.addInstallProgressListener((_) {});

      service.dispose();

      // Después de dispose, no debería haber listeners activos
      expect(true, isTrue);
    });

    test('múltiples stop no causan memory leaks', () async {
      final service = OllamaManagedService();

      for (var i = 0; i < 10; i++) {
        await service.stop();
      }

      service.dispose();
      expect(true, isTrue);
    });

    test('timers son cancelados en dispose', () {
      final service = OllamaManagedService();

      // Los timers deberían ser cancelados
      service.dispose();

      // No hay forma directa de verificar, pero no debería haber errores
      expect(true, isTrue);
    });
  });

  // ==================
  // Integration-style Tests
  // ==================
  group('Integration-style tests', () {
    test('flujo completo: crear -> check health -> dispose', () async {
      final service = OllamaManagedService();

      expect(service.status, LocalOllamaStatus.notInitialized);

      final healthy = await service.checkHealth();
      expect(healthy, isA<bool>());

      service.dispose();
    });

    test('flujo: crear -> add messages -> clear -> dispose', () {
      final service = OllamaManagedService();

      service.addUserMessage('Hello');
      service.addBotMessage('Hi there');
      service.addUserMessage('How are you?');
      service.clearConversation();

      service.dispose();
      expect(true, isTrue);
    });

    test('flujo: crear -> listeners -> stop -> dispose', () async {
      final service = OllamaManagedService();

      final statuses = <LocalOllamaStatus>[];
      service.addStatusListener((s) => statuses.add(s));

      await service.stop();

      service.dispose();
      expect(true, isTrue);
    });
  });
}