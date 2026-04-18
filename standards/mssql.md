# SQL Server Standards — Schema Design, Queries & Azure SQL

Every database change must be idempotent, parameterised, and reviewed for performance impact before merge. Schema design must enforce correctness at the database level — never rely solely on application logic for constraints, referential integrity, or data type safety.

---

## 1 · Schema Design

### 1.1 · Tables

- Every table must have a clearly defined primary key.
- Primary keys must use `INT IDENTITY` or `BIGINT IDENTITY` for simple entities; `UNIQUEIDENTIFIER` (GUID) only where distributed generation or external references are needed.
- GUIDs must use `NEWSEQUENTIALID()` as default — never `NEWID()` — to avoid index fragmentation.
- Column nullability must be deliberate — never leave columns nullable that should always have a value.
- Column data types must be appropriately sized — never use `NVARCHAR(MAX)` for short strings; never use `INT` for values that will exceed 2.1B.
- `NVARCHAR` must always be used over `VARCHAR` for string data unless the column is provably ASCII-only.
- Columns storing currency must always use `DECIMAL(19,4)` — never `FLOAT` or `REAL`.
- `DATETIME2` must always be used over legacy `DATETIME` for new columns.
- `BIT` must always be used for boolean flags — never `CHAR(1)` or `TINYINT`.

### 1.2 · Relationships

- Foreign key constraints must be defined for all relationships — never implied by naming alone.
- Cascade behaviour (`ON DELETE`, `ON UPDATE`) must be explicit and intentional.
- Cascade deletes must be used sparingly and documented — prefer soft delete or explicit application-level deletion.
- Self-referencing foreign keys (hierarchical data) must be handled intentionally with documented traversal strategy.

### 1.3 · Constraints

- `NOT NULL` must be applied to all columns that should never be null.
- `DEFAULT` values must be defined where a sensible default exists.
- `CHECK` constraints must enforce domain rules at the database level.
- `UNIQUE` constraints must be applied where business uniqueness is required — never rely solely on application logic.
- Constraint names must follow a consistent naming convention (e.g., `PK_`, `FK_`, `UQ_`, `CK_`, `IX_`, `DF_`).

### 1.4 · Soft Delete

- Soft delete pattern must be consistent across all tables that use it (`IsDeleted BIT NOT NULL DEFAULT 0` or `DeletedAt DATETIME2 NULL`).
- Indexes on soft-deleted tables must include the soft delete column as a filter where appropriate.
- Application queries must consistently filter out soft-deleted rows — never miss a `WHERE` clause.

---

## 2 · Naming Conventions

- Table names must be `PascalCase` and singular (e.g., `Order`, `OrderItem`).
- Column names must be `PascalCase`.
- Foreign key columns must follow the pattern `{ReferencedTable}Id` (e.g., `CustomerId`).
- Boolean columns must use `Is`, `Has`, or `Can` prefix (e.g., `IsActive`, `HasBeenProcessed`).
- Audit columns must be consistent across all tables (`CreatedAt`, `CreatedBy`, `ModifiedAt`, `ModifiedBy`).
- Stored procedure names must use `usp_` prefix or a consistent verb-noun format (e.g., `GetOrderById`, `CreateOrder`).
- Function names must use `udf_` prefix or verb-noun format.
- View names must use `v_` prefix or be clearly distinguished from tables.
- Index names must follow `IX_{Table}_{Columns}` pattern; unique indexes must use `UQ_{Table}_{Columns}`.
- Reserved words must never be used as object names — even with bracket escaping.

---

## 3 · Migration Scripts

### 3.1 · Idempotency

- Scripts must always be idempotent — safe to run more than once without error.
- `IF NOT EXISTS` / `IF EXISTS` guards must be used for all DDL changes.
- Object creation must use `CREATE OR ALTER` where supported (SQL Server 2016+).
- Data migration steps must handle already-migrated rows gracefully.
- Rollback or compensating scripts must exist for destructive changes.

