# AGENTS.md — EdTech API Backend

## 1. PRIME DIRECTIVE

You are working on the **EdTech API backend**.

Before making ANY code change:

1. Read this `AGENTS.md`.
2. Read `MASTER_SYSTEM_DESIGN_FINAL.md`.
3. Read `AI_CODING_AGENT_RULES_FINAL.md`.
4. Inspect the existing repository structure and implementation.
5. Reuse existing patterns before creating new abstractions.
6. Implement only the requested scope.
7. Do not redesign the architecture unless explicitly requested.
8. Do not modify unrelated files.
9. Run appropriate tests and validation.
10. Review the final git diff before reporting completion.

Golden workflow:

**READ → INSPECT → REUSE → PLAN → IMPLEMENT → TEST → VERIFY → DIFF → REPORT**

---

# 2. SOURCE OF TRUTH

Follow this priority order:

1. Current user requirement
2. `MASTER_SYSTEM_DESIGN_FINAL.md`
3. `AI_CODING_AGENT_RULES_FINAL.md`
4. This `AGENTS.md`
5. Existing repository patterns
6. Rails/framework conventions

If two instructions conflict, do not silently choose a design.

Identify the conflict and ask for clarification when necessary.

---

# 3. BACKEND STACK

The backend is a Rails API application.

Primary architecture:

* Ruby on Rails API
* PostgreSQL
* Redis
* Sidekiq / background jobs
* JWT authentication
* `has_secure_password`
* Pundit authorization
* Multi-tenancy
* Service objects
* Query objects where appropriate
* ActiveRecord models
* RESTful `/api/v1/...` APIs

Do not introduce another backend framework or architectural style without explicit approval.

---

# 4. REPOSITORY RECONNAISSANCE

Before implementation, inspect:

```bash
pwd
git status
find . -maxdepth 3 -type f | sort
```

Also inspect relevant:

```text
Gemfile
Gemfile.lock
config/routes.rb
config/application.rb
config/database.yml
db/schema.rb
app/models/
app/controllers/
app/services/
app/policies/
app/jobs/
app/serializers/
app/queries/
```

Do not assume these directories or files exist.

If a directory does not exist, first inspect how the existing application organizes equivalent functionality.

---

# 5. DO NOT WANDER

The agent MUST NOT:

* rewrite the application
* redesign existing architecture
* replace Rails patterns without reason
* introduce unnecessary gems
* create duplicate services
* create duplicate controllers
* create duplicate serializers
* create duplicate authorization systems
* create duplicate API clients
* rename unrelated files
* perform unrelated refactoring
* modify production configuration unnecessarily
* change database infrastructure unnecessarily
* remove existing functionality just to simplify implementation

Prefer the **smallest correct change**.

---

# 6. MULTI-TENANCY — NON-NEGOTIABLE

Tenant isolation is a core security boundary.

Every tenant-owned resource MUST be scoped to the current tenant.

Never trust:

```text
tenant_id
```

from:

* request body
* query parameters
* URL parameters
* frontend
* client-side state
* hidden form fields

The server determines the current tenant.

Use the application's established tenant mechanism, including:

```ruby
Current.tenant
```

and/or the configured tenant-scoping mechanism.

Never allow one tenant to access another tenant's:

* users
* students
* courses
* batches
* admissions
* fees
* attendance
* exams
* certificates
* assets
* leads
* wallet transactions
* reports
* documents
* notifications
* other tenant-owned records

Cross-tenant access must be treated as a critical security defect.

---

# 7. AUTHENTICATION

Authentication is a backend responsibility.

Follow the existing authentication architecture.

Expected concepts include:

* JWT access tokens
* refresh tokens
* password authentication
* secure password handling
* token expiration
* logout/revocation where applicable
* authentication middleware/controller concerns

Never trust frontend authentication state as proof of authorization.

Never place secrets in source code.

Never expose:

```text
JWT secrets
database passwords
API secrets
private keys
Rails master keys
storage credentials
SMTP credentials
payment secrets
```

---

# 8. AUTHORIZATION — PUNDIT

Authorization MUST be handled server-side.

Use Pundit policies and action-level authorization.

Do not implement authorization using only:

```ruby
if user.admin?
```

when a policy-based authorization rule is appropriate.

Every protected action must have an explicit authorization decision.

