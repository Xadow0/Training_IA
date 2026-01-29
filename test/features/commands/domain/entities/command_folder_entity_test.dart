import 'package:flutter_test/flutter_test.dart';
import 'package:chatbot_app/features/commands/domain/entities/command_folder_entity.dart';

void main() {
  group('CommandFolderEntity', () {
    final fixedDate = DateTime(2024, 1, 1);

    test('constructor sets required fields and default values', () {
      final folder = CommandFolderEntity(
        id: '1',
        name: 'Utilidades',
        createdAt: fixedDate,
      );

      expect(folder.id, '1');
      expect(folder.name, 'Utilidades');
      expect(folder.icon, null);
      expect(folder.order, 0);
      expect(folder.createdAt, fixedDate);
    });

    test('constructor allows optional fields', () {
      final folder = CommandFolderEntity(
        id: '2',
        name: 'Sistema',
        icon: '⚙️',
        order: 5,
        createdAt: fixedDate,
      );

      expect(folder.icon, '⚙️');
      expect(folder.order, 5);
    });

    test('copyWith updates only provided fields', () {
      final original = CommandFolderEntity(
        id: '1',
        name: 'Base',
        icon: '📁',
        order: 1,
        createdAt: fixedDate,
      );

      final updated = original.copyWith(
        name: 'Actualizado',
        order: 2,
      );

      expect(updated.id, original.id);
      expect(updated.name, 'Actualizado');
      expect(updated.icon, original.icon);
      expect(updated.order, 2);
      expect(updated.createdAt, fixedDate);
    });

    test('copyWith can update icon and createdAt', () {
      final original = CommandFolderEntity(
        id: '1',
        name: 'Base',
        icon: null,
        createdAt: fixedDate,
      );

      final newDate = fixedDate.add(const Duration(days: 1));

      final updated = original.copyWith(
        icon: '📂',
        createdAt: newDate,
      );

      expect(updated.icon, '📂');
      expect(updated.createdAt, newDate);
    });

    test('equatable: identical folders are equal', () {
      final folder1 = CommandFolderEntity(
        id: '1',
        name: 'Carpeta',
        icon: '📁',
        order: 1,
        createdAt: fixedDate,
      );

      final folder2 = CommandFolderEntity(
        id: '1',
        name: 'Carpeta',
        icon: '📁',
        order: 1,
        createdAt: fixedDate,
      );

      expect(folder1, equals(folder2));
      expect(folder1.hashCode, folder2.hashCode);
    });

    test('equatable: different folders are not equal', () {
      final folder1 = CommandFolderEntity(
        id: '1',
        name: 'Carpeta',
        createdAt: fixedDate,
      );

      final folder2 = CommandFolderEntity(
        id: '2',
        name: 'Carpeta',
        createdAt: fixedDate,
      );

      expect(folder1 == folder2, false);
    });

    test('props contains all fields in correct order', () {
      final folder = CommandFolderEntity(
        id: '1',
        name: 'Carpeta',
        icon: '📁',
        order: 3,
        createdAt: fixedDate,
      );

      expect(folder.props, [
        folder.id,
        folder.name,
        folder.icon,
        folder.order,
        folder.createdAt,
      ]);
    });
  });
}
