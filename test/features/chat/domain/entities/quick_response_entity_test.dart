import 'package:flutter_test/flutter_test.dart';
import 'package:chatbot_app/features/chat/domain/entities/quick_response_entity.dart'; // Ajusta la ruta

void main() {
  group('QuickResponseEntity', () {
    test('Debe inicializar correctamente un comando simple', () {
      const response = QuickResponseEntity(
        text: '/resumir',
        description: 'Resume el texto',
        type: QuickResponseType.command,
      );

      expect(response.text, '/resumir');
      expect(response.isEditable, isFalse); // valor por defecto
      expect(response.isSystem, isFalse);   // valor por defecto
      expect(response.type, QuickResponseType.command);
    });

    test('Debe identificar correctamente si es carpeta o comando', () {
      const command = QuickResponseEntity(text: 'c', type: QuickResponseType.command);
      const folder = QuickResponseEntity(text: 'f', type: QuickResponseType.folder);

      expect(command.isFolder, isFalse);
      expect(command.isCommand, isTrue);
      expect(folder.isFolder, isTrue);
      expect(folder.isCommand, isFalse);
    });

    group('Metodo copyWith', () {
      test('Debe actualizar todos los campos posibles', () {
        const original = QuickResponseEntity(text: 'original', isSystem: true);
        
        final updated = original.copyWith(
          text: 'nuevo',
          description: 'desc',
          promptTemplate: 'template',
          isEditable: true,
          type: QuickResponseType.folder,
          folderId: 'f1',
          folderIcon: '📁',
          children: [],
          isSystem: false,
        );

        expect(updated.text, 'nuevo');
        expect(updated.description, 'desc');
        expect(updated.promptTemplate, 'template');
        expect(updated.isEditable, isTrue);
        expect(updated.type, QuickResponseType.folder);
        expect(updated.folderId, 'f1');
        expect(updated.folderIcon, '📁');
        expect(updated.children, isEmpty);
        expect(updated.isSystem, isFalse);
      });

      test('Debe mantener valores si se llama copyWith sin argumentos', () {
        const original = QuickResponseEntity(text: 'test', description: 'desc');
        final updated = original.copyWith();
        expect(updated.text, original.text);
        expect(updated.description, original.description);
      });
    });

    group('Igualdad y HashCode', () {
      test('Dos comandos idénticos deben ser iguales', () {
        const r1 = QuickResponseEntity(text: 'a', type: QuickResponseType.command);
        const r2 = QuickResponseEntity(text: 'a', type: QuickResponseType.command);

        expect(r1, equals(r2));
        expect(r1.hashCode, equals(r2.hashCode));
      });

      test('Debe detectar diferencias en campos clave', () {
        const r1 = QuickResponseEntity(text: 'a', isSystem: true);
        const r2 = QuickResponseEntity(text: 'a', isSystem: false);

        expect(r1, isNot(equals(r2)));
      });

      test('Identical check (shortcut)', () {
        const r1 = QuickResponseEntity(text: 'a');
        expect(r1 == r1, isTrue);
      });
    });
  });

  group('QuickResponseType Enum', () {
    test('Debe tener los valores definidos', () {
      expect(QuickResponseType.values.length, 2);
      expect(QuickResponseType.values, contains(QuickResponseType.command));
      expect(QuickResponseType.values, contains(QuickResponseType.folder));
    });
  });
}