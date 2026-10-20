# PharmaTrace 360

A DBMS course project demonstrating pharmaceutical batch traceability, serialized QR verification, quality-control gates, suspicious-scan review, audit logging, and product recalls.

## Components

- **MySQL 8.0+** — schema, constraints, stored procedures, functions, views, and triggers in `db/`.
- **PHP 8.1+ with PDO MySQL** — public verification and staff portals in `web/`.
- **Python 3** — reproducible seed-data and medicine-data builders.
- **Documentation** — setup, data assumptions, schema, test cases, audit notes, and limitations in `docs/`.

## Setup

Start with [docs/SETUP.md](docs/SETUP.md). It covers MySQL users, local configuration, demo passwords, and running the PHP application.

**Important:** `db/00_reset_all.sql` is destructive: it drops and recreates the demo database. Do not run it against a database containing data you need to keep. For an existing installation, review the preconditions and use `db/09_upgrade_existing.sql` instead.

## Features

- Public verification for genuine, expired, recalled, not-approved, and suspicious codes.
- Manufacturer-scoped batch creation, material linkage, and QA recording.
- Database-enforced approval rules and QR generation.
- Material inventory and batch traceability.
- Regulatory recall workflow and post-recall scan reporting.
- Audit log and suspicious-code review status.

## Demo-data boundary

Supplier, factory, batch, QA, and scan data are simulated. Medicine data is derived from community datasets and hand-entered overrides documented under `docs/`. This is an academic demonstration, not a clinical decision system or a production-grade anti-counterfeiting service.

## Tests

See [docs/test_cases.md](docs/test_cases.md) and [db/08_feature_tests.sql](db/08_feature_tests.sql). Some SQL scripts contain negative tests that intentionally raise errors; execute them only against a disposable demo database. Test the project on the target MySQL/PHP installation before deployment.
