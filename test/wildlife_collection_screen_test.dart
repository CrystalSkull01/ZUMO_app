import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dehiwala_zoo_app/models/animal_discovery.dart';
import 'package:dehiwala_zoo_app/models/gamification_profile.dart';
import 'package:dehiwala_zoo_app/models/zoo_waypoint.dart';
import 'package:dehiwala_zoo_app/screens/wildlife_collection_screen.dart';

void main() {
  const ostrich = ZooWaypoint(
    id: 'WP002',
    name: 'Ostrich',
    latitude: 6.856792,
    longitude: 79.872837,
    category: 'animal',
    nameVerified: false,
    needsReview: false,
    reviewNote: 'Name retained from the recorded waypoint.',
  );
  const crane = ZooWaypoint(
    id: 'WP003',
    name: 'Crowned Crane',
    latitude: 6.85723,
    longitude: 79.872722,
    category: 'animal',
  );

  testWidgets('collection shows progress, unlocks and map action', (
    WidgetTester tester,
  ) async {
    final profile = GamificationProfile.empty().record(
      AnimalDiscovery(
        waypointId: ostrich.id,
        xpAwarded: 100,
        discoveredAtUtc: DateTime.utc(2026, 10, 25),
      ),
    );
    ZooWaypoint? opened;
    ZooWaypoint? mapped;

    await tester.pumpWidget(
      MaterialApp(
        home: WildlifeCollectionScreen(
          animals: const [ostrich, crane],
          profile: profile,
          onOpenAnimal: (waypoint) => opened = waypoint,
          onShowOnMap: (waypoint) => mapped = waypoint,
        ),
      ),
    );

    expect(find.text('1 / 2'), findsOneWidget);
    expect(find.text('100 XP'), findsOneWidget);
    expect(find.text('LOCKED'), findsOneWidget);
    expect(find.text('UNLOCKED'), findsOneWidget);
    expect(find.textContaining('Name not verified'), findsNWidgets(2));
    expect(
      find.textContaining('Name retained from the recorded waypoint.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Ostrich'));
    expect(opened?.id, ostrich.id);

    opened = null;
    await tester.tap(find.text('Explore the zoo to unlock this animal!'));
    expect(opened, isNull);
    expect(find.byIcon(Icons.lock_rounded), findsWidgets);

    await tester.tap(find.byTooltip('Show habitat on map').first);
    expect(mapped?.id, ostrich.id);

    await tester.tap(find.widgetWithText(FilterChip, 'Undiscovered'));
    await tester.pumpAndSettle();
    expect(find.text('Mystery animal'), findsOneWidget);
    expect(find.text('Ostrich'), findsNothing);
  });

  testWidgets('collection artwork uses existing animal illustration assets', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: WildlifeCollectionScreen(
          animals: const [ostrich],
          profile: GamificationProfile.empty(),
          onOpenAnimal: (_) {},
          onShowOnMap: (_) {},
        ),
      ),
    );
    expect(find.byType(Image), findsOneWidget);
    expect(find.textContaining('Name not verified'), findsOneWidget);
  });
}
