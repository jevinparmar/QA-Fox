import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qafox/core/enums/app_status.dart';
import 'package:qafox/shared/models/message_model.dart';
import 'package:qafox/shared/widgets/bug_report_message_card.dart';
import 'package:qafox/shared/widgets/chat_message_bubble.dart';

void main() {
  group('Chat Widgets Tests', () {
    testWidgets('ChatMessageBubble renders user text message and timestamp', (
      WidgetTester tester,
    ) async {
      final message = MessageModel(
        id: 'msg_1',
        chatId: 'chat_1',
        senderId: 'user_1',
        senderName: 'John Tester',
        content: 'Hey, I reproduced the checkout bug on Android 14.',
        type: MessageType.text,
        createdAt: DateTime(2026, 11, 2, 10, 30),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatMessageBubble(
              message: message,
              isSender: false,
              isGroup: true,
            ),
          ),
        ),
      );

      expect(find.text('John Tester'), findsOneWidget);
      expect(
        find.text('Hey, I reproduced the checkout bug on Android 14.'),
        findsOneWidget,
      );
    });

    testWidgets('ChatMessageBubble renders system message format correctly', (
      WidgetTester tester,
    ) async {
      final sysMessage = MessageModel(
        id: 'msg_sys_1',
        chatId: 'chat_1',
        senderId: 'system',
        senderName: 'System',
        content: 'Ravi assigned BUG-102 to Priya',
        type: MessageType.system,
        createdAt: DateTime(2026, 11, 2, 11, 0),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatMessageBubble(message: sysMessage, isSender: false),
          ),
        ),
      );

      expect(find.text('Ravi assigned BUG-102 to Priya'), findsOneWidget);
    });

    testWidgets('BugReportMessageCard renders structured bug fields', (
      WidgetTester tester,
    ) async {
      var tapped = false;

      final bugMsg = MessageModel(
        id: 'msg_bug_1',
        chatId: 'chat_proj_1',
        senderId: 'user_tester',
        senderName: 'Sarah QA',
        content: 'Login button alignment issue on small screens',
        type: MessageType.bugReport,
        bugId: 'BUG-001',
        bugData: {
          'id': 'bug_001',
          'bugNumber': 'BUG-001',
          'title': 'Login button alignment issue on small screens',
          'description': 'The submit button overlaps with the bottom navigation bar on iPhone SE.',
          'category': 'uiUx',
          'severity': 'medium',
          'priority': 'high',
          'status': 'open',
          'attachmentUrls': <String>[],
        },
        createdAt: DateTime(2026, 11, 2, 11, 15),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BugReportMessageCard(
              message: bugMsg,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('UI / UX'), findsOneWidget);
      expect(
        find.text('Login button alignment issue on small screens'),
        findsOneWidget,
      );
      expect(
        find.text(
          'The submit button overlaps with the bottom navigation bar on iPhone SE.',
        ),
        findsOneWidget,
      );
      expect(find.text('Open'), findsOneWidget);

      await tester.tap(find.text('UI / UX'));
      await tester.pump();
      expect(tapped, isTrue);
    });
  });
}