### 3.2 · Script Structure

- Each migration must be a single, atomic change where possible.
- Large data migrations must always be batched — never use single-transaction full-table updates.
- Schema changes and data migrations must be separated into distinct scripts where order matters.
- Scripts must include a header comment: purpose, author, date, linked work item.
- `SET NOCOUNT ON` must always be set at the top of scripts to suppress row count noise.

### 3.3 · Destructive Changes

- Column/table drops must always be preceded by a deprecation period with the column marked (comment or naming convention).
- Rename operations must use a two-step approach (add new, migrate data, drop old) to avoid breaking dependent code mid-deployment.
- Backfill scripts for new `NOT NULL` columns without defaults must always be included.
- New `NOT NULL` columns must be added with a temporary `DEFAULT` constraint which is dropped after backfill.

### 3.4 · Compatibility

- Scripts must be tested against the target SQL Server / Azure SQL compatibility level.
- EF Core migrations (if used) must never conflict with manual migration scripts.
- Scripts must account for multi-tenant deployments where multiple databases must be updated.

---

## 4 · Query Writing

### 4.1 · Correctness

- `WHERE` clauses must be correct — never allow accidental full-table scans or Cartesian products.
- `JOIN` type must be correct (`INNER`, `LEFT`, `RIGHT`) — never default to `INNER` when `LEFT` is needed.
- `NULL` comparisons must always use `IS NULL` / `IS NOT NULL` — never `= NULL`.
- `DISTINCT` must never be used to mask an incorrect join.
- `GROUP BY` must always include all non-aggregated columns.
- `HAVING` must always be used for aggregate filters — never `WHERE`.

### 4.2 · Style

- SQL keywords must always be `UPPER CASE`.
- Object names must always be qualified with schema (e.g., `dbo.Order`, not just `Order`).
- Table aliases must be meaningful — never use single letters like `a`, `b`, `c` for complex queries.
- `SELECT *` must never be used in production code — columns must always be explicitly listed.
- Commas in column lists must be leading (`,ColumnName`) or trailing — consistent per team convention.
- CTEs (`WITH`) must be used to improve readability of complex queries over deeply nested subqueries.

### 4.3 · Parameterisation

- All queries accepting external input must use parameterised queries — never string concatenation.
- Dynamic SQL (where unavoidable) must use `sp_executesql` with parameter substitution.
- Dynamic SQL must always be reviewed for SQL injection risk — object names must be validated via whitelist, never concatenated directly.

---

## 5 · Indexes

### 5.1 · Coverage

- Primary key columns must have a clustered index (default for PK unless justified otherwise).
- Foreign key columns must have a non-clustered index to support join and delete performance.
- Columns frequently used in `WHERE`, `ORDER BY`, and `JOIN` conditions must always be candidates for indexing.
- Covering indexes must include `INCLUDE` columns to avoid key lookups for common query patterns.
- Composite indexes must have the most selective columns first (unless specific query patterns dictate otherwise).

### 5.2 · Maintenance

- New indexes must always be assessed for impact on write performance (insert/update/delete overhead).
- Duplicate or redundant indexes must be removed (same leading columns as existing index).
- An index fragmentation strategy must exist (rebuild vs reorganise thresholds).
- Filtered indexes must be used for sparse data (e.g., `WHERE IsDeleted = 0`).
- Index names must always follow the agreed naming convention.

---

## 6 · Stored Procedures and Functions

### 6.1 · Stored Procedures

- `SET NOCOUNT ON` must always appear at the top of every stored procedure.
- `SET XACT_ABORT ON` must always be set in procedures that contain transactions.
- Parameters must be typed and sized appropriately.
- `WITH RECOMPILE` must only be used where parameter sniffing is a documented issue.
- Output parameters must be used sparingly — prefer result sets or return values.
- Error handling must use `TRY...CATCH` with meaningful error re-raise.
- Procedures must never mix DDL and DML unless explicitly required.
- Procedures must never use `SELECT *`.

