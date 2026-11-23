
import 'dart:convert';

import 'package:http/http.dart' as http;

class GeocodingService {
  static const String _baseUrl =
      'https://nominatim.openstreetmap.org/reverse';

  Future<String?> getAddressFromCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.parse(_baseUrl).replace(
      queryParameters: {
        'lat': latitude.toString(),
        'lon': longitude.toString(),
        'format': 'jsonv2',
        'accept-language': 'id',
      },
    );

    try {
      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'LaundryGo/1.0',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception('Failed to retrieve address.');
      }

      final data = jsonDecode(response.body);

      return data['display_name'] as String?;
    } catch (e) {
      rethrow;
    }
  }
}
