import 'package:flutter_test/flutter_test.dart';
import 'package:chatbot_app/features/commands/data/models/command_model.dart';
import 'package:chatbot_app/features/commands/domain/entities/command_entity.dart';

void main() {
  group('CommandModel', () {
    test('constructor creates model correctly', () {
      final model = CommandModel(
        id: '1',
        trigger: '/test',
        title: 'Test',
        description: 'Description',
        promptTemplate: 'Prompt',
        isSystem: true,
        systemType: SystemCommandType.codigo,
        isEditable: true,
        folderId: 'folder1',
      );

      expect(model.id, '1');
      expect(model.trigger, '/test');
      expect(model.title, 'Test');
      expect(model.description, 'Description');
      expect(model.promptTemplate, 'Prompt');
      expect(model.isSystem, true);
      expect(model.systemType, SystemCommandType.codigo);
      expect(model.isEditable, true);
      expect(model.folderId, 'folder1');
    });

    test('fromJson parses full json correctly', () {
      final json = {
        'id': '1',
        'trigger': '/test',
        'title': 'Test',
        'description': 'Description',
        'promptTemplate': 'Prompt',
        'isSystem': true,
        'systemType': 'traducir',
        'isEditable': true,
        'folderId': 'folder1',
      };

      final model = CommandModel.fromJson(json);

      expect(model.systemType, SystemCommandType.traducir);
      expect(model.isSystem, true);
      expect(model.isEditable, true);
      expect(model.folderId, 'folder1');
    });

    test('fromJson uses defaults for optional values', () {
      final model = CommandModel.fromJson({
        'id': '1',
        'trigger': '/test',
        'title': 'Test',
        'description': 'Description',
        'promptTemplate': 'Prompt',
      });

      expect(model.isSystem, false);
      expect(model.isEditable, false);
      expect(model.systemType, SystemCommandType.none);
      expect(model.folderId, null);
    });

    test('fromJson handles invalid systemType safely', () {
      final model = CommandModel.fromJson({
        'id': '1',
        'trigger': '/test',
        'title': 'Test',
        'description': 'Description',
        'promptTemplate': 'Prompt',
        'systemType': 'invalid_value',
      });

      expect(model.systemType, SystemCommandType.none);
    });

    test('toJson serializes correctly', () {
      final model = CommandModel(
        id: '1',
        trigger: '/test',
        title: 'Test',
        description: 'Description',
        promptTemplate: 'Prompt',
        isSystem: true,
        systemType: SystemCommandType.explicar,
        isEditable: false,
        folderId: 'folder1',
      );

      expect(model.toJson(), {
        'id': '1',
        'trigger': '/test',
        'title': 'Test',
        'description': 'Description',
        'promptTemplate': 'Prompt',
        'isSystem': true,
        'systemType': 'explicar',
        'isEditable': false,
        'folderId': 'folder1',
      });
    });

    test('fromEntity converts correctly', () {
      final entity = CommandEntity(
        id: '1',
        trigger: '/test',
        title: 'Test',
        description: 'Description',
        promptTemplate: 'Prompt',
        isSystem: true,
        systemType: SystemCommandType.resumir,
        isEditable: true,
        folderId: 'folder1',
      );

      final model = CommandModel.fromEntity(entity);

      expect(model, isA<CommandModel>());
      expect(model.systemType, SystemCommandType.resumir);
      expect(model.isEditable, true);
    });

    test('copyWith overrides values correctly', () {
      final original = CommandModel(
        id: '1',
        trigger: '/test',
        title: 'Test',
        description: 'Description',
        promptTemplate: 'Prompt',
        folderId: 'folder1',
      );

      final updated = original.copyWith(
        title: 'Updated',
        isEditable: true,
      );

      expect(updated.title, 'Updated');
      expect(updated.isEditable, true);
      expect(updated.folderId, 'folder1');
    });

    test('copyWith clearFolderId removes folderId', () {
      final original = CommandModel(
        id: '1',
        trigger: '/test',
        title: 'Test',
        description: 'Description',
        promptTemplate: 'Prompt',
        folderId: 'folder1',
      );

      final updated = original.copyWith(clearFolderId: true);

      expect(updated.folderId, null);
    });

    test('equatable equality works correctly', () {
      final a = CommandModel(
        id: '1',
        trigger: '/test',
        title: 'Test',
        description: 'Description',
        promptTemplate: 'Prompt',
      );

      final b = CommandModel(
        id: '1',
        trigger: '/test',
        title: 'Test',
        description: 'Description',
        promptTemplate: 'Prompt',
      );

      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });
  });

  group('CommandModel.getDefaultCommands', () {
    final commands = CommandModel.getDefaultCommands();

    test('returns non-empty list', () {
      expect(commands, isNotEmpty);
    });

    test('all default commands are system and non-editable', () {
      for (final cmd in commands) {
        expect(cmd.isSystem, true);
        expect(cmd.isEditable, false);
        expect(cmd.promptTemplate.trim(), isNotEmpty);
      }
    });

    test('contains required system command types', () {
      final types = commands.map((c) => c.systemType).toSet();

      expect(types, contains(SystemCommandType.evaluarPrompt));
      expect(types, contains(SystemCommandType.traducir));
      expect(types, contains(SystemCommandType.resumir));
      expect(types, contains(SystemCommandType.codigo));
      expect(types, contains(SystemCommandType.corregir));
      expect(types, contains(SystemCommandType.explicar));
      expect(types, contains(SystemCommandType.comparar));
    });

    test('triggers are unique', () {
      final triggers = commands.map((c) => c.trigger).toList();
      expect(triggers.length, triggers.toSet().length);
    });
  });
}
