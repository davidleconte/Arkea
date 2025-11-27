CREATE TABLE IF NOT EXISTS domirama_poc.operations_by_account (
    code_si text,
    contrat text,
    op_date timestamp,
    op_seq int,
    cat_auto text,
    cat_user text,
    cobol_data_base64 text,
    copy_type text,
    date_valeur timestamp,
    devise text,
    libelle text,
    montant decimal,
    op_id text,
    sens_operation text,
    type_operation text,
    meta_flags map<text, text>,
    PRIMARY KEY ((code_si, contrat), op_date, op_seq)
) WITH ID = 9f9d2330-ca08-11f0-be27-359fac312e46
    AND CLUSTERING ORDER BY (op_date DESC, op_seq ASC)
    AND additional_write_policy = '99p'
    AND bloom_filter_fp_chance = 0.01
    AND caching = {'keys': 'ALL', 'rows_per_partition': 'NONE'}
    AND cdc = false
    AND comment = ''
    AND compaction = {'class': 'org.apache.cassandra.db.compaction.UnifiedCompactionStrategy'}
    AND compression = {'chunk_length_in_kb': '16', 'class': 'org.apache.cassandra.io.compress.LZ4Compressor'}
    AND memtable = {}
    AND crc_check_chance = 1.0
    AND default_time_to_live = 315360000
    AND extensions = {}
    AND gc_grace_seconds = 864000
    AND max_index_interval = 2048
    AND memtable_flush_period_in_ms = 0
    AND min_index_interval = 128
    AND read_repair = 'BLOCKING'
    AND speculative_retry = '99p';
CREATE CUSTOM INDEX IF NOT EXISTS idx_cat_auto ON domirama_poc.operations_by_account (cat_auto) USING 'StorageAttachedIndex';
CREATE CUSTOM INDEX IF NOT EXISTS idx_montant ON domirama_poc.operations_by_account (montant) USING 'StorageAttachedIndex';
CREATE CUSTOM INDEX IF NOT EXISTS idx_type_operation ON domirama_poc.operations_by_account (type_operation) USING 'StorageAttachedIndex';
