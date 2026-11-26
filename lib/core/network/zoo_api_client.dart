import 'dart:convert';

import 'package:http/http.dart' as http;

class ZooApiException implements Exception {
  final String message;

  const ZooApiException(this.message);

  @override
  String toString() => message;
}

class ZooApiClient {
  static const _configuredBaseUrl = String.fromEnvironment(
    'ZOO_API_BASE_URL',
    defaultValue: 'http://localhost:8080/api/v1/',
  );

  final http.Client _client;
  final Uri baseUri;

  ZooApiClient({http.Client? client, Uri? baseUri})
    : _client = client ?? http.Client(),
      baseUri = baseUri ?? Uri.parse(_configuredBaseUrl);

  Future<Map<String, dynamic>> getMapFeatures() async {
    final normalizedBase = baseUri.path.endsWith('/')
        ? baseUri
        : baseUri.replace(path: '${baseUri.path}/');
    final response = await _client
        .get(normalizedBase.resolve('map/features'))
        .timeout(const Duration(milliseconds: 800));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ZooApiException('Map API returned HTTP ${response.statusCode}.');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> ||
        decoded['type'] != 'FeatureCollection' ||
        decoded['features'] is! List) {
      throw const ZooApiException('Map API returned invalid GeoJSON.');
    }
    return decoded;
  }

  void close() => _client.close();
}
