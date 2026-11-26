package lk.zoo.api.migration;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Instant;
import java.util.Iterator;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.core.env.Environment;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

@Component
@ConditionalOnProperty(name = "app.legacy-import.enabled", havingValue = "true")
public class LegacyMapDataImporter implements ApplicationRunner {
    private static final Logger logger = LoggerFactory.getLogger(LegacyMapDataImporter.class);

    private final JdbcTemplate jdbc;
    private final ObjectMapper objectMapper;
    private final Path dataDirectory;

    public LegacyMapDataImporter(
            JdbcTemplate jdbc, ObjectMapper objectMapper, Environment environment) {
        this.jdbc = jdbc;
        this.objectMapper = objectMapper;
        this.dataDirectory = Path.of(environment.getProperty(
                "app.legacy-import.data-dir", "../assets/data"));
    }

    @Override
    @Transactional
    public void run(ApplicationArguments args) throws Exception {
        Path waypointsPath = dataDirectory.resolve("waypoints_flutter.json");
        Path routePath = dataDirectory.resolve("recorded_route.geojson");
        if (!Files.isRegularFile(waypointsPath) || !Files.isRegularFile(routePath)) {
            throw new IllegalStateException("Legacy map files were not found under "
                    + dataDirectory.toAbsolutePath());
        }

        long mapId = jdbc.queryForObject("""
                INSERT INTO zoo_map (map_key, name, description)
                VALUES ('dehiwala-zoo', 'Dehiwala Zoo', 'Zoo visitor map')
                ON CONFLICT (map_key) DO UPDATE SET name = EXCLUDED.name
                RETURNING id
                """, Long.class);
        long versionId = jdbc.queryForObject("""
                INSERT INTO map_version (zoo_map_id, version_label, source_description)
                VALUES (?, 'legacy-import-1',
                        'Imported from the Flutter waypoint JSON and recorded route GeoJSON')
                ON CONFLICT (zoo_map_id, version_label)
                DO UPDATE SET source_description = EXCLUDED.source_description
                RETURNING id
                """, Long.class, mapId);

        JsonNode waypoints = objectMapper.readTree(Files.readString(waypointsPath));
        if (!waypoints.isArray()) throw new IllegalArgumentException("Waypoint JSON must be an array.");
        for (JsonNode waypoint : waypoints) importWaypoint(versionId, waypoint);

        JsonNode document = objectMapper.readTree(Files.readString(routePath));
        JsonNode features = document.path("features");
        if (!"FeatureCollection".equals(document.path("type").asText()) || !features.isArray()) {
            throw new IllegalArgumentException("Recorded data must be a GeoJSON FeatureCollection.");
        }
        for (JsonNode feature : features) importRoute(versionId, feature);
        logger.info("Imported {} waypoint records and {} unverified recorded traces.",
                waypoints.size(), features.size());
    }

    private void importWaypoint(long versionId, JsonNode waypoint) throws Exception {
        String id = requiredText(waypoint, "id");
        String name = requiredText(waypoint, "name");
        double latitude = waypoint.path("latitude").asDouble(Double.NaN);
        double longitude = waypoint.path("longitude").asDouble(Double.NaN);
        validateCoordinates(longitude, latitude, id);

        String category = waypoint.path("category").asText("other").toLowerCase();
        String featureType = switch (category) {
            case "animal" -> "ANIMAL_LOCATION";
            case "facility" -> "FACILITY";
            case "landmark" -> "LANDMARK";
            default -> throw new IllegalArgumentException(
                    "Unsupported waypoint category for " + id + ": " + category);
        };
        boolean nameVerified = waypoint.path("nameVerified").asBoolean(false);
        boolean needsReview = waypoint.path("needsReview").asBoolean(false);
        String status = nameVerified ? "VERIFIED" : (needsReview ? "PENDING_REVIEW" : "UNVERIFIED");
        String recordedAt = nullableText(waypoint, "recordedAtUtc");

        jdbc.update("""
                INSERT INTO map_feature (
                    id, map_version_id, feature_type, name, geometry,
                    verification_status, name_verified, needs_review, review_note,
                    source_name, source_record_id, source_recorded_at, properties, active
                ) VALUES (
                    ?, ?, ?, ?, ST_SetSRID(ST_MakePoint(?, ?), 4326),
                    ?, ?, ?, ?, 'waypoints_flutter.json', ?, ?::timestamptz, ?::jsonb, TRUE
                )
                ON CONFLICT (id) DO UPDATE SET
                    map_version_id = EXCLUDED.map_version_id,
                    feature_type = EXCLUDED.feature_type,
                    name = EXCLUDED.name,
                    geometry = EXCLUDED.geometry,
                    verification_status = EXCLUDED.verification_status,
                    name_verified = EXCLUDED.name_verified,
                    needs_review = EXCLUDED.needs_review,
                    review_note = EXCLUDED.review_note,
                    source_name = EXCLUDED.source_name,
                    source_record_id = EXCLUDED.source_record_id,
                    source_recorded_at = EXCLUDED.source_recorded_at,
                    properties = EXCLUDED.properties,
                    updated_at = NOW()
                """,
                id, versionId, featureType, name, longitude, latitude,
                status, nameVerified, needsReview, nullableText(waypoint, "reviewNote"),
                id, recordedAt, objectMapper.writeValueAsString(waypoint));
    }

