# SQL Code Review Standards

This document provides code review standards for SQL — covering schema design, migration scripts, stored procedures, and query patterns. Primarily targeted at SQL Server / Azure SQL.

## Table of Contents

- [Schema Design](#schema-design)
- [Naming Conventions](#naming-conventions)
- [Migration Scripts](#migration-scripts)
- [Query Writing](#query-writing)
- [Indexes](#indexes)
- [Stored Procedures and Functions](#stored-procedures-and-functions)
- [Transactions and Concurrency](#transactions-and-concurrency)
- [Performance](#performance)
- [Security](#security)
- [Azure SQL Specific](#azure-sql-specific)
- [Documentation](#documentation)

---

## Schema Design

### Tables

- [ ] Tables have a clearly defined primary key
- [ ] Primary keys use `INT IDENTITY` or `BIGINT IDENTITY` for simple entities; `UNIQUEIDENTIFIER` (GUID) where distributed generation or external references are needed
- [ ] GUIDs use `NEWSEQUENTIALID()` as default (not `NEWID()`) to avoid index fragmentation
- [ ] Column nullability is deliberate — no nullable columns that should always have a value
- [ ] Column data types are appropriately sized (no `NVARCHAR(MAX)` for short strings; no `INT` for values that will exceed 2.1B)
- [ ] `NVARCHAR` is used over `VARCHAR` for string data unless the column is provably ASCII-only
- [ ] Columns storing currency use `DECIMAL(19,4)` — never `FLOAT` or `REAL`
- [ ] `DATETIME2` is used over legacy `DATETIME` for new columns
- [ ] `BIT` is used for boolean flags, not `CHAR(1)` or `TINYINT`

### Relationships

- [ ] Foreign key constraints are defined for all relationships (not just implied by naming)
- [ ] Cascade behaviour (`ON DELETE`, `ON UPDATE`) is explicit and intentional
- [ ] Cascade deletes are used sparingly and documented — prefer soft delete or explicit application-level deletion
- [ ] Self-referencing foreign keys (hierarchical data) are handled intentionally

### Constraints

- [ ] `NOT NULL` is applied to all columns that should never be null
- [ ] `DEFAULT` values are defined where a sensible default exists
- [ ] `CHECK` constraints enforce domain rules at the database level
- [ ] `UNIQUE` constraints are applied where business uniqueness is required (not just relying on application logic)
- [ ] Constraint names follow a consistent naming convention (e.g., `PK_`, `FK_`, `UQ_`, `CK_`, `IX_`, `DF_`)

### Soft Delete

- [ ] Soft delete pattern is consistent across all tables that use it (`IsDeleted BIT NOT NULL DEFAULT 0` or `DeletedAt DATETIME2 NULL`)
- [ ] Indexes on soft-deleted tables include the soft delete column as a filter where appropriate
- [ ] Application queries consistently filter out soft-deleted rows — no missed WHERE clauses

---

## Naming Conventions

- [ ] Table names are `PascalCase` and singular (e.g., `Order`, `OrderItem`)
- [ ] Column names are `PascalCase`
- [ ] Foreign key columns follow the pattern `{ReferencedTable}Id` (e.g., `CustomerId`)
- [ ] Boolean columns use `Is`, `Has`, or `Can` prefix (e.g., `IsActive`, `HasBeenProcessed`)
- [ ] Audit columns are consistent across all tables (`CreatedAt`, `CreatedBy`, `ModifiedAt`, `ModifiedBy`)
- [ ] Stored procedure names use `usp_` prefix or a consistent verb-noun format (e.g., `GetOrderById`, `CreateOrder`)
- [ ] Function names use `udf_` prefix or verb-noun format
- [ ] View names use `v_` prefix or are clearly distinguished from tables
- [ ] Index names follow `IX_{Table}_{Columns}` pattern; unique indexes use `UQ_{Table}_{Columns}`
- [ ] No reserved words used as object names (even with bracket escaping)

---

## Migration Scripts

### Idempotency

- [ ] Scripts are idempotent — safe to run more than once without error
- [ ] `IF NOT EXISTS` / `IF EXISTS` guards are used for DDL changes
- [ ] Object creation uses `CREATE OR ALTER` where supported (SQL Server 2016+)
- [ ] Data migration steps handle already-migrated rows gracefully
- [ ] Rollback or compensating scripts exist for destructive changes

### Script Structure

- [ ] Each migration is a single, atomic change where possible
- [ ] Large data migrations are batched (see [Batching](#performance)) — no single-transaction full-table updates
- [ ] Schema changes and data migrations are separated into distinct scripts where order matters
- [ ] Scripts include a header comment: purpose, author, date, linked work item
- [ ] `SET NOCOUNT ON` is set at the top of scripts to suppress row count noise

### Destructive Changes

- [ ] Column/table drops are preceded by a deprecation period with the column marked (comment or naming convention)
- [ ] Rename operations use a two-step approach (add new → migrate data → drop old) to avoid breaking dependent code mid-deployment
- [ ] Backfill scripts for new `NOT NULL` columns without defaults are included
- [ ] New `NOT NULL` columns are added with a temporary `DEFAULT` constraint which is dropped after backfill

### Compatibility

- [ ] Scripts are tested against the target SQL Server / Azure SQL compatibility level
- [ ] EF Core migrations (if used) do not conflict with manual migration scripts
- [ ] Scripts account for multi-tenant deployments where multiple databases must be updated

---

## Query Writing

### Correctness

- [ ] `WHERE` clauses are correct — no accidental full-table scans or Cartesian products
- [ ] `JOIN` type is correct (`INNER`, `LEFT`, `RIGHT`) — not defaulting to `INNER` when `LEFT` is needed
- [ ] `NULL` comparisons use `IS NULL` / `IS NOT NULL`, never `= NULL`
- [ ] `DISTINCT` is not used to mask an incorrect join
- [ ] `GROUP BY` includes all non-aggregated columns
- [ ] `HAVING` is used for aggregate filters, not `WHERE`

### Style

- [ ] SQL keywords are `UPPER CASE`
- [ ] Object names are consistently qualified with schema (e.g., `dbo.Order`, not just `Order`)
- [ ] Table aliases are meaningful (not single letters like `a`, `b`, `c` for complex queries)
- [ ] `SELECT *` is never used in production code — columns are explicitly listed
- [ ] Commas in column lists are leading (`,ColumnName`) or trailing — consistent per team convention
- [ ] CTEs (`WITH`) are used to improve readability of complex queries over deeply nested subqueries

### Parameterisation

- [ ] All queries accepting external input use parameterised queries — no string concatenation
- [ ] Dynamic SQL (where unavoidable) uses `sp_executesql` with parameter substitution
- [ ] Dynamic SQL is reviewed for SQL injection risk — object names are validated via whitelist not concatenated directly

---

## Indexes

### Coverage

- [ ] Primary key columns have a clustered index (default for PK unless justified otherwise)
- [ ] Foreign key columns have a non-clustered index to support join and delete performance
- [ ] Columns frequently used in `WHERE`, `ORDER BY`, and `JOIN` conditions are candidates for indexing
- [ ] Covering indexes include `INCLUDE` columns to avoid key lookups for common query patterns
- [ ] Composite indexes have the most selective columns first (unless specific query patterns dictate otherwise)

### Maintenance

- [ ] New indexes are assessed for impact on write performance (insert/update/delete overhead)
- [ ] Duplicate or redundant indexes are removed (same leading columns as existing index)
- [ ] Index fragmentation strategy exists (rebuild vs reorganise thresholds)
- [ ] Filtered indexes are used for sparse data (e.g., `WHERE IsDeleted = 0`)
- [ ] Index names follow the agreed naming convention

---

## Stored Procedures and Functions

### Stored Procedures

- [ ] `SET NOCOUNT ON` at the top
- [ ] `SET XACT_ABORT ON` in procedures that contain transactions
- [ ] Parameters are typed and sized appropriately
- [ ] `WITH RECOMPILE` is used only where parameter sniffing is a documented issue
- [ ] Output parameters are used sparingly — prefer result sets or return values
- [ ] Error handling uses `TRY...CATCH` with meaningful error re-raise
- [ ] Procedures do not mix DDL and DML unless explicitly required
- [ ] Procedures do not use `SELECT *`

### Functions

- [ ] Scalar functions are avoided in `WHERE` clauses on large tables (non-SARGable; kills parallelism in older compatibility levels)
- [ ] Table-valued functions (TVFs) are preferred over scalar functions for set-based logic
- [ ] Inline TVFs are preferred over multi-statement TVFs for performance
- [ ] Functions do not have side effects (no DML inside functions)
- [ ] `RETURNS NULL ON NULL INPUT` is specified where appropriate

---

## Transactions and Concurrency

### Transactions

- [ ] Transactions are kept as short as possible
- [ ] No user interaction or external calls occur inside a transaction
- [ ] `BEGIN TRANSACTION` / `COMMIT` / `ROLLBACK` are always paired
- [ ] `SET XACT_ABORT ON` is used in transactional procedures to auto-rollback on error
- [ ] Nested transactions are avoided — use save points if partial rollback is needed
- [ ] Deadlock potential is assessed for procedures that update multiple tables

### Isolation Levels

- [ ] Default isolation level is appropriate for the workload (`READ COMMITTED SNAPSHOT` recommended for Azure SQL)
- [ ] `NOLOCK` / `READ UNCOMMITTED` hints are not used as a general performance fix — document if used
- [ ] `UPDLOCK` / `HOLDLOCK` hints are used intentionally to prevent race conditions
- [ ] Optimistic concurrency (`ROWVERSION` / `TIMESTAMP` column) is implemented for entities with concurrent edit risk

### Locking

- [ ] Query hints (`WITH (NOLOCK)`, `WITH (ROWLOCK)`) are justified and commented
- [ ] Lock escalation implications are considered for large batch operations
- [ ] Indexes support the lock granularity needed (row vs page vs table)

---

## Performance

### Query Efficiency

- [ ] Queries are SARGable — functions on indexed columns in `WHERE` clauses are avoided
- [ ] Implicit type conversions are avoided (parameter types match column types exactly)
- [ ] `OR` conditions are reviewed — consider rewriting as `UNION ALL` if causing poor plan selection
- [ ] `NOT IN` with subqueries is replaced with `NOT EXISTS` or `LEFT JOIN ... WHERE IS NULL`
- [ ] `COUNT(*)` is used over `COUNT(1)` or `COUNT(column)` unless null handling matters

### Batching

- [ ] Large data modifications are batched in loops (e.g., update/delete 1000–10,000 rows per batch with `WAITFOR DELAY`)
- [ ] Batch size is configurable, not hardcoded
- [ ] Batched operations include progress logging for long-running migrations
- [ ] Batching prevents log file growth and long-held locks

### Query Plans

- [ ] Execution plans are reviewed for expensive operators (Hash Match, Sort, Key Lookup, RID Lookup, Parallelism) on critical queries
- [ ] Statistics are up to date before reviewing query plan issues
- [ ] Parameter sniffing issues are identified and addressed (local variables, `OPTIMIZE FOR`, or `RECOMPILE`)

---

## Security

### Access Control

- [ ] Application connects using a least-privilege login (not `sa` or `db_owner`)
- [ ] Application role has only `EXECUTE` on stored procedures, not direct table `SELECT`/`INSERT`/`UPDATE`/`DELETE` where possible
- [ ] Row-level security is implemented where multi-tenant data isolation is required
- [ ] Sensitive columns (PII, payment data) have column-level permissions applied

### Data Protection

- [ ] Sensitive data at rest uses Transparent Data Encryption (TDE) — confirm it is enabled
- [ ] Sensitive columns use Always Encrypted or Dynamic Data Masking where appropriate
- [ ] Backup encryption is enabled
- [ ] Connection strings use integrated authentication / managed identity, not SQL logins with passwords where possible

### Auditing

- [ ] Auditing is enabled at the server or database level for sensitive operations
- [ ] DDL changes are tracked in a change log table or via SQL Audit
- [ ] Access to sensitive data is audited

---

## Azure SQL Specific

### Elastic Pools

- [ ] Databases assigned to elastic pools are sized considering peak concurrent load, not just average load
- [ ] Per-database DTU/vCore min/max settings prevent resource monopolisation
- [ ] Noisy neighbour patterns are identified via `sys.dm_elastic_pool_resource_stats`
- [ ] Databases sharing a pool are grouped by workload profile (EPOS transactional separate from reporting)

### Compatibility Level

- [ ] Database compatibility level is appropriate for the features used
- [ ] Cardinality estimator behaviour (CE 70 vs CE 120+) is considered for migrated databases
- [ ] `COMPATIBILITY_LEVEL` is not left at SQL 2008 (80/100) unless there is a specific regression reason

### Monitoring

- [ ] Query Store is enabled with appropriate capture mode (`AUTO` recommended)
- [ ] Query Store max size and cleanup policy are configured
- [ ] `sys.dm_exec_query_stats` and Query Store are used for performance baselining post-migration
- [ ] Azure SQL Intelligent Insights and Advisor recommendations are reviewed

### Maintenance

- [ ] Index rebuild/reorganise jobs are configured (Elastic Pool complicates on-premises approaches — use Ola Hallengren or Azure Automation)
- [ ] Statistics update jobs are configured
- [ ] `DBCC CHECKDB` equivalent is scheduled or confirmed to be covered by Azure SQL's built-in checks

---

## Documentation

### Inline

- [ ] Complex queries have a comment explaining the business reason, not just what the SQL does
- [ ] Non-obvious index hints have a comment explaining the reason
- [ ] Suppressed or worked-around SQL Server issues are documented with a KB/Stack Overflow reference
- [ ] Migration scripts include: purpose, date, author, linked work item

### Schema Documentation

- [ ] Extended properties (`sys.extended_properties`) are used for table/column descriptions on significant objects
- [ ] ERD or schema diagram is updated for significant structural changes
- [ ] Deprecated tables/columns are marked (extended property or naming convention) before removal

---

## Review Checklist Summary

Before approving a PR, ensure:

1. **Idempotency**: Migration scripts are safe to re-run
2. **Correctness**: JOINs, NULLs, and WHERE clauses are logically correct
3. **Parameterisation**: No dynamic SQL string concatenation from user input
4. **Indexes**: Foreign keys indexed; covering indexes for key query patterns
5. **Performance**: No SARGability issues; large modifications are batched
6. **Transactions**: Short, `XACT_ABORT ON`, no external calls inside
7. **Security**: Least-privilege access; no hardcoded credentials; TDE confirmed
8. **Azure SQL**: Elastic pool sizing considered; Query Store enabled; compatibility level correct
9. **Naming**: Consistent convention throughout; no reserved words
10. **Documentation**: Complex logic commented; migration header present

---

## Customisation Notes

- Add your standard database role names and permission model
- Reference your migration tooling (Flyway, DbUp, EF Core Migrations)
- Add your approved batch size for large data operations
- Reference your index maintenance job setup (Ola Hallengren scripts, etc.)
- Add your elastic pool naming convention and sizing tier guidance