package lk.zoo.api.map;

import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(MapFeatureController.class)
class MapFeatureControllerTest {
    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private MapFeatureService service;

    @Test
    void returnsGeoJsonFeatureCollection() throws Exception {
        when(service.findFeatures(null, null, null, null))
                .thenReturn(new GeoJsonFeatureCollectionDto(List.of()));

        mockMvc.perform(get("/api/v1/map/features"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.type").value("FeatureCollection"))
                .andExpect(jsonPath("$.features").isArray());
    }

    @Test
    void rejectsPartialBounds() throws Exception {
        mockMvc.perform(get("/api/v1/map/features").param("minLon", "79.8"))
                .andExpect(status().isBadRequest());
    }
}