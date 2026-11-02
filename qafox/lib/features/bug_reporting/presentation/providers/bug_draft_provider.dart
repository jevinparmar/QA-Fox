import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../domain/repositories/bug_repository.dart';

class BugDraftState {
  final List<BugDraft> drafts;
  final int currentIndex;
  final bool isSubmitting;
  final double uploadProgress;
  final String? errorMessage;

  BugDraftState({
    required this.drafts,
    this.currentIndex = 0,
    this.isSubmitting = false,
    this.uploadProgress = 0.0,
    this.errorMessage,
  });

  BugDraft get currentDraft => drafts.isNotEmpty
      ? drafts[currentIndex]
      : BugDraft(id: const Uuid().v4());

  BugDraftState copyWith({
    List<BugDraft>? drafts,
    int? currentIndex,
    bool? isSubmitting,
    double? uploadProgress,
    String? errorMessage,
  }) {
    return BugDraftState(
      drafts: drafts ?? this.drafts,
      currentIndex: currentIndex ?? this.currentIndex,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      errorMessage: errorMessage,
    );
  }
}

class BugDraftNotifier extends Notifier<BugDraftState> {
  static const _uuid = Uuid();

  @override
  BugDraftState build() => BugDraftState(drafts: [BugDraft(id: _uuid.v4())]);

  void addNewDraft() {
    final newDraft = BugDraft(id: _uuid.v4());
    state = state.copyWith(
      drafts: [...state.drafts, newDraft],
      currentIndex: state.drafts.length,
    );
  }

  void setCurrentIndex(int index) {
    if (index >= 0 && index < state.drafts.length) {
      state = state.copyWith(currentIndex: index);
    }
  }

  void removeDraft(int index) {
    if (state.drafts.length <= 1) {
      state = BugDraftState(drafts: [BugDraft(id: _uuid.v4())]);
      return;
    }

    final newDrafts = List<BugDraft>.from(state.drafts)..removeAt(index);
    final newIndex = state.currentIndex >= newDrafts.length
        ? newDrafts.length - 1
        : state.currentIndex;

    state = state.copyWith(drafts: newDrafts, currentIndex: newIndex);
  }

  void updateCurrentDraft({
    String? title,
    String? description,
    String? category,
    String? severity,
    String? priority,
    String? screenName,
    String? url,
    String? stepsToReproduce,
    String? expectedResult,
    String? actualResult,
  }) {
    if (state.drafts.isEmpty) return;

    final current = state.drafts[state.currentIndex];
    if (title != null) current.title = title;
    if (description != null) current.description = description;
    if (category != null) current.category = category;
    if (severity != null) current.severity = severity;
    if (priority != null) current.priority = priority;
    if (screenName != null) current.screenName = screenName;
    if (url != null) current.url = url;
    if (stepsToReproduce != null) current.stepsToReproduce = stepsToReproduce;
    if (expectedResult != null) current.expectedResult = expectedResult;
    if (actualResult != null) current.actualResult = actualResult;

    state = state.copyWith(drafts: List.from(state.drafts));
  }

  void addFilesToCurrentDraft(List<XFile> files) {
    if (state.drafts.isEmpty) return;
    final current = state.drafts[state.currentIndex];
    current.localFiles.addAll(files);
    state = state.copyWith(drafts: List.from(state.drafts));
  }

  void removeFileFromCurrentDraft(int fileIndex) {
    if (state.drafts.isEmpty) return;
    final current = state.drafts[state.currentIndex];
    if (fileIndex >= 0 && fileIndex < current.localFiles.length) {
      current.localFiles.removeAt(fileIndex);
      state = state.copyWith(drafts: List.from(state.drafts));
    }
  }

  void reset() {
    state = BugDraftState(drafts: [BugDraft(id: _uuid.v4())]);
  }

  void setSubmitting(bool isSubmitting, [double progress = 0.0]) {
    state = state.copyWith(
      isSubmitting: isSubmitting,
      uploadProgress: progress,
    );
  }
}

final bugDraftProvider = NotifierProvider<BugDraftNotifier, BugDraftState>(
  BugDraftNotifier.new,
);
