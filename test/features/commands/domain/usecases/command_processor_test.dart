import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:chatbot_app/features/commands/domain/entities/command_entity.dart';
import 'package:chatbot_app/features/commands/domain/repositories/command_repository.dart';
import 'package:chatbot_app/features/commands/domain/usecases/command_processor.dart';

// Mocks
class MockAIService extends Mock implements AIServiceBase {}

class MockCommandRepository extends Mock implements ICommandRepository {}

void main() {
  group('CommandStreamResult', () {
    test('factory notCommand creates result with isCommand false', () {
      final result = CommandStreamResult.notCommand();
      
      expect(result.isCommand, false);
      expect(result.command, null);
      expect(result.responseStream, null);
      expect(result.error, null);
    });

    test('factory success creates result with all success fields', () {
      final testCommand = CommandEntity(
        id: '1',
        trigger: '/test',
        title: 'Test',
        description: 'Test command',
        promptTemplate: 'Test template',
      );
      final testStream = Stream.fromIterable(['response']);

      final result = CommandStreamResult.success(testCommand, testStream);

      expect(result.isCommand, true);
      expect(result.command, testCommand);
      expect(result.responseStream, testStream);
      expect(result.error, null);
    });

    test('factory error creates result with error message', () {
      final testCommand = CommandEntity(
        id: '1',
        trigger: '/test',
        title: 'Test',
        description: 'Test command',
        promptTemplate: 'Test template',
      );
      const errorMessage = 'Test error';

      final result = CommandStreamResult.error(testCommand, errorMessage);

      expect(result.isCommand, true);
      expect(result.command, testCommand);
      expect(result.responseStream, null);
      expect(result.error, errorMessage);
    });

    test('factory error can be created with null command', () {
      const errorMessage = 'Command not found';
      
      final result = CommandStreamResult.error(null, errorMessage);

      expect(result.isCommand, true);
      expect(result.command, null);
      expect(result.error, errorMessage);
    });
  });

  group('CommandProcessor', () {
    late MockAIService mockAIService;
    late MockCommandRepository mockCommandRepository;
    late CommandProcessor commandProcessor;

    setUp(() {
      mockAIService = MockAIService();
      mockCommandRepository = MockCommandRepository();
      commandProcessor = CommandProcessor(mockAIService, mockCommandRepository);
    });

    group('processMessageStream - Not a command', () {
      test('returns notCommand when message is whitespace only with /', () async {
        final result = await commandProcessor.processMessageStream('  /  ');

        expect(result.isCommand, false);
      });
    });
    group('processMessageStream - Edge cases', () {
      test('handles message that is just a slash', () async {
        final result = await commandProcessor.processMessageStream('/');

        expect(result.isCommand, false);
      });
    });
  });
}
