import 'package:flutter_test/flutter_test.dart';
import 'package:chatbot_app/features/commands/domain/entities/command_entity.dart';

void main() {
  group('CommandEntity', () {
    const baseCommand = CommandEntity(
      id: '1',
      trigger: '/traducir',
      title: 'Traducir',
      description: 'Traduce texto',
      promptTemplate: 'Traduce {{content}}',
    );

    test('constructor sets required fields and defaults', () {
      expect(baseCommand.id, '1');
      expect(baseCommand.trigger, '/traducir');
      expect(baseCommand.title, 'Traducir');
      expect(baseCommand.description, 'Traduce texto');
      expect(baseCommand.promptTemplate, 'Traduce {{content}}');

      // Defaults
      expect(baseCommand.isSystem, false);
      expect(baseCommand.systemType, SystemCommandType.none);
      expect(baseCommand.isEditable, false);
      expect(baseCommand.folderId, null);
    });

    test('constructor allows custom optional values', () {
      const command = CommandEntity(
        id: '2',
        trigger: '/resumir',
        title: 'Resumir',
        description: 'Resume texto',
        promptTemplate: 'Resume {{content}}',
        isSystem: true,
        systemType: SystemCommandType.resumir,
        isEditable: true,
        folderId: 'folder-1',
      );

      expect(command.isSystem, true);
      expect(command.systemType, SystemCommandType.resumir);
      expect(command.isEditable, true);
      expect(command.folderId, 'folder-1');
    });

    test('copyWith modifies only provided fields', () {
      final updated = baseCommand.copyWith(
        title: 'Traducir texto',
        isEditable: true,
      );

      expect(updated.id, baseCommand.id);
      expect(updated.trigger, baseCommand.trigger);
      expect(updated.title, 'Traducir texto');
      expect(updated.isEditable, true);
      expect(updated.systemType, baseCommand.systemType);
    });

    test('copyWith replaces folderId', () {
      final withFolder = baseCommand.copyWith(folderId: 'folder-1');

      expect(withFolder.folderId, 'folder-1');
    });

    test('copyWith clears folderId when clearFolderId is true', () {
      final withFolder = baseCommand.copyWith(folderId: 'folder-1');

      final cleared = withFolder.copyWith(clearFolderId: true);

      expect(cleared.folderId, null);
    });

    test('copyWith allows changing systemType and isSystem', () {
      final updated = baseCommand.copyWith(
        isSystem: true,
        systemType: SystemCommandType.traducir,
      );

      expect(updated.isSystem, true);
      expect(updated.systemType, SystemCommandType.traducir);
    });

    test('equatable: two identical commands are equal', () {
      const command1 = CommandEntity(
        id: '1',
        trigger: '/codigo',
        title: 'Código',
        description: 'Genera código',
        promptTemplate: 'Genera {{content}}',
      );

      const command2 = CommandEntity(
        id: '1',
        trigger: '/codigo',
        title: 'Código',
        description: 'Genera código',
        promptTemplate: 'Genera {{content}}',
      );

      expect(command1, equals(command2));
      expect(command1.hashCode, command2.hashCode);
    });

    test('equatable: different commands are not equal', () {
      const command1 = CommandEntity(
        id: '1',
        trigger: '/codigo',
        title: 'Código',
        description: 'Genera código',
        promptTemplate: 'Genera {{content}}',
      );

      const command2 = CommandEntity(
        id: '2',
        trigger: '/codigo',
        title: 'Código',
        description: 'Genera código',
        promptTemplate: 'Genera {{content}}',
      );

      expect(command1 == command2, false);
    });

    test('props contains all fields in correct order', () {
      final props = baseCommand.props;

      expect(props, [
        baseCommand.id,
        baseCommand.trigger,
        baseCommand.title,
        baseCommand.description,
        baseCommand.promptTemplate,
        baseCommand.isSystem,
        baseCommand.systemType,
        baseCommand.isEditable,
        baseCommand.folderId,
      ]);
    });
  });

  group('SystemCommandType enum', () {
    test('contains all expected values', () {
      expect(SystemCommandType.values, contains(SystemCommandType.none));
      expect(SystemCommandType.values, contains(SystemCommandType.traducir));
      expect(SystemCommandType.values, contains(SystemCommandType.resumir));
      expect(SystemCommandType.values, contains(SystemCommandType.codigo));
      expect(SystemCommandType.values, contains(SystemCommandType.evaluarPrompt));
      expect(SystemCommandType.values, contains(SystemCommandType.corregir));
      expect(SystemCommandType.values, contains(SystemCommandType.explicar));
      expect(SystemCommandType.values, contains(SystemCommandType.comparar));
    });
  });
}
