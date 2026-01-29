import 'package:flutter_test/flutter_test.dart';
import 'package:chatbot_app/features/chat/domain/entities/remote_ollama_entity.dart'; // Ajusta la ruta

void main() {
  group('OllamaModelEntity', () {
    final now = DateTime.now();
    late final model = OllamaModelEntity(
      name: 'llama3:latest',
      size: 4660884275, // ~4.34 GB
      digest: 'sha256:123',
      modifiedAt: now,
    );

    test('sizeFormatted debe convertir bytes a GB correctamente', () {
      expect(model.sizeFormatted, '4.3 GB');
      
      late final zeroModel = OllamaModelEntity(
        name: 'test', size: 0, digest: '', modifiedAt: now,
      );
      expect(zeroModel.sizeFormatted, 'Unknown');
    });

    test('displayName debe eliminar el tag :latest', () {
      expect(model.displayName, 'llama3');
      
      late final otherModel = OllamaModelEntity(
        name: 'phi3:mini', size: 100, digest: '', modifiedAt: now,
      );
      expect(otherModel.displayName, 'phi3:mini');
    });

    test('copyWith y equality', () {
      final m1 = OllamaModelEntity(name: 'a', size: 1, digest: 'd', modifiedAt: now);
      final m2 = m1.copyWith(name: 'b');
      
      expect(m2.name, 'b');
      expect(m2.size, 1);
      expect(m1 == m1.copyWith(), isTrue);
      expect(m1.hashCode, equals(m1.copyWith().hashCode));
    });

    test('toString debe contener información clave', () {
      final m = OllamaModelEntity(name: 'llama', size: 0, digest: 'd', modifiedAt: now);
      expect(m.toString(), contains('llama'));
      expect(m.toString(), contains('Unknown'));
    });
  });

  group('ConnectionInfoEntity', () {
    const urlShort = 'http://localhost:11434';
    const urlLong = 'http://ollama-service-very-long-domain-name-identification.tailscale.net:11434';

    test('statusText debe retornar el string y emoji correcto', () {
      expect(const ConnectionInfoEntity(status: ConnectionStatusEntity.connected, url: '', isHealthy: true).statusText, '🟢 Conectado');
      expect(const ConnectionInfoEntity(status: ConnectionStatusEntity.connecting, url: '', isHealthy: false).statusText, '🟡 Conectando...');
      expect(const ConnectionInfoEntity(status: ConnectionStatusEntity.disconnected, url: '', isHealthy: false).statusText, '🔴 Desconectado');
      expect(const ConnectionInfoEntity(status: ConnectionStatusEntity.error, url: '', isHealthy: false).statusText, '❌ Error');
    });

    test('urlForDisplay debe truncar URLs muy largas', () {
      const infoShort = ConnectionInfoEntity(status: ConnectionStatusEntity.connected, url: urlShort, isHealthy: true);
      const infoLong = ConnectionInfoEntity(status: ConnectionStatusEntity.connected, url: urlLong, isHealthy: true);

      expect(infoShort.urlForDisplay, urlShort);
      expect(infoLong.urlForDisplay, contains('...'));
      expect(infoLong.urlForDisplay.length, lessThan(urlLong.length));
    });

    test('copyWith y equality', () {
      const info = ConnectionInfoEntity(status: ConnectionStatusEntity.connected, url: 'url', isHealthy: true);
      final updated = info.copyWith(status: ConnectionStatusEntity.error, errorMessage: 'Fail');

      expect(updated.status, ConnectionStatusEntity.error);
      expect(updated.errorMessage, 'Fail');
      expect(info == info.copyWith(), isTrue);
      expect(info.hashCode, info.copyWith().hashCode);
    });
  });

  group('OllamaHealthEntity', () {
    test('Valores iniciales y equality', () {
      const health = OllamaHealthEntity(
        success: true,
        status: 'OK',
        ollamaAvailable: true,
        modelCount: 5,
        tailscaleIP: '100.1.2.3',
      );

      expect(health.success, isTrue);
      expect(health.modelCount, 5);
      expect(health == health.copyWith(), isTrue);
      expect(health.hashCode, health.copyWith().hashCode);
    });

    test('copyWith debe actualizar campos individuales', () {
      const health = OllamaHealthEntity(success: true, status: 'OK', ollamaAvailable: true, modelCount: 1);
      final updated = health.copyWith(modelCount: 10, tailscaleIP: 'new-ip');

      expect(updated.modelCount, 10);
      expect(updated.tailscaleIP, 'new-ip');
      expect(updated.status, 'OK');
    });
  });

  group('ConnectionStatusEntity Enum', () {
    test('Debe tener todos los estados requeridos', () {
      expect(ConnectionStatusEntity.values.length, 4);
      expect(ConnectionStatusEntity.values, contains(ConnectionStatusEntity.connected));
    });
  });
}