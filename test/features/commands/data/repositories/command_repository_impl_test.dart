import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:chatbot_app/features/commands/data/repositories/command_repository_impl.dart';
import 'package:chatbot_app/features/commands/data/datasources/local_command_source.dart';
import 'package:chatbot_app/features/commands/data/datasources/local_folder_source.dart';
import 'package:chatbot_app/features/commands/data/datasources/firebase_command_sync.dart';
import 'package:chatbot_app/features/commands/data/datasources/firebase_folder_sync.dart';
import 'package:chatbot_app/features/commands/domain/entities/command_entity.dart';
import 'package:chatbot_app/features/commands/domain/entities/command_folder_entity.dart';
import 'package:chatbot_app/features/commands/data/models/command_model.dart';

/* -------------------------------------------------------------------------- */
/*                                   MOCKS                                    */
/* -------------------------------------------------------------------------- */

class MockLocalCommandService extends Mock implements LocalCommandService {}
class MockLocalFolderService extends Mock implements LocalFolderService {}
class MockFirebaseCommandSyncService extends Mock implements FirebaseCommandSyncService {}
class MockFirebaseFolderSyncService extends Mock implements FirebaseFolderSyncService {}

void main() {
  late MockLocalCommandService localCommand;
  late MockLocalFolderService localFolder;
  late MockFirebaseCommandSyncService firebaseCommand;
  late MockFirebaseFolderSyncService firebaseFolder;

  late CommandRepositoryImpl repository;

  bool syncEnabled = true;

  setUp(() {
    localCommand = MockLocalCommandService();
    localFolder = MockLocalFolderService();
    firebaseCommand = MockFirebaseCommandSyncService();
    firebaseFolder = MockFirebaseFolderSyncService();

    repository = CommandRepositoryImpl(
      localCommand,
      localFolder,
      firebaseCommand,
      firebaseFolder,
      () => syncEnabled,
    );
  });

  /* -------------------------------------------------------------------------- */
  /*                                COMMANDS                                    */
  /* -------------------------------------------------------------------------- */

  test('getAllCommands returns system + user commands', () async {
    when(() => localCommand.getUserCommands()).thenAnswer((_) async => []);

    final result = await repository.getAllCommands();

    expect(result.isNotEmpty, true); // system commands
  });

  test('saveCommand throws if system command', () async {
    final systemCommand = CommandEntity(
      id: 'sys',
      trigger: '/sys',
      title: 'System',
      description: '',
      promptTemplate: '',
      isSystem: true,
    );

    expect(
      () => repository.saveCommand(systemCommand),
      throwsException,
    );
  });

  test('deleteCommand throws if system command', () async {
    final systemId = CommandModel.getDefaultCommands().first.id;

    expect(
      () => repository.deleteCommand(systemId),
      throwsException,
    );
  });

  test('deleteAllLocalCommands success', () async {
    when(() => localCommand.deleteAllCommands())
        .thenAnswer((_) async => true);

    await repository.deleteAllLocalCommands();

    verify(() => localCommand.deleteAllCommands()).called(1);
  });

  /* -------------------------------------------------------------------------- */
  /*                                  FOLDERS                                   */
  /* -------------------------------------------------------------------------- */

  test('getAllFolders returns local folders', () async {
    when(() => localFolder.getFolders()).thenAnswer((_) async => []);

    final result = await repository.getAllFolders();

    expect(result, isA<List<CommandFolderEntity>>());
  });

  test('deleteFolder syncs and updates commands', () async {
    when(() => localCommand.removeCommandsFromFolder(any()))
        .thenAnswer((_) async => true);
    when(() => localFolder.deleteFolder(any()))
        .thenAnswer((_) async => true);
    when(() => localCommand.getUserCommands())
        .thenAnswer((_) async => []);
    when(() => firebaseFolder.deleteFolderFromFirebase(any()))
        .thenAnswer((_) async => true);

    await repository.deleteFolder('folder-1');

    verify(() => localFolder.deleteFolder('folder-1')).called(1);
  });

  test('deleteAllLocalFolders success', () async {
    when(() => localFolder.getFolders()).thenAnswer((_) async => []);
    when(() => localFolder.deleteAllFolders())
        .thenAnswer((_) async => true);
    when(() => localCommand.removeCommandsFromFolder(any()))
        .thenAnswer((_) async => true);

    await repository.deleteAllLocalFolders();

    verify(() => localFolder.deleteAllFolders()).called(1);
  });

  /* -------------------------------------------------------------------------- */
  /*                             PREFERENCES                                    */
  /* -------------------------------------------------------------------------- */

  test('getGroupSystemPreference returns null when sync disabled', () async {
    syncEnabled = false;

    final result = await repository.getGroupSystemPreference();

    expect(result, null);
  });

  /* -------------------------------------------------------------------------- */
  /*                                SYNC                                        */
  /* -------------------------------------------------------------------------- */

  test('syncAll returns error when disabled', () async {
    syncEnabled = false;

    final result = await repository.syncAll();

    expect(result.success, false);
  });

  test('deleteAllFromFirebase returns false when disabled', () async {
    syncEnabled = false;

    final result = await repository.deleteAllFromFirebase();

    expect(result, false);
  });
}
