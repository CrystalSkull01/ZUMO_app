import 'package:flutter/material.dart';

import '../models/animal_discovery.dart';
import '../models/animal_profile.dart';
import '../models/gamification_profile.dart';
import '../models/zoo_waypoint.dart';
import '../services/animal_information_service.dart';
import '../widgets/animal_illustration.dart';

enum _CollectionFilter { all, discovered, undiscovered }

class WildlifeCollectionScreen extends StatefulWidget {
  final List<ZooWaypoint> animals;
  final GamificationProfile profile;
  final AnimalInformationService? informationService;
  final ValueChanged<ZooWaypoint> onOpenAnimal;
  final ValueChanged<ZooWaypoint> onShowOnMap;

  const WildlifeCollectionScreen({
    super.key,
    required this.animals,
    required this.profile,
    this.informationService,
    required this.onOpenAnimal,
    required this.onShowOnMap,
  });

  @override
  State<WildlifeCollectionScreen> createState() =>
      _WildlifeCollectionScreenState();
}

class _WildlifeCollectionScreenState extends State<WildlifeCollectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  _CollectionFilter _filter = _CollectionFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final query = _searchController.text.trim().toLowerCase();
    final discoveredCount = widget.animals
        .where((animal) => widget.profile.hasDiscovered(animal.id))
        .length;
    final progress = widget.animals.isEmpty
        ? 0.0
        : discoveredCount / widget.animals.length;
    final animals = widget.animals.where((animal) {
      final discovered = widget.profile.hasDiscovered(animal.id);
      final matchesFilter = switch (_filter) {
        _CollectionFilter.all => true,
        _CollectionFilter.discovered => discovered,
        _CollectionFilter.undiscovered => !discovered,
      };
      return matchesFilter &&
          (query.isEmpty || animal.name.toLowerCase().contains(query));
    }).toList();

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: const Text('Wildlife Collection'),
        leading: const Icon(Icons.auto_awesome_rounded),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 7, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CollectionProgressCard(
                  discoveredCount: discoveredCount,
                  animalCount: widget.animals.length,
                  totalXp: widget.profile.totalXp,
                  progress: progress,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search your collection',
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: colors.primary,
                    ),
                    suffixIcon: query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                    filled: true,
                    fillColor: colors.surfaceContainerLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(17),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterChip('All', _CollectionFilter.all),
                      const SizedBox(width: 8),
                      _filterChip('Discovered', _CollectionFilter.discovered),
                      const SizedBox(width: 8),
                      _filterChip(
                        'Undiscovered',
                        _CollectionFilter.undiscovered,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: animals.isEmpty
                ? Center(
                    child: Text(
                      'No animals match this search.',
                      style: Theme.of(context).textTheme.bodyLarge
                          ?.copyWith(color: colors.onSurfaceVariant),
                    ),
                  )
                : ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: animals.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 9),
                    itemBuilder: (context, index) {
                      final animal = animals[index];
                      final discovery = widget.profile.discoveries[animal.id];
                      final isDiscovered = discovery != null;
                      final profile = widget.informationService?.profileFor(
                        animal.id,
                      );
                      final scientificName = _verifiedScientificName(
                        animal,
                        profile,
                      );

                      return AnimatedSwitcher(
                        duration: const Duration(milliseconds: 480),
                        reverseDuration: const Duration(milliseconds: 200),
                        switchInCurve: Curves.easeOutBack,
                        switchOutCurve: Curves.easeIn,
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: Tween<double>(
                              begin: .94,
                              end: 1,
                            ).animate(animation),
                            child: child,
                          ),
                        ),
                        child: _CollectionAnimalCard(
                          key: ValueKey('${animal.id}-$isDiscovered'),
                          animal: animal,
                          isDiscovered: isDiscovered,
                          discovery: discovery,
                          scientificName: scientificName,
                          onOpen: isDiscovered
                              ? () => widget.onOpenAnimal(animal)
                              : () => _showLockedMessage(context),
                          onShowOnMap: () => widget.onShowOnMap(animal),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String? _verifiedScientificName(ZooWaypoint animal, AnimalProfile? profile) {
    if (!animal.nameVerified || !(profile?.isVerified ?? false)) return null;
    final scientificName = profile?.scientificName?.trim();
    return scientificName == null || scientificName.isEmpty
        ? null
        : scientificName;
  }

  Widget _filterChip(String label, _CollectionFilter filter) {
    final colors = Theme.of(context).colorScheme;
    final selected = _filter == filter;
    return FilterChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      visualDensity: VisualDensity.compact,
      backgroundColor: colors.surfaceContainerLow,
      selectedColor: colors.primaryContainer,
      side: BorderSide(
        color: selected
            ? colors.primary.withValues(alpha: .35)
            : colors.outlineVariant.withValues(alpha: .5),
      ),
      labelStyle: TextStyle(
        color: selected ? colors.onPrimaryContainer : colors.onSurfaceVariant,
        fontWeight: FontWeight.w700,
      ),
      onSelected: (_) => setState(() => _filter = filter),
    );
  }

  void _showLockedMessage(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Explore the zoo to unlock this animal!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}

