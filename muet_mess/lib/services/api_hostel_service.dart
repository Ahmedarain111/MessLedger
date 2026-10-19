import '../core/network/api_client.dart';
import '../models/hostel_model.dart';

/// Service to fetch university hostels from FastAPI backend.
class ApiHostelService {
  ApiHostelService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<Hostel>> getHostels() async {
    final response = await _client.get('/hostels');
    final list = response as List;
    return list.map((e) => Hostel.fromJson(e as Map<String, dynamic>)).toList();
  }
}
