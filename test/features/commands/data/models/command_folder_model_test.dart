import 'package:flutter_test/flutter_test.dart';
import 'package:chatbot_app/features/commands/data/models/command_folder_model.dart';
import 'package:chatbot_app/features/commands/domain/entities/command_folder_entity.dart';

void main() {
  group('CommandFolderModel', () {
    final fixedDate = DateTime(2024, 1, 1);

    test('constructor creates model correctly', () {
      final model = CommandFolderModel(
        id: '1',
        name: 'Carpeta',
        icon: '📁',
        order: 2,
        createdAt: fixedDate,
      );

      expect(model.id, '1');
      expect(model.name, 'Carpeta');
      expect(model.icon, '📁');
      expect(model.order, 2);
      expect(model.createdAt, fixedDate);
    });

    test('fromJson parses full json correctly', () {
      final json = {
        'id': '1',
        'name': 'Carpeta',
        'icon': '📁',
        'order': 3,
        'createdAt': fixedDate.toIso8601String(),
      };

      final model = CommandFolderModel.fromJson(json);

      expect(model.id, '1');
      expect(model.name, 'Carpeta');
      expect(model.icon, '📁');
      expect(model.order, 3);
      expect(model.createdAt, fixedDate);
    });

    test('fromJson uses defaults when optional fields are missing', () {
      final model = CommandFolderModel.fromJson({
        'id': '1',
        'name': 'Carpeta',
      });

      expect(model.icon, null);
      expect(model.order, 0);
      expect(model.createdAt, isA<DateTime>());
    });

    test('toJson serializes correctly', () {
      final model = CommandFolderModel(
        id: '1',
        name: 'Carpeta',
        icon: null,
        order: 0,
        createdAt: fixedDate,
      );

      expect(model.toJson(), {
        'id': '1',
        'name': 'Carpeta',
        'icon': null,
        'order': 0,
        'createdAt': fixedDate.toIso8601String(),
      });
    });

    test('fromEntity converts correctly', () {
      final entity = CommandFolderEntity(
        id: '1',
        name: 'Carpeta',
        icon: '📁',
        order: 1,
        createdAt: fixedDate,
      );

      final model = CommandFolderModel.fromEntity(entity);

      expect(model.id, entity.id);
      expect(model.name, entity.name);
      expect(model.icon, entity.icon);
      expect(model.order, entity.order);
      expect(model.createdAt, entity.createdAt);
    });

    test('copyWith overrides correctly and returns CommandFolderModel', () {
      final original = CommandFolderModel(
        id: '1',
        name: 'Original',
        icon: '📁',
        order: 1,
        createdAt: fixedDate,
      );

      final updated = original.copyWith(
        name: 'Actualizado',
        order: 2,
      );

      expect(updated, isA<CommandFolderModel>());
      expect(updated.id, '1');
      expect(updated.name, 'Actualizado');
      expect(updated.icon, '📁');
      expect(updated.order, 2);
      expect(updated.createdAt, fixedDate);
    });

    test('equatable: model equality works via inherited props', () {
      final model1 = CommandFolderModel(
        id: '1',
        name: 'Carpeta',
        createdAt: fixedDate,
      );

      final model2 = CommandFolderModel(
        id: '1',
        name: 'Carpeta',
        createdAt: fixedDate,
      );

      expect(model1, equals(model2));
      expect(model1.hashCode, model2.hashCode);
    });
  });
}
