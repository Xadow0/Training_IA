import 'package:flutter_test/flutter_test.dart';
import 'package:chatbot_app/features/chat/data/models/remote_ollama_models.dart';
import 'package:chatbot_app/features/chat/domain/entities/remote_ollama_entity.dart';

void main() {
  group('OllamaModel', () {
    final fixedDate = DateTime(2024, 1, 1);

    test('fromJson with full data', () {
      final json = {
        'name': 'llama:latest',
        'size': 1073741824, // 1GB
        'digest': 'abc123',
        'modified_at': fixedDate.toIso8601String(),
      };

      final model = OllamaModel.fromJson(json);

      expect(model.name, 'llama:latest');
      expect(model.size, 1073741824);
      expect(model.digest, 'abc123');
      expect(model.modifiedAt, fixedDate);
    });

    test('fromJson with missing fields uses defaults', () {
      final model = OllamaModel.fromJson({});

      expect(model.name, '');
      expect(model.size, 0);
      expect(model.digest, '');
      expect(model.modifiedAt, isA<DateTime>());
    });

    test('sizeFormatted returns Unknown when size is 0', () {
      final model = OllamaModel(
        name: 'test',
        size: 0,
        digest: '',
        modifiedAt: fixedDate,
      );

      expect(model.sizeFormatted, 'Unknown');
    });

    test('sizeFormatted formats GB correctly', () {
      final model = OllamaModel(
        name: 'test',
        size: 1073741824,
        digest: '',
        modifiedAt: fixedDate,
      );

      expect(model.sizeFormatted, '1.0 GB');
    });

    test('displayName removes :latest tag', () {
      final model = OllamaModel(
        name: 'llama:latest',
        size: 1,
        digest: '',
        modifiedAt: fixedDate,
      );

      expect(model.displayName, 'llama');
    });

    test('toEntity converts correctly', () {
      final model = OllamaModel(
        name: 'llama',
        size: 1,
        digest: 'abc',
        modifiedAt: fixedDate,
      );

      final entity = model.toEntity();

      expect(entity.name, 'llama');
      expect(entity.size, 1);
      expect(entity.digest, 'abc');
      expect(entity.modifiedAt, fixedDate);
    });

    test('fromEntity converts correctly', () {
      final entity = OllamaModelEntity(
        name: 'llama',
        size: 1,
        digest: 'abc',
        modifiedAt: fixedDate,
      );

      final model = OllamaModel.fromEntity(entity);

      expect(model.name, 'llama');
      expect(model.size, 1);
      expect(model.digest, 'abc');
      expect(model.modifiedAt, fixedDate);
    });
  });

  group('ChatMessage', () {
    test('toJson serializes correctly', () {
      final message = ChatMessage(role: 'user', content: 'Hola');

      expect(message.toJson(), {
        'role': 'user',
        'content': 'Hola',
      });
    });

    test('fromJson with full data', () {
      final message = ChatMessage.fromJson({
        'role': 'assistant',
        'content': 'Hola',
      });

      expect(message.role, 'assistant');
      expect(message.content, 'Hola');
    });

    test('fromJson with missing data uses defaults', () {
      final message = ChatMessage.fromJson({});

      expect(message.role, 'user');
      expect(message.content, '');
    });
  });

  group('OllamaHealthResponse', () {
    test('fromJson parses full response', () {
      final json = {
        'success': true,
        'status': 'ok',
        'ollama': {
          'available': true,
          'models': 5,
        },
        'tailscale': {
          'ip': '100.0.0.1',
        },
      };

      final response = OllamaHealthResponse.fromJson(json);

      expect(response.success, true);
      expect(response.status, 'ok');
      expect(response.ollamaAvailable, true);
      expect(response.modelCount, 5);
      expect(response.tailscaleIP, '100.0.0.1');
    });

    test('fromJson uses defaults when fields are missing', () {
      final response = OllamaHealthResponse.fromJson({});

      expect(response.success, false);
      expect(response.status, 'unknown');
      expect(response.ollamaAvailable, false);
      expect(response.modelCount, 0);
      expect(response.tailscaleIP, null);
    });

    test('toEntity converts correctly', () {
      final response = OllamaHealthResponse(
        success: true,
        status: 'ok',
        ollamaAvailable: true,
        modelCount: 3,
        tailscaleIP: null,
      );

      final entity = response.toEntity();

      expect(entity.success, true);
      expect(entity.status, 'ok');
      expect(entity.ollamaAvailable, true);
      expect(entity.modelCount, 3);
      expect(entity.tailscaleIP, null);
    });

    test('fromEntity converts correctly', () {
      final entity = OllamaHealthEntity(
        success: true,
        status: 'ok',
        ollamaAvailable: true,
        modelCount: 3,
        tailscaleIP: '1.1.1.1',
      );

      final response = OllamaHealthResponse.fromEntity(entity);

      expect(response.success, true);
      expect(response.status, 'ok');
      expect(response.ollamaAvailable, true);
      expect(response.modelCount, 3);
      expect(response.tailscaleIP, '1.1.1.1');
    });
  });

  group('ConnectionInfo', () {
    test('statusText for all statuses', () {
      expect(
        ConnectionInfo(
          status: ConnectionStatus.connected,
          url: '',
          isHealthy: true,
        ).statusText,
        '🟢 Conectado',
      );

      expect(
        ConnectionInfo(
          status: ConnectionStatus.connecting,
          url: '',
          isHealthy: false,
        ).statusText,
        '🟡 Conectando...',
      );

      expect(
        ConnectionInfo(
          status: ConnectionStatus.disconnected,
          url: '',
          isHealthy: false,
        ).statusText,
        '🔴 Desconectado',
      );

      expect(
        ConnectionInfo(
          status: ConnectionStatus.error,
          url: '',
          isHealthy: false,
        ).statusText,
        '❌ Error',
      );
    });

    test('urlForDisplay short url', () {
      final info = ConnectionInfo(
        status: ConnectionStatus.connected,
        url: 'http://localhost',
        isHealthy: true,
      );

      expect(info.urlForDisplay, 'http://localhost');
    });

    test('urlForDisplay long url', () {
      final info = ConnectionInfo(
        status: ConnectionStatus.connected,
        url: 'http://very-long-url-example.com/api/v1/models',
        isHealthy: true,
      );

      expect(info.urlForDisplay.contains('...'), true);
    });

    test('toEntity and fromEntity conversion', () {
      final health = OllamaHealthResponse(
        success: true,
        status: 'ok',
        ollamaAvailable: true,
        modelCount: 2,
      );

      final info = ConnectionInfo(
        status: ConnectionStatus.connected,
        url: 'http://localhost',
        isHealthy: true,
        errorMessage: null,
        healthData: health,
      );

      final entity = info.toEntity();
      final restored = ConnectionInfo.fromEntity(entity);

      expect(restored.status, ConnectionStatus.connected);
      expect(restored.url, 'http://localhost');
      expect(restored.isHealthy, true);
      expect(restored.healthData!.modelCount, 2);
    });
  });

  group('OllamaException', () {
    test('toString formats correctly', () {
      final exception = OllamaException('Error', statusCode: 500);

      expect(exception.toString(), 'OllamaException: Error');
    });
  });
}
