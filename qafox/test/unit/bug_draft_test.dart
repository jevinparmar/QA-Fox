import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qafox/features/bug_reporting/presentation/providers/bug_draft_provider.dart';

void main() {
  group('BugDraftNotifier Multi-Bug Management Tests', () {
    test('initializes with single blank draft', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final state = container.read(bugDraftProvider);
      expect(state.drafts.length, 1);
      expect(state.currentIndex, 0);
      expect(state.currentDraft.title, isEmpty);
    });

    test('addNewDraft adds new report and updates currentIndex', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(bugDraftProvider.notifier);
      notifier.updateCurrentDraft(title: 'Bug 1: Crash on launch');

      notifier.addNewDraft();
      final state = container.read(bugDraftProvider);
      expect(state.drafts.length, 2);
      expect(state.currentIndex, 1);
      expect(state.currentDraft.title, isEmpty);

      // Verify draft 0 data is preserved
      expect(state.drafts[0].title, 'Bug 1: Crash on launch');
    });

    test(
      'removeDraft removes specified draft and maintains valid currentIndex',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final notifier = container.read(bugDraftProvider.notifier);
        notifier.updateCurrentDraft(title: 'Bug 1');
        notifier.addNewDraft();
        notifier.updateCurrentDraft(title: 'Bug 2');

        expect(container.read(bugDraftProvider).drafts.length, 2);
        notifier.removeDraft(1);

        final state = container.read(bugDraftProvider);
        expect(state.drafts.length, 1);
        expect(state.currentIndex, 0);
        expect(state.currentDraft.title, 'Bug 1');
      },
    );
  });
}
