package lk.zoo.api.animal;

import java.util.List;
import org.springframework.stereotype.Service;

@Service
public class AnimalService {
    private final AnimalRepository repository;

    public AnimalService(AnimalRepository repository) {
        this.repository = repository;
    }

    public List<AnimalDto> findVerifiedAnimals(String query) {
        return repository.findVerifiedAnimals(query);
    }
}