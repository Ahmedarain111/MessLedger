import 'package:uuid/uuid.dart';

/// Generates a new unique ID for mock entities.
String newId() => const Uuid().v4();
