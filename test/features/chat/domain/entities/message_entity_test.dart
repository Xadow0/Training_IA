import 'package:flutter_test/flutter_test.dart';
import 'package:chatbot_app/features/chat/domain/entities/message_entity.dart'; // Ajusta la ruta según tu proyecto

void main() {
  group('MessageEntity', () {
    final fixedTimestamp = DateTime(2024, 1, 1, 12, 0, 0);
    
    late final baseMessage = MessageEntity(
      id: 'msg-123',
      content: 'Hola mundo',
      type: MessageTypeEntity.user,
      timestamp: fixedTimestamp,
    );

    // Helper para crear un mensaje con el timestamp fijo
    MessageEntity createMessage({
      String id = '1',
      String content = 'Test',
      MessageTypeEntity type = MessageTypeEntity.user,
    }) {
      return MessageEntity(
        id: id,
        content: content,
        type: type,
        timestamp: fixedTimestamp,
      );
    }

    test('Debe inicializar correctamente todas las propiedades', () {
      final message = createMessage();
      expect(message.id, '1');
      expect(message.content, 'Test');
      expect(message.type, MessageTypeEntity.user);
      expect(message.timestamp, fixedTimestamp);
    });

    group('Getters de tipo (isUser, isBot)', () {
      test('Debe identificar correctamente un mensaje de usuario', () {
        final message = createMessage(type: MessageTypeEntity.user);
        expect(message.isUser, isTrue);
        expect(message.isBot, isFalse);
      });

      test('Debe identificar correctamente un mensaje de bot', () {
        final message = createMessage(type: MessageTypeEntity.bot);
        expect(message.isUser, isFalse);
        expect(message.isBot, isTrue);
      });
    });

    group('Getters visuales (displayPrefix, displayName)', () {
      test('Debe retornar los valores correctos para Usuario', () {
        final message = createMessage(type: MessageTypeEntity.user);
        expect(message.displayPrefix, '👤');
        expect(message.displayName, 'Usuario');
      });

      test('Debe retornar los valores correctos para Bot', () {
        final message = createMessage(type: MessageTypeEntity.bot);
        expect(message.displayPrefix, '🤖');
        expect(message.displayName, 'Bot');
      });
    });

    group('Metodo copyWith', () {
      test('Debe cambiar solo las propiedades especificadas', () {
        final original = createMessage();
        final updated = original.copyWith(content: 'Nuevo contenido', id: '2');

        expect(updated.id, '2');
        expect(updated.content, 'Nuevo contenido');
        expect(updated.type, original.type); // Se mantiene
        expect(updated.timestamp, original.timestamp); // Se mantiene
      });

      test('Debe mantener los valores originales si los parámetros son nulos', () {
        final original = createMessage();
        final updated = original.copyWith();

        expect(updated.id, original.id);
        expect(updated.content, original.content);
        expect(updated.type, original.type);
        expect(updated.timestamp, original.timestamp);
      });
    });

    group('Igualdad y HashCode', () {
      test('Dos instancias con mismos datos deben ser iguales', () {
        final m1 = createMessage(id: '1');
        final m2 = createMessage(id: '1');

        expect(m1, equals(m2));
        expect(m1.hashCode, equals(m2.hashCode));
      });

      test('Dos instancias con distinto ID no deben ser iguales', () {
        final m1 = createMessage(id: '1');
        final m2 = createMessage(id: '2');

        expect(m1, isNot(equals(m2)));
      });
      
      test('Comparación con objeto idéntico debe ser true', () {
        final m1 = createMessage();
        expect(m1 == m1, isTrue);
      });
    });

    group('Metodo toString', () {
      test('Debe mostrar el contenido completo si es corto', () {
        final message = createMessage(content: 'Mensaje corto');
        expect(message.toString(), contains('content: Mensaje corto'));
      });

      test('Debe truncar el contenido si supera los 30 caracteres', () {
        final message = createMessage(
          content: 'Este es un mensaje sumamente largo que debería ser truncado por el método toString'
        );
        // "Este es un mensaje sumamente l" son 30 caracteres
        expect(message.toString(), contains('content: Este es un mensaje sumamente l...'));
        expect(message.toString(), isNot(contains('por el método toString')));
      });
    });
  });

  group('MessageTypeEntity Enum', () {
    test('Debe contener los tipos esperados', () {
      expect(MessageTypeEntity.values, [
        MessageTypeEntity.user,
        MessageTypeEntity.bot,
      ]);
    });
  });
}