    private void importRoute(long versionId, JsonNode feature) throws Exception {
        JsonNode properties = feature.path("properties");
        String id = requiredText(properties, "track_id");
        JsonNode geometry = feature.path("geometry");
        String geometryType = geometry.path("type").asText();
        if (!"LineString".equals(geometryType) && !"MultiLineString".equals(geometryType)) {
            throw new IllegalArgumentException("Unsupported geometry for recorded trace " + id);
        }
        JsonNode coordinates = geometry.path("coordinates");
        if (!coordinates.isArray() || coordinates.isEmpty()) {
            throw new IllegalArgumentException("Recorded trace " + id + " has no coordinates.");
        }
        validateRouteCoordinates(geometryType, coordinates, id);
        String source = nullableText(properties, "source");
        String recordedAt = nullableText(properties, "start_time_utc");
        String useNote = nullableText(properties, "use_note");

        jdbc.update("""
                INSERT INTO map_feature (
                    id, map_version_id, feature_type, name, geometry,
                    verification_status, name_verified, needs_review, review_note,
                    source_name, source_record_id, source_recorded_at, properties, active
                ) VALUES (
                    ?, ?, 'RECORDED_ROUTE', ?, ST_SetSRID(ST_GeomFromGeoJSON(?), 4326),
                    'UNVERIFIED', FALSE, TRUE, ?, ?, ?, ?::timestamptz, ?::jsonb, TRUE
                )
                ON CONFLICT (id) DO UPDATE SET
                    map_version_id = EXCLUDED.map_version_id,
                    feature_type = EXCLUDED.feature_type,
                    name = EXCLUDED.name,
                    geometry = EXCLUDED.geometry,
                    verification_status = 'UNVERIFIED',
                    name_verified = FALSE,
                    needs_review = TRUE,
                    review_note = EXCLUDED.review_note,
                    source_name = EXCLUDED.source_name,
                    source_record_id = EXCLUDED.source_record_id,
                    source_recorded_at = EXCLUDED.source_recorded_at,
                    properties = EXCLUDED.properties,
                    updated_at = NOW()
                """,
                id, versionId, "Recorded GPS trace " + id, geometry.toString(),
                useNote, source, id,
                recordedAt == null ? null : Instant.parse(recordedAt).toString(),
                objectMapper.writeValueAsString(properties));
    }

    private void validateRouteCoordinates(String type, JsonNode coordinates, String id) {
        if ("LineString".equals(type)) {
            if (coordinates.size() < 2) {
                throw new IllegalArgumentException("Recorded trace " + id + " needs at least two points.");
            }
            Iterator<JsonNode> points = coordinates.elements();
            while (points.hasNext()) validatePoint(points.next(), id);
            return;
        }
        for (JsonNode line : coordinates) {
            if (!line.isArray() || line.size() < 2) {
                throw new IllegalArgumentException("Recorded trace " + id + " has an invalid line.");
            }
            for (JsonNode point : line) validatePoint(point, id);
        }
    }

    private void validatePoint(JsonNode point, String id) {
        if (!point.isArray() || point.size() < 2) {
            throw new IllegalArgumentException("Recorded trace " + id + " contains an invalid point.");
        }
        validateCoordinates(point.path(0).asDouble(Double.NaN),
                point.path(1).asDouble(Double.NaN), id);
    }

    private void validateCoordinates(double longitude, double latitude, String id) {
        if (!Double.isFinite(longitude) || longitude < -180 || longitude > 180
                || !Double.isFinite(latitude) || latitude < -90 || latitude > 90) {
            throw new IllegalArgumentException("Invalid coordinates for map record " + id);
        }
    }

    private String requiredText(JsonNode node, String field) {
        String value = nullableText(node, field);
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException("Missing required field: " + field);
        }
        return value;
    }

    private String nullableText(JsonNode node, String field) {
        JsonNode value = node.path(field);
        return value.isMissingNode() || value.isNull() ? null : value.asText();
    }
}