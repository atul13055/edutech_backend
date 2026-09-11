# AI CODING AGENT RULES
## Multi-Tenant B2B EdTech SaaS + Franchise ERP + Headless CMS

**Status:** Mandatory  
**Purpose:** This document is the operating contract for every AI coding agent working on this repository.

---

# 1. PRIME DIRECTIVE

You are working inside an existing production-oriented architecture.

**Do not redesign the application while implementing a feature.**

Your job is to:
1. Understand the existing architecture.
2. Locate the correct module and layer.
3. Make the smallest correct change.
4. Preserve established conventions.
5. Add/update tests.
6. Validate the result.
7. Report exactly what changed.

If the requested feature conflicts with the Master System Design, stop and identify the conflict before implementing an architectural deviation.

---

# 2. SOURCE OF TRUTH

Use this priority order:

```text
1. Explicit user requirement for the current task
2. Master System Design
3. Existing repository architecture and established patterns
4. Existing tests
5. Framework conventions
6. Agent assumptions
```

Never silently replace the project's documented architecture with personal preference.

When documentation and code disagree:
- inspect the relevant implementation and tests;
- identify the mismatch;
- do not silently redesign unrelated code;
- make the smallest change required by the current task.

---

# 3. FIRST STEP — REPOSITORY RECONNAISSANCE

Before editing code, inspect:

```text
README
Master System Design
AGENTS.md / AI agent rules
package / Gem configuration
routes
models
policies
services
jobs
tests
environment configuration
existing module patterns
```

Then answer internally:

```text
What module am I changing?
What existing implementation is closest?
What files are expected to change?
What security rules apply?
What tests cover this behavior?
```

Do not start coding immediately after reading only one file.

---

# 4. NEVER WANDER

Do not:
- create random folders;
- duplicate existing services;
- create a second API client;
- create a second authorization mechanism;
- introduce a new naming convention;
- move files unnecessarily;
- rewrite unrelated modules;
- refactor the entire codebase for a small feature;
- introduce dependencies without justification.

If a suitable file already exists, modify it.

If a suitable abstraction does not exist, create one in the canonical location defined by the system design.

---

# 5. CANONICAL BACKEND STRUCTURE

```text
app/controllers/api/v1/  -> HTTP layer
app/models/              -> persistence/domain invariants
app/policies/            -> authorization
app/services/            -> business workflows
app/queries/             -> complex read logic
app/jobs/                -> asynchronous processing
app/serializers/         -> API representation
app/validators/          -> reusable complex validation
app/mailers/             -> email
spec/                    -> tests
db/migrate/              -> schema changes
```

### Layer rules

### Controllers
Controllers must be thin.

Allowed:
- authenticate;
- resolve/request context;
- authorize;
- parse input;
- call service/query;
- render response.

Avoid:
- complex business logic;
- financial calculations;
- large database workflows;
- repeated authorization logic.

### Models
Models contain:
- associations;
- validations;
- enums;
- domain invariants;
- small domain methods.

Do not turn models into huge service objects.

### Services
Use services for:
- multi-step workflows;
- transactions;
- financial operations;
- certificate issuance;
- enrollment workflows;
- complex state transitions.

### Policies
Policies contain authorization rules.

Never use:

```ruby
if current_user.admin?
```

as a replacement for proper resource authorization when Pundit applies.

### Jobs
Jobs perform asynchronous work.

Jobs must be:
- retry-safe where possible;
- idempotent where required;
- observable;
- free from request-specific assumptions.

---

# 6. MULTI-TENANCY IS NON-NEGOTIABLE

Tenant isolation is one of the highest-priority security requirements.

Tenant-owned models must explicitly use:

```ruby
acts_as_tenant :tenant
```

and normally:

```ruby
belongs_to :tenant
```

Controllers must NEVER accept a client-controlled:

```text
tenant_id
```

as the authority for tenant selection.

Never trust:

```json
{
  "tenant_id": "another-tenant"
}
```

The authenticated context and secure tenant-resolution mechanism determine the tenant.

---

# 7. TENANT ISOLATION CHECKLIST

For every tenant-owned feature verify:

```text
[ ] Model has tenant association
[ ] acts_as_tenant is present where required
[ ] Controller does not trust tenant_id
[ ] Query is tenant scoped
[ ] Policy prevents cross-tenant access
[ ] Foreign keys are correct
[ ] Unique indexes include tenant_id when appropriate
[ ] Tests attempt cross-tenant access
```

A feature is not complete until tenant isolation is considered.

---

# 8. AUTHORIZATION

Every protected domain resource requires a Pundit policy.

For mutations:

```ruby
authorize @record
```

For collection queries:

```ruby
policy_scope(Model)
```

Do not rely on frontend permission checks for security.

Frontend permission checks are UX only.

Backend authorization is authoritative.

---

# 9. API CONTRACT

Success:

```json
{
  "success": true,
  "data": {}
}
```

Optional metadata:

```json
{
  "success": true,
  "data": {},
  "meta": {}
}
```

Error:

```json
{
  "success": false,
  "errors": [
    {
      "code": "VALIDATION_ERROR",
      "message": "Course name is required",
      "field": "name"
    }
  ]
}
```

Use stable machine-readable error codes.

Do not invent a different response envelope for individual endpoints.

---

# 10. DATABASE RULES

Use:
- foreign keys;
- NOT NULL constraints where required;
- unique indexes;
- tenant-aware unique constraints;
- useful indexes;
- database transactions for financial operations;
- row locking for concurrency-sensitive balances.

Examples:

```text
UNIQUE (tenant_id, roll_number)
UNIQUE (tenant_id, receipt_number)
UNIQUE (tenant_id, certificate_number)
UNIQUE (tenant_id, asset_code)
```

Do not rely exclusively on application-level uniqueness validation.

---

# 11. MIGRATION RULES

Every schema change must use a migration.

Never manually edit:

```text
db/schema.rb
```

to implement a schema change.

After migration:
- run migration;
- verify schema;
- verify indexes/constraints;
- update model/tests as required.

Avoid destructive migrations unless explicitly required.

For production-sensitive changes, prefer a safe expand/contract migration strategy.

---

# 12. FINANCIAL SAFETY

Financial data requires extra care.

Affected areas:

```text
Fees
Wallet
Refunds
Adjustments
Receipts
Certificate royalty deductions
```

Rules:

1. Use database transactions.
2. Protect concurrent balance changes with locking.
3. Never allow direct client-side balance mutation.
4. Do not silently edit historical financial transactions.
5. Prefer reversal/refund/adjustment transactions.
6. Use idempotency for externally retried payment operations.
7. Preserve audit history.
8. Never log payment secrets or sensitive credentials.

---

# 13. WALLET RULE

The wallet ledger is the financial source of truth.

Preferred flow:

```text
Request
  ↓
Authorize
  ↓
BEGIN TRANSACTION
  ↓
Lock wallet
  ↓
Validate balance
  ↓
Create ledger transaction
  ↓
Update cached balance if used
  ↓
COMMIT
```

Never implement:

```ruby
wallet.balance -= amount
```

without concurrency protection and a corresponding immutable ledger entry.

---

# 14. CERTIFICATE RULES

Certificate lifecycle:

```text
draft
  ↓
queued
  ↓
generating
  ↓
issued
```

Failure:

```text
generating → failed
```

Revocation:

```text
issued → revoked
```

Certificate issuance must:
- verify enrollment;
- verify required academic/payment conditions;
- protect wallet deduction;
- create a ledger entry;
- generate a unique verification identifier;
- enqueue PDF generation safely;
- upload the final file;
- update status.

Public verification must not expose:
- internal database IDs;
- tenant IDs;
- private KYC;
- sensitive student information.

---

# 15. BACKGROUND JOB RULES

Use Sidekiq for work such as:

```text
Certificate generation
Email delivery
Notifications
Fee reminders
Large reports
File processing
Maintenance
```

Every job should consider:

```text
[ ] retry behavior
[ ] idempotency
[ ] failure state
[ ] logging
[ ] duplicate execution
[ ] external API failure
```

Do not put long-running processing inside HTTP requests when it belongs in a background job.

---

# 16. FILE STORAGE RULES

Files belong in object storage:

```text
S3
MinIO
Cloudflare R2
```

Application databases should store metadata, not large binary payloads.

Use the central file abstraction where available.

Never:
- expose private storage credentials;
- hard-code bucket credentials;
- commit secret keys;
- make private student documents public accidentally.

---

# 17. FRONTEND RULES

Canonical responsibilities:

```text
app/        → routes/pages/layouts
features/   → domain UI logic
components/ → reusable UI
lib/api/    → API client
stores/     → shared client state
hooks/      → reusable React hooks
types/      → TypeScript types
```

Do not duplicate API calls throughout components.

Prefer:

```text
Component
   ↓
Feature hook/service
   ↓
Central API client
   ↓
Rails API
```

---

# 18. STUDENT PWA RULE

Student screens are mobile-first.

Every student feature must work at approximately:

```text
360px viewport
```

Requirements:

```text
[ ] no horizontal scrolling
[ ] usable touch targets
[ ] fixed bottom navigation where applicable
[ ] responsive typography
[ ] loading state
[ ] empty state
[ ] error state
```

Desktop admin UX and mobile student UX should not be forced into the same layout.

---

# 19. SERVER SECURITY

Never trust the browser for:

```text
Authorization
Tenant selection
Financial balances
Exam results
Certificate validity
Attendance integrity
```

The server must enforce these.

Never commit:

```text
.env
private keys
JWT secrets
API secrets
database passwords
storage credentials
```

Update `.env.example` with variable names, never real secrets.

---

# 20. INPUT VALIDATION

Validate input at the appropriate layer.

Use:
- model validations for domain invariants;
- request/service validation for workflow requirements;
- database constraints for critical integrity.

Never assume frontend validation is sufficient.

---

# 21. ERROR HANDLING

Errors should be:
- predictable;
- structured;
- actionable;
- safe.

Do not expose:
- stack traces;
- SQL;
- secrets;
- internal credentials;
- sensitive infrastructure details.

Use application-level error codes.

---

# 22. LOGGING

Use structured logs where possible.

Include useful context:

```text
request_id
user_id
tenant context where safe
action
resource type
resource identifier
duration
job id
```

Never log:

```text
passwords
JWTs
refresh tokens
API keys
secret credentials
```

---

# 23. AUDIT LOGGING

Sensitive actions should be auditable:

```text
Login/security events
Role changes
Permission changes
Wallet changes
Fee corrections
Certificate issue
Certificate revoke
Student deletion/archive
Asset changes
Important administrative actions
```

Audit records should preserve enough context to answer:

```text
Who?
What?
When?
Which tenant?
Which resource?
What changed?
```

---

# 24. TESTING IS PART OF IMPLEMENTATION

Do not consider a feature complete because the code compiles.

For backend changes consider:

```text
[ ] model tests
[ ] request/API tests
[ ] policy tests
[ ] service tests
[ ] job tests
[ ] tenant isolation tests
[ ] financial concurrency tests when relevant
```

For frontend changes consider:

```text
[ ] component tests where appropriate
[ ] integration tests
[ ] responsive behavior
[ ] critical E2E flow
```

---

# 25. CROSS-TENANT TEST

For every tenant-sensitive resource, include the conceptual test:

```text
Tenant A user
    ↓
attempts Tenant B resource
    ↓
ACCESS DENIED
```

Never assume `acts_as_tenant` alone means the entire feature is correctly protected.

---

# 26. API VERSIONING

Use:

```text
/api/v1/
```

Do not silently introduce incompatible behavior into an existing endpoint.

If a breaking API change is required, discuss versioning.

---

# 27. NAMING RULES

Follow Rails and TypeScript conventions.

Examples:

```text
CertificateIssuanceService
FeeCollectionService
ExamEvaluationService

CertificatePolicy
StudentPolicy

GenerateCertificateJob
SendFeeReminderJob
```

Avoid vague names:

```text
HelperService
CommonService
MiscService
Utils
Manager
Processor
```

unless the responsibility is genuinely clear.

---

# 28. SERVICE DESIGN

A service should have one clear business responsibility.

Good:

```text
StudentEnrollmentService
CertificateIssuanceService
WalletDebitService
ExamEvaluationService
```

Bad:

```text
EverythingService
StudentManager
CommonBusinessService
```

Do not create services merely to move three lines of code out of a controller.

---

# 29. QUERY OBJECTS

Use query objects when read logic becomes:
- complex;
- reused;
- difficult to test;
- performance-sensitive.

Do not create a query class for every simple:

```ruby
Model.where(status: :active)
```

---

# 30. DON'T OVER-ENGINEER

Do not add:
- microservices;
- event buses;
- Kafka;
- GraphQL;
- unnecessary caching;
- unnecessary abstractions;
- unnecessary gems;
- unnecessary design patterns

unless the project requirement actually justifies them.

This project is a modular Rails + Next.js application.

Prefer a clean modular monolith unless explicitly instructed otherwise.

---

# 31. DEPENDENCY RULE

Before adding a gem/npm package:

```text
1. Check whether existing dependencies already solve it.
2. Check whether framework functionality solves it.
3. Consider maintenance/security impact.
4. Explain why the dependency is needed.
5. Keep the dependency narrowly scoped.
```

Never add a dependency just because it is convenient for one small function.

---

# 32. REUSE BEFORE CREATE

Before creating:
- component;
- service;
- policy;
- validator;
- hook;
- API helper;
- query;
- utility;

search the repository first.

If an equivalent exists, reuse or extend it.

---

# 33. DO NOT DUPLICATE BUSINESS RULES

A business rule should have one authoritative implementation where practical.

Examples:

```text
Certificate royalty calculation
Fee balance calculation
Exam pass criteria
Wallet debit validation
Permission evaluation
```

Do not implement the same rule independently in:
- controller;
- frontend;
- service;
- job.

Frontend may mirror rules for UX, but backend remains authoritative.

---

# 34. STATE TRANSITIONS

Important state changes must be explicit.

Examples:

```text
Certificate:
draft → queued → generating → issued/revoked/failed

Lead:
new → contacted → interested → converted/lost

Enrollment:
pending → active → completed/cancelled

Asset:
available → assigned → maintenance → retired
```

Do not scatter state transitions across unrelated controllers.

---

# 35. EXAM INTEGRITY

Exam submission must be server-authoritative.

Do not trust the frontend for:
- final score;
- pass/fail;
- timer completion;
- correct answers;
- attempt limits.

The browser may display state, but Rails determines the authoritative result.

---

# 36. ATTENDANCE INTEGRITY

Attendance must be tied to the appropriate:

```text
Tenant
Enrollment
Batch/Class Session
```

Prevent duplicate records using application validation plus appropriate database constraints.

---

# 37. RESPONSE PERFORMANCE

Avoid:
- N+1 queries;
- loading huge datasets;
- unbounded endpoints;
- expensive dashboard calculations on every request.

Use:
- pagination;
- eager loading;
- indexes;
- query objects;
- reporting snapshots where justified.

---

# 38. PAGINATION

Admin list endpoints should support pagination.

Never return thousands of records by default.

Typical parameters:

```text
page
per_page
search
sort
status
from
to
```

Enforce a reasonable maximum `per_page`.

---

# 39. API FILTERING

Filtering should be predictable and validated.

Do not dynamically interpolate arbitrary SQL from client input.

Whitelist:
- sortable columns;
- filterable fields;
- allowed directions.

---

# 40. GIT RULES

Before modifying:

```text
git status
```

Understand existing changes.

Do not overwrite user changes.

After implementation:

```text
git diff
git status
```

Review every changed file.

Do not include unrelated modifications.

Commit messages should describe the actual change.

---

# 41. CHANGE SCOPE RULE

Every task should have a clear scope.

Before coding write mentally:

```text
IN SCOPE:
- ...

OUT OF SCOPE:
- ...
```

Do not expand a small request into an unrelated refactor.

If a discovered issue is important but unrelated:
- mention it;
- do not silently fix it unless necessary for the requested feature.

---

# 42. WHEN SOMETHING IS UNCLEAR

Do not guess when ambiguity changes architecture, security, financial behavior, or data integrity.

Examples requiring clarification:

```text
Should money be refunded?
Should a certificate be revoked or regenerated?
Should an enrollment be deleted or archived?
Should a role be global or tenant-specific?
Should an exam allow multiple attempts?
```

For small implementation details, follow established repository conventions.

---

# 43. REQUIRED IMPLEMENTATION WORKFLOW

Every meaningful coding task should follow:

```text
STEP 1
Read requirements.

STEP 2
Inspect repository structure.

STEP 3
Find similar existing implementation.

STEP 4
Identify affected layers.

STEP 5
Check tenant + authorization implications.

STEP 6
Design the smallest change.

STEP 7
Implement.

STEP 8
Add/update tests.

STEP 9
Run formatter/linter/tests.

STEP 10
Review git diff.

STEP 11
Check for security/regression issues.

STEP 12
Report implementation clearly.
```

---

# 44. FINAL VALIDATION CHECKLIST

Before saying "done":

```text
ARCHITECTURE
[ ] Correct module
[ ] Correct layer
[ ] Existing patterns reused

SECURITY
[ ] Authentication considered
[ ] Tenant isolation considered
[ ] Authorization implemented
[ ] Sensitive data protected

DATABASE
[ ] Migration added if required
[ ] Constraints/indexes considered
[ ] N+1 considered

API
[ ] Response envelope consistent
[ ] Error format consistent
[ ] Pagination where needed

BUSINESS
[ ] State transitions correct
[ ] Financial transaction safety checked
[ ] Idempotency checked where needed

TESTS
[ ] Relevant tests added/updated
[ ] Existing tests remain green
[ ] Cross-tenant access considered

QUALITY
[ ] No unrelated files changed
[ ] No secrets committed
[ ] No unnecessary dependency
[ ] No unnecessary refactor
```

---

# 45. AGENT RESPONSE FORMAT

After completing a coding task, report:

```text
## Implemented

- What changed
- Main files changed
- Important business/security behavior

## Tests

- Commands executed
- Result

## Notes

- Any limitation
- Any follow-up that is genuinely required
```

Do not claim tests passed if they were not actually run.

Do not claim an endpoint works if it was not verified.

---

# 46. ARCHITECTURAL CHANGE RULE

If an implementation requires changing the Master System Design:

```text
1. Identify the conflict.
2. Explain why the current design is insufficient.
3. Propose the smallest architectural change.
4. Update the design documentation.
5. Then implement the code.
```

Do not let implementation silently drift away from architecture.

---

# 47. ABSOLUTE DON'Ts

```text
DO NOT bypass tenant isolation.
DO NOT trust client tenant_id.
DO NOT bypass Pundit.
DO NOT expose private student data.
DO NOT directly mutate wallet balances.
DO NOT delete financial history.
DO NOT trust frontend exam results.
DO NOT expose certificate internals publicly.
DO NOT commit secrets.
DO NOT ignore failing tests.
DO NOT rewrite unrelated modules.
DO NOT invent new architecture without need.
DO NOT duplicate existing abstractions.
DO NOT claim unverified work is complete.
```

---

# 48. GOLDEN RULE

When in doubt:

```text
UNDERSTAND
   ↓
LOCATE
   ↓
REUSE
   ↓
IMPLEMENT
   ↓
TEST
   ↓
VERIFY
   ↓
REPORT
```

**The AI agent must behave like a disciplined senior engineer working inside an existing product—not like an autonomous developer inventing a new codebase for every task.**
