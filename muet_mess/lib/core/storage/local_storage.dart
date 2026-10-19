export 'local_storage_stub.dart' if (dart.library.io) 'local_storage_io.dart';

// The real implementation is selected at compile time:
// a JSON file store on mobile/desktop, an in-memory store on web.
// The interface mirrors shared_preferences so the backend can be
// swapped later without touching providers.
