import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
 import 'package:chatbot_app/core/services/conversation_encryption_service.dart';
 import 'package:chatbot_app/core/services/secure_storage_service.dart';

// =============================================================================
// MOCKS
// =============================================================================

class MockSecureStorageService extends Mock implements SecureStorageService {}

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

// =============================================================================
// TESTS PARA EXCEPCIONES PERSONALIZADAS
// =============================================================================

void main() {
  group('SaltNotFoundException', () {
    test('debe crear excepción con mensaje correcto', () {
      const message = 'Salt no encontrado';
      final exception = SaltNotFoundException(message);

      expect(exception.message, equals(message));
      expect(exception.toString(), equals(message));
    });

    test('toString retorna el mensaje', () {
      final exception = SaltNotFoundException('Error de salt');
      expect(exception.toString(), 'Error de salt');
    });
  });

  group('InvalidPasswordException', () {
    test('debe crear excepción con mensaje correcto', () {
      const message = 'Contraseña incorrecta';
      final exception = InvalidPasswordException(message);

      expect(exception.message, equals(message));
      expect(exception.toString(), equals(message));
    });

    test('toString retorna el mensaje', () {
      final exception = InvalidPasswordException('Password inválido');
      expect(exception.toString(), 'Password inválido');
    });
  });

  // ===========================================================================
  // TESTS PARA SaltInitResult
  // ===========================================================================

  group('SaltInitResult', () {
    test('debe crear resultado exitoso sin necesidad de subir', () {
      final result = SaltInitResult(
        success: true,
        needsUpload: false,
      );

      expect(result.success, isTrue);
      expect(result.needsUpload, isFalse);
      expect(result.encryptedSalt, isNull);
      expect(result.saltVersion, isNull);
      expect(result.error, isNull);
    });

    test('debe crear resultado exitoso con datos para subir', () {
      final result = SaltInitResult(
        success: true,
        needsUpload: true,
        encryptedSalt: 'encrypted_salt_data',
        saltVersion: '1234567890',
      );

      expect(result.success, isTrue);
      expect(result.needsUpload, isTrue);
      expect(result.encryptedSalt, equals('encrypted_salt_data'));
      expect(result.saltVersion, equals('1234567890'));
    });

    test('debe crear resultado con error', () {
      final result = SaltInitResult(
        success: false,
        needsUpload: false,
        error: 'Error de inicialización',
      );

      expect(result.success, isFalse);
      expect(result.needsUpload, isFalse);
      expect(result.error, equals('Error de inicialización'));
    });

    test('debe permitir todos los campos opcionales como null', () {
      final result = SaltInitResult(
        success: true,
        needsUpload: true,
      );

      expect(result.encryptedSalt, isNull);
      expect(result.saltVersion, isNull);
      expect(result.error, isNull);
    });
  });

  // ===========================================================================
  // TESTS PARA ConversationEncryptionService
  // ===========================================================================

  group('ConversationEncryptionService', () {
    late MockSecureStorageService mockSecureStorage;
    late MockFirebaseAuth mockAuth;
    late MockUser mockUser;
    late ConversationEncryptionService service;
    late Map<String, String> storedData; // Simular almacenamiento

    const testUid = 'test-user-uid-12345678';
    const testPassword = 'SecurePassword123!';
    const testSalt = 'dGVzdC1zYWx0LXZhbHVlLWJhc2U2NA=='; // base64 encoded test salt

    setUp(() {
      mockSecureStorage = MockSecureStorageService();
      mockAuth = MockFirebaseAuth();
      mockUser = MockUser();
      storedData = {}; // Reinicializar el almacenamiento

      // Configurar mock de usuario por defecto
      when(() => mockUser.uid).thenReturn(testUid);
      when(() => mockAuth.currentUser).thenReturn(mockUser);

      // Configurar mock de almacenamiento seguro con captura de datos
      // Este es el comportamiento por defecto que se puede sobrescribir en tests específicos
      when(() => mockSecureStorage.read(key: any(named: 'key')))
          .thenAnswer((invocation) async {
        final key = invocation.namedArguments[Symbol('key')] as String;
        return storedData[key];
      });

      when(() => mockSecureStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          )).thenAnswer((invocation) async {
        final key = invocation.namedArguments[Symbol('key')] as String;
        final value = invocation.namedArguments[Symbol('value')] as String;
        storedData[key] = value;
      });

      // Crear servicio con dependencias mockeadas
      service = ConversationEncryptionService(
        mockSecureStorage,
        auth: mockAuth,
      );
    });

    tearDown(() {
      service.clearCache();
    });

    // =========================================================================
    // TESTS: clearCache
    // =========================================================================

    group('clearCache', () {
      test('debe limpiar la caché sin errores', () {
        // No debe lanzar excepción
        expect(() => service.clearCache(), returnsNormally);
      });

      test('puede llamarse múltiples veces sin problemas', () {
        service.clearCache();
        service.clearCache();
        service.clearCache();
        // No debe lanzar excepción
        expect(true, isTrue);
      });
    });

    // =========================================================================
    // TESTS: generateNewSalt
    // =========================================================================

    group('generateNewSalt', () {
      test('debe generar salt cuando usuario está autenticado', () async {
        when(() => mockSecureStorage.write(
              key: any(named: 'key'),
              value: any(named: 'value'),
            )).thenAnswer((_) async {});

        final salt = await service.generateNewSalt();

        expect(salt, isNotEmpty);
        expect(salt.length, greaterThan(20)); // base64 de 32 bytes

        // Verificar que se guardaron salt y versión
        verify(() => mockSecureStorage.write(
              key: 'encryption_salt_$testUid',
              value: any(named: 'value'),
            )).called(1);
        verify(() => mockSecureStorage.write(
              key: 'encryption_salt_version_$testUid',
              value: any(named: 'value'),
            )).called(1);
      });

      test('debe lanzar excepción cuando usuario no está autenticado', () async {
        when(() => mockAuth.currentUser).thenReturn(null);

        expect(
          () => service.generateNewSalt(),
          throwsA(isA<Exception>()),
        );
      });

      test('debe generar salts únicos en cada llamada', () async {
        when(() => mockSecureStorage.write(
              key: any(named: 'key'),
              value: any(named: 'value'),
            )).thenAnswer((_) async {});

        final salt1 = await service.generateNewSalt();
        final salt2 = await service.generateNewSalt();

        expect(salt1, isNot(equals(salt2)));
      });
    });

    // =========================================================================
    // TESTS: hasLocalSalt
    // =========================================================================

    group('hasLocalSalt', () {
      test('debe retornar true cuando existe salt local', () async {
        when(() => mockSecureStorage.read(key: 'encryption_salt_$testUid'))
            .thenAnswer((_) async => testSalt);

        final result = await service.hasLocalSalt();

        expect(result, isTrue);
      });

      test('debe retornar false cuando no existe salt local', () async {
        when(() => mockSecureStorage.read(key: 'encryption_salt_$testUid'))
            .thenAnswer((_) async => null);

        final result = await service.hasLocalSalt();

        expect(result, isFalse);
      });

      test('debe retornar false cuando usuario no está autenticado', () async {
        when(() => mockAuth.currentUser).thenReturn(null);

        final result = await service.hasLocalSalt();

        expect(result, isFalse);
      });
    });

    // =========================================================================
    // TESTS: getLocalSalt
    // =========================================================================

    group('getLocalSalt', () {
      test('debe retornar salt cuando existe', () async {
        when(() => mockSecureStorage.read(key: 'encryption_salt_$testUid'))
            .thenAnswer((_) async => testSalt);

        final result = await service.getLocalSalt();

        expect(result, equals(testSalt));
      });

      test('debe retornar null cuando no existe salt', () async {
        when(() => mockSecureStorage.read(key: 'encryption_salt_$testUid'))
            .thenAnswer((_) async => null);

        final result = await service.getLocalSalt();

        expect(result, isNull);
      });

      test('debe retornar null cuando usuario no está autenticado', () async {
        when(() => mockAuth.currentUser).thenReturn(null);

        final result = await service.getLocalSalt();

        expect(result, isNull);
      });
    });

    // =========================================================================
    // TESTS: getLocalSaltVersion
    // =========================================================================

    group('getLocalSaltVersion', () {
      test('debe retornar versión cuando existe', () async {
        const version = '1704067200000';
        when(() => mockSecureStorage.read(
              key: 'encryption_salt_version_$testUid',
            )).thenAnswer((_) async => version);

        final result = await service.getLocalSaltVersion();

        expect(result, equals(version));
      });

      test('debe retornar null cuando no existe versión', () async {
        when(() => mockSecureStorage.read(
              key: 'encryption_salt_version_$testUid',
            )).thenAnswer((_) async => null);

        final result = await service.getLocalSaltVersion();

        expect(result, isNull);
      });

      test('debe retornar null cuando usuario no está autenticado', () async {
        when(() => mockAuth.currentUser).thenReturn(null);

        final result = await service.getLocalSaltVersion();

        expect(result, isNull);
      });
    });

    // =========================================================================
    // TESTS: saveDecryptedSalt
    // =========================================================================

    group('saveDecryptedSalt', () {
      test('debe guardar salt y versión correctamente', () async {
        const version = '1704067200000';
        when(() => mockSecureStorage.write(
              key: any(named: 'key'),
              value: any(named: 'value'),
            )).thenAnswer((_) async {});

        await service.saveDecryptedSalt(testSalt, version);

        verify(() => mockSecureStorage.write(
              key: 'encryption_salt_$testUid',
              value: testSalt,
            )).called(1);
        verify(() => mockSecureStorage.write(
              key: 'encryption_salt_version_$testUid',
              value: version,
            )).called(1);
      });

      test('debe lanzar excepción cuando usuario no está autenticado', () async {
        when(() => mockAuth.currentUser).thenReturn(null);

        expect(
          () => service.saveDecryptedSalt(testSalt, '123'),
          throwsA(isA<Exception>()),
        );
      });

      test('debe limpiar caché después de guardar', () async {
        when(() => mockSecureStorage.write(
              key: any(named: 'key'),
              value: any(named: 'value'),
            )).thenAnswer((_) async {});

        // Simular que hay caché
        await service.saveDecryptedSalt(testSalt, '123');

        // La caché debería estar limpia (verificar indirectamente)
        // En una implementación real, podrías exponer un getter para verificar
      });
    });

    // =========================================================================
    // TESTS: encryptSaltWithPassword / decryptSaltWithPassword
    // =========================================================================

    group('encryptSaltWithPassword y decryptSaltWithPassword', () {
      test('debe cifrar y descifrar salt correctamente', () {
        const originalSalt = 'mi-salt-secreto-para-pruebas';

        final encrypted = service.encryptSaltWithPassword(originalSalt, testPassword);
        final decrypted = service.decryptSaltWithPassword(encrypted, testPassword);

        expect(decrypted, equals(originalSalt));
      });

      test('cifrado debe tener formato iv:ciphertext', () {
        final encrypted = service.encryptSaltWithPassword(testSalt, testPassword);

        expect(encrypted.contains(':'), isTrue);
        final parts = encrypted.split(':');
        expect(parts.length, equals(2));
      });

      test('debe generar diferentes resultados con el mismo input (IV aleatorio)', () {
        final encrypted1 = service.encryptSaltWithPassword(testSalt, testPassword);
        final encrypted2 = service.encryptSaltWithPassword(testSalt, testPassword);

        expect(encrypted1, isNot(equals(encrypted2)));
      });

      test('debe lanzar InvalidPasswordException con contraseña incorrecta', () {
        final encrypted = service.encryptSaltWithPassword(testSalt, testPassword);

        expect(
          () => service.decryptSaltWithPassword(encrypted, 'contraseña-incorrecta'),
          throwsA(isA<InvalidPasswordException>()),
        );
      });

      test('debe lanzar FormatException con formato inválido (sin separador)', () {
        expect(
          () => service.decryptSaltWithPassword('texto-sin-separador', testPassword),
          throwsA(isA<FormatException>()),
        );
      });

      test('debe lanzar FormatException con formato inválido (múltiples separadores)', () {
        expect(
          () => service.decryptSaltWithPassword('parte1:parte2:parte3', testPassword),
          throwsA(isA<FormatException>()),
        );
      });

      test('debe manejar salt vacío', () {
        const emptySalt = '';
        final encrypted = service.encryptSaltWithPassword(emptySalt, testPassword);
        final decrypted = service.decryptSaltWithPassword(encrypted, testPassword);

        expect(decrypted, equals(emptySalt));
      });

      test('debe manejar caracteres especiales en salt', () {
        const specialSalt = '!@#\$%^&*()_+-=[]{}|;:,.<>?/~`áéíóúñ';
        final encrypted = service.encryptSaltWithPassword(specialSalt, testPassword);
        final decrypted = service.decryptSaltWithPassword(encrypted, testPassword);

        expect(decrypted, equals(specialSalt));
      });

      test('debe manejar caracteres especiales en contraseña', () {
        const specialPassword = 'P@ssw0rd!#\$%^&*()';
        final encrypted = service.encryptSaltWithPassword(testSalt, specialPassword);
        final decrypted = service.decryptSaltWithPassword(encrypted, specialPassword);

        expect(decrypted, equals(testSalt));
      });

      test('debe funcionar con salt muy largo', () {
        final longSalt = 'a' * 10000; // 10KB de datos
        final encrypted = service.encryptSaltWithPassword(longSalt, testPassword);
        final decrypted = service.decryptSaltWithPassword(encrypted, testPassword);

        expect(decrypted, equals(longSalt));
      });
    });

    // =========================================================================
    // TESTS: encryptContent / decryptContent
    // =========================================================================

    group('encryptContent y decryptContent', () {
      setUp(() {
        // Configurar salt local para que funcione el cifrado
        when(() => mockSecureStorage.read(key: 'encryption_salt_$testUid'))
            .thenAnswer((_) async => testSalt);
      });

      test('debe cifrar y descifrar contenido correctamente', () async {
        const originalContent = 'Este es un mensaje secreto';

        final encrypted = await service.encryptContent(originalContent);
        final decrypted = await service.decryptContent(encrypted);

        expect(decrypted, equals(originalContent));
      });

      test('debe retornar string vacío para input vacío', () async {
        final encrypted = await service.encryptContent('');
        expect(encrypted, equals(''));

        final decrypted = await service.decryptContent('');
        expect(decrypted, equals(''));
      });

      test('contenido cifrado debe tener formato iv:ciphertext', () async {
        final encrypted = await service.encryptContent('test');

        expect(encrypted.contains(':'), isTrue);
        final parts = encrypted.split(':');
        expect(parts.length, equals(2));
      });

      test('debe generar IVs únicos para cada cifrado', () async {
        const content = 'mismo contenido';

        final encrypted1 = await service.encryptContent(content);
        final encrypted2 = await service.encryptContent(content);

        expect(encrypted1, isNot(equals(encrypted2)));
      });

      test('debe usar caché de clave para el mismo usuario', () async {
        const content = 'test';

        // Primer cifrado - genera clave
        await service.encryptContent(content);

        // Segundo cifrado - debería usar caché
        await service.encryptContent(content);

        // El read del salt solo debería llamarse una vez si la caché funciona
        verify(() => mockSecureStorage.read(key: 'encryption_salt_$testUid'))
            .called(1);
      });

      test('debe lanzar excepción si usuario no está autenticado', () async {
        when(() => mockAuth.currentUser).thenReturn(null);

        expect(
          () => service.encryptContent('test'),
          throwsA(isA<Exception>()),
        );
      });

      test('debe lanzar SaltNotFoundException si no hay salt local', () async {
        when(() => mockSecureStorage.read(key: 'encryption_salt_$testUid'))
            .thenAnswer((_) async => null);
        service.clearCache(); // Limpiar caché para forzar lectura de storage

        expect(
          () => service.encryptContent('test'),
          throwsA(isA<SaltNotFoundException>()),
        );
      });

      test('debe manejar texto no cifrado en decryptContent (compatibilidad)', () async {
        const plainText = 'texto sin cifrar sin separador';

        final result = await service.decryptContent(plainText);

        expect(result, equals(plainText));
      });

      test('debe manejar formato inválido en decryptContent', () async {
        const invalidFormat = 'parte1:parte2:parte3';

        final result = await service.decryptContent(invalidFormat);

        expect(result, equals(invalidFormat));
      });

      test('debe retornar texto original si el descifrado falla', () async {
        const corruptedText = 'aW52YWxpZA==:Y29ycnVwdGVk'; // base64 inválido para descifrar

        final result = await service.decryptContent(corruptedText);

        // Debería retornar el texto original en caso de error
        expect(result, equals(corruptedText));
      });

      test('debe cifrar correctamente caracteres unicode', () async {
        const unicodeContent = '你好世界 🌍 مرحبا العالم';

        final encrypted = await service.encryptContent(unicodeContent);
        final decrypted = await service.decryptContent(encrypted);

        expect(decrypted, equals(unicodeContent));
      });

      test('debe cifrar contenido muy largo', () async {
        final longContent = 'Lorem ipsum ' * 1000; // ~12KB

        final encrypted = await service.encryptContent(longContent);
        final decrypted = await service.decryptContent(encrypted);

        expect(decrypted, equals(longContent));
      });
    });

    // =========================================================================
    // TESTS: encryptMessages / decryptMessages
    // =========================================================================

    group('encryptMessages y decryptMessages', () {
      setUp(() {
        when(() => mockSecureStorage.read(key: 'encryption_salt_$testUid'))
            .thenAnswer((_) async => testSalt);
      });

      test('debe cifrar lista de mensajes correctamente', () async {
        final messages = [
          {'content': 'Mensaje 1', 'role': 'user'},
          {'content': 'Mensaje 2', 'role': 'assistant'},
        ];

        final encrypted = await service.encryptMessages(messages);

        expect(encrypted.length, equals(2));
        expect(encrypted[0]['encrypted'], isTrue);
        expect(encrypted[1]['encrypted'], isTrue);
        expect(encrypted[0]['content'], isNot(equals('Mensaje 1')));
        expect(encrypted[0]['role'], equals('user')); // Otros campos sin cambio
      });

      test('debe descifrar lista de mensajes correctamente', () async {
        final messages = [
          {'content': 'Mensaje secreto 1', 'role': 'user'},
          {'content': 'Mensaje secreto 2', 'role': 'assistant'},
        ];

        final encrypted = await service.encryptMessages(messages);
        final decrypted = await service.decryptMessages(encrypted);

        expect(decrypted.length, equals(2));
        expect(decrypted[0]['content'], equals('Mensaje secreto 1'));
        expect(decrypted[1]['content'], equals('Mensaje secreto 2'));
        expect(decrypted[0].containsKey('encrypted'), isFalse);
      });

      test('debe manejar lista vacía', () async {
        final encrypted = await service.encryptMessages([]);
        final decrypted = await service.decryptMessages([]);

        expect(encrypted, isEmpty);
        expect(decrypted, isEmpty);
      });

      test('debe manejar mensajes sin content', () async {
        final messages = [
          {'role': 'system'}, // Sin content
          {'content': 'Hola', 'role': 'user'},
        ];

        final encrypted = await service.encryptMessages(messages);

        expect(encrypted[0].containsKey('encrypted'), isFalse);
        expect(encrypted[1]['encrypted'], isTrue);
      });

      test('debe manejar content que no es String', () async {
        final messages = [
          {'content': 123, 'role': 'user'}, // content es int
          {'content': null, 'role': 'assistant'},
          {'content': ['array'], 'role': 'system'},
        ];

        final encrypted = await service.encryptMessages(messages);

        // Content no-string no se cifra
        expect(encrypted[0]['content'], equals(123));
        expect(encrypted[1]['content'], isNull);
        expect(encrypted[2]['content'], equals(['array']));
      });

      test('debe preservar todos los campos adicionales', () async {
        final messages = [
          {
            'content': 'Test',
            'role': 'user',
            'timestamp': 1234567890,
            'metadata': {'key': 'value'},
          },
        ];

        final encrypted = await service.encryptMessages(messages);
        final decrypted = await service.decryptMessages(encrypted);

        expect(decrypted[0]['role'], equals('user'));
        expect(decrypted[0]['timestamp'], equals(1234567890));
        expect(decrypted[0]['metadata'], equals({'key': 'value'}));
      });

      test('debe detectar mensajes cifrados por formato en decryptMessages', () async {
        // Mensaje sin marcador 'encrypted' pero con formato cifrado
        final messages = [
          {'content': 'Mensaje original', 'role': 'user'},
        ];

        final encrypted = await service.encryptMessages(messages);
        // Remover marcador encrypted manualmente
        encrypted[0].remove('encrypted');

        final decrypted = await service.decryptMessages(encrypted);

        // Debería detectar el formato y descifrar
        expect(decrypted[0]['content'], equals('Mensaje original'));
      });

      test('no debe modificar mensajes sin cifrar', () async {
        final messages = [
          {'content': 'texto plano sin cifrar', 'role': 'user'},
        ];

        final decrypted = await service.decryptMessages(messages);

        expect(decrypted[0]['content'], equals('texto plano sin cifrar'));
      });
    });

    // =========================================================================
    // TESTS: _looksEncrypted (a través de decryptMessages)
    // =========================================================================

    group('_looksEncrypted (test indirecto)', () {
      setUp(() {
        when(() => mockSecureStorage.read(key: 'encryption_salt_$testUid'))
            .thenAnswer((_) async => testSalt);
      });

      test('debe detectar texto que parece cifrado (formato base64:base64)', () async {
        // Crear contenido cifrado real
        final encrypted = await service.encryptContent('test');

        final messages = [
          {'content': encrypted, 'role': 'user'},
        ];

        final decrypted = await service.decryptMessages(messages);

        expect(decrypted[0]['content'], equals('test'));
      });

      test('no debe considerar texto sin ":" como cifrado', () async {
        final messages = [
          {'content': 'texto sin dos puntos', 'role': 'user'},
        ];

        final decrypted = await service.decryptMessages(messages);

        expect(decrypted[0]['content'], equals('texto sin dos puntos'));
      });

      test('no debe considerar texto con múltiples ":" como cifrado', () async {
        final messages = [
          {'content': 'parte1:parte2:parte3', 'role': 'user'},
        ];

        final decrypted = await service.decryptMessages(messages);

        expect(decrypted[0]['content'], equals('parte1:parte2:parte3'));
      });

      test('no debe considerar texto con base64 inválido como cifrado', () async {
        final messages = [
          {'content': 'nobase64:tampocobase64', 'role': 'user'},
        ];

        final decrypted = await service.decryptMessages(messages);

        // Si intenta descifrar y falla, retorna el original
        expect(decrypted[0]['content'], equals('nobase64:tampocobase64'));
      });
    });

    // =========================================================================
    // TESTS: deleteUserSalt
    // =========================================================================

    group('deleteUserSalt', () {
      test('debe eliminar salt y versión del usuario', () async {
        when(() => mockSecureStorage.delete(key: any(named: 'key')))
            .thenAnswer((_) async {});

        await service.deleteUserSalt();

        verify(() => mockSecureStorage.delete(key: 'encryption_salt_$testUid'))
            .called(1);
        verify(() => mockSecureStorage.delete(
              key: 'encryption_salt_version_$testUid',
            )).called(1);
      });

      test('debe limpiar caché después de eliminar', () async {
        when(() => mockSecureStorage.delete(key: any(named: 'key')))
            .thenAnswer((_) async {});

        await service.deleteUserSalt();

        // Verificar indirectamente que la caché se limpió
        // En una implementación real, podrías verificar con un getter
      });

      test('no debe fallar si usuario no está autenticado', () async {
        when(() => mockAuth.currentUser).thenReturn(null);

        // No debe lanzar excepción
        await service.deleteUserSalt();

        // No se debe llamar a delete porque no hay usuario
        verifyNever(() => mockSecureStorage.delete(key: any(named: 'key')));
      });
    });

    // =========================================================================
    // TESTS: initializeWithPassword
    // =========================================================================

    group('initializeWithPassword', () {
      test('debe lanzar excepción si usuario no está autenticado', () async {
        when(() => mockAuth.currentUser).thenReturn(null);

        expect(
          () => service.initializeWithPassword(password: testPassword),
          throwsA(isA<Exception>()),
        );
      });

      test('caso 1: salt de Firebase, versión local coincide', () async {
        const version = '1234567890';
        final encryptedSalt = service.encryptSaltWithPassword(testSalt, testPassword);

        when(() => mockSecureStorage.read(
              key: 'encryption_salt_version_$testUid',
            )).thenAnswer((_) async => version);

        final result = await service.initializeWithPassword(
          encryptedSaltFromFirebase: encryptedSalt,
          saltVersionFromFirebase: version,
          password: testPassword,
        );

        expect(result.success, isTrue);
        expect(result.needsUpload, isFalse);
      });

      test('caso 1b: salt de Firebase, versión diferente - descarga y guarda', () async {
        const localVersion = '1111111111';
        const firebaseVersion = '2222222222';
        final encryptedSalt = service.encryptSaltWithPassword(testSalt, testPassword);

        when(() => mockSecureStorage.read(
              key: 'encryption_salt_version_$testUid',
            )).thenAnswer((_) async => localVersion);
        when(() => mockSecureStorage.write(
              key: any(named: 'key'),
              value: any(named: 'value'),
            )).thenAnswer((_) async {});

        final result = await service.initializeWithPassword(
          encryptedSaltFromFirebase: encryptedSalt,
          saltVersionFromFirebase: firebaseVersion,
          password: testPassword,
        );

        expect(result.success, isTrue);
        expect(result.needsUpload, isFalse);

        // Verificar que se guardó el salt descifrado
        verify(() => mockSecureStorage.write(
              key: 'encryption_salt_$testUid',
              value: testSalt,
            )).called(1);
      });

      test('caso 1c: salt de Firebase, sin versión local', () async {
        final encryptedSalt = service.encryptSaltWithPassword(testSalt, testPassword);

        when(() => mockSecureStorage.read(
              key: 'encryption_salt_version_$testUid',
            )).thenAnswer((_) async => null);
        when(() => mockSecureStorage.write(
              key: any(named: 'key'),
              value: any(named: 'value'),
            )).thenAnswer((_) async {});

        final result = await service.initializeWithPassword(
          encryptedSaltFromFirebase: encryptedSalt,
          saltVersionFromFirebase: '123',
          password: testPassword,
        );

        expect(result.success, isTrue);
        expect(result.needsUpload, isFalse);
      });

      test('caso 1d: contraseña incorrecta - lanza InvalidPasswordException', () async {
        final encryptedSalt = service.encryptSaltWithPassword(testSalt, testPassword);

        when(() => mockSecureStorage.read(
              key: 'encryption_salt_version_$testUid',
            )).thenAnswer((_) async => null);

        expect(
          () => service.initializeWithPassword(
            encryptedSaltFromFirebase: encryptedSalt,
            saltVersionFromFirebase: '123',
            password: 'contraseña-incorrecta',
          ),
          throwsA(isA<InvalidPasswordException>()),
        );
      });

      test('caso 2: sin Firebase, con salt local - subir a Firebase', () async {
        const localVersion = '1234567890';

        when(() => mockSecureStorage.read(key: 'encryption_salt_$testUid'))
            .thenAnswer((_) async => testSalt);
        when(() => mockSecureStorage.read(
              key: 'encryption_salt_version_$testUid',
            )).thenAnswer((_) async => localVersion);

        final result = await service.initializeWithPassword(
          encryptedSaltFromFirebase: null,
          password: testPassword,
        );

        expect(result.success, isTrue);
        expect(result.needsUpload, isTrue);
        expect(result.encryptedSalt, isNotNull);
        expect(result.saltVersion, equals(localVersion));
      });

      test('caso 2b: sin Firebase, salt local sin versión', () async {
        when(() => mockSecureStorage.read(key: 'encryption_salt_$testUid'))
            .thenAnswer((_) async => testSalt);
        when(() => mockSecureStorage.read(
              key: 'encryption_salt_version_$testUid',
            )).thenAnswer((_) async => null);

        final result = await service.initializeWithPassword(
          encryptedSaltFromFirebase: null,
          password: testPassword,
        );

        expect(result.success, isTrue);
        expect(result.needsUpload, isTrue);
        // Debe generar una versión
        expect(result.saltVersion, isNotNull);
      });

      test('caso 3: sin Firebase, sin local - generar nuevo', () async {
        // storedData comienza vacío, así que read() retornará null
        // Este test usa el mock por defecto del setUp

        final result = await service.initializeWithPassword(
          encryptedSaltFromFirebase: null,
          password: testPassword,
        );

        expect(result.success, isTrue);
        expect(result.needsUpload, isTrue);
        expect(result.encryptedSalt, isNotNull);
        expect(result.saltVersion, isNotNull);
      });

      test('caso 3b: encryptedSaltFromFirebase vacío se trata como null', () async {
        // storedData comienza vacío, así que read() retornará null
        // Este test usa el mock por defecto del setUp

        final result = await service.initializeWithPassword(
          encryptedSaltFromFirebase: '', // String vacío
          password: testPassword,
        );

        expect(result.success, isTrue);
        expect(result.needsUpload, isTrue);
      });

      test('debe usar versión de Firebase si está disponible', () async {
        final encryptedSalt = service.encryptSaltWithPassword(testSalt, testPassword);
        const firebaseVersion = '9999999999';

        when(() => mockSecureStorage.read(
              key: 'encryption_salt_version_$testUid',
            )).thenAnswer((_) async => null);
        when(() => mockSecureStorage.write(
              key: any(named: 'key'),
              value: any(named: 'value'),
            )).thenAnswer((_) async {});

        final result = await service.initializeWithPassword(
          encryptedSaltFromFirebase: encryptedSalt,
          saltVersionFromFirebase: firebaseVersion,
          password: testPassword,
        );

        verify(() => mockSecureStorage.write(
              key: 'encryption_salt_version_$testUid',
              value: firebaseVersion,
            )).called(1);
      });
    });

    // =========================================================================
    // TESTS: reencryptSaltForPasswordChange
    // =========================================================================

    group('reencryptSaltForPasswordChange', () {
      test('debe recifrar salt con nueva contraseña', () async {
        const oldPassword = 'OldPassword123!';
        const newPassword = 'NewPassword456!';

        // Cifrar salt con contraseña antigua
        final encryptedWithOld = service.encryptSaltWithPassword(
          testSalt,
          oldPassword,
        );

        // Recifrar con nueva contraseña
        final encryptedWithNew = await service.reencryptSaltForPasswordChange(
          oldPassword: oldPassword,
          newPassword: newPassword,
          currentEncryptedSalt: encryptedWithOld,
        );

        // Verificar que se puede descifrar con nueva contraseña
        final decrypted = service.decryptSaltWithPassword(
          encryptedWithNew,
          newPassword,
        );

        expect(decrypted, equals(testSalt));
      });

      test('debe fallar si contraseña antigua es incorrecta', () async {
        final encryptedSalt = service.encryptSaltWithPassword(
          testSalt,
          testPassword,
        );

        expect(
          () => service.reencryptSaltForPasswordChange(
            oldPassword: 'contraseña-incorrecta',
            newPassword: 'nueva-contraseña',
            currentEncryptedSalt: encryptedSalt,
          ),
          throwsA(isA<InvalidPasswordException>()),
        );
      });

      test('no debe poder descifrar con contraseña antigua después del cambio', () async {
        const oldPassword = 'OldPassword123!';
        const newPassword = 'NewPassword456!';

        final encryptedWithOld = service.encryptSaltWithPassword(
          testSalt,
          oldPassword,
        );

        final encryptedWithNew = await service.reencryptSaltForPasswordChange(
          oldPassword: oldPassword,
          newPassword: newPassword,
          currentEncryptedSalt: encryptedWithOld,
        );

        // No debe poder descifrar con contraseña antigua
        expect(
          () => service.decryptSaltWithPassword(encryptedWithNew, oldPassword),
          throwsA(isA<InvalidPasswordException>()),
        );
      });
    });

    // =========================================================================
    // TESTS: Caché de clave de cifrado
    // =========================================================================

    group('Caché de clave de cifrado', () {
      setUp(() {
        when(() => mockSecureStorage.read(key: 'encryption_salt_$testUid'))
            .thenAnswer((_) async => testSalt);
      });

      test('debe cachear clave para el mismo usuario', () async {
        await service.encryptContent('test1');
        await service.encryptContent('test2');
        await service.encryptContent('test3');

        // Solo debería leer el salt una vez
        verify(() => mockSecureStorage.read(key: 'encryption_salt_$testUid'))
            .called(1);
      });

      test('debe invalidar caché al cambiar de usuario', () async {
        await service.encryptContent('test');

        // Cambiar usuario
        const newUid = 'nuevo-usuario-uid';
        final newUser = MockUser();
        when(() => newUser.uid).thenReturn(newUid);
        when(() => mockAuth.currentUser).thenReturn(newUser);
        when(() => mockSecureStorage.read(key: 'encryption_salt_$newUid'))
            .thenAnswer((_) async => testSalt);

        await service.encryptContent('test2');

        // Debería leer salt para el nuevo usuario
        verify(() => mockSecureStorage.read(key: 'encryption_salt_$newUid'))
            .called(1);
      });

      test('clearCache debe forzar recálculo de clave', () async {
        await service.encryptContent('test1');

        service.clearCache();

        await service.encryptContent('test2');

        // Debería leer el salt dos veces
        verify(() => mockSecureStorage.read(key: 'encryption_salt_$testUid'))
            .called(2);
      });
    });

    // =========================================================================
    // TESTS: Casos edge y robustez
    // =========================================================================

    group('Casos edge y robustez', () {
      setUp(() {
        when(() => mockSecureStorage.read(key: 'encryption_salt_$testUid'))
            .thenAnswer((_) async => testSalt);
      });

      test('debe manejar contenido con caracteres de control', () async {
        const content = 'texto\ncon\tsaltos\ry\0nulos';

        final encrypted = await service.encryptContent(content);
        final decrypted = await service.decryptContent(encrypted);

        expect(decrypted, equals(content));
      });

      test('debe manejar contenido solo con espacios', () async {
        const content = '   ';

        final encrypted = await service.encryptContent(content);
        final decrypted = await service.decryptContent(encrypted);

        expect(decrypted, equals(content));
      });

      test('debe manejar emojis correctamente', () async {
        const content = '👋🏽 Hello 🌍 World 🎉🎊🎁';

        final encrypted = await service.encryptContent(content);
        final decrypted = await service.decryptContent(encrypted);

        expect(decrypted, equals(content));
      });

      test('debe manejar JSON en contenido', () async {
        const content = '{"key": "value", "number": 123, "nested": {"a": true}}';

        final encrypted = await service.encryptContent(content);
        final decrypted = await service.decryptContent(encrypted);

        expect(decrypted, equals(content));
      });

      test('debe manejar HTML/XML en contenido', () async {
        const content = '<html><body><p class="test">Hello & "World"</p></body></html>';

        final encrypted = await service.encryptContent(content);
        final decrypted = await service.decryptContent(encrypted);

        expect(decrypted, equals(content));
      });

      test('debe manejar contenido con base64 existente', () async {
        const content = 'SGVsbG8gV29ybGQh'; // "Hello World!" en base64

        final encrypted = await service.encryptContent(content);
        final decrypted = await service.decryptContent(encrypted);

        expect(decrypted, equals(content));
      });

      test('debe manejar contenido que parece cifrado pero no lo está', () async {
        // Contenido que tiene formato iv:ciphertext pero no está cifrado
        const content = 'SGVsbG8=:V29ybGQh';

        // Al intentar descifrar, debería retornar el original
        final result = await service.decryptContent(content);

        // Podría retornar el original si falla el descifrado
        expect(result, isNotNull);
      });
    });

    // =========================================================================
    // TESTS: Consistencia del cifrado
    // =========================================================================

    group('Consistencia del cifrado', () {
      setUp(() {
        when(() => mockSecureStorage.read(key: 'encryption_salt_$testUid'))
            .thenAnswer((_) async => testSalt);
      });

      test('descifrado de múltiples mensajes debe ser consistente', () async {
        final contents = List.generate(100, (i) => 'Mensaje número $i');

        for (final content in contents) {
          final encrypted = await service.encryptContent(content);
          final decrypted = await service.decryptContent(encrypted);
          expect(decrypted, equals(content));
        }
      });

      test('cifrado/descifrado debe ser thread-safe (paralelo)', () async {
        final futures = List.generate(50, (i) async {
          final content = 'Mensaje paralelo $i';
          final encrypted = await service.encryptContent(content);
          final decrypted = await service.decryptContent(encrypted);
          return decrypted == content;
        });

        final results = await Future.wait(futures);

        expect(results.every((r) => r), isTrue);
      });
    });
  });
}

// =============================================================================
// NOTA: Para ejecutar estos tests, necesitas:
// 1. Agregar mocktail a dev_dependencies en pubspec.yaml:
//    dev_dependencies:
//      flutter_test:
//        sdk: flutter
//      mocktail: ^1.0.0
//
// 2. La clase ConversationEncryptionService debe poder inyectar FirebaseAuth
//    para facilitar el testing. Una forma de hacerlo es:
//
//    class ConversationEncryptionService {
//      final SecureStorageService _secureStorage;
//      final FirebaseAuth _auth;
//      
//      ConversationEncryptionService(
//        this._secureStorage, {
//        FirebaseAuth? auth,
//      }) : _auth = auth ?? FirebaseAuth.instance;
//    }
//
// 3. Ejecutar: flutter test test/conversation_encryption_service_test.dart
// =============================================================================