import 'package:flutter_test/flutter_test.dart';
import 'package:chatbot_app/features/chat/domain/entities/local_ollama_entity.dart'; // Ajusta la ruta

void main() {
  group('LocalOllamaStatusEntity Extension', () {
    test('displayText returns correct Spanish strings', () {
      expect(LocalOllamaStatusEntity.notInitialized.displayText, 'No inicializado');
      expect(LocalOllamaStatusEntity.checkingInstallation.displayText, 'Verificando instalación...');
      expect(LocalOllamaStatusEntity.downloadingInstaller.displayText, 'Descargando Ollama...');
      expect(LocalOllamaStatusEntity.installing.displayText, 'Instalando Ollama...');
      expect(LocalOllamaStatusEntity.downloadingModel.displayText, 'Descargando modelo de IA...');
      expect(LocalOllamaStatusEntity.starting.displayText, 'Iniciando servidor...');
      expect(LocalOllamaStatusEntity.loading.displayText, 'Cargando modelo...');
      expect(LocalOllamaStatusEntity.ready.displayText, 'Listo');
      expect(LocalOllamaStatusEntity.error.displayText, 'Error');
    });

    test('emoji returns correct status indicators', () {
      expect(LocalOllamaStatusEntity.notInitialized.emoji, '⚫');
      expect(LocalOllamaStatusEntity.ready.emoji, '🟢');
      expect(LocalOllamaStatusEntity.error.emoji, '🔴');
      // Verificamos uno del grupo amarillo
      expect(LocalOllamaStatusEntity.installing.emoji, '🟡');
    });

    test('isUsable only true when status is ready', () {
      expect(LocalOllamaStatusEntity.ready.isUsable, isTrue);
      expect(LocalOllamaStatusEntity.error.isUsable, isFalse);
    });

    test('isProcessing returns true for all intermediate states', () {
      final processingStates = [
        LocalOllamaStatusEntity.checkingInstallation,
        LocalOllamaStatusEntity.downloadingInstaller,
        LocalOllamaStatusEntity.installing,
        LocalOllamaStatusEntity.downloadingModel,
        LocalOllamaStatusEntity.starting,
        LocalOllamaStatusEntity.loading,
      ];

      for (var state in processingStates) {
        expect(state.isProcessing, isTrue, reason: 'State $state should be processing');
      }

      expect(LocalOllamaStatusEntity.ready.isProcessing, isFalse);
      expect(LocalOllamaStatusEntity.error.isProcessing, isFalse);
    });
  });

  group('OllamaInstallationInfoEntity', () {
    test('needsInstallation logic', () {
      const info = OllamaInstallationInfoEntity(isInstalled: false, canExecute: false);
      expect(info.needsInstallation, isTrue);
      
      const infoInstalledButNoExec = OllamaInstallationInfoEntity(isInstalled: true, canExecute: false);
      expect(infoInstalledButNoExec.needsInstallation, isTrue);
      
      const infoReady = OllamaInstallationInfoEntity(isInstalled: true, canExecute: true);
      expect(infoReady.needsInstallation, isFalse);
    });

    test('copyWith creates new instance with updated values', () {
      const info = OllamaInstallationInfoEntity(isInstalled: false, canExecute: false);
      final updated = info.copyWith(isInstalled: true, version: '1.0.0');
      
      expect(updated.isInstalled, isTrue);
      expect(updated.version, '1.0.0');
      expect(updated.canExecute, isFalse); // Mantiene el original
    });
  });

  group('LocalOllamaInstallProgressEntity', () {
    test('progressText format with bytes', () {
      const progress = LocalOllamaInstallProgressEntity(
        status: LocalOllamaStatusEntity.downloadingModel,
        progress: 0.5,
        bytesDownloaded: 1048576, // 1MB
        totalBytes: 2097152,      // 2MB
      );
      expect(progress.progressText, '1.0 MB / 2.0 MB');
    });

    test('progressText format with percentage when bytes are null', () {
      const progress = LocalOllamaInstallProgressEntity(
        status: LocalOllamaStatusEntity.installing,
        progress: 0.75,
      );
      expect(progress.progressText, '75%');
    });

    test('copyWith functional check', () {
      const progress = LocalOllamaInstallProgressEntity(status: LocalOllamaStatusEntity.loading, progress: 0.1);
      final updated = progress.copyWith(progress: 0.9, message: 'Done');
      expect(updated.progress, 0.9);
      expect(updated.message, 'Done');
      expect(updated.status, LocalOllamaStatusEntity.loading);
    });
  });

  group('LocalOllamaInitResultEntity', () {
    test('userMessage returns correct format for success (New Install)', () {
      final result = LocalOllamaInitResultEntity(
        success: true,
        modelName: 'llama3',
        availableModels: ['llama3', 'phi3'],
        initTime: const Duration(seconds: 5),
        wasNewInstallation: true,
      );
      expect(result.userMessage, contains('Ollama instalado correctamente'));
      expect(result.userMessage, contains('Modelo activo: llama3'));
      expect(result.userMessage, contains('Tiempo: 5s'));
    });

    test('userMessage returns correct format for error', () {
      const result = LocalOllamaInitResultEntity(success: false, error: 'Timeout');
      expect(result.userMessage, '❌ Error: Timeout');
    });

    test('copyWith functional check', () {
      const result = LocalOllamaInitResultEntity(success: false);
      final updated = result.copyWith(success: true, modelName: 'test');
      expect(updated.success, isTrue);
      expect(updated.modelName, 'test');
    });
  });

  group('LocalOllamaModelEntity', () {
    const model1 = LocalOllamaModelEntity(
      name: 'llama3',
      displayName: 'Llama 3',
      description: 'Desc',
      isDownloaded: true,
      estimatedSize: '4.7GB',
      parametersB: 8,
    );

    test('Equality and HashCode', () {
      const model2 = LocalOllamaModelEntity(
        name: 'llama3',
        displayName: 'Llama 3',
        description: 'Desc',
        isDownloaded: true,
        estimatedSize: '4.7GB',
        parametersB: 8,
      );

      expect(model1, equals(model2));
      expect(model1.hashCode, equals(model2.hashCode));
    });

    test('copyWith functional check', () {
      final updated = model1.copyWith(isDownloaded: false);
      expect(updated.isDownloaded, isFalse);
      expect(updated.name, model1.name);
    });
  });

  group('LocalOllamaConfigEntity', () {
    test('default values and fullBaseUrl', () {
      const config = LocalOllamaConfigEntity();
      expect(config.fullBaseUrl, 'http://localhost:11434');
      expect(config.temperature, 0.7);
    });

    test('copyWith functional check', () {
      const config = LocalOllamaConfigEntity();
      final updated = config.copyWith(port: 8080, temperature: 0.1);
      expect(updated.fullBaseUrl, 'http://localhost:8080');
      expect(updated.temperature, 0.1);
    });
  });
}