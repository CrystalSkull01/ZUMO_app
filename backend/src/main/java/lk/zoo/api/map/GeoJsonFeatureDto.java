package lk.zoo.api.map;

import java.util.LinkedHashMap;
import java.util.Map;

public record GeoJsonFeatureDto(
        String type,
        String id,
        Map<String, Object> geometry,
        Map<String, Object> properties) {
    static GeoJsonFeatureDto from(MapFeatureDto feature) {
        var properties = new LinkedHashMap<>(feature.properties());
        properties.put("featureType", feature.featureType());
        properties.put("name", feature.name());
        properties.put("verificationStatus", feature.verificationStatus());
        properties.put("nameVerified", feature.nameVerified());
        properties.put("needsReview", feature.needsReview());
        if (feature.reviewNote() != null) properties.put("reviewNote", feature.reviewNote());
        if (feature.sourceName() != null) properties.put("sourceName", feature.sourceName());
        if (feature.sourceRecordId() != null) properties.put("sourceRecordId", feature.sourceRecordId());
        return new GeoJsonFeatureDto("Feature", feature.id(), feature.geometry(), properties);
    }
}