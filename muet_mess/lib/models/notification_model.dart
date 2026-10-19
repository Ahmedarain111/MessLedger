/// In-app notification (mock now, push/API later).
class AppNotification {
  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
  });

  final String id;
  final String userId;
  final String title;
  final String message;
  final DateTime createdAt;
  bool isRead;
}
