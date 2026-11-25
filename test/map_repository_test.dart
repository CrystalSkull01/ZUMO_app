import 'dart:convert';

import 'package:dehiwala_zoo_app/core/network/zoo_api_client.dart';
import 'package:dehiwala_zoo_app/repositories/map_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _waypointBackup =
    '[{"id":"WP001","name":"Ostrich","latitude":6.8,"longitude":79.8,"category":"animal","nameVerified":false,"needsReview":true,"reviewNote":"Check name"}]';
const _routeBackup = '{"type":"FeatureCollection","features":[]}';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads map waypoints and routes from the backend GeoJSON', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/v1/map/features');
      return httpResponse({
        'type': 'FeatureCollection',
        'features': [
          {
            'type': 'Feature',
            'id': 'WP001',
            'geometry': {
              'type': 'Point',
              'coordinates': [79.8, 6.8],
            },
            'properties': {
              'featureType': 'ANIMAL_LOCATION',
              'category': 'animal',
              'name': 'Ostrich',
              'nameVerified': false,
              'needsReview': true,
              'reviewNote': 'Check name',
            },
          },
          {
            'type': 'Feature',
            'id': 'TRACK01',
            'geometry': {
              'type': 'LineString',
              'coordinates': [
                [79.8, 6.8, 20],
                [79.81, 6.81, 21],
              ],
            },
            'properties': {
              'featureType': 'RECORDED_ROUTE',
              'verificationStatus': 'UNVERIFIED',
            },
          },
        ],
      });
    });
    final repository = MapRepository(
      apiClient: ZooApiClient(
        client: client,
        baseUri: Uri.parse('https://zoo.example/api/v1/'),
      ),
      assetLoader: (_) async => throw StateError('API should be used.'),
    );
    addTearDown(repository.dispose);

    final data = await repository.loadMapData();

    expect(data.waypoints, hasLength(1));
    expect(data.waypoints.single.id, 'WP001');
    expect(data.waypoints.single.nameVerified, isFalse);
    expect(data.waypoints.single.needsReview, isTrue);
    expect(data.waypoints.single.reviewNote, 'Check name');
    expect(data.routes, hasLength(1));
    expect(data.routes.single, hasLength(2));
  });

  test(
    'falls back to the unchanged local assets when the API is empty',
    () async {
      final client = MockClient(
        (_) async =>
            httpResponse({'type': 'FeatureCollection', 'features': []}),
      );
      final repository = MapRepository(
        apiClient: ZooApiClient(client: client),
        assetLoader: (path) async => path.endsWith('waypoints_flutter.json')
            ? _waypointBackup
            : _routeBackup,
      );
      addTearDown(repository.dispose);

      final data = await repository.loadMapData();

      expect(data.waypoints.single.id, 'WP001');
      expect(data.waypoints.single.needsReview, isTrue);
    },
  );
}

http.Response httpResponse(Map<String, Object?> body) =>
    http.Response(jsonEncode(body), 200);
