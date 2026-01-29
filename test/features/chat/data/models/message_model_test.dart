import 'package:flutter_test/flutter_test.dart';
import 'package:chatbot_app/features/chat/data/models/message_model.dart';
import 'package:chatbot_app/features/chat/domain/entities/message_entity.dart';

void main() {
  group('Message model', () {
    final fixedDate = DateTime(2024, 1, 1);

    test('constructor creates a Message correctly', () {
      final message = Message(
        id: '1',
        content: 'Hola',
        type: MessageType.user,
        timestamp: fixedDate,
      );

      expect(message.id, '1');
      expect(message.content, 'Hola');
      expect(message.type, MessageType.user);
      expect(message.timestamp, fixedDate);
    });

    test('Message.user factory creates user message', () {
      final message = Message.user('Hola');

      expect(message.content, 'Hola');
      expect(message.type, MessageType.user);
      expect(message.id.isNotEmpty, true);
      expect(message.timestamp, isA<DateTime>());
    });

    test('Message.bot factory creates bot message', () {
      final message = Message.bot('Hola');

      expect(message.content, 'Hola');
      expect(message.type, MessageType.bot);
      expect(message.id.isNotEmpty, true);
      expect(message.timestamp, isA<DateTime>());
    });

    test('displayPrefix and displayName for user', () {
      final message = Message(
        id: '1',
        content: 'Hola',
        type: MessageType.user,
        timestamp: fixedDate,
      );

      expect(message.displayPrefix, '👤');
      expect(message.displayName, 'Usuario');
    });

    test('displayPrefix and displayName for bot', () {
      final message = Message(
        id: '1',
        content: 'Hola',
        type: MessageType.bot,
        timestamp: fixedDate,
      );

      expect(message.displayPrefix, '🤖');
      expect(message.displayName, 'Bot');
    });

    test('compatibility getters isUser and text', () {
      final message = Message(
        id: '1',
        content: 'Texto',
        type: MessageType.user,
        timestamp: fixedDate,
      );

      expect(message.isUser, true);
      expect(message.text, 'Texto');
    });

    test('toJson serializes correctly', () {
      final message = Message(
        id: '1',
        content: 'Hola',
        type: MessageType.user,
        timestamp: fixedDate,
      );

      final json = message.toJson();

      expect(json, {
        'id': '1',
        'content': 'Hola',
        'type': 'user',
        'timestamp': fixedDate.toIso8601String(),
      });
    });

    test('fromJson deserializes correctly with valid type', () {
      final json = {
        'id': '1',
        'content': 'Hola',
        'type': 'user',
        'timestamp': fixedDate.toIso8601String(),
      };

      final message = Message.fromJson(json);

      expect(message.id, '1');
      expect(message.content, 'Hola');
      expect(message.type, MessageType.user);
      expect(message.timestamp, fixedDate);
    });

    test('fromJson defaults to bot when type is invalid', () {
      final json = {
        'id': '1',
        'content': 'Hola',
        'type': 'invalid_type',
        'timestamp': fixedDate.toIso8601String(),
      };

      final message = Message.fromJson(json);

      expect(message.type, MessageType.bot);
    });

    test('toEntity converts model to domain entity', () {
      final message = Message(
        id: '1',
        content: 'Hola',
        type: MessageType.user,
        timestamp: fixedDate,
      );

      final entity = message.toEntity();

      expect(entity.id, '1');
      expect(entity.content, 'Hola');
      expect(entity.type, MessageTypeEntity.user);
      expect(entity.timestamp, fixedDate);
    });

    test('fromEntity converts domain entity to model', () {
      final entity = MessageEntity(
        id: '1',
        content: 'Hola',
        type: MessageTypeEntity.bot,
        timestamp: fixedDate,
      );

      final message = Message.fromEntity(entity);

      expect(message.id, '1');
      expect(message.content, 'Hola');
      expect(message.type, MessageType.bot);
      expect(message.timestamp, fixedDate);
    });
  });
}
