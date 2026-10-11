class AppException implements Exception {
  final String message;
  final String? code;

  const AppException(this.message, {this.code});

  @override
  String toString() => 'AppException($code): $message';
}

class AuthException extends AppException {
  const AuthException(super.message, {super.code});
}

class QueueException extends AppException {
  const QueueException(super.message, {super.code});
}

class InvalidStateTransitionException extends QueueException {
  InvalidStateTransitionException(String from, String to)
      : super('Invalid transition: $from → $to', code: 'INVALID_TRANSITION');
}

class NetworkException extends AppException {
  const NetworkException(super.message, {super.code});
}

class PermissionException extends AppException {
  const PermissionException(super.message, {super.code});
}
