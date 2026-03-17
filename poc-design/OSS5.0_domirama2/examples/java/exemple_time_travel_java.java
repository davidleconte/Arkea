// ============================================
// Exemple d'Implémentation Time Travel en Java
// ============================================

package com.arkea.domirama.service;

import com.arkea.domirama.model.Operation;
import com.arkea.domirama.repository.OperationRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class OperationService {

    @Autowired
    private OperationRepository operationRepository;

    /**
     * Logique Time Travel : Détermine la catégorie valide à une date donnée
     *
     * @param operation L'opération avec cat_auto, cat_user, cat_date_user
     * @param queryDate La date pour laquelle on veut connaître la catégorie
     * @return La catégorie valide à cette date
     */
    public String getCategoryAtDate(Operation operation, LocalDateTime queryDate) {
        // Si correction client existe ET date de correction <= date de requête
        if (operation.getCatUser() != null
            && operation.getCatDateUser() != null
            && !operation.getCatDateUser().isAfter(queryDate)) {
            return operation.getCatUser(); // Correction client était en place
        }

        // Sinon, utiliser la catégorie batch
        return operation.getCatAuto();
    }

    /**
     * Récupère une opération avec sa catégorie valide à une date donnée
     */
    public OperationWithCategory getOperationWithCategory(
            String codeSi, String contrat,
            LocalDateTime dateOp, int numeroOp,
            LocalDateTime queryDate) {

        // 1. Récupérer l'opération depuis HCD
        Operation operation = operationRepository.findByKey(
            codeSi, contrat, dateOp, numeroOp);

        if (operation == null) {
            throw new OperationNotFoundException(
                String.format("Operation not found: %s/%s/%s/%d",
                    codeSi, contrat, dateOp, numeroOp));
        }

        // 2. Appliquer la logique Time Travel
        String categoryAtDate = getCategoryAtDate(operation, queryDate);
        String source = categoryAtDate.equals(operation.getCatUser())
            ? "CLIENT"
            : "BATCH";

        return OperationWithCategory.builder()
            .operation(operation)
            .categoryAtDate(categoryAtDate)
            .source(source)
            .queryDate(queryDate)
            .build();
    }
}