When adding a new resource/action:

1. Check whether a policy exists.
2. Reuse it if appropriate.
3. Extend it if required.
4. Add policy tests.
5. Verify unauthorized access.

Never rely on frontend role checks for security.

---

# 9. API ARCHITECTURE

API routes should follow:

```text
/api/v1/...
```

Keep API versioning explicit.

Use RESTful resource naming.

Examples:

```text
GET    /api/v1/students
GET    /api/v1/students/:id
POST   /api/v1/students
PATCH  /api/v1/students/:id
DELETE /api/v1/students/:id
```

Do not create random endpoint naming patterns.

Before adding an endpoint:

```bash
bin/rails routes
```

Check whether an equivalent route already exists.

---

# 10. API RESPONSE CONTRACT

Follow the response envelope defined by the master system design and existing application conventions.

Do not invent a new response format for one endpoint.

Maintain consistency for:

* success responses
* validation errors
* authentication errors
* authorization errors
* not-found errors
* pagination metadata
* collection responses

If the repository already has a response helper/serializer, reuse it.

---

# 11. MODELS

Models own:

* associations
* validations
* database relationships
* simple domain invariants
* scopes appropriate to the model

Avoid putting large workflows inside models.

Do not create massive models containing unrelated business logic.

Use services for multi-step workflows.

---

# 12. SERVICE OBJECTS

Use service objects for complex business operations.

Examples:

```text
Admissions
Fees
Wallet
Certificates
Exam submission
Attendance
Notifications
File processing
Authentication workflows
```

A service should have one clear responsibility.

Prefer:

```ruby
SomeService.call(...)
```

when that matches the existing project convention.

Do not create a service for trivial one-line ActiveRecord operations.

Do not create generic services such as:

```text
BaseService
UniversalService
CommonService
EverythingService
```

without a real architectural reason.

---

# 13. DATABASE CHANGES

Every schema change must use a migration.

Never manually edit:

```text
db/schema.rb
```

to implement a database change.

Use:

```bash
bin/rails generate migration ...
bin/rails db:migrate
```

Then verify:

```bash
bin/rails db:migrate:status
```

Important database rules:

* use foreign keys where appropriate
* use indexes for important lookup paths
* use unique constraints for true uniqueness
* use database constraints for critical invariants
* avoid unnecessary nullable columns
* avoid duplicate data where possible

Application validation alone is not enough for critical uniqueness/integrity requirements.

---

# 14. FINANCIAL DATA

Financial data is high risk.

For:

* fees
* payments
* wallet
* wallet transactions
* refunds
* balances
* invoices

follow the financial rules in the master design.

Never perform unsafe balance updates such as:

```ruby
wallet.balance += amount
wallet.save
```

without considering concurrency and transaction safety.

Prefer immutable ledger records where required.

Do not silently modify historical financial transactions.

Never use floating point arithmetic for monetary values when the architecture requires precise monetary representation.

---

# 15. WALLET

Wallet operations must maintain ledger integrity.

Rules include:

* immutable transaction history
* atomic balance changes
* database transactions
* concurrency protection
* idempotency for retryable operations
* correct debit/credit semantics
* tenant isolation
* auditability

If implementing wallet functionality, inspect existing wallet models/services/migrations before changing anything.

---

# 16. CERTIFICATES

Certificate generation is a business-critical workflow.

Respect the lifecycle defined by:

```text
issued
revoked
```

and any additional states defined in the master design.

Certificate generation may involve:

* background jobs
* HTML rendering
* Chromium/Grover
* PDF generation
* object storage
* verification
* revocation

Do not generate certificates synchronously if the architecture specifies background processing.

Certificate verification must not expose unauthorized tenant data.

Revoked certificates must remain verifiable as revoked rather than being silently deleted.

---

# 17. BACKGROUND JOBS

Use background jobs for operations that are:

* slow
* asynchronous
* CPU-heavy
* PDF generation
* email delivery
* notifications
* file processing
* report generation

Before creating a job:

1. Search for an existing equivalent.
2. Reuse existing job conventions.
3. Make the job retry-safe.
4. Consider idempotency.
5. Do not place large business workflows directly inside the job.

The job should call the appropriate service when business logic is complex.

---

# 18. FILES AND ASSETS

File uploads must follow the configured storage architecture.

