-- Create idempotency table in comfunds00 database
CREATE TABLE IF NOT EXISTS idempotency_keys (
    id VARCHAR(255) PRIMARY KEY,
    user_id UUID NOT NULL,
    endpoint VARCHAR(255) NOT NULL,
    request_hash VARCHAR(64) NOT NULL,
    response_data JSONB,
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NOT NULL,
    sequence_number INTEGER NOT NULL,
    table_name VARCHAR(100) NOT NULL,
    random_suffix VARCHAR(5) NOT NULL
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_idempotency_user_endpoint ON idempotency_keys(user_id, endpoint);
CREATE INDEX IF NOT EXISTS idx_idempotency_expires_at ON idempotency_keys(expires_at);
CREATE INDEX IF NOT EXISTS idx_idempotency_sequence ON idempotency_keys(sequence_number);
CREATE INDEX IF NOT EXISTS idx_idempotency_table_name ON idempotency_keys(table_name);

-- Create sequence for idempotency keys
CREATE SEQUENCE IF NOT EXISTS idempotency_sequence START 1;

-- Add comment
COMMENT ON TABLE idempotency_keys IS 'Stores idempotency keys to prevent duplicate transactions';
COMMENT ON COLUMN idempotency_keys.id IS 'Format: yyyymmddhhmm + sequence_number + table_name + 5_random_chars';
COMMENT ON COLUMN idempotency_keys.sequence_number IS 'Auto-incrementing sequence number';
COMMENT ON COLUMN idempotency_keys.table_name IS 'Target table name for the transaction';
COMMENT ON COLUMN idempotency_keys.random_suffix IS '5 random alphanumeric characters';