class _CollectionProgressCard extends StatelessWidget {
  final int discoveredCount;
  final int animalCount;
  final int totalXp;
  final double progress;

  const _CollectionProgressCard({
    required this.discoveredCount,
    required this.animalCount,
    required this.totalXp,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(17, 15, 17, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF174E3A), Color(0xFF176B64)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x28174E3A),
            blurRadius: 13,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -8,
            top: -15,
            child: Icon(
              Icons.eco_rounded,
              size: 84,
              color: Colors.white.withValues(alpha: .07),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.explore_rounded,
                    color: Color(0xFFFFD36E),
                    size: 21,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'WILDLIFE FIELD GUIDE',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: const Color(0xFFD7EBDC),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD36E),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$totalXp XP',
                      style: const TextStyle(
                        color: Color(0xFF604409),
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Text(
                'Animals discovered',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFFD7EBDC),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                '$discoveredCount / $animalCount',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 9),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0).toDouble(),
                  minHeight: 8,
                  backgroundColor: Colors.white.withValues(alpha: .22),
                  color: const Color(0xFFFFD36E),
                ),
              ),
              const SizedBox(height: 7),
              Text(
                discoveredCount == animalCount && animalCount > 0
                    ? 'Collection complete. Keep exploring the zoo!'
                    : 'Explore the zoo to unlock your next animal friend.',
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: Colors.white.withValues(alpha: .9)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CollectionAnimalCard extends StatelessWidget {
  final ZooWaypoint animal;
  final bool isDiscovered;
  final AnimalDiscovery? discovery;
  final String? scientificName;
  final VoidCallback onOpen;
  final VoidCallback onShowOnMap;

  const _CollectionAnimalCard({
    super.key,
    required this.animal,
    required this.isDiscovered,
    required this.discovery,
    required this.scientificName,
    required this.onOpen,
    required this.onShowOnMap,
  });

  static const _grayscale = ColorFilter.matrix([
    .2126,
    .7152,
    .0722,
    0,
    0,
    .2126,
    .7152,
    .0722,
    0,
    0,
    .2126,
    .7152,
    .0722,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ]);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final reviewNote = animal.reviewNote?.trim();
    final qualityNotes = <String>[
      if (!animal.nameVerified) 'Name not verified',
      if (animal.needsReview) 'Details need review',
      if (reviewNote != null && reviewNote.isNotEmpty) reviewNote,
    ];
    final isNameKnown = animal.nameVerified;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: isDiscovered
            ? const Color(0xFFFFFBF0)
            : colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(
          color: isDiscovered
              ? const Color(0xFFE0B044)
              : colors.outlineVariant.withValues(alpha: .55),
          width: isDiscovered ? 1.7 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDiscovered
                ? const Color(0x33DEA930)
                : colors.shadow.withValues(alpha: .06),
            blurRadius: isDiscovered ? 14 : 7,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                _AnimalArtwork(animal: animal, isDiscovered: isDiscovered),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _StatusBadge(isDiscovered: isDiscovered),
                        const SizedBox(height: 6),
                        Text(
                          isDiscovered
                              ? animal.name
                              : isNameKnown
                              ? animal.name
                              : 'Mystery animal',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: colors.onSurface,
                              ),
                        ),
                        if (isDiscovered) ...[
                          const SizedBox(height: 2),
                          Text(
                            scientificName ?? 'Scientific name unavailable',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: colors.onSurfaceVariant,
                                  fontStyle: scientificName == null
                                      ? FontStyle.normal
                                      : FontStyle.italic,
                                  fontSize: 11,
                                ),
                          ),
                          if (!animal.nameVerified)
                            Text(
                              'Recorded name not verified',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: colors.onSurfaceVariant,
                                    fontSize: 10,
                                  ),
                            ),
                          const SizedBox(height: 3),
                          _XpRewardBadge(xp: discovery?.xpAwarded ?? 0),
                        ] else ...[
                          const SizedBox(height: 3),
                          Text(
                            'Explore the zoo to unlock this animal!',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: colors.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                        if (qualityNotes.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            qualityNotes.join(' / '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: colors.onSurfaceVariant.withValues(
                                    alpha: .82,
                                  ),
                                  fontSize: 9,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Show habitat on map',
                  onPressed: onShowOnMap,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.map_outlined, color: colors.primary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimalArtwork extends StatelessWidget {
  final ZooWaypoint animal;
  final bool isDiscovered;

  const _AnimalArtwork({required this.animal, required this.isDiscovered});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      height: 104,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (isDiscovered)
              AnimalIllustration(
                animalName: animal.name,
                width: 96,
                height: 104,
              )
            else
              ColorFiltered(
                colorFilter: _CollectionAnimalCard._grayscale,
                child: AnimalIllustration(
                  animalName: animal.name,
                  width: 96,
                  height: 104,
                ),
              ),
            if (!isDiscovered) ...[
              ColoredBox(color: const Color(0x660D211A)),
              Center(
                child: Container(
                  width: 43,
                  height: 43,
                  decoration: BoxDecoration(
                    color: const Color(0xCC173F32),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0x99FFFFFF),
                      width: 1.2,
                    ),
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    color: Color(0xFFFFD36E),
                    size: 22,
                  ),
                ),
              ),
            ],
            if (isDiscovered)
              const Positioned(
                right: 6,
                top: 6,
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: Color(0xFFFFD36E),
                  size: 17,
                  shadows: [Shadow(color: Color(0x991A352B), blurRadius: 5)],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isDiscovered;

  const _StatusBadge({required this.isDiscovered});

  @override
  Widget build(BuildContext context) {
    final tint = isDiscovered
        ? const Color(0xFFFFD36E)
        : const Color(0xFFDEE5DF);
    final textColor = isDiscovered
        ? const Color(0xFF604409)
        : const Color(0xFF48574D);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isDiscovered ? Icons.lock_open_rounded : Icons.lock_rounded,
            size: 12,
            color: textColor,
          ),
          const SizedBox(width: 4),
          Text(
            isDiscovered ? 'UNLOCKED' : 'LOCKED',
            style: TextStyle(
              color: textColor,
              fontSize: 9,
              letterSpacing: .6,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _XpRewardBadge extends StatelessWidget {
  final int xp;

  const _XpRewardBadge({required this.xp});

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: .8, end: 1),
    duration: const Duration(milliseconds: 460),
    curve: Curves.easeOutBack,
    builder: (context, scale, child) => Transform.scale(
      scale: scale,
      alignment: Alignment.centerLeft,
      child: child,
    ),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0BE),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFE0B044).withValues(alpha: .7),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.stars_rounded, size: 13, color: Color(0xFF9A6A06)),
          const SizedBox(width: 4),
          Text(
            '+$xp XP',
            style: const TextStyle(
              color: Color(0xFF704D07),
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    ),
  );
}
