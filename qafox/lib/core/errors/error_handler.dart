import 'package:firebase_auth/firebase_auth.dart';

import 'app_exception.dart';

class ErrorHandler {
  const ErrorHandler._();

  static String getFriendlyMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No account found with this email address.';
        case 'wrong-password':
        case 'invalid-credential':
          return 'Invalid email or password. Please check and try again.';
        case 'email-already-in-use':
          return 'An account already exists for this email address.';
        case 'weak-password':
          return 'The password provided is too weak. Use at least 6 characters.';
        case 'invalid-email':
          return 'The email address is badly formatted.';
        case 'user-disabled':
          return 'This user account has been disabled.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection.';
        default:
          return error.message ?? 'Authentication failed. Please try again.';
      }
    }

    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
        case 'unauthorized':
          return 'You do not have permission to perform this action.';
        case 'bucket-not-found':
          return 'Firebase Storage bucket not found. Please activate Firebase Storage in your Firebase Console.';
        case 'not-found':
        case 'object-not-found':
          return 'The requested resource was not found.';
        case 'already-exists':
          return 'A resource with this ID already exists.';
        case 'unavailable':
          return 'Service is temporarily unavailable. Please try again later.';
        default:
          return error.message ?? 'An unexpected service error occurred.';
      }
    }

    if (error is AppException) {
      return error.message;
    }

    return error?.toString() ?? 'Something went wrong. Please try again.';
  }
}
