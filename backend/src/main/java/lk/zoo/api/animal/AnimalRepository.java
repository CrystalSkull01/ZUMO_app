package lk.zoo.api.animal;

import java.sql.ResultSet;
import java.util.List;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

@Repository
public class AnimalRepository {
    private final JdbcTemplate jdbc;

    public AnimalRepository(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public List<AnimalDto> findVerifiedAnimals(String query) {
        String search = query == null ? "" : query.trim();
        return jdbc.query("""
                SELECT a.id, a.common_name, s.scientific_name, s.classification,
                       s.habitat, s.diet, s.native_range, s.conservation_status,
                       a.description
                FROM animal a
                LEFT JOIN species s
                    ON s.id = a.species_id AND s.verification_status = 'VERIFIED'
                WHERE a.verification_status = 'VERIFIED'
                  AND (? = '' OR a.common_name ILIKE ?)
                ORDER BY a.common_name, a.id
                """, mapper(), search, "%" + search + "%");
    }

    private RowMapper<AnimalDto> mapper() {
        return (ResultSet row, int rowNumber) -> new AnimalDto(
                row.getLong("id"),
                row.getString("common_name"),
                row.getString("scientific_name"),
                row.getString("classification"),
                row.getString("habitat"),
                row.getString("diet"),
                row.getString("native_range"),
                row.getString("conservation_status"),
                row.getString("description"));
    }
}
