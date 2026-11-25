# Dehiwala Zoo backend foundation

This is the first backend increment. It adds a Spring Boot REST service, a PostGIS-backed PostgreSQL service, and the initial Flyway schema. No Flutter client switch or source data import has happened yet.

## Data safety and import policy

The Flutter source files remain the migration backups:
- ../assets/data/waypoints_flutter.json
- ../assets/data/recorded_route.geojson

All current waypoint names are unverified. The schema keeps review and verification state separate from animal records. Unverified animal-category waypoints should be imported as ANIMAL_LOCATION map features with no animal_id; an animal row and discovery eligibility are created only after the zoo confirms the identity and association.

The two recorded GeoJSON traces remain RECORDED_ROUTE, with their source metadata and UNVERIFIED status. They are not inserted into the official zoo_path table and are not represented as official visitor routes.

## Start locally

1. Install Docker Desktop and ensure its engine is running.
2. Copy .env.example to .env in this directory and replace the placeholder password with a local development value.
3. Keep the two password values equal for this local Compose setup.
4. Run docker compose -f compose.yaml up --build.
5. Check http://localhost:8080/api/v1/health.

Flyway applies V1__initial_schema.sql when the API connects. Database credentials are supplied through environment variables; do not commit .env.

## Initial schema

- zoo_map and map_version scope imported feature sets and support future map revisions.
- map_feature stores point, line, and polygon geometries in SRID 4326 with source, review, verification, and JSON metadata.
- animal and species store confirmed wildlife information; animal_image and animal_information_verification attach sourced content.
- facility adds type and visitor-facing details to a map feature.
- zoo_path is reserved for approved paths. It is inactive and unverified by default.
- app_user, animal_discovery, visitor_progress, and badge tables prepare the relational model for server-owned progress. Authentication and endpoints are introduced in a later increment.

## Environment

| Variable | Purpose |
|---|---|
| POSTGRES_DB | Local database name |
| POSTGRES_USER | Local database role |
| POSTGRES_PASSWORD | Local database password |
| SPRING_DATASOURCE_URL | API connection URL |
| SPRING_DATASOURCE_USERNAME | API database account |
| SPRING_DATASOURCE_PASSWORD | API database password |

Only GET /api/v1/health is exposed in this increment. Administrative and visitor endpoints will be added behind authorization as their API and validation rules are implemented.
