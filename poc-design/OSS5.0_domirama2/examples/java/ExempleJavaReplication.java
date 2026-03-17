package com.arkea.domirama;

import com.datastax.oss.driver.api.core.CqlSession;
import com.datastax.oss.driver.api.core.ConsistencyLevel;
import com.datastax.oss.driver.api.core.config.DriverConfigLoader;
import com.datastax.oss.driver.api.core.config.DefaultDriverOption;
import com.datastax.oss.driver.api.core.cql.SimpleStatement;
import com.datastax.oss.driver.api.core.cql.ResultSet;
import com.datastax.oss.driver.api.core.cql.Row;
import com.datastax.oss.driver.api.core.loadbalancing.LoadBalancingPolicy;
import com.datastax.oss.driver.internal.core.loadbalancing.DefaultLoadBalancingPolicy;

import java.math.BigDecimal;
import java.time.Instant;

/**
 * Exemple d'utilisation du Driver Java avec consistency levels
 * Équivalent REPLICATION_SCOPE HBase avec contrôle de consistance
 *
 * Ce code démontre :
 * - Configuration du driver avec consistency level par défaut
 * - Utilisation de QUORUM pour consistance forte
 * - Utilisation de LOCAL_QUORUM pour performance locale (multi-datacenter)
 * - Load Balancing Policy pour multi-datacenter
 * - Retry Policy pour gestion des erreurs
 */
public class ExempleJavaReplication {

    public static void main(String[] args) {
        // ============================================
        // Configuration du Driver avec Consistency Level par défaut
        // ============================================

        CqlSession session = CqlSession.builder()
            .withConfigLoader(DriverConfigLoader.programmaticBuilder()
                // Consistency Level par défaut : QUORUM (bon équilibre performance/consistance)
                .withString(DefaultDriverOption.REQUEST_CONSISTENCY, "QUORUM")

                // Load Balancing : Datacenter local en priorité (pour LOCAL_QUORUM)
                .withString(DefaultDriverOption.LOAD_BALANCING_LOCAL_DATACENTER, "paris")

                // Retry Policy : Gestion automatique des erreurs
                .withString(DefaultDriverOption.RETRY_POLICY_CLASS,
                    "com.datastax.oss.driver.internal.core.retry.DefaultRetryPolicy")

                .build())
            .build();

        // ============================================
        // Exemple 1 : Lecture avec QUORUM (consistance forte)
        // Équivalent REPLICATION_SCOPE => '1' avec garantie de consistance
        // ============================================

        System.out.println("=== Exemple 1 : Lecture avec QUORUM ===");

        SimpleStatement select = SimpleStatement.builder(
                "SELECT * FROM operations_by_account WHERE code_si = ? AND contrat = ?")
            .addPositionalValue("DEMO_MV")
            .addPositionalValue("DEMO_001")
            .setConsistencyLevel(ConsistencyLevel.QUORUM)  // Consistance forte
            .build();

        ResultSet result = session.execute(select);
        for (Row row : result) {
            System.out.println("Opération: " + row.getString("libelle") +
                             " - Montant: " + row.getBigDecimal("montant"));
        }

        // ============================================
        // Exemple 2 : Lecture avec LOCAL_QUORUM (performance locale)
        // Pour multi-datacenter : Performance locale sans latence inter-datacenter
        // ============================================

        System.out.println("\n=== Exemple 2 : Lecture avec LOCAL_QUORUM ===");

        SimpleStatement selectLocal = SimpleStatement.builder(
                "SELECT * FROM operations_by_account WHERE code_si = ? AND contrat = ?")
            .addPositionalValue("DEMO_MV")
            .addPositionalValue("DEMO_001")
            .setConsistencyLevel(ConsistencyLevel.LOCAL_QUORUM)  // Performance locale
            .build();

        ResultSet resultLocal = session.execute(selectLocal);
        for (Row row : resultLocal) {
            System.out.println("Opération: " + row.getString("libelle"));
        }

        // ============================================
        // Exemple 3 : Écriture avec QUORUM (consistance forte)
        // Équivalent REPLICATION_SCOPE => '1' avec garantie de réplication
        // ============================================

        System.out.println("\n=== Exemple 3 : Écriture avec QUORUM ===");

        SimpleStatement insert = SimpleStatement.builder(
                "INSERT INTO operations_by_account (code_si, contrat, date_op, numero_op, libelle, montant) VALUES (?, ?, ?, ?, ?, ?)")
            .addPositionalValue("DEMO_MV")
            .addPositionalValue("DEMO_001")
            .addPositionalValue(Instant.now())
            .addPositionalValue(1)
            .addPositionalValue("VIREMENT SEPA")
            .addPositionalValue(new BigDecimal("1000.00"))
            .setConsistencyLevel(ConsistencyLevel.QUORUM)  // Consistance forte
            .build();

        session.execute(insert);
        System.out.println("Opération insérée avec QUORUM (consistance forte)");

        // ============================================
        // Exemple 4 : Écriture avec LOCAL_QUORUM (performance locale)
        // Pour multi-datacenter : Performance locale, réplication asynchrone
        // ============================================

        System.out.println("\n=== Exemple 4 : Écriture avec LOCAL_QUORUM ===");

        SimpleStatement insertLocal = SimpleStatement.builder(
                "INSERT INTO operations_by_account (code_si, contrat, date_op, numero_op, libelle, montant) VALUES (?, ?, ?, ?, ?, ?)")
            .addPositionalValue("DEMO_MV")
            .addPositionalValue("DEMO_001")
            .addPositionalValue(Instant.now())
            .addPositionalValue(2)
            .addPositionalValue("PRLV EDF")
            .addPositionalValue(new BigDecimal("-50.00"))
            .setConsistencyLevel(ConsistencyLevel.LOCAL_QUORUM)  // Performance locale
            .build();

        session.execute(insertLocal);
        System.out.println("Opération insérée avec LOCAL_QUORUM (performance locale)");

        // ============================================
        // Exemple 5 : Lecture avec ONE (performance maximale)
        // Risque : Données potentiellement non à jour
        // ============================================

        System.out.println("\n=== Exemple 5 : Lecture avec ONE (performance maximale) ===");

        SimpleStatement selectOne = SimpleStatement.builder(
                "SELECT * FROM operations_by_account WHERE code_si = ? AND contrat = ? LIMIT 1")
            .addPositionalValue("DEMO_MV")
            .addPositionalValue("DEMO_001")
            .setConsistencyLevel(ConsistencyLevel.ONE)  // Performance maximale
            .build();

        ResultSet resultOne = session.execute(selectOne);
        Row firstRow = resultOne.one();
        if (firstRow != null) {
            System.out.println("Opération: " + firstRow.getString("libelle"));
        }

        session.close();

        System.out.println("\n=== Exemples terminés ===");
    }
}
