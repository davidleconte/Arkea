-- Schéma HCD pour Kafka Streaming
-- Keyspace et table pour recevoir les événements Kafka

CREATE KEYSPACE IF NOT EXISTS poc_hbase_migration
WITH REPLICATION = {'class': 'SimpleStrategy', 'replication_factor': 1};

USE poc_hbase_migration;

CREATE TABLE IF NOT EXISTS kafka_events (
    id UUID PRIMARY KEY,
    timestamp timestamp,
    topic text,
    partition int,
    offset bigint,
    key text,
    value text,
    processed_at timestamp
);




