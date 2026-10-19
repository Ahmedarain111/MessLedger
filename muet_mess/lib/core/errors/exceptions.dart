/// Thrown when a user attempts an action they are not allowed to perform.
class PermissionDeniedException implements Exception {
  /// A short description of the denied action.
  final String message;

  /// Creates a new permission error with [message].
  const PermissionDeniedException(this.message);

  @override
  String toString() => 'PermissionDeniedException: $message';
}
