import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:chatbot_app/features/chat/data/utils/ai_service_selector.dart';
import 'package:chatbot_app/features/chat/data/datasources/remote/gemini_datasource.dart';
import 'package:chatbot_app/features/chat/data/datasources/remote/ollama_remote_source.dart';
import 'package:chatbot_app/features/chat/data/datasources/remote/openai_datasource.dart';
import 'package:chatbot_app/features/chat/data/datasources/local/local_ollama_source.dart';
import 'package:chatbot_app/features/chat/data/models/remote_ollama_models.dart';
import 'package:chatbot_app/features/chat/data/models/local_ollama_models.dart';
import 'package:chatbot_app/features/chat/data/datasources/ai_interfaces/ai_service_adapters.dart';

class MockGeminiService extends Mock implements GeminiService {}

class MockOllamaService extends Mock implements OllamaService {}

class MockOpenAIService extends Mock implements OpenAIService {}

class MockOllamaManagedService extends Mock implements OllamaManagedService {}

void main() {
  late AIServiceSelector selector;
  late MockGeminiService mockGemini;
  late MockOllamaService mockOllama;
  late MockOpenAIService mockOpenAI;
  late MockOllamaManagedService mockLocalOllama;

  late StreamController<ConnectionInfo> ollamaStreamController;

  // Variable para capturar el listener de LocalOllama
  late void Function(LocalOllamaStatus) capturedStatusListener;

  setUp(() {
    mockGemini = MockGeminiService();
    mockOllama = MockOllamaService();
    mockOpenAI = MockOpenAIService();
    mockLocalOllama = MockOllamaManagedService();

    ollamaStreamController = StreamController<ConnectionInfo>.broadcast();

    // Configuración por defecto de los mocks
    when(() => mockOllama.connectionStream)
        .thenAnswer((_) => ollamaStreamController.stream);
    when(() => mockOllama.connectionInfo).thenReturn(ConnectionInfo(
        status: ConnectionStatus.disconnected, url: '', isHealthy: false));
    when(() => mockLocalOllama.isPlatformSupported).thenReturn(true);
    when(() => mockLocalOllama.addStatusListener(any())).thenAnswer((invocation) {
      capturedStatusListener =
          invocation.positionalArguments[0] as void Function(LocalOllamaStatus);
    });
    when(() => mockLocalOllama.removeStatusListener(any())).thenAnswer((_) {});
    when(() => mockLocalOllama.dispose()).thenAnswer((_) async {});
    when(() => mockOllama.dispose()).thenAnswer((_) async {});
    when(() => mockOpenAI.isAvailable()).thenAnswer((_) async => true);
    when(() => mockLocalOllama.errorMessage).thenReturn(null);

    selector = AIServiceSelector(
      geminiService: mockGemini,
      ollamaService: mockOllama,
      openaiService: mockOpenAI,
      localOllamaService: mockLocalOllama,
    );
  });

  tearDown(() {
    ollamaStreamController.close();
  });

  group('Inicialización y Estado Inicial', () {
    test('Debe inicializar con Gemini como proveedor por defecto', () {
      expect(selector.currentProvider, AIProvider.gemini);
      expect(selector.ollamaAvailable, false);
    });

    test(
        'Debe suscribirse a los cambios de Ollama y LocalOllama al crear la instancia',
        () {
      verify(() => mockOllama.connectionStream).called(1);
      verify(() => mockLocalOllama.addStatusListener(any())).called(1);
    });

    test('Debe inicializar OpenAI durante la construcción', () async {
      // Esperar a que se complete la inicialización asíncrona
      await Future.delayed(Duration.zero);
      verify(() => mockOpenAI.isAvailable()).called(1);
    });

    test('Debe manejar error en inicialización de OpenAI', () async {
      // Crear nuevo selector con OpenAI que falla
      when(() => mockOpenAI.isAvailable()).thenThrow(Exception('API Error'));

      final newSelector = AIServiceSelector(
        geminiService: mockGemini,
        ollamaService: mockOllama,
        openaiService: mockOpenAI,
        localOllamaService: mockLocalOllama,
      );

      await Future.delayed(Duration.zero);
      expect(newSelector.openaiAvailable, false);
    });
  });

  group('Getters', () {
    test('currentOllamaModel retorna el modelo actual de Ollama', () {
      expect(selector.currentOllamaModel, 'phi3:latest');
    });

    test('currentOpenAIModel retorna el modelo actual de OpenAI', () {
      expect(selector.currentOpenAIModel, 'gpt-4o-mini');
    });

    test('availableModels retorna lista vacía inicialmente', () {
      expect(selector.availableModels, isEmpty);
    });

    test('availableOpenAIModels retorna los modelos estáticos de OpenAI', () {
      expect(selector.availableOpenAIModels, OpenAIService.availableModels);
    });

    test('ollamaService retorna el servicio de Ollama', () {
      expect(selector.ollamaService, mockOllama);
    });

    test('openaiService retorna el servicio de OpenAI', () {
      expect(selector.openaiService, mockOpenAI);
    });

    test('geminiService retorna el servicio de Gemini', () {
      expect(selector.geminiService, mockGemini);
    });

    test('localOllamaService retorna el servicio de Ollama Local', () {
      expect(selector.localOllamaService, mockLocalOllama);
    });

    test('connectionInfo retorna la información de conexión de Ollama', () {
      final info = ConnectionInfo(
          status: ConnectionStatus.disconnected, url: '', isHealthy: false);
      when(() => mockOllama.connectionInfo).thenReturn(info);
      expect(selector.connectionInfo.status, ConnectionStatus.disconnected);
    });

    test('connectionStream retorna el stream de conexión de Ollama', () {
      expect(selector.connectionStream, ollamaStreamController.stream);
    });

    test('localOllamaStatus retorna el estado actual de Ollama Local', () {
      expect(selector.localOllamaStatus, LocalOllamaStatus.notInitialized);
    });

    test('localOllamaAvailable retorna true solo cuando está listo', () {
      expect(selector.localOllamaAvailable, false);

      // Simular cambio de estado a ready
      capturedStatusListener(LocalOllamaStatus.ready);
      expect(selector.localOllamaAvailable, true);
    });

    test('localOllamaLoading retorna true cuando está procesando', () {
      expect(selector.localOllamaLoading, false);

      capturedStatusListener(LocalOllamaStatus.downloadingModel);
      expect(selector.localOllamaLoading, true);

      capturedStatusListener(LocalOllamaStatus.starting);
      expect(selector.localOllamaLoading, true);
    });

    test('localOllamaError retorna el mensaje de error del servicio', () {
      when(() => mockLocalOllama.errorMessage).thenReturn('Test error');
      expect(selector.localOllamaError, 'Test error');
    });

    test('isLocalOllamaSupported retorna si la plataforma es compatible', () {
      expect(selector.isLocalOllamaSupported, true);

      when(() => mockLocalOllama.isPlatformSupported).thenReturn(false);
      final newSelector = AIServiceSelector(
        geminiService: mockGemini,
        ollamaService: mockOllama,
        openaiService: mockOpenAI,
        localOllamaService: mockLocalOllama,
      );
      expect(newSelector.isLocalOllamaSupported, false);
    });
  });

  group('Gestión de Proveedores (setProvider)', () {
    test('Debe cambiar exitosamente a Gemini', () async {
      await selector.setProvider(AIProvider.gemini);
      expect(selector.currentProvider, AIProvider.gemini);
    });

    test('Debe lanzar excepción si se elige OpenAI y no está disponible',
        () async {
      when(() => mockOpenAI.isAvailable()).thenAnswer((_) async => false);
      await selector.refreshOpenAIAvailability();

      expect(
          () => selector.setProvider(AIProvider.openai), throwsA(isA<Exception>()));
    });

    test('Debe cambiar a Ollama si está disponible', () async {
      ollamaStreamController.add(ConnectionInfo(
          status: ConnectionStatus.connected, url: '', isHealthy: true));
      await Future.delayed(Duration.zero);

      when(() => mockOllama.getModels()).thenAnswer((_) async => [
            OllamaModel(
                name: 'llama3',
                size: 4,
                digest: 'test',
                modifiedAt: DateTime.now())
          ]);

      await selector.setProvider(AIProvider.ollama);
      expect(selector.currentProvider, AIProvider.ollama);
    });

    test('Debe lanzar excepción si Ollama no está disponible', () async {
      expect(
          () => selector.setProvider(AIProvider.ollama), throwsA(isA<Exception>()));
    });

    test('Debe lanzar excepción si LocalOllama no está listo', () async {
      when(() => mockLocalOllama.isPlatformSupported).thenReturn(true);
      expect(() => selector.setProvider(AIProvider.localOllama),
          throwsA(isA<Exception>()));
    });

    test('Debe lanzar excepción si LocalOllama no está soportado en la plataforma',
        () async {
      when(() => mockLocalOllama.isPlatformSupported).thenReturn(false);

      final newSelector = AIServiceSelector(
        geminiService: mockGemini,
        ollamaService: mockOllama,
        openaiService: mockOpenAI,
        localOllamaService: mockLocalOllama,
      );

      expect(() => newSelector.setProvider(AIProvider.localOllama),
          throwsA(isA<Exception>()));
    });

    test('Debe cambiar a LocalOllama si está listo y soportado', () async {
      when(() => mockLocalOllama.isPlatformSupported).thenReturn(true);
      capturedStatusListener(LocalOllamaStatus.ready);

      await selector.setProvider(AIProvider.localOllama);
      expect(selector.currentProvider, AIProvider.localOllama);
    });

    test('Debe cambiar a OpenAI si está disponible', () async {
      when(() => mockOpenAI.isAvailable()).thenAnswer((_) async => true);
      await selector.refreshOpenAIAvailability();

      await selector.setProvider(AIProvider.openai);
      expect(selector.currentProvider, AIProvider.openai);
    });
  });

  group('Ollama Remoto', () {
    test('_onOllamaConnectionChanged debe cargar modelos al conectar', () async {
      final models = [
        OllamaModel(
            name: 'llama3',
            size: 4,
            digest: 'Llama 3 Model',
            modifiedAt: DateTime.now())
      ];
      when(() => mockOllama.getModels()).thenAnswer((_) async => models);

      ollamaStreamController.add(ConnectionInfo(
          status: ConnectionStatus.connected, url: '', isHealthy: true));
      await Future.delayed(Duration.zero);

      expect(selector.ollamaAvailable, true);
      expect(selector.availableModels, models);
      expect(selector.currentOllamaModel, 'llama3');
    });

    test('_onOllamaConnectionChanged debe vaciar modelos al desconectar',
        () async {
      final models = [
        OllamaModel(
            name: 'llama3',
            size: 4,
            digest: 'test',
            modifiedAt: DateTime.now())
      ];
      when(() => mockOllama.getModels()).thenAnswer((_) async => models);

      // Primero conectar
      ollamaStreamController.add(ConnectionInfo(
          status: ConnectionStatus.connected, url: '', isHealthy: true));
      await Future.delayed(Duration.zero);
      expect(selector.ollamaAvailable, true);

      // Luego desconectar
      ollamaStreamController.add(ConnectionInfo(
          status: ConnectionStatus.disconnected, url: '', isHealthy: false));
      await Future.delayed(Duration.zero);

      expect(selector.ollamaAvailable, false);
      expect(selector.availableModels, isEmpty);
    });

    test('No debe recargar modelos si ya estaba conectado', () async {
      final models = [
        OllamaModel(
            name: 'llama3',
            size: 4,
            digest: 'test',
            modifiedAt: DateTime.now())
      ];
      when(() => mockOllama.getModels()).thenAnswer((_) async => models);

      // Primera conexión
      ollamaStreamController.add(ConnectionInfo(
          status: ConnectionStatus.connected, url: '', isHealthy: true));
      await Future.delayed(Duration.zero);

      // Segunda conexión (ya estaba conectado)
      ollamaStreamController.add(ConnectionInfo(
          status: ConnectionStatus.connected, url: '', isHealthy: true));
      await Future.delayed(Duration.zero);

      // getModels solo debe haberse llamado una vez
      verify(() => mockOllama.getModels()).called(1);
    });

    test('setOllamaModel debe lanzar error si el modelo no existe en la lista',
        () {
      expect(
          () => selector.setOllamaModel('non-existent'), throwsA(isA<Exception>()));
    });

    test('setOllamaModel debe cambiar el modelo si existe', () async {
      final models = [
        OllamaModel(
            name: 'llama3', size: 4, digest: 'test', modifiedAt: DateTime.now()),
        OllamaModel(
            name: 'mistral', size: 4, digest: 'test', modifiedAt: DateTime.now())
      ];
      when(() => mockOllama.getModels()).thenAnswer((_) async => models);

      ollamaStreamController.add(ConnectionInfo(
          status: ConnectionStatus.connected, url: '', isHealthy: true));
      await Future.delayed(Duration.zero);

      await selector.setOllamaModel('mistral');
      expect(selector.currentOllamaModel, 'mistral');
    });

    test('refreshOllama debe llamar a reconnect del servicio', () async {
      when(() => mockOllama.reconnect()).thenAnswer((_) async {});

      await selector.refreshOllama();

      verify(() => mockOllama.reconnect()).called(1);
    });

    test('refreshOllama debe manejar errores', () async {
      when(() => mockOllama.reconnect()).thenThrow(Exception('Connection error'));

      // No debe lanzar excepción
      await selector.refreshOllama();

      verify(() => mockOllama.reconnect()).called(1);
    });

    test('Debe usar el primer modelo disponible si el actual no existe',
        () async {
      final models = [
        OllamaModel(
            name: 'mistral', size: 4, digest: 'test', modifiedAt: DateTime.now()),
        OllamaModel(
            name: 'llama3', size: 4, digest: 'test', modifiedAt: DateTime.now())
      ];
      when(() => mockOllama.getModels()).thenAnswer((_) async => models);

      ollamaStreamController.add(ConnectionInfo(
          status: ConnectionStatus.connected, url: '', isHealthy: true));
      await Future.delayed(Duration.zero);

      // El modelo por defecto es phi3:latest que no está en la lista
      expect(selector.currentOllamaModel, 'mistral');
    });

    test('Debe manejar error al cargar modelos', () async {
      when(() => mockOllama.getModels()).thenThrow(Exception('Network error'));

      ollamaStreamController.add(ConnectionInfo(
          status: ConnectionStatus.connected, url: '', isHealthy: true));
      await Future.delayed(Duration.zero);

      expect(selector.availableModels, isEmpty);
    });

    test('Debe manejar lista de modelos vacía', () async {
      when(() => mockOllama.getModels()).thenAnswer((_) async => []);

      ollamaStreamController.add(ConnectionInfo(
          status: ConnectionStatus.connected, url: '', isHealthy: true));
      await Future.delayed(Duration.zero);

      expect(selector.availableModels, isEmpty);
    });
  });

  group('OpenAI', () {
    test('refreshOpenAIAvailability actualiza el estado correctamente', () async {
      when(() => mockOpenAI.isAvailable()).thenAnswer((_) async => true);
      await selector.refreshOpenAIAvailability();
      expect(selector.openaiAvailable, true);
    });

    test('refreshOpenAIAvailability maneja errores correctamente', () async {
      when(() => mockOpenAI.isAvailable()).thenThrow(Exception('API Error'));

      await selector.refreshOpenAIAvailability();

      expect(selector.openaiAvailable, false);
    });

    test('setOpenAIModel cambia el modelo si es válido', () async {
      await selector.setOpenAIModel('gpt-4o-mini');
      expect(selector.currentOpenAIModel, 'gpt-4o-mini');
    });

    test('setOpenAIModel lanza excepción si el modelo no es válido', () async {
      expect(() => selector.setOpenAIModel('invalid-model'),
          throwsA(isA<Exception>()));
    });
  });

  group('Local Ollama', () {
    test('initializeLocalOllama debe delegar al servicio gestionado', () async {
      final result = LocalOllamaInitResult(success: true, modelName: 'phi3');
      when(() => mockLocalOllama.initialize()).thenAnswer((_) async => result);

      final response = await selector.initializeLocalOllama();

      expect(response.success, true);
      verify(() => mockLocalOllama.initialize()).called(1);
    });

    test('initializeLocalOllama con modelos disponibles', () async {
      final result = LocalOllamaInitResult(
        success: true,
        modelName: 'phi3',
        availableModels: ['phi3', 'llama3'],
      );
      when(() => mockLocalOllama.initialize()).thenAnswer((_) async => result);

      final response = await selector.initializeLocalOllama();

      expect(response.success, true);
      expect(response.availableModels, ['phi3', 'llama3']);
    });

    test('initializeLocalOllama con error', () async {
      final result = LocalOllamaInitResult(
        success: false,
        error: 'Initialization failed',
      );
      when(() => mockLocalOllama.initialize()).thenAnswer((_) async => result);

      final response = await selector.initializeLocalOllama();

      expect(response.success, false);
      expect(response.error, 'Initialization failed');
    });

    test('stopLocalOllama debe detener el servicio', () async {
      when(() => mockLocalOllama.stop()).thenAnswer((_) async {});

      await selector.stopLocalOllama();

      verify(() => mockLocalOllama.stop()).called(1);
    });

    test('stopLocalOllama debe cambiar a Gemini si estaba usando LocalOllama',
        () async {
      // Primero poner LocalOllama como proveedor
      capturedStatusListener(LocalOllamaStatus.ready);
      await selector.setProvider(AIProvider.localOllama);
      expect(selector.currentProvider, AIProvider.localOllama);

      when(() => mockLocalOllama.stop()).thenAnswer((_) async {});

      await selector.stopLocalOllama();

      expect(selector.currentProvider, AIProvider.gemini);
      verify(() => mockLocalOllama.stop()).called(1);
    });

    test('retryLocalOllama debe reintentar la inicialización', () async {
      final result = LocalOllamaInitResult(success: true, modelName: 'phi3');
      when(() => mockLocalOllama.retry()).thenAnswer((_) async => result);

      final response = await selector.retryLocalOllama();

      expect(response.success, true);
      verify(() => mockLocalOllama.retry()).called(1);
    });

    test('setLocalOllamaModel debe cambiar el modelo exitosamente', () async {
      when(() => mockLocalOllama.changeModel('llama3'))
          .thenAnswer((_) async => true);

      final success = await selector.setLocalOllamaModel('llama3');

      expect(success, true);
      verify(() => mockLocalOllama.changeModel('llama3')).called(1);
    });

    test('setLocalOllamaModel debe retornar false si falla', () async {
      when(() => mockLocalOllama.changeModel('invalid'))
          .thenAnswer((_) async => false);

      final success = await selector.setLocalOllamaModel('invalid');

      expect(success, false);
    });

    test('_onLocalOllamaStatusChanged actualiza el estado y notifica', () {
      var notified = false;
      selector.addListener(() => notified = true);

      capturedStatusListener(LocalOllamaStatus.ready);

      expect(selector.localOllamaStatus, LocalOllamaStatus.ready);
      expect(notified, true);
    });
  });

  group('Adaptadores', () {
    test('getCurrentAdapter retorna GeminiServiceAdapter para Gemini', () {
      expect(selector.getCurrentAdapter(), isA<GeminiServiceAdapter>());
    });

    test('getCurrentAdapter retorna OpenAIServiceAdapter para OpenAI', () async {
      when(() => mockOpenAI.isAvailable()).thenAnswer((_) async => true);
      await selector.refreshOpenAIAvailability();
      await selector.setProvider(AIProvider.openai);

      expect(selector.getCurrentAdapter(), isA<OpenAIServiceAdapter>());
    });

    test('getCurrentAdapter retorna OllamaServiceAdapter para Ollama', () async {
      final models = [
        OllamaModel(
            name: 'llama3', size: 4, digest: 'test', modifiedAt: DateTime.now())
      ];
      when(() => mockOllama.getModels()).thenAnswer((_) async => models);

      ollamaStreamController.add(ConnectionInfo(
          status: ConnectionStatus.connected, url: '', isHealthy: true));
      await Future.delayed(Duration.zero);

      await selector.setProvider(AIProvider.ollama);

      expect(selector.getCurrentAdapter(), isA<OllamaServiceAdapter>());
    });

    test('getCurrentAdapter retorna LocalOllamaServiceAdapter para LocalOllama',
        () async {
      capturedStatusListener(LocalOllamaStatus.ready);
      await selector.setProvider(AIProvider.localOllama);

      expect(selector.getCurrentAdapter(), isA<LocalOllamaServiceAdapter>());
    });
  });

  group('Dispose', () {
    test('dispose cancela suscripciones y libera servicios', () {
      selector.dispose();

      verify(() => mockOllama.dispose()).called(1);
      verify(() => mockLocalOllama.dispose()).called(1);
      verify(() => mockLocalOllama.removeStatusListener(any())).called(1);
    });
  });

  group('Notificaciones', () {
    test('notifyListeners se llama al cambiar proveedor', () async {
      var notified = false;
      selector.addListener(() => notified = true);

      await selector.setProvider(AIProvider.gemini);

      expect(notified, true);
    });

    test('notifyListeners se llama al cambiar modelo Ollama', () async {
      final models = [
        OllamaModel(
            name: 'llama3', size: 4, digest: 'test', modifiedAt: DateTime.now()),
        OllamaModel(
            name: 'mistral', size: 4, digest: 'test', modifiedAt: DateTime.now())
      ];
      when(() => mockOllama.getModels()).thenAnswer((_) async => models);

      ollamaStreamController.add(ConnectionInfo(
          status: ConnectionStatus.connected, url: '', isHealthy: true));
      await Future.delayed(Duration.zero);

      var notified = false;
      selector.addListener(() => notified = true);

      await selector.setOllamaModel('mistral');

      expect(notified, true);
    });

    test('notifyListeners se llama al cambiar modelo OpenAI', () async {
      var notified = false;
      selector.addListener(() => notified = true);

      await selector.setOpenAIModel('gpt-4o-mini');

      expect(notified, true);
    });

    test('notifyListeners se llama al refrescar OpenAI', () async {
      var notified = false;
      selector.addListener(() => notified = true);

      when(() => mockOpenAI.isAvailable()).thenAnswer((_) async => true);
      await selector.refreshOpenAIAvailability();

      expect(notified, true);
    });

    test('notifyListeners se llama al cambiar conexión Ollama', () async {
      when(() => mockOllama.getModels()).thenAnswer((_) async => []);

      var notified = false;
      selector.addListener(() => notified = true);

      ollamaStreamController.add(ConnectionInfo(
          status: ConnectionStatus.connected, url: '', isHealthy: true));
      await Future.delayed(Duration.zero);

      expect(notified, true);
    });

    test('notifyListeners se llama al detener LocalOllama', () async {
      when(() => mockLocalOllama.stop()).thenAnswer((_) async {});

      var notified = false;
      selector.addListener(() => notified = true);

      await selector.stopLocalOllama();

      expect(notified, true);
    });

    test('notifyListeners se llama al inicializar LocalOllama', () async {
      final result = LocalOllamaInitResult(success: true, modelName: 'phi3');
      when(() => mockLocalOllama.initialize()).thenAnswer((_) async => result);

      var notified = false;
      selector.addListener(() => notified = true);

      await selector.initializeLocalOllama();

      expect(notified, true);
    });
  });

  group('Casos edge del modelo Ollama actual', () {
    test('Mantiene el modelo actual si existe en la lista de modelos', () async {
      // Cambiar el modelo actual primero
      final models = [
        OllamaModel(
            name: 'phi3:latest',
            size: 4,
            digest: 'test',
            modifiedAt: DateTime.now()),
        OllamaModel(
            name: 'llama3', size: 4, digest: 'test', modifiedAt: DateTime.now())
      ];
      when(() => mockOllama.getModels()).thenAnswer((_) async => models);

      ollamaStreamController.add(ConnectionInfo(
          status: ConnectionStatus.connected, url: '', isHealthy: true));
      await Future.delayed(Duration.zero);

      // El modelo por defecto phi3:latest está en la lista
      expect(selector.currentOllamaModel, 'phi3:latest');
    });
  });
}