Possible storage:

* S3
* Cloudflare R2
* MinIO
* configured Active Storage backend

Do not hard-code storage credentials.

Do not store large binary files directly in PostgreSQL unless explicitly required.

Validate:

* file type
* file size
* ownership
* tenant
* authorization

Never expose private files without authorization.

---

# 19. EXAMS

Exam functionality must preserve integrity.

Important concepts:

* exam ownership
* question ownership
* submission ownership
* attempt rules
* answer validation
* scoring
* timing where applicable
* tenant isolation
* authorization

Never allow students to modify another student's submission.

Never trust client-provided scores.

Scores must be calculated or validated server-side.

---

# 20. ATTENDANCE

Attendance is business data.

Respect:

* student ownership
* batch ownership
* session ownership
* tenant isolation
* duplicate prevention
* authorization
* audit requirements

Do not allow arbitrary attendance manipulation through client-provided identifiers.

---

# 21. ADMISSIONS AND FEES

Admission workflows should follow the domain lifecycle defined in the master design.

Do not create ad-hoc status values.

Before adding a status:

1. Search existing status definitions.
2. Check the master design.
3. Check database constraints/enums.
4. Check dependent services.
5. Check frontend expectations if relevant.

Use explicit state transitions where required.

---

# 22. AUDIT LOGGING

Sensitive business operations should be auditable.

Consider audit logging for:

* authentication/security events
* role changes
* permission changes
* financial operations
* certificate issuance/revocation
* important student/admission changes
* administrative actions
* destructive actions

Do not log secrets, passwords, tokens, or sensitive credentials.

---

# 23. PAGINATION AND FILTERING

Collection APIs should support pagination where appropriate.

Avoid returning unbounded large datasets.

For list endpoints consider:

```text
page
per_page
search
status
date filters
sorting
```

Use database-level filtering.

Do not load thousands of records into Ruby just to filter them in memory.

Avoid N+1 queries.

Use appropriate:

```ruby
includes
preload
eager_load
joins
```

when justified.

---

# 24. PERFORMANCE

Before optimizing:

1. Identify the actual bottleneck.
2. Inspect queries.
3. Check indexes.
4. Check N+1 queries.
5. Check unnecessary object loading.
6. Make the smallest effective change.

Do not introduce caching everywhere without a clear invalidation strategy.

---

# 25. TESTING

Every meaningful backend change must include appropriate tests.

Depending on the change, test:

```text
model
request/API
service
policy
job
query
integration
```

Security-sensitive features MUST include authorization tests.

Multi-tenant features MUST include cross-tenant isolation tests.

Financial features MUST include transaction/concurrency/idempotency tests where relevant.

Run appropriate checks such as:

```bash
bin/rails test
bin/rubocop
bin/brakeman
bin/bundler-audit
```

Use the project's existing test framework and commands if they differ.

Do not claim a feature is complete without validation.

---

# 26. SECURITY

Never:

* commit secrets
* log passwords
* log JWTs
* expose private credentials
* trust client authorization
* trust client tenant IDs
* bypass Pundit
* disable CSRF/security protections without explicit reason
* expose internal exceptions unnecessarily
* return sensitive database fields by default

Use strong server-side validation.

Treat authorization failures as security issues.

---

# 27. ENVIRONMENT VARIABLES

Secrets and environment-specific configuration must remain outside source code.

Examples:

```text
DATABASE_URL
REDIS_URL
JWT_SECRET
AWS credentials
R2 credentials
SMTP credentials
payment provider secrets
```

Never move secrets into:

```text
NEXT_PUBLIC_*
```

or any publicly exposed configuration.

Do not commit `.env` files containing secrets.

---

# 28. ROUTES

Before adding routes:

```bash
bin/rails routes
```

Search for existing equivalents.

Keep routes organized under API version namespaces.

Do not create duplicate routes simply because an existing route is inconvenient.

---

# 29. CODE STYLE

Follow existing project conventions.

Prefer:

* clear names
* small methods
* explicit responsibilities
* predictable control flow
* meaningful errors
* reusable existing helpers

Avoid:

* clever abstractions
* unnecessary metaprogramming
* deeply nested conditionals
* giant controllers
* giant service objects
* duplicate helpers
* unexplained magic constants

---

# 30. DEPENDENCIES

