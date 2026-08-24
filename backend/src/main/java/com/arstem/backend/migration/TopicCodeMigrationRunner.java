package com.arstem.backend.migration;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;

/**
 * Runs {@link TopicCodeMigrationService} once on application startup.
 *
 * <p>Ordering: {@code @Order(2)} ensures this runs <em>after</em>
 * {@code TopicSeeder} ({@code @Order(1)} or default) has already seeded the
 * canonical topic catalogue, so the migration can safely reference canonical
 * codes without worrying about an empty topics collection.
 *
 * <p>The migration is idempotent — running it on a clean database or after a
 * previous successful run simply finds 0 legacy documents and exits instantly.
 */
@Component
@Order(2)
public class TopicCodeMigrationRunner implements ApplicationRunner {

    private static final Logger log = LoggerFactory.getLogger(TopicCodeMigrationRunner.class);

    private final TopicCodeMigrationService migrationService;

    public TopicCodeMigrationRunner(TopicCodeMigrationService migrationService) {
        this.migrationService = migrationService;
    }

    @Override
    public void run(ApplicationArguments args) {
        log.info("TopicCodeMigrationRunner: executing startup migration.");
        migrationService.migrate();
    }
}