### 6.2 · Functions

- Scalar functions must never be used in `WHERE` clauses on large tables (non-SARGable; kills parallelism in older compatibility levels).
- Table-valued functions (TVFs) must always be preferred over scalar functions for set-based logic.
- Inline TVFs must always be preferred over multi-statement TVFs for performance.
- Functions must never have side effects — never include DML inside functions.
- `RETURNS NULL ON NULL INPUT` must be specified where appropriate.

---

## 7 · Transactions and Concurrency

### 7.1 · Transactions

- Transactions must always be kept as short as possible.
- No user interaction or external calls must ever occur inside a transaction.
- `BEGIN TRANSACTION` / `COMMIT` / `ROLLBACK` must always be paired.
- `SET XACT_ABORT ON` must always be used in transactional procedures to auto-rollback on error.
- Nested transactions must be avoided — use save points if partial rollback is needed.
- Deadlock potential must always be assessed for procedures that update multiple tables.

### 7.2 · Isolation Levels

- Default isolation level must be appropriate for the workload (`READ COMMITTED SNAPSHOT` recommended for Azure SQL).
- `NOLOCK` / `READ UNCOMMITTED` hints must never be used as a general performance fix — always document if used.
- `UPDLOCK` / `HOLDLOCK` hints must be used intentionally to prevent race conditions.
- Optimistic concurrency (`ROWVERSION` / `TIMESTAMP` column) must be implemented for entities with concurrent edit risk.

### 7.3 · Locking

- Query hints (`WITH (NOLOCK)`, `WITH (ROWLOCK)`) must always be justified and commented.
- Lock escalation implications must always be considered for large batch operations.
- Indexes must support the lock granularity needed (row vs page vs table).

---

## 8 · Performance

### 8.1 · Query Efficiency

- Queries must always be SARGable — never use functions on indexed columns in `WHERE` clauses.
- Implicit type conversions must always be avoided — parameter types must match column types exactly.
- `OR` conditions must always be reviewed — consider rewriting as `UNION ALL` if causing poor plan selection.
- `NOT IN` with subqueries must be replaced with `NOT EXISTS` or `LEFT JOIN ... WHERE IS NULL`.
- `COUNT(*)` must be used over `COUNT(1)` or `COUNT(column)` unless null handling matters.

### 8.2 · Batching

- Large data modifications must always be batched in loops (e.g., update/delete 1,000-10,000 rows per batch with `WAITFOR DELAY`).
- Batch size must be configurable — never hardcoded.
- Batched operations must always include progress logging for long-running migrations.
- Batching must always prevent log file growth and long-held locks.

### 8.3 · Query Plans

- Execution plans must be reviewed for expensive operators (Hash Match, Sort, Key Lookup, RID Lookup, Parallelism) on critical queries.
- Statistics must always be up to date before reviewing query plan issues.
- Parameter sniffing issues must be identified and addressed (local variables, `OPTIMIZE FOR`, or `RECOMPILE`).

---

## 9 · Security

### 9.1 · Access Control

- Applications must connect using a least-privilege login — never `sa` or `db_owner`.
- Application role must have only `EXECUTE` on stored procedures — never direct table `SELECT`/`INSERT`/`UPDATE`/`DELETE` where possible.
- Row-level security must be implemented where multi-tenant data isolation is required.
- Sensitive columns (PII, payment data) must have column-level permissions applied.

### 9.2 · Data Protection

- Sensitive data at rest must use Transparent Data Encryption (TDE) — always confirm it is enabled.
- Sensitive columns must use Always Encrypted or Dynamic Data Masking where appropriate.
- Backup encryption must always be enabled.
- Connection strings must use integrated authentication / managed identity — never SQL logins with passwords where possible.

### 9.3 · Auditing

- Auditing must be enabled at the server or database level for sensitive operations.
- DDL changes must be tracked in a change log table or via SQL Audit.
- Access to sensitive data must always be audited.

