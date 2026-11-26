package lk.zoo.api.map;

import java.util.List;
import org.springframework.stereotype.Service;

@Service
public class MapFeatureService {
    private final MapFeatureRepository repository;

    public MapFeatureService(MapFeatureRepository repository) {
        this.repository = repository;
    }

    public GeoJsonFeatureCollectionDto findFeatures(
            Double minLon, Double minLat, Double maxLon, Double maxLat) {
        List<GeoJsonFeatureDto> features = repository
                .findActiveFeatures(minLon, minLat, maxLon, maxLat)
                .stream()
                .map(GeoJsonFeatureDto::from)
                .toList();
        return new GeoJsonFeatureCollectionDto(features);
    }
}