Do NOT add a gem unless it is actually required.

Before adding a gem:

1. Check whether the project already provides the capability.
2. Search the codebase.
3. Check Gemfile/Gemfile.lock.
4. Confirm the architecture allows it.
5. Add only if justified.

Never install a library merely because it is popular.

---

# 31. GIT SAFETY

Before changes:

```bash
git status
```

After changes:

```bash
git status
git diff --stat
git diff
```

Do not overwrite unrelated user changes.

Do not reset or delete user work.

Do not use destructive commands such as:

```bash
git reset --hard
git clean -fd
```

unless explicitly requested.

Keep commits focused.

---

# 32. IMPLEMENTATION PROCESS

For every task follow exactly:

## Step 1 — Read

Read the relevant architecture/rules.

## Step 2 — Inspect

Inspect existing implementation.

## Step 3 — Search

Search for:

* similar models
* controllers
* services
* policies
* routes
* migrations
* tests

## Step 4 — Plan

Identify:

```text
Files to create
Files to modify
Files that must NOT change
Database changes
Authorization changes
Tests required
```

## Step 5 — Implement

Make the smallest correct change.

## Step 6 — Test

Run relevant tests and static checks.

## Step 7 — Verify

Verify:

* tenant isolation
* authorization
* validations
* database integrity
* API response
* error handling
* performance implications

## Step 8 — Diff

Review:

```bash
git diff
```

## Step 9 — Report

Clearly report what changed and what remains.

---

# 33. DO NOT CLAIM SUCCESS WITHOUT EVIDENCE

Never say:

```text
Done
Working
Production ready
Fully implemented
All tests pass
```

unless the corresponding validation was actually performed.

Report actual evidence.

Example:

```text
Tests:
bin/rails test — PASS

Rubocop:
bin/rubocop — PASS

Brakeman:
bin/brakeman — PASS
```

If something could not be run, explicitly state it.

---

# 34. REQUIRED FINAL REPORT

After implementation, respond with:

```text
## Implementation Summary

### Changed
- file/path
- file/path

### Added
- file/path

### Database
- migration details

### Authorization
- policy changes

### API
- endpoint changes

### Tests
- commands executed
- results

### Validation
- tenant isolation
- authorization
- edge cases

### Git Diff
- summary of changes

### Remaining
- anything not implemented
- known limitations
```

Do not hide incomplete work.

---

# 35. GOLDEN RULE

When uncertain:

**DO NOT GUESS.**

Read the architecture.

Inspect the existing code.

Search for the existing pattern.

Reuse before creating.

Ask before redesigning.

Implement the smallest correct change.

Then test and verify.

**READ → INSPECT → REUSE → PLAN → IMPLEMENT → TEST → VERIFY → DIFF → REPORT**
## Controller Organization & API Namespace Rules

Controllers MUST be organized by API consumer/actor boundary first,
and by domain/resource second.

The controller namespace MUST clearly represent who is consuming the API.

Canonical structure:

app/controllers/api/v1/
├── admin/
├── student/
├── trainer/
├── receptionist/
├── public/
└── auth/

### Actor Namespace Rules

- `admin/`
  - Administrative APIs
  - Tenant/branch management
  - User management
  - Role/permission management
  - Wallet/financial administration
  - Administrative dashboards and reports

- `student/`
  - Student-facing APIs
  - Student dashboard
  - Courses
  - Enrollments
  - Attendance
  - Exams
  - Certificates
  - Student profile

- `trainer/`
  - Trainer-facing APIs
  - Trainer dashboard
  - Assigned courses
  - Batches
  - Attendance
  - Exams
  - Trainer operations

- `receptionist/`
  - Reception/front-desk APIs
  - Admissions
  - Leads
  - Student registration
  - Fee collection where authorized
  - Reception operations

- `public/`
  - Unauthenticated/public APIs
  - Public course catalog
  - Public tenant/branch discovery
  - Public CMS content
  - Public-facing resources

- `auth/`
  - Authentication/session APIs
  - Login
  - Refresh
  - Logout
  - Other authentication lifecycle operations

### Examples

Correct:

