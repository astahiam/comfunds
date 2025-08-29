DROP TRIGGER IF EXISTS update_investments_updated_at ON investments;
DROP INDEX IF EXISTS idx_investments_created_at;
DROP INDEX IF EXISTS idx_investments_transaction_ref;
DROP INDEX IF EXISTS idx_investments_investment_date;
DROP INDEX IF EXISTS idx_investments_status;
DROP INDEX IF EXISTS idx_investments_investor_id;
DROP INDEX IF EXISTS idx_investments_project_id;
DROP TABLE IF EXISTS investments;
DROP SEQUENCE IF EXISTS global_transaction_seq;
