package lk.zoo.api.map;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

@RestController
@RequestMapping("/api/v1/map")
public class MapFeatureController {
    private final MapFeatureService service;

    public MapFeatureController(MapFeatureService service) {
        this.service = service;
    }

    @GetMapping("/features")
    public GeoJsonFeatureCollectionDto getFeatures(
            @RequestParam(required = false) Double minLon,
            @RequestParam(required = false) Double minLat,
            @RequestParam(required = false) Double maxLon,
            @RequestParam(required = false) Double maxLat) {
        boolean anyBound = minLon != null || minLat != null || maxLon != null || maxLat != null;
        boolean allBounds = minLon != null && minLat != null && maxLon != null && maxLat != null;
        if (anyBound && !allBounds) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Provide all four bounds: minLon, minLat, maxLon, maxLat.");
        }
        if (allBounds && (minLon < -180 || maxLon > 180 || minLat < -90 || maxLat > 90
                || minLon >= maxLon || minLat >= maxLat)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid geographic bounds.");
        }
        return service.findFeatures(minLon, minLat, maxLon, maxLat);
    }
}