app/controllers/api/v1/admin/tenants_controller.rb
app/controllers/api/v1/admin/users_controller.rb
app/controllers/api/v1/student/courses_controller.rb
app/controllers/api/v1/student/enrollments_controller.rb
app/controllers/api/v1/trainer/batches_controller.rb
app/controllers/api/v1/receptionist/admissions_controller.rb
app/controllers/api/v1/public/courses_controller.rb
app/controllers/api/v1/auth/sessions_controller.rb

Incorrect:

app/controllers/api/v1/tenants_controller.rb
app/controllers/api/v1/students_controller.rb
app/controllers/api/v1/courses_controller.rb

when those controllers are actor-specific.

### Critical Rules

1. Actor namespace MUST be the first organizational boundary after
   `api/v1`.

2. Controllers belonging to different actor boundaries MUST NOT be
   mixed in the same directory.

3. Domain/business logic MUST NOT be duplicated between actor controllers.

4. Shared business logic belongs in:
   - models
   - service objects
   - domain services
   - shared concerns where genuinely appropriate

5. Controller namespace is an organizational/API boundary, NOT an
   authorization mechanism.

6. Pundit authorization remains mandatory regardless of controller namespace.

7. A user MUST NOT gain authorization merely because an endpoint exists
   under an authorized-looking namespace.

8. Never bypass or weaken Pundit because the controller is under:
   `admin/`, `student/`, `trainer/`, or `receptionist/`.

9. Tenant isolation through `Current.tenant`, `TenantScoped`, and
   `ActsAsTenant` remains mandatory.

10. Routes MUST mirror the controller namespace.

Example:

GET /api/v1/admin/tenants
    → Api::V1::Admin::TenantsController

GET /api/v1/student/courses
    → Api::V1::Student::CoursesController

GET /api/v1/trainer/batches
    → Api::V1::Trainer::BatchesController

GET /api/v1/receptionist/admissions
    → Api::V1::Receptionist::AdmissionsController

GET /api/v1/public/courses
    → Api::V1::Public::CoursesController

POST /api/v1/auth/login
    → Api::V1::Auth::SessionsController

### Resource Ownership

Use the actor namespace when the API represents an actor-specific
experience.

Examples:

Student:
GET /api/v1/student/courses
GET /api/v1/student/enrollments
GET /api/v1/student/attendance

Trainer:
GET /api/v1/trainer/batches
GET /api/v1/trainer/attendance

Admin:
GET /api/v1/admin/tenants
GET /api/v1/admin/users
GET /api/v1/admin/wallet

### Shared Resources

If a resource is used by multiple actors, DO NOT automatically create
duplicate controllers.

First determine whether:

1. the API behavior is genuinely different by actor, or
2. the same endpoint/business operation can safely be shared.

If behavior is materially different, actor-specific controllers may be
created while sharing the underlying service/domain logic.

Example:

admin/courses_controller.rb
trainer/courses_controller.rb
student/courses_controller.rb

These controllers may expose different actions/data, but MUST reuse
shared domain logic instead of duplicating business rules.

### Naming

Use singular actor namespace names:

admin
student
trainer
receptionist
public
auth

Do NOT use:

admins
students
trainers
receptionists
public_api
users_area
frontend
mobile

unless explicitly required by the architecture.

### Future Actors

New actor namespaces MUST NOT be introduced casually.

Before adding a new actor namespace:

1. Verify the actor exists in the master system design.
2. Verify that the API behavior is genuinely actor-specific.
3. Confirm that an existing namespace cannot represent the operation.
4. Keep authorization independent from namespace naming.

### Migration of Existing Controllers

When an existing controller is actor-specific, move it into the correct
actor namespace rather than creating a duplicate controller.

Example:

api/v1/tenants_controller.rb
        ↓
api/v1/admin/tenants_controller.rb

api/v1/users_controller.rb
        ↓
api/v1/admin/users_controller.rb

Preserve existing behavior, policies, services, response contracts,
and tests during migration.

Do NOT perform large unrelated refactors while reorganizing controllers.

### Mandatory Rule for New Modules

Every new business module MUST decide its API actor boundary BEFORE
creating its controller.

The implementation workflow is:

1. Identify API consumer.
2. Select actor namespace.
3. Define route.
4. Create controller inside that namespace.
5. Apply Pundit authorization.
6. Apply tenant isolation.
7. Reuse domain/service logic.
8. Add controller tests.
9. Verify route/controller mapping.

Never create a generic controller under `api/v1/` simply because the
resource name exists.