import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:chatbot_app/features/commands/data/datasources/local_folder_source.dart';
import 'package:chatbot_app/features/commands/data/models/command_folder_model.dart';
import 'package:chatbot_app/core/services/secure_storage_service.dart';

class MockSecureStorageService extends Mock
    implements SecureStorageService {}

void main() {
  late MockSecureStorageService storage;
  late LocalFolderService service;

  CommandFolderModel folder({
    required String id,
    int order = 0,
  }) {
    return CommandFolderModel(
      id: id,
      name: 'Folder $id',
      order: order,
      createdAt: DateTime(2024),
    );
  }

  setUp(() {
    storage = MockSecureStorageService();
    service = LocalFolderService(storage);
  });

  group('getFolders', () {
    test('returns empty list when storage is empty', () async {
      when(() => storage.read(key: any(named: 'key')))
          .thenAnswer((_) async => null);

      final result = await service.getFolders();

      expect(result, isEmpty);
    });

    test('returns sorted folders by order', () async {
      final folders = [
        folder(id: 'b', order: 2),
        folder(id: 'a', order: 0),
        folder(id: 'c', order: 1),
      ];

      when(() => storage.read(key: any(named: 'key')))
          .thenAnswer((_) async => jsonEncode(
                folders.map((f) => f.toJson()).toList(),
              ));

      final result = await service.getFolders();

      expect(result.map((f) => f.id), ['a', 'c', 'b']);
    });

    test('returns empty list on json error', () async {
      when(() => storage.read(key: any(named: 'key')))
          .thenAnswer((_) async => 'invalid json');

      final result = await service.getFolders();

      expect(result, isEmpty);
    });
  });

  group('getFolderById', () {
    test('returns folder when found', () async {
      final f = folder(id: '1');

      when(() => storage.read(key: any(named: 'key')))
          .thenAnswer((_) async => jsonEncode([f.toJson()]));

      final result = await service.getFolderById('1');

      expect(result?.id, '1');
    });

    test('returns null when not found', () async {
      when(() => storage.read(key: any(named: 'key')))
          .thenAnswer((_) async => jsonEncode([]));

      final result = await service.getFolderById('x');

      expect(result, isNull);
    });
  });

  group('saveFolder', () {
    test('adds new folder with incremental order', () async {
      when(() => storage.read(key: any(named: 'key')))
          .thenAnswer((_) async => jsonEncode([
                folder(id: 'a', order: 0).toJson(),
              ]));

      when(() => storage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          )).thenAnswer((_) async {});

      final newFolder = folder(id: 'b');

      await service.saveFolder(newFolder);

      verify(() => storage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          )).called(1);
    });

    test('updates existing folder', () async {
      final original = folder(id: 'a', order: 0);

      when(() => storage.read(key: any(named: 'key')))
          .thenAnswer((_) async => jsonEncode([original.toJson()]));

      when(() => storage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          )).thenAnswer((_) async {});

      final updated = original.copyWith(name: 'Updated');

      await service.saveFolder(updated);

      verify(() => storage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          )).called(1);
    });
  });

  group('saveFolders', () {
    test('merges existing and new folders', () async {
      when(() => storage.read(key: any(named: 'key')))
          .thenAnswer((_) async => jsonEncode([
                folder(id: 'a').toJson(),
              ]));

      when(() => storage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          )).thenAnswer((_) async {});

      await service.saveFolders([
        folder(id: 'a'),
        folder(id: 'b'),
      ]);

      verify(() => storage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          )).called(1);
    });
  });

  group('deleteFolder', () {
    test('removes existing folder', () async {
      when(() => storage.read(key: any(named: 'key')))
          .thenAnswer((_) async => jsonEncode([
                folder(id: 'a').toJson(),
              ]));

      when(() => storage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          )).thenAnswer((_) async {});

      await service.deleteFolder('a');

      verify(() => storage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          )).called(1);
    });

    test('does nothing when folder does not exist', () async {
      when(() => storage.read(key: any(named: 'key')))
          .thenAnswer((_) async => jsonEncode([]));

      await service.deleteFolder('x');

      verifyNever(() => storage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          ));
    });
  });

  group('reorderFolders', () {
    test('reorders folders correctly', () async {
      when(() => storage.read(key: any(named: 'key')))
          .thenAnswer((_) async => jsonEncode([
                folder(id: 'a', order: 0).toJson(),
                folder(id: 'b', order: 1).toJson(),
              ]));

      when(() => storage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          )).thenAnswer((_) async {});

      final result = await service.reorderFolders(['b', 'a']);

      expect(result[0].id, 'b');
      expect(result[0].order, 0);
      expect(result[1].id, 'a');
      expect(result[1].order, 1);
    });

    test('throws if folder id does not exist', () async {
      when(() => storage.read(key: any(named: 'key')))
          .thenAnswer((_) async => jsonEncode([]));

      expect(
        () => service.reorderFolders(['x']),
        throwsException,
      );
    });
  });

  group('deleteAllFolders', () {
    test('deletes storage key', () async {
      when(() => storage.delete(key: any(named: 'key')))
          .thenAnswer((_) async {});

      await service.deleteAllFolders();

      verify(() => storage.delete(key: any(named: 'key'))).called(1);
    });
  });
}