---

## 10 · Azure SQL Specific

### 10.1 · Elastic Pools

- Databases assigned to elastic pools must be sized considering peak concurrent load, not just average load.
- Per-database DTU/vCore min/max settings must prevent resource monopolisation.
- Noisy neighbour patterns must be identified via `sys.dm_elastic_pool_resource_stats`.
- Databases sharing a pool must be grouped by workload profile (EPOS transactional separate from reporting).

### 10.2 · Compatibility Level

- Database compatibility level must be appropriate for the features used.
- Cardinality estimator behaviour (CE 70 vs CE 120+) must always be considered for migrated databases.
- `COMPATIBILITY_LEVEL` must never be left at SQL 2008 (80/100) unless there is a specific regression reason.

### 10.3 · Monitoring

- Query Store must be enabled with appropriate capture mode (`AUTO` recommended).
- Query Store max size and cleanup policy must always be configured.
- `sys.dm_exec_query_stats` and Query Store must be used for performance baselining post-migration.
- Azure SQL Intelligent Insights and Advisor recommendations must always be reviewed.

### 10.4 · Maintenance

- Index rebuild/reorganise jobs must be configured (Elastic Pool complicates on-premises approaches — use Ola Hallengren or Azure Automation).
- Statistics update jobs must always be configured.
- `DBCC CHECKDB` equivalent must be scheduled or confirmed to be covered by Azure SQL's built-in checks.

---

## 11 · Documentation

### 11.1 · Inline

- Complex queries must always have a comment explaining the business reason, not just what the SQL does.
- Non-obvious index hints must always have a comment explaining the reason.
- Suppressed or worked-around SQL Server issues must be documented with a KB/Stack Overflow reference.
- Migration scripts must always include: purpose, date, author, linked work item.

### 11.2 · Schema Documentation

- Extended properties (`sys.extended_properties`) must be used for table/column descriptions on significant objects.
- ERD or schema diagram must be updated for significant structural changes.
- Deprecated tables/columns must be marked (extended property or naming convention) before removal.

---

## Non-Negotiables

- Every query accepting external input must use parameterised queries — never string concatenation. No exceptions.
- Every migration script must be idempotent — safe to re-run without error or data corruption.
- `SELECT *` must never appear in production code — always list columns explicitly.
- Applications must never connect as `sa` or `db_owner` — always use least-privilege.
- Transactions must never contain user interaction or external calls.
- `SET XACT_ABORT ON` must always be present in procedures that contain transactions.
- `NOLOCK` must never be used as a general performance fix — it must always be justified and documented.
- Large data modifications must always be batched — never run a single-transaction full-table update.

---

## Decision Checklist

- [ ] Migration scripts are idempotent with `IF NOT EXISTS` / `IF EXISTS` guards
- [ ] `JOIN` types, `NULL` comparisons, and `WHERE` clauses are logically correct
- [ ] All external input is parameterised — no string concatenation in dynamic SQL
- [ ] Foreign keys have non-clustered indexes; covering indexes exist for key query patterns
- [ ] Queries are SARGable — no functions on indexed columns in `WHERE` clauses
- [ ] Large data modifications are batched with configurable batch sizes
- [ ] Transactions are short, use `XACT_ABORT ON`, and contain no external calls
- [ ] Access uses least-privilege; no hardcoded credentials; TDE is enabled
- [ ] Elastic pool sizing considers peak concurrent load; Query Store is enabled
- [ ] Compatibility level is appropriate for the features used
- [ ] Naming conventions are consistent throughout — no reserved words as object names
- [ ] Stored procedures include `SET NOCOUNT ON` and `TRY...CATCH` error handling
- [ ] Complex logic is commented with business context; migration headers are present
- [ ] Schema changes use the two-step rename approach to avoid mid-deployment breakage
- [ ] New `NOT NULL` columns include a temporary `DEFAULT` constraint with backfill script
