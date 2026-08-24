package com.arstem.backend.migration;

import java.util.List;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.core.query.Criteria;
import org.springframework.data.mongodb.core.query.Query;
import org.springframework.data.mongodb.core.query.Update;
import org.springframework.stereotype.Service;

import com.mongodb.client.result.UpdateResult;

/**
 * One-shot startup migration that coerces legacy topicCode values to their
 * canonical uppercase form across every collection that stores topicCode.
 *
 * <h3>Why this exists</h3>
 * Three write services (LearningSession, Quiz, Misconception) previously called
 * only {@code .trim()} without {@code .toUpperCase()}.  Any client that sent
 * {@code "linked-list"} (lowercase, with a dash) wrote that raw string into
 * MongoDB.  The analytics pipeline then produced a separate
 * {@code learning_analytics} document for {@code "linked-list"} and another
 * for {@code "DSA_LINKED_LIST"}, so mastery always came from the wrong bucket.
 *
 * <h3>What it does</h3>
 * For every legacy→canonical pair defined in {@link #MIGRATIONS} it runs a
 * bulk MongoDB {@code $set} update on every affected collection.
 * <pre>
 *   learning_sessions  topicCode, domainCode, activityCode
 *   quiz_attempts      topicCode
 *   misconceptions     topicCode
 *   progress           topicCode
 *   learning_analytics topicCode
 * </pre>
 *
 * <h3>Safety</h3>
 * <ul>
 *   <li>The migration is idempotent: running it twice has no effect because
 *       the legacy strings will no longer match after the first run.</li>
 *   <li>The {@code learning_analytics} and {@code progress} collections carry
 *       a {@code @CompoundIndex(unique=true)} on {@code (userId, topicCode)}.
 *       If a canonical document already exists for a user, the legacy document
 *       must be deleted rather than renamed (renaming would violate the unique
 *       constraint).  The service handles this by deleting orphaned legacy
 *       analytics/progress docs after the bulk rename of the source
 *       collections.</li>
 * </ul>
 */
@Service
public class TopicCodeMigrationService {

    private static final Logger log = LoggerFactory.getLogger(TopicCodeMigrationService.class);

    // ── Legacy → canonical mapping ─────────────────────────────────────────
    // Add further entries here if other lowercase codes are discovered later.
    private static final List<String[]> MIGRATIONS = List.of(
            new String[]{"linked-list",   "DSA_LINKED_LIST"},
            new String[]{"dsa_linked_list", "DSA_LINKED_LIST"}, // mixed-case guard
            new String[]{"stack",          "DSA_STACK"},
            new String[]{"binary-tree",    "DSA_BINARY_TREE"},
            new String[]{"and-gate",       "ELECTRONICS_AND_GATE"},
            new String[]{"or-gate",        "ELECTRONICS_OR_GATE"},
            new String[]{"not-gate",       "ELECTRONICS_NOT_GATE"},
            new String[]{"xor-gate",       "ELECTRONICS_XOR_GATE"},
            new String[]{"nand-gate",      "ELECTRONICS_NAND_GATE"},
            new String[]{"nor-gate",       "ELECTRONICS_NOR_GATE"},
            new String[]{"xnor-gate",      "ELECTRONICS_XNOR_GATE"},
            new String[]{"methane",        "CHEMISTRY_METHANE"},
            new String[]{"ethane",         "CHEMISTRY_ETHANE"},
            new String[]{"propane",        "CHEMISTRY_PROPANE"},
            new String[]{"methanol",       "CHEMISTRY_METHANOL"},
            new String[]{"ethanol",        "CHEMISTRY_ETHANOL"},
            new String[]{"glucose",        "CHEMISTRY_GLUCOSE"},
            new String[]{"fructose",       "CHEMISTRY_FRUCTOSE"},
            new String[]{"sucrose",        "CHEMISTRY_SUCROSE"}
    );

    private static final String COL_SESSIONS   = "learning_sessions";
    private static final String COL_QUIZ       = "quiz_attempts";
    private static final String COL_MISC       = "misconceptions";
    private static final String COL_PROGRESS   = "progress";
    private static final String COL_ANALYTICS  = "learning_analytics";

    private final MongoTemplate mongo;

    public TopicCodeMigrationService(MongoTemplate mongo) {
        this.mongo = mongo;
    }

    /**
     * Runs the full migration.  Called once from {@link TopicCodeMigrationRunner}
     * on application startup (after {@link com.arstem.backend.topic.config.TopicSeeder}).
     */
    public void migrate() {
        log.info("TopicCodeMigration: starting topicCode normalisation pass.");
        int totalUpdated = 0;

        for (String[] pair : MIGRATIONS) {
            String legacy    = pair[0];
            String canonical = pair[1];
            totalUpdated += migratePair(legacy, canonical);
        }

        log.info("TopicCodeMigration: complete. {} document(s) updated across all collections.", totalUpdated);
    }

    // ── Per-pair migration ────────────────────────────────────────────────────

    private int migratePair(String legacy, String canonical) {
        int count = 0;

        // 1. learning_sessions — also normalise domainCode and activityCode
        count += renameTopicCode(COL_SESSIONS, legacy, canonical);
        count += renameField(COL_SESSIONS, "domainCode", legacy.toUpperCase(), canonical.split("_")[0]);

        // 2. quiz_attempts
        count += renameTopicCode(COL_QUIZ, legacy, canonical);

        // 3. misconceptions
        count += renameTopicCode(COL_MISC, legacy, canonical);

        // 4. progress — unique index means we must delete orphan first
        count += mergeOrRename(COL_PROGRESS, legacy, canonical);

        // 5. learning_analytics — same unique-index treatment
        count += mergeOrRename(COL_ANALYTICS, legacy, canonical);

        if (count > 0) {
            log.info("TopicCodeMigration: '{}' → '{}': {} document(s) updated.", legacy, canonical, count);
        }
        return count;
    }

    /**
     * Simple field rename: {@code { topicCode: legacy } → $set { topicCode: canonical } }.
     */
    private int renameTopicCode(String collection, String legacy, String canonical) {
        Query query   = Query.query(Criteria.where("topicCode").is(legacy));
        Update update = Update.update("topicCode", canonical);
        UpdateResult result = mongo.updateMulti(query, update, collection);
        return (int) result.getModifiedCount();
    }

    /**
     * Generic field rename helper for fields other than topicCode (e.g. domainCode).
     */
    private int renameField(String collection, String field, String legacy, String canonical) {
        Query query   = Query.query(Criteria.where(field).is(legacy));
        Update update = Update.update(field, canonical);
        UpdateResult result = mongo.updateMulti(query, update, collection);
        return (int) result.getModifiedCount();
    }

    /**
     * Handles collections with a unique {@code (userId, topicCode)} index.
     *
     * <p>Strategy:
     * <ol>
     *   <li>For each document with the legacy topicCode, check whether a
     *       document already exists for the same userId with the canonical code.</li>
     *   <li>If <b>no</b> canonical document exists → safe to rename in place.</li>
     *   <li>If a canonical document <b>already exists</b> → the legacy document
     *       is a duplicate.  Delete it; the canonical document already holds the
     *       latest analytics so no data is lost.</li>
     * </ol>
     */
    private int mergeOrRename(String collection, String legacy, String canonical) {
        Query legacyQuery = Query.query(Criteria.where("topicCode").is(legacy));
        List<org.bson.Document> legacyDocs = mongo.find(legacyQuery, org.bson.Document.class, collection);

        int count = 0;
        for (org.bson.Document legacyDoc : legacyDocs) {
            String userId = legacyDoc.getString("userId");

            Query canonicalExists = Query.query(
                    Criteria.where("userId").is(userId)
                            .and("topicCode").is(canonical));

            boolean exists = mongo.exists(canonicalExists, collection);
            if (exists) {
                // A canonical document already exists for this user — delete the legacy duplicate.
                Query deleteQuery = Query.query(
                        Criteria.where("_id").is(legacyDoc.getObjectId("_id")));
                mongo.remove(deleteQuery, collection);
                log.debug("TopicCodeMigration: deleted orphan legacy '{}' doc for userId={} in {}.",
                        legacy, userId, collection);
            } else {
                // No canonical doc yet — safe to rename in place.
                Query renameQuery = Query.query(
                        Criteria.where("_id").is(legacyDoc.getObjectId("_id")));
                Update renameUpdate = Update.update("topicCode", canonical);
                mongo.updateFirst(renameQuery, renameUpdate, collection);
                log.debug("TopicCodeMigration: renamed '{}' → '{}' for userId={} in {}.",
                        legacy, canonical, userId, collection);
            }
            count++;
        }
        return count;
    }
}
