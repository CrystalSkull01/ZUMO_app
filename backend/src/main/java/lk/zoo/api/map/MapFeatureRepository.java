package lk.zoo.api.map;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.List;
import java.util.Map;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

@Repository
public class MapFeatureRepository {
    private static final TypeReference<Map<String, Object>> JSON_OBJECT =
            new TypeReference<>() {};

    private final JdbcTemplate jdbc;
    private final ObjectMapper objectMapper;

    public MapFeatureRepository(JdbcTemplate jdbc, ObjectMapper objectMapper) {
        this.jdbc = jdbc;
        this.objectMapper = objectMapper;
    }

    public List<MapFeatureDto> findActiveFeatures(
            Double minLon, Double minLat, Double maxLon, Double maxLat) {
        boolean hasBounds = minLon != null;
        String sql = """
                SELECT id, feature_type, name, ST_AsGeoJSON(geometry) AS geometry_json,
                       verification_status, name_verified, needs_review, review_note,
                       source_name, source_record_id, properties::text AS properties_json
                FROM map_feature
                WHERE active = TRUE
                """ + (hasBounds
                ? " AND ST_Intersects(geometry, ST_MakeEnvelope(?, ?, ?, ?, 4326))"
                : "") + " ORDER BY feature_type, name, id";

        RowMapper<MapFeatureDto> mapper = this::mapRow;
        if (!hasBounds) return jdbc.query(sql, mapper);
        return jdbc.query(sql, mapper, minLon, minLat, maxLon, maxLat);
    }

    private MapFeatureDto mapRow(ResultSet row, int rowNumber) throws SQLException {
        try {
            Map<String, Object> geometry =
                    objectMapper.readValue(row.getString("geometry_json"), JSON_OBJECT);
            Map<String, Object> properties =
                    objectMapper.readValue(row.getString("properties_json"), JSON_OBJECT);
            return new MapFeatureDto(
                    row.getString("id"),
                    row.getString("feature_type"),
                    row.getString("name"),
                    geometry,
                    row.getString("verification_status"),
                    row.getBoolean("name_verified"),
                    row.getBoolean("needs_review"),
                    row.getString("review_note"),
                    row.getString("source_name"),
                    row.getString("source_record_id"),
                    properties);
        } catch (Exception exception) {
            throw new SQLException("Could not decode stored map feature JSON.", exception);
        }
    }
}