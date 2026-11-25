package lk.zoo.api.animal;

public record AnimalDto(
        long id,
        String commonName,
        String scientificName,
        String classification,
        String habitat,
        String diet,
        String nativeRange,
        String conservationStatus,
        String description) {
}