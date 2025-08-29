-- Create audit_logs table for tracking all system operations (FR-013)
CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_type VARCHAR(50) NOT NULL,
    entity_id UUID NOT NULL,
    operation VARCHAR(20) NOT NULL CHECK (operation IN ('CREATE', 'READ', 'UPDATE', 'DELETE', 'LOGIN', 'LOGOUT')),
    user_id UUID NOT NULL,
    ip_address INET,
    user_agent TEXT,
    changes JSONB,
    old_values JSONB,
    new_values JSONB,
    reason TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'SUCCESS' CHECK (status IN ('SUCCESS', 'FAILED', 'UNAUTHORIZED')),
    error_msg TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for efficient querying
CREATE INDEX idx_audit_logs_entity_type ON audit_logs(entity_type);
CREATE INDEX idx_audit_logs_entity_id ON audit_logs(entity_id);
CREATE INDEX idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_operation ON audit_logs(operation);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at DESC);
CREATE INDEX idx_audit_logs_status ON audit_logs(status);

-- Composite index for common queries
CREATE INDEX idx_audit_logs_entity_operation ON audit_logs(entity_type, entity_id, operation);
CREATE INDEX idx_audit_logs_user_operation ON audit_logs(user_id, operation, created_at DESC);
