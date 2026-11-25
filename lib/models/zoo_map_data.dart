import 'package:latlong2/latlong.dart';

import 'zoo_waypoint.dart';

class ZooMapData {
  final List<ZooWaypoint> waypoints;
  final List<List<LatLng>> routes;

  const ZooMapData({required this.waypoints, required this.routes});
}
