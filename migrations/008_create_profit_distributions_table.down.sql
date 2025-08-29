DROP TRIGGER IF EXISTS update_investment_returns_updated_at ON investment_returns;
DROP TRIGGER IF EXISTS update_profit_distributions_updated_at ON profit_distributions;

DROP INDEX IF EXISTS idx_investment_returns_created_at;
DROP INDEX IF EXISTS idx_investment_returns_transaction_ref;
DROP INDEX IF EXISTS idx_investment_returns_payment_date;
DROP INDEX IF EXISTS idx_investment_returns_status;
DROP INDEX IF EXISTS idx_investment_returns_distribution_id;
DROP INDEX IF EXISTS idx_investment_returns_investment_id;

DROP INDEX IF EXISTS idx_profit_distributions_created_at;
DROP INDEX IF EXISTS idx_profit_distributions_distribution_date;
DROP INDEX IF EXISTS idx_profit_distributions_status;
DROP INDEX IF EXISTS idx_profit_distributions_project_id;

DROP TABLE IF EXISTS investment_returns;
DROP TABLE IF EXISTS profit_distributions;
