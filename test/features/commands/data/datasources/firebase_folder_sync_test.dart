import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:chatbot_app/features/commands/data/datasources/firebase_folder_sync.dart';
import 'package:chatbot_app/features/commands/data/models/command_folder_model.dart';

// ==================== Mocks ====================

class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUser extends Mock implements User {}
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockCollectionReference<T extends Object?> extends Mock
    implements CollectionReference<T> {}
class MockDocumentReference<T extends Object?> extends Mock
    implements DocumentReference<T> {}
class MockQuerySnapshot<T extends Object?> extends Mock
    implements QuerySnapshot<T> {}
class MockQueryDocumentSnapshot<T extends Object?> extends Mock
    implements QueryDocumentSnapshot<T> {}
class MockDocumentSnapshot<T extends Object?> extends Mock
    implements DocumentSnapshot<T> {}
class MockWriteBatch extends Mock implements WriteBatch {}

void main() {
  late FirebaseFolderSyncService service;
  late MockFirebaseAuth auth;
  late MockFirebaseFirestore firestore;
  late MockUser user;
  late MockCollectionReference<Map<String, dynamic>> usersCollection;
  late MockDocumentReference<Map<String, dynamic>> userDoc;
  late MockCollectionReference<Map<String, dynamic>> settingsCollection;
  late MockDocumentReference<Map<String, dynamic>> settingsDoc;
  late MockCollectionReference<Map<String, dynamic>> foldersCollection;
  late MockDocumentReference<Map<String, dynamic>> folderDoc;
  late MockWriteBatch batch;

  CommandFolderModel folder({required String id}) => CommandFolderModel(
        id: id,
        name: 'Folder $id',
        createdAt: DateTime.now(),
      );

  setUp(() {
    auth = MockFirebaseAuth();
    firestore = MockFirebaseFirestore();
    user = MockUser();
    usersCollection = MockCollectionReference<Map<String, dynamic>>();
    userDoc = MockDocumentReference<Map<String, dynamic>>();
    settingsCollection = MockCollectionReference<Map<String, dynamic>>();
    settingsDoc = MockDocumentReference<Map<String, dynamic>>();
    foldersCollection = MockCollectionReference<Map<String, dynamic>>();
    folderDoc = MockDocumentReference<Map<String, dynamic>>();
    batch = MockWriteBatch();

    // Inyectamos los mocks en el servicio
    service = FirebaseFolderSyncService(
      auth: auth,
      firestore: firestore,
    );

    when(() => auth.currentUser).thenReturn(user);
    when(() => user.uid).thenReturn('test-user-123');

    // Setup para la estructura de Firebase (users -> uid -> folders/settings)
    when(() => firestore.collection('users')).thenReturn(usersCollection);
    when(() => usersCollection.doc(any())).thenReturn(userDoc);
    when(() => userDoc.collection('command_folders')).thenReturn(foldersCollection);
    when(() => userDoc.collection('settings')).thenReturn(settingsCollection);
    when(() => settingsCollection.doc(any())).thenReturn(settingsDoc);
  });

  group('Preferences', () {
    test('saveGroupSystemPreference returns false if prefsRef null', () async {
      when(() => auth.currentUser).thenReturn(null);

      final result = await service.saveGroupSystemPreference(true);

      expect(result, false);
    });

    test('saveGroupSystemPreference succeeds', () async {
      when(() => settingsDoc.set(any(), any())).thenAnswer((_) async {});

      final result = await service.saveGroupSystemPreference(true);
      expect(result, true);
    });

    test('getGroupSystemPreference returns null if doc does not exist', () async {
      final doc = MockDocumentSnapshot<Map<String, dynamic>>();
      when(() => doc.exists).thenReturn(false);
      when(() => settingsDoc.get()).thenAnswer((_) async => doc);

      final result = await service.getGroupSystemPreference();
      expect(result, null);
    });
  });

  group('Folders CRUD', () {
    test('saveFolderToFirebase returns false if foldersRef null', () async {
      when(() => auth.currentUser).thenReturn(null);

      final result = await service.saveFolderToFirebase(folder(id: '1'));
      expect(result, false);
    });

    test('deleteFolderFromFirebase returns false if foldersRef null', () async {
      when(() => auth.currentUser).thenReturn(null);

      final result = await service.deleteFolderFromFirebase('1');
      expect(result, false);
    });
  });

  group('syncFolders', () {
    test('returns error if foldersRef null', () async {
      when(() => auth.currentUser).thenReturn(null);

      final result = await service.syncFolders([]);
      expect(result.success, false);
      expect(result.error, 'Usuario no autenticado');
    });

    test('uploads local folders missing in remote', () async {
      final remoteSnap = MockQuerySnapshot<Map<String, dynamic>>();
      when(() => foldersCollection.get()).thenAnswer((_) async => remoteSnap);
      when(() => remoteSnap.docs).thenReturn([]);
      when(() => foldersCollection.doc(any())).thenReturn(folderDoc);
      when(() => folderDoc.set(any())).thenAnswer((_) async {});
      
      // Mock para getGroupSystemPreference a través de settingsDoc.get()
      final prefsDoc = MockDocumentSnapshot<Map<String, dynamic>>();
      when(() => prefsDoc.exists).thenReturn(true);
      when(() => prefsDoc.data()).thenReturn({'groupSystemCommands': true});
      when(() => settingsDoc.get()).thenAnswer((_) async => prefsDoc);

      final local = [folder(id: 'a')];
      final result = await service.syncFolders(local);

      expect(result.success, true);
      expect(result.uploaded, 1);
      expect(result.downloaded, 0);
      expect(result.remoteGroupSystemCommands, true);
    });
  });
}
