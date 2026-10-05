# CAI dbt POC: Development, Testing, and Production Promotion Process

## Purpose

This document defines the proposed application-development lifecycle (ADLC) and operating model for the CAI dbt proof of concept (POC). It evaluates how dbt Projects on Snowflake, GitHub, Snowflake Tasks, and controlled release practices can provide a repeatable path from development through production.

The POC focuses on the Email Campaign pipeline and is intended to establish a reusable pattern for version-controlled transformations, data-quality testing, documentation, lineage, review, deployment approval, and recovery.

## Scope and guiding principles

### In scope

- Existing Snowflake source and landing tables.
- One Snowflake SQL stored procedure that loads engagement and conversion data into a landing table.
- A Snowflake Task that triggers the stored procedure.
- dbt staging, intermediate, and fact models downstream of the landing data.
- GitHub-based version control, pull requests, validation, documentation, and promotion controls.
- Development in `CA_MKTG_OPS_NP` and protected production deployment in `CA_MKTG_OPS`.

### Environment principles

| Environment | Purpose | Warehouse |
|---|---|---|
| `CA_MKTG_OPS_NP` | Shared development, integration testing, validation, and available UAT | `CA_MKTG_OPS_NP` |
| `CA_MKTG_OPS` | Protected production environment | `CA_MKTG_OPS` |

- Developers validate changes in nonproduction before any production promotion.
- Production fact marts must not be manually changed by developers as a normal operating practice.
- Production deployments should run through a controlled dbt job or deployment identity and require explicit approval.
- Data classification, privacy controls, masking, and restrictions on cloned production data remain client validation dependencies.
- The final role, grant, and service-account model must be validated with CAI; the default design direction is least privilege.

## Decision: dbt promotion versus Snowflake-native promotion

The Email Campaign POC should evaluate dbt as the preferred approach for transformation logic that can be expressed as modular, declarative SQL models and that benefits from automated tests, documentation, lineage, code review, and repeatable deployments.

The POC should demonstrate how transformation logic currently embedded in a stored procedure can be decomposed into reusable and testable dbt models. This is not a commitment to migrate every procedure. Its purpose is to establish a repeatable delivery pattern and identify the workload types for which dbt provides a meaningful operational advantage.

### Migration decision criteria

Assess each candidate transformation using the following criteria:

- Suitability for declarative SQL modeling.
- Expected benefit from modularity, testing, documentation, and lineage.
- Complexity and operational dependencies of the current stored procedure.
- Dataset criticality and expected rate of change.
- Data-quality, documentation, or traceability gaps in the current process.
- Migration, validation, operational-support, and training effort.
- Whether dbt can be operated without disproportionate overhead for the team.

## Hybrid operating model

A hybrid approach is appropriate during initial adoption. dbt should own transformations that benefit from source-to-mart lineage, modular data modeling, data-quality testing, documentation, and frequent analytics-oriented changes. Existing Snowflake procedures and Tasks may remain for operationally complex processes that are not practical or cost-effective to migrate during this POC.

### Governance across both pathways

The implementation mechanism may differ, but release controls should be consistent:

- Store all code in GitHub, including dbt project files, stored-procedure SQL, Task DDL, tests, macros, and documentation.
- Develop changes in short-lived feature branches.
- Use pull requests and documented approval before merging shared code.
- Validate all changes in `CA_MKTG_OPS_NP` before production promotion.
- Capture automated-check results, reconciliation evidence, and UAT expectations consistently.
- Make production promotion controlled and traceable whether the implementation is dbt or Snowflake-native SQL/DDL.

### Migration backlog

Use the current inventory of procedures and objects as a prioritized migration backlog. Rank candidates using:

- Business demand or urgency.
- Upcoming enhancement requests.
- dbt-modeling suitability and implementation simplicity.
- Change frequency and anticipated maintenance.
- Existing data-quality, documentation, or lineage gaps.
- Pipeline criticality and downstream impact.
- Training and onboarding value.
- Estimated migration effort, validation effort, and operational risk.

A request to modify an existing procedure is a practical trigger to evaluate whether the asset should move higher in the dbt migration backlog.

## Orchestration and scheduling

### Target execution sequence

```text
Snowflake Task
  -> Snowflake SQL stored procedure
  -> Landing table
  -> dbt staging models
  -> dbt intermediate models
  -> dbt fact email-marketing campaign mart
  -> dbt tests and documentation artifacts
  -> Notifications or operational logging
```

### Division of responsibility

| Component | Primary owner | Responsibility |
|---|---|---|
| Snowflake Task | Snowflake | Schedules the landing-load procedure and native operational steps |
| Stored procedure | Snowflake SQL, version controlled in GitHub | Loads engagement and conversion data into the landing table |
| Landing/source definitions | dbt | Documents sources and exposes the inputs used by dbt models |
| Staging, intermediate, and fact layers | dbt | Performs downstream transformations using layered, testable SQL models |
| Tests and documentation | dbt | Applies data-quality tests, model/column documentation, and lineage artifacts |
| Storage, warehouses, schemas, and RBAC | Snowflake | Provides the underlying platform controls and compute |

### Snowflake Tasks versus dbt jobs

| Consideration | Snowflake Task | dbt job or external orchestrator |
|---|---|---|
| Primary responsibility | Schedule Snowflake SQL procedures and operational steps | Execute approved dbt commands, such as `dbt build`, against a defined environment |
| POC recommendation | Retain for the landing-table stored procedure | Consider for downstream transformations where dbt job capability is available |
| Version control | Keep `CREATE TASK` DDL with procedure SQL in GitHub | Keep dbt project code in GitHub; document job configuration and manage it as code where the selected platform supports it |
| Advantages | Maintains the existing native Snowflake scheduling pattern | Provides dbt-specific artifacts, test visibility, notifications, and environment-specific job controls |
| Trade-off | Less visibility into dbt-specific run artifacts | Requires additional platform configuration, credentials, access governance, and operational ownership |

For the POC, retain the Snowflake Task and stored procedure for landing ingestion, then run the downstream dbt workload separately. A later decision can determine whether dbt Cloud, GitHub Actions, or another orchestrator is the long-term mechanism for dbt execution.

## Git and release workflow

### Branch model

| Branch | Purpose | Protection expectation |
|---|---|---|
| `main` | Production-approved code | Protected; no direct commits |
| `develop` | Shared development and integration code validated in `CA_MKTG_OPS_NP` | Merge through pull request and required checks |
| `feature/<descriptive-name>` | Short-lived isolated development branch created from `develop` | Pull request into `develop` |
| `release/<descriptive-name>` or `uat/<descriptive-name>` | Optional isolation for work awaiting UAT or production approval | Use only when needed to avoid blocking unrelated releases |

### Promotion workflow

1. Create a `feature/<descriptive-name>` branch from `develop`.
2. Implement changes to dbt models, schema YAML, tests, macros, documentation, and/or version-controlled Snowflake SQL.
3. Validate the change in `CA_MKTG_OPS_NP`.
4. Open a GitHub pull request into `develop`.
5. Run automated checks appropriate to the POC.
6. Christianne Smith reviews and approves the pull request.
7. Merge approved code into `develop` after checks pass.
8. Conduct UAT when required and when stakeholder availability permits.
9. Promote the exact approved and validated code to protected `main` through a pull request from `develop` or an approved release/UAT branch.
10. Christianne Smith manually approves the production dbt job.
11. Run the controlled production job against `CA_MKTG_OPS` only after approval and release conditions are satisfied.

### UAT release-control risk

Technical validation does not replace business acceptance. Do not promote a UAT-required change to production merely because technical checks pass.

- Label and track changes awaiting UAT explicitly.
- Keep UAT-pending changes out of `main`.
- Use a release or UAT branch when pending work would otherwise block unrelated production-ready changes.
- Recognize the trade-off: shared `develop` is simpler for the POC, while release/UAT branches add isolation at the cost of branch-management overhead.

## Access and production controls

The target state is to remove routine production write access from developer personal roles and run production deployments through a controlled deployment identity, such as an approved dbt production job or GitHub Actions service account.

A role-based interim model may be acceptable during the POC if automation is not fully available. In that model, production permissions must be deliberately limited, separately assigned, and used only for approved deployment activity.

| Role type | Purpose | Typical permissions |
|---|---|---|
| Read-only role | Investigation, validation, documentation, and stakeholder support | `USAGE` on approved databases, schemas, and warehouses; `SELECT` on approved objects |
| Development write role | Build and validate changes in `CA_MKTG_OPS_NP` | Create, modify, and run approved development objects; write access only in nonproduction schemas |
| Deployment/DDL role | Execute approved production deployments | Only the `CREATE`, `ALTER`, `DROP`, `TRUNCATE`, `INSERT`, `MERGE`, and related privileges required by the approved deployment process |

The production deployment role must not be used for daily development, exploration, or routine manual production fixes. Document the minimum privileges based on the selected dbt materialization strategy rather than assigning broad ownership privileges.

## Data-quality controls

Tests are release gates, not merely informational checks. Apply a consistent baseline to dbt models and Snowflake-native processes.

### Minimum test baseline

- `not_null` tests for required fields, especially primary and business keys.
- Uniqueness tests at the dataset's declared grain.
- Relationship tests when a valid parent or lookup dataset exists.
- Accepted-value or domain tests for important categorical fields.
- Row-count or volume-anomaly checks when expected volume can be reasonably defined.
- Freshness or load-completeness checks when reliable timestamps or batch metadata are available.
- Reconciliation tests when replacing an existing procedure, report, or downstream dataset.

### Layer-specific expectations

| Layer | Primary test focus |
|---|---|
| Staging | Structural quality, required fields, business keys, uniqueness, and source conformance |
| Intermediate | Relationships, join integrity, deduplication, derived-logic checks, and targeted business rules |
| Fact mart | Declared grain, duplicate prevention, metric integrity, key relationships, and critical business rules |

### Example business assertions

- A conversion date cannot precede the related engagement date.
- A campaign identifier must map to a valid campaign record.
- A customer or account key must resolve to an approved dimensional record.
- Revenue, counts, or conversion metrics cannot be negative unless a documented adjustment scenario permits it.
- The fact table must contain no duplicate records at its declared grain.

For retained non-dbt procedures, implement equivalent version-controlled SQL assertions that return failing records or fail the pipeline when an agreed threshold is exceeded. For dbt models, use schema tests and custom data tests. Failed critical tests block promotion until they are corrected or formally approved as an exception.

## UAT acceptance gate

UAT is the business validation that confirms data is accurate, complete, and usable for its intended purpose. Automated checks confirm that the pipeline executed correctly; they do not independently validate the business outcome.

### UAT process

1. Agree on the required business validation scenarios and a target UAT date while the change is being scoped.
2. Complete nonproduction validation and required reconciliation.
3. Send a UAT notice identifying the change, environment, test period or dataset, expected results, and validation scenarios.
4. Provide a defined testing window, typically three to five business days unless another timeline is agreed.
5. Record a pass, fail, conditional approval, or pending result.
6. Remediate failures and repeat applicable validation.
7. Promote only after required UAT approval is recorded.
8. Mark unavailable or incomplete UAT as `awaiting UAT`; keep the change out of the production branch or release until validation resumes.

### UAT sign-off record

| Field | Description |
|---|---|
| Change identifier | Pull request, ticket, release, or version identifier |
| Dataset or pipeline | Object or objects being validated |
| Test scenario | Business scenario and expected result |
| Stakeholder | Person responsible for acceptance |
| Test date | Date testing occurred |
| Result | Pass, fail, conditional pass, or pending |
| Evidence | Query result, screenshot, report comparison, or validation note |
| Production decision | Approved, rejected, deferred, or awaiting UAT |

## Incident response and rollback

For a production defect, do not default immediately to a corrective rerun. First stop further incorrect processing, preserve evidence, assess impact, and then choose the safest recovery mechanism.

### Production incident sequence

1. **Contain:** Suspend the affected Snowflake Task, disable the downstream dbt job, or otherwise stop additional incorrect runs.
2. **Assess:** Identify the affected time window, tables, downstream dashboards, extracts, users, and potentially impacted business decisions.
3. **Notify:** Communicate the known impact, affected period, and expected next update to downstream users and business owners.
4. **Preserve:** Capture the Git commit, release tag, deployment artifact, stored-procedure definition, dbt invocation, and relevant run logs.
5. **Recover:** Choose between reverting to the previously approved code version, applying a controlled data correction, or using Snowflake Time Travel where appropriate.
6. **Validate:** Reproduce the issue in `CA_MKTG_OPS_NP`, develop and validate the fix, and rerun required tests and reconciliations.
7. **Deploy and verify:** Promote the approved correction through the controlled production process, rerun the pipeline, and verify corrected output.
8. **Close:** Notify users of resolution, document root cause and follow-up actions, and improve tests or monitoring to prevent recurrence.

Create a Git release tag for every approved production deployment, not only after an incident. Snowflake Time Travel is a useful recovery capability within its retention period, but it is not a substitute for versioned code rollback, controlled reruns, and documented reconciliation.

## Recommended POC outcomes

The POC should produce evidence that CAI can operate a maintainable, reusable, and controlled transformation workflow:

- A version-controlled Snowflake stored-procedure definition and Task DDL.
- dbt source definitions and a layered staging, intermediate, and fact-model pipeline.
- Tests, documentation, lineage artifacts, and reconciliation evidence.
- GitHub branch protection, pull-request review, and approval evidence.
- Controlled development-to-production promotion using separate nonproduction and production environments.
- A documented UAT sign-off approach, deployment runbook, and incident/rollback procedure.
- A prioritized migration backlog and decision criteria for future procedure-to-dbt candidates.

## Leadership summary

The recommended approach is a governed hybrid model: retain Snowflake Tasks and the existing stored procedure for landing ingestion during the POC, while using dbt for downstream transformations, testing, documentation, and lineage. Apply the same Git-based review, validation, UAT, approval, and traceability controls to both pathways.

This approach limits POC delivery risk while establishing a scalable pattern for future dbt adoption. The longer-term objective is to increase automation, use controlled deployment identities for production, and reduce routine manual production access without removing the explicit human approval required for production releases.
