package lk.zoo.api.animal;

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

@WebMvcTest(AnimalController.class)
class AnimalControllerTest {
    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private AnimalService service;

    @Test
    void returnsTheVerifiedCatalogue() throws Exception {
        when(service.findVerifiedAnimals("")).thenReturn(List.of(
                new AnimalDto(1L, "Example species", null, null, null, null,
                        null, null, null)));

        mockMvc.perform(get("/api/v1/animals"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].commonName").value("Example species"));
    }

    @Test
    void passesSearchTermsToTheService() throws Exception {
        when(service.findVerifiedAnimals("tiger")).thenReturn(List.of());

        mockMvc.perform(get("/api/v1/animals").param("query", "tiger"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isEmpty());
    }
}