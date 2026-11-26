import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

import '../core/network/zoo_api_client.dart';
import '../models/zoo_map_data.dart';
import '../models/zoo_waypoint.dart';

typedef AssetTextLoader = Future<String> Function(String path);

class MapRepository {
  final ZooApiClient _apiClient;
  final AssetTextLoader _loadAsset;

  MapRepository({ZooApiClient? apiClient, AssetTextLoader? assetLoader})
    : _apiClient = apiClient ?? ZooApiClient(),
      _loadAsset = assetLoader ?? ((path) => rootBundle.loadString(path));

  Future<ZooMapData> loadMapData() async {
    try {
      final document = await _apiClient.getMapFeatures();
      final remoteData = _parseFeatureCollection(document);
      if (remoteData.waypoints.isNotEmpty || remoteData.routes.isNotEmpty) {
        return remoteData;
      }
      debugPrint('Zoo API returned no map features; using bundled map data.');
    } catch (error) {
      debugPrint('Zoo map API unavailable; using bundled map data: $error');
    }
    return _loadBundledMapData();
  }

  ZooMapData _parseFeatureCollection(Map<String, dynamic> document) {
    final features = document['features'] as List<dynamic>;
    final waypoints = <ZooWaypoint>[];
    final routes = <List<LatLng>>[];

    for (final rawFeature in features) {
      if (rawFeature is! Map) continue;
      final feature = Map<String, dynamic>.from(rawFeature);
      final rawProperties = feature['properties'];
      final properties = rawProperties is Map
          ? Map<String, dynamic>.from(rawProperties)
          : <String, dynamic>{};
      final rawGeometry = feature['geometry'];
      if (rawGeometry is! Map) continue;
      final geometry = Map<String, dynamic>.from(rawGeometry);
      final geometryType = geometry['type'];
      final coordinates = geometry['coordinates'];
      final featureType = (properties['featureType'] as String? ?? '')
          .toUpperCase();

      if (geometryType == 'Point' && coordinates is List) {
        final point = _parsePoint(coordinates);
        final category =
            properties['category'] as String? ??
            switch (featureType) {
              'ANIMAL_LOCATION' => 'animal',
              'FACILITY' => 'facility',
              'LANDMARK' => 'landmark',
              _ => 'other',
            };
        waypoints.add(
          ZooWaypoint.fromJson({
            ...properties,
            'id': feature['id'] ?? properties['id'] ?? 'unknown',
            'name': properties['name'] ?? 'Unnamed location',
            'latitude': point.latitude,
            'longitude': point.longitude,
            'category': category,
          }),
        );
      } else if (geometryType == 'LineString' && coordinates is List) {
        _addRoute(coordinates, routes);
      } else if (geometryType == 'MultiLineString' && coordinates is List) {
        for (final line in coordinates) {
          if (line is List) _addRoute(line, routes);
        }
      }
    }

    return ZooMapData(waypoints: waypoints, routes: routes);
  }

  LatLng _parsePoint(List<dynamic> coordinates) {
    if (coordinates.length < 2 ||
        coordinates[0] is! num ||
        coordinates[1] is! num) {
      throw const FormatException(
        'GeoJSON point needs longitude and latitude.',
      );
    }
    return LatLng(
      (coordinates[1] as num).toDouble(),
      (coordinates[0] as num).toDouble(),
    );
  }

  void _addRoute(List<dynamic> coordinates, List<List<LatLng>> routes) {
    final points = coordinates
        .whereType<List<dynamic>>()
        .map(_parsePoint)
        .toList(growable: false);
    if (points.length >= 2) routes.add(points);
  }

  Future<ZooMapData> _loadBundledMapData() async {
    final files = await Future.wait([
      _loadAsset('assets/data/waypoints_flutter.json'),
      _loadAsset('assets/data/recorded_route.geojson'),
    ]);
    final waypointJson = jsonDecode(files[0]) as List<dynamic>;
    final waypoints = waypointJson.map((item) {
      return ZooWaypoint.fromJson(Map<String, dynamic>.from(item as Map));
    }).toList();

    final routeJson = jsonDecode(files[1]) as Map<String, dynamic>;
    final features = routeJson['features'] as List<dynamic>;
    final routes = <List<LatLng>>[];
    for (final feature in features) {
      final featureMap = Map<String, dynamic>.from(feature as Map);
      final geometry = Map<String, dynamic>.from(featureMap['geometry'] as Map);
      if (geometry['type'] == 'LineString') {
        final coordinates = geometry['coordinates'] as List<dynamic>;
        _addRoute(coordinates, routes);
      } else if (geometry['type'] == 'MultiLineString') {
        final lines = geometry['coordinates'] as List<dynamic>;
        for (final line in lines.whereType<List<dynamic>>()) {
          _addRoute(line, routes);
        }
      }
    }
    return ZooMapData(waypoints: waypoints, routes: routes);
  }

  void dispose() => _apiClient.close();
}
