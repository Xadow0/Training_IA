import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:chatbot_app/features/commands/data/datasources/firebase_command_sync.dart';
import 'package:chatbot_app/features/commands/data/models/command_model.dart';

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

void main() {
  late FirebaseCommandSyncService service;
  late MockFirebaseAuth auth;
  late MockFirebaseFirestore firestore;
  late MockUser user;
  late MockCollectionReference<Map<String, dynamic>> usersCollection;
  late MockDocumentReference<Map<String, dynamic>> userDoc;
  late MockCollectionReference<Map<String, dynamic>> commandsCollection;
  late MockDocumentReference<Map<String, dynamic>> commandDoc;

  CommandModel command({required String trigger}) => CommandModel(
        id: trigger,
        trigger: trigger,
        title: 'Title $trigger',
        description: 'Desc $trigger',
        promptTemplate: 'Prompt $trigger',
      );

  setUp(() {
    auth = MockFirebaseAuth();
    firestore = MockFirebaseFirestore();
    user = MockUser();
    usersCollection = MockCollectionReference<Map<String, dynamic>>();
    userDoc = MockDocumentReference<Map<String, dynamic>>();
    commandsCollection = MockCollectionReference<Map<String, dynamic>>();
    commandDoc = MockDocumentReference<Map<String, dynamic>>();

    // Inyectamos mocks en el servicio a través del constructor
    service = FirebaseCommandSyncService(
      auth: auth,
      firestore: firestore,
    );

    when(() => auth.currentUser).thenReturn(user);
    when(() => user.uid).thenReturn('test-user-123');

    // Setup Firebase paths: users -> uid -> user_commands
    when(() => firestore.collection('users')).thenReturn(usersCollection);
    when(() => usersCollection.doc(any())).thenReturn(userDoc);
    when(() => userDoc.collection('user_commands')).thenReturn(commandsCollection);
    when(() => commandsCollection.doc(any())).thenReturn(commandDoc);
  });

  group('saveCommandToFirebase', () {
    test('returns false if commandsRef null', () async {
      when(() => auth.currentUser).thenReturn(null);

      final result = await service.saveCommandToFirebase(command(trigger: 'c1'));
      expect(result, false);
    });

    test('saves command successfully', () async {
      when(() => commandDoc.set(any())).thenAnswer((_) async {});

      final result = await service.saveCommandToFirebase(command(trigger: 'c1'));
      expect(result, true);
    });
  });

  group('deleteCommandFromFirebase', () {
    test('returns false if commandsRef null', () async {
      when(() => auth.currentUser).thenReturn(null);

      final result = await service.deleteCommandFromFirebase('c1');
      expect(result, false);
    });

    test('deletes command successfully', () async {
      when(() => commandDoc.delete()).thenAnswer((_) async {});

      final result = await service.deleteCommandFromFirebase('c1');
      expect(result, true);
    });
  });

  group('getCommandsFromFirebase', () {
    test('returns empty list if commandsRef null', () async {
      when(() => auth.currentUser).thenReturn(null);

      final result = await service.getCommandsFromFirebase();
      expect(result, isEmpty);
    });

    test('returns list of commands', () async {
      final querySnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      final queryDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      when(() => commandsCollection.get()).thenAnswer((_) async => querySnapshot);
      when(() => querySnapshot.docs).thenReturn([queryDoc]);
      when(() => queryDoc.data()).thenReturn(command(trigger: 'c1').toJson());

      final result = await service.getCommandsFromFirebase();
      expect(result.length, 1);
      expect(result.first.trigger, 'c1');
    });
  });

  group('syncCommands', () {
    test('returns error if commandsRef null', () async {
      when(() => auth.currentUser).thenReturn(null);

      final result = await service.syncCommands([]);
      expect(result.success, false);
      expect(result.error, 'Usuario no autenticado');
    });

    test('uploads local commands missing in remote and counts downloaded', () async {
      final remoteSnap = MockQuerySnapshot<Map<String, dynamic>>();
      final remoteDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();

      when(() => commandsCollection.get()).thenAnswer((_) async => remoteSnap);
      when(() => remoteSnap.docs).thenReturn([remoteDoc]);
      when(() => remoteDoc.data()).thenReturn(command(trigger: 'c2').toJson());
      when(() => commandsCollection.doc(any())).thenReturn(commandDoc);
      when(() => commandDoc.set(any())).thenAnswer((_) async {});

      final local = [command(trigger: 'c1')];
      final result = await service.syncCommands(local);

      expect(result.success, true);
      expect(result.uploaded, 1);    // c1 subido
      expect(result.downloaded, 1);  // c2 no está en local
      expect(result.remoteCommands!.first.trigger, 'c2');
    });
  });
}
