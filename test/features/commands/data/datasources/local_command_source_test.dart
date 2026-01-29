import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:chatbot_app/features/commands/data/datasources/local_command_source.dart';
import 'package:chatbot_app/features/commands/data/models/command_model.dart';
import 'package:chatbot_app/core/services/secure_storage_service.dart';
import 'package:chatbot_app/features/commands/domain/entities/command_entity.dart';

class MockSecureStorageService extends Mock
    implements SecureStorageService {}

void main() {
  late MockSecureStorageService storage;
  late LocalCommandService service;

  CommandModel command({
    required String id,
    String? folderId,
  }) {
    return CommandModel(
      id: id,
      trigger: '/$id',
      title: 'Command $id',
      description: 'desc',
      promptTemplate: 'prompt',
      systemType: SystemCommandType.none,
      folderId: folderId,
    );
  }

  setUp(() {
    storage = MockSecureStorageService();
    service = LocalCommandService(storage);
  });

  group('getUserCommands', () {
    test('returns empty list when storage is empty', () async {
      when(() => storage.read(key: any(named: 'key')))
          .thenAnswer((_) async => null);

      final result = await service.getUserCommands();

      expect(result, isEmpty);
    });

    test('returns commands when json is valid', () async {
      final commands = [
        command(id: 'a'),
        command(id: 'b'),
      ];

      when(() => storage.read(key: any(named: 'key')))
          .thenAnswer((_) async => jsonEncode(
                commands.map((c) => c.toJson()).toList(),
              ));

      final result = await service.getUserCommands();

      expect(result.length, 2);
      expect(result.first.id, 'a');
    });

    test('returns empty list on json error', () async {
      when(() => storage.read(key: any(named: 'key')))
          .thenAnswer((_) async => 'invalid json');

      final result = await service.getUserCommands();

      expect(result, isEmpty);
    });
  });

  group('getCommandsByFolder', () {
    test('filters by folderId', () async {
      final commands = [
        command(id: 'a', folderId: 'f1'),
        command(id: 'b'),
      ];

      when(() => storage.read(key: any(named: 'key')))
          .thenAnswer((_) async => jsonEncode(
                commands.map((c) => c.toJson()).toList(),
              ));

      final result = await service.getCommandsByFolder('f1');

      expect(result.length, 1);
      expect(result.first.id, 'a');
    });

    test('returns commands without folder when folderId is null', () async {
      final commands = [
        command(id: 'a', folderId: 'f1'),
        command(id: 'b'),
      ];

      when(() => storage.read(key: any(named: 'key')))
          .thenAnswer((_) async => jsonEncode(
                commands.map((c) => c.toJson()).toList(),
              ));

      final result = await service.getCommandsByFolder(null);

      expect(result.length, 1);
      expect(result.first.id, 'b');
    });
  });

  group('saveCommand', () {
    test('adds new command', () async {
      when(() => storage.read(key: any(named: 'key')))
          .thenAnswer((_) async => jsonEncode([]));

      when(() => storage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          )).thenAnswer((_) async {});

      await service.saveCommand(command(id: 'a'));

      verify(() => storage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          )).called(1);
    });

    test('updates existing command', () async {
      final original = command(id: 'a');

      when(() => storage.read(key: any(named: 'key')))
          .thenAnswer((_) async => jsonEncode([original.toJson()]));

      when(() => storage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          )).thenAnswer((_) async {});

      final updated = original.copyWith(title: 'Updated');

      await service.saveCommand(updated);

      verify(() => storage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          )).called(1);
    });
  });

  group('moveCommandToFolder', () {
    test('moves command to folder', () async {
      final cmd = command(id: 'a');

      when(() => storage.read(key: any(named: 'key')))
          .thenAnswer((_) async => jsonEncode([cmd.toJson()]));

      when(() => storage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          )).thenAnswer((_) async {});

      await service.moveCommandToFolder('a', 'folder1');

      verify(() => storage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          )).called(1);
    });

    test('clears folder when folderId is null', () async {
      final cmd = command(id: 'a', folderId: 'f1');

      when(() => storage.read(key: any(named: 'key')))
          .thenAnswer((_) async => jsonEncode([cmd.toJson()]));

      when(() => storage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          )).thenAnswer((_) async {});

      await service.moveCommandToFolder('a', null);

      verify(() => storage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          )).called(1);
    });

    test('does nothing if command does not exist', () async {
      when(() => storage.read(key: any(named: 'key')))
          .thenAnswer((_) async => jsonEncode([]));

      await service.moveCommandToFolder('x', 'f1');

      verifyNever(() => storage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          ));
    });
  });

  group('removeCommandsFromFolder', () {
    test('removes folder from affected commands', () async {
      final commands = [
        command(id: 'a', folderId: 'f1'),
        command(id: 'b'),
      ];

      when(() => storage.read(key: any(named: 'key')))
          .thenAnswer((_) async => jsonEncode(
                commands.map((c) => c.toJson()).toList(),
              ));

      when(() => storage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          )).thenAnswer((_) async {});

      await service.removeCommandsFromFolder('f1');

      verify(() => storage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          )).called(1);
    });

    test('does nothing if no command uses folder', () async {
      final commands = [
        command(id: 'a'),
      ];

      when(() => storage.read(key: any(named: 'key')))
          .thenAnswer((_) async => jsonEncode(
                commands.map((c) => c.toJson()).toList(),
              ));

      await service.removeCommandsFromFolder('f1');

      verifyNever(() => storage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          ));
    });
  });

  group('deleteCommand', () {
    test('deletes existing command', () async {
      final commands = [command(id: 'a')];

      when(() => storage.read(key: any(named: 'key')))
          .thenAnswer((_) async => jsonEncode(
                commands.map((c) => c.toJson()).toList(),
              ));

      when(() => storage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          )).thenAnswer((_) async {});

      await service.deleteCommand('a');

      verify(() => storage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          )).called(1);
    });

    test('does nothing if command does not exist', () async {
      when(() => storage.read(key: any(named: 'key')))
          .thenAnswer((_) async => jsonEncode([]));

      await service.deleteCommand('x');

      verifyNever(() => storage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          ));
    });
  });

  group('deleteAllCommands', () {
    test('deletes storage key', () async {
      when(() => storage.read(key: any(named: 'key')))
          .thenAnswer((_) async => jsonEncode([]));

      when(() => storage.delete(key: any(named: 'key')))
          .thenAnswer((_) async {});

      await service.deleteAllCommands();

      verify(() => storage.delete(key: any(named: 'key'))).called(1);
    });
  });
}
