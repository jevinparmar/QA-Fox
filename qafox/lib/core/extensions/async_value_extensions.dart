import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors/error_handler.dart';
import 'context_extensions.dart';

extension AsyncValueUI on AsyncValue {
  void showSnackBarOnError(BuildContext context) {
    if (!isLoading && hasError) {
      final msg = ErrorHandler.getFriendlyMessage(error);
      context.showSnackBar(msg, isError: true);
    }
  }
}
