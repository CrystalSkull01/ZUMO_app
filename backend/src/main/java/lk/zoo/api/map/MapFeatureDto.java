package lk.zoo.api.map;

import java.util.Map;

public record MapFeatureDto(
        String id,
        String featureType,
        String name,
        Map<String, Object> geometry,
        String verificationStatus,
        boolean nameVerified,
        boolean needsReview,
        String reviewNote,
        String sourceName,
        String sourceRecordId,
        Map<String, Object> properties) {
}