# 🏛️ Master System Design, Domain Models & Agent Blueprint

**Project Name:** Multi-Tenant B2B EdTech SaaS, Franchise ERP & Headless CMS

**Backend:** Ruby on Rails 8 (API Mode) + PostgreSQL + Redis/Sidekiq

**Frontend:** Next.js 15+ (App Router) + Tailwind CSS + shadcn/ui + PWA

## 1. High-Level Architecture & Flow Diagrams

### System Architecture Topology

```
+-----------------------------------------------------------------------------------+
|                                  CLIENT DEVICES                                   |
|   [ Mobile PWA (Students) ]               [ Desktop Web (Admins / Reception) ]   |
|   (Bottom Nav, Offline Cache)             (Data-tables, Asset Grid, CMS Setup)    |
+-----------------------------------------+-----------------------------------------+
                                          |
                                          | HTTPS / REST / JWT
                                          v
+-----------------------------------------------------------------------------------+
|                           NEXT.JS 15 APP ROUTER                                   |
|   - app/(marketing): Public SSR, Dynamic Themes, QR Verify Pages                  |
|   - app/(student): Mobile-first PWA, Enrolled Batches, Typing Engine              |
|   - app/(admin): Desktop-first Franchise, Accounts & IT Inventory ERP            |
+-----------------------------------------+-----------------------------------------+
                                          |
                                          | JSON API (Subdomain / X-Tenant-Id)
                                          v
+-----------------------------------------------------------------------------------+
|                         REVERSE PROXY (Nginx / Caddy)                             |
+-----------------------------------------+-----------------------------------------+
                                          |
                                          v
+-----------------------------------------------------------------------------------+
|                         RAILS 8 API CORE ENGINE (Puma)                            |
|   - App Controller: Current.tenant resolver via acts_as_tenant                    |
|   - Auth Engine: Lightweight custom JWT + has_secure_password                    |
|   - Authorization: Pundit Action-Level RBAC Policies                              |
+--------------------+------------------------------------+-------------------------+
                     |                                    |
                     v                                    v
     +-------------------------------+    +-------------------------------+
     |          PostgreSQL           |    |        Redis + Sidekiq        |
     |   - Multi-tenant data store   |    |   - Asynchronous PDF jobs     |
     |   - Scoped foreign keys       |    |   - Automated alerts queue    |
     +-------------------------------+    +---------------+---------------+
                                                          |
                                                          v
                                          +-------------------------------+
                                          |  Grover (Headless Chromium)   |
                                          |  - Vector 300 DPI PDF Engine  |
                                          +---------------+---------------+
                                                          |
                                                          v
                                          +-------------------------------+
                                          | Cloud Storage (S3 / MinIO/ R2)|
                                          +-------------------------------+

```

### Certificate Issuance & Verification Flow

```
Center Admin Clicks "Issue Certificate"
                   │
                   ▼
Rails Controller Validates:
[ Tenant Wallet Balance >= Course Royalty Fee ]
                   │
       ┌───────────┴───────────┐
      NO                      YES
       │                       │
       ▼                       ▼
Return 422 Error       DB Atomic Transaction:
("Insufficient         1. Deduct Wallet Balance
 Wallet Balance")      2. Log WalletTransaction (debit)
                       3. Create Certificate (status: queued)
                       4. Generate Unique Verification Hash (SHA-256)
                               │
                               ▼
                       Enqueue GenerateCertificateJob (Sidekiq)
                               │
                               ▼
                       Background Worker:
                       - Fetch Student, Center & Marks Data
                       - Generate QR pointing to /verify/:hash
                       - Render HTML via Grover (Chromium) to PDF
                       - Upload PDF to S3/R2 Bucket
                       - Update Certificate status: 'issued'
                               │
                               ▼
Public User Scans QR Code on Physical Certificate
                               │
                               ▼
Next.js Route: /verify/:hash ──> Rails Public API ──> Displays Verified Transcript

```

## 2. Module-Wise Domain Models & Relationships

Har model ka role aur uske exact Rails associations (`belongs_to`, `has_many`, `acts_as_tenant`):

### Module 1: Dynamic Headless CMS & White-Label Branding

- **`CmsSetting`** *(Global - Managed by Super Admin)*
  - **Role:** Platform theme colors, fonts, logo, footer, aur contact info store karna.
  - **Associations:** Standalone key-value store.
- **`CmsBanner`** *(Global - Managed by Super Admin)*
  - **Role:** Desktop aur mobile marketing sliders aur promotional banners.
  - **Associations:** Standalone ordered model with scheduling scopes.
- **`CmsAnnouncement`** *(Global - Managed by Super Admin)*
  - **Role:** Timed modal popups aur top marquee alerts handle karna.
  - **Associations:** Standalone model with trigger events.

### Module 2: Multi-Tenancy, Franchise Network & Wallet System

- **`Tenant`** *(Franchise Branch)*
  - **Role:** Root entity for every computer center.
  - **Associations:**
    - `has_many :users, dependent: :destroy`
    - `has_many :roles, dependent: :destroy`
    - `has_many :assets, dependent: :destroy`
    - `has_many :students, dependent: :destroy`
    - `has_many :courses, dependent: :destroy` (custom branch courses)
    - `has_many :wallet_transactions, dependent: :destroy`
    - `has_many :certificates, dependent: :restrict_with_error`
- **`WalletTransaction`**
  - **Role:** Har branch ka ledger entry (recharge credit, certificate deduction debit).
  - **Associations:**
    - `acts_as_tenant :tenant`
    - `belongs_to :tenant`

### Module 3: Role-Based Access Control (RBAC) & Users

- **`User`**
  - **Role:** Login credentials, profile, authentication gate.
  - **Associations:**
    - `belongs_to :tenant, optional: true` (Super Admin ka `tenant` null hota hai)
    - `belongs_to :role`
    - `has_many :permissions, through: :role`
    - `has_many :reported_tickets, class_name: 'AssetTicket', foreign_key: :reported_by_user_id`
    - `has_many :collected_fees, class_name: 'FeeTransaction', foreign_key: :collected_by_user_id`
- **`Role`**
  - **Role:** Defines system role (`super_admin`, `branch_admin`, `trainer`, `receptionist`, `student`).
  - **Associations:**
    - `belongs_to :tenant, optional: true` (Global vs branch-specific custom roles)
    - `has_many :role_permissions, dependent: :destroy`
    - `has_many :permissions, through: :role_permissions`
    - `has_many :users, dependent: :restrict_with_error`
- **`Permission`**
  - **Role:** Atomic capabilities (`fees.collect`, `assets.manage`, `certificates.issue`).
  - **Associations:**
    - `has_many :role_permissions, dependent: :destroy`
    - `has_many :roles, through: :role_permissions`
- **`RolePermission`**
  - **Role:** Join table connecting Roles and Permissions.
  - **Associations:**
    - `belongs_to :role`
    - `belongs_to :permission`

### Module 4: IT & Lab Hardware Asset Management

- **`Asset`**
  - **Role:** Physical computer systems, monitors, routers, and biometric devices.
  - **Associations:**
    - `acts_as_tenant :tenant`
    - `belongs_to :tenant`
    - `has_many :asset_tickets, dependent: :destroy`
- **`AssetTicket`**
  - **Role:** Hardware breakdown/repair tickets (SMPS burnt, RAM issue, OS corrupt).
  - **Associations:**
    - `acts_as_tenant :tenant`
    - `belongs_to :tenant`
    - `belongs_to :asset`
    - `belongs_to :reported_by, class_name: 'User', foreign_key: :reported_by_user_id`

### Module 5: Academic Lifecycle, Admissions & Fee Engine

- **`Course`**
  - **Role:** Master course catalog (Global: DCA, ADCA, Tally | Custom: Branch Spoken English).
  - **Associations:**
    - `belongs_to :tenant, optional: true` (Global courses have null `tenant_id`)
    - `has_many :enrollments, dependent: :restrict_with_error`
    - `has_many :exams, dependent: :destroy`
- **`Student`**
  - **Role:** Student profile, roll number, KYC.
  - **Associations:**
    - `acts_as_tenant :tenant`
    - `belongs_to :tenant`
    - `belongs_to :user, optional: true` (Linked user account for student PWA portal)
    - `has_many :enrollments, dependent: :destroy`
    - `has_many :certificates, dependent: :restrict_with_error`
    - `has_many :typing_tests, dependent: :destroy`
    - `has_many :exam_submissions, dependent: :destroy`
- **`Enrollment`**
  - **Role:** Maps student to a course, batch time, and fee agreement.
  - **Associations:**
    - `acts_as_tenant :tenant`
    - `belongs_to :tenant`
    - `belongs_to :student`
    - `belongs_to :course`
    - `has_many :fee_transactions, dependent: :destroy`
    - `has_many :attendances, dependent: :destroy`
    - `has_one :certificate, dependent: :destroy`
- **`FeeTransaction`**
  - **Role:** Fee installment receipts, payment mode, and balance tracking.
  - **Associations:**
    - `acts_as_tenant :tenant`
    - `belongs_to :tenant`
    - `belongs_to :enrollment`
    - `belongs_to :collected_by, class_name: 'User', foreign_key: :collected_by_user_id`
- **`Attendance`**
  - **Role:** Daily batch attendance logs.
  - **Associations:**
    - `acts_as_tenant :tenant`
    - `belongs_to :tenant`
    - `belongs_to :enrollment`
    - `belongs_to :marked_by, class_name: 'User', foreign_key: :marked_by_user_id`

### Module 6: Online Examinations & Typing Lab

- **`Exam`**
  - **Role:** Course-specific online test configuration.
  - **Associations:**
    - `acts_as_tenant :tenant`
    - `belongs_to :tenant`
    - `belongs_to :course`
    - `has_many :exam_questions, dependent: :destroy`
    - `has_many :exam_submissions, dependent: :destroy`
- **`ExamQuestion`**
  - **Role:** MCQ question repository with options and answer keys.
  - **Associations:**
    - `belongs_to :exam`
- **`ExamSubmission`**
  - **Role:** Student test result, score, and passing status.
  - **Associations:**
    - `acts_as_tenant :tenant`
    - `belongs_to :tenant`
    - `belongs_to :exam`
    - `belongs_to :student`
- **`TypingTest`**
  - **Role:** Hindi/English typing evaluation log (WPM, Accuracy %, Backspaces).
  - **Associations:**
    - `acts_as_tenant :tenant`
    - `belongs_to :tenant`
    - `belongs_to :student`

### Module 7: Tamper-Proof Certificates & Verification

- **`Certificate`**
  - **Role:** Issued diploma, marks summary, PDF URL, and unique SHA-256 verification hash.
  - **Associations:**
    - `acts_as_tenant :tenant`
    - `belongs_to :tenant`
    - `belongs_to :student`
    - `belongs_to :enrollment`
    - `has_one :course, through: :enrollment`

## 3. Strict AI Coding Agent Guidelines

1. **Multi-Tenancy:**
   - Models with tenant affiliation must explicitly declare `acts_as_tenant(:tenant)`.
   - Controllers must never accept `tenant_id` from client payloads. Scoping is handled implicitly by `acts_as_tenant` via `Current.tenant`.
2. **Access Control:**
   - Always write a matching policy in `app/policies/` for every domain resource.
   - Call `authorize @record` on mutations and use `policy_scope(Model)` for index queries.
3. **Response Envelope:**
   - APIs must consistently return:
     - Success: `{ "success": true, "data": { ... } }`
     - Error: `{ "success": false, "errors": [ ... ] }`
4. **Mobile-First Student Interface:**
   - Student portal pages in `app/(student)` must stay clean on 360px mobile viewports with fixed bottom navigation and zero horizontal scrolling.

##

---

# 4. Recommended Production-Grade Additions & Corrections

The following additions close important architectural gaps in the initial blueprint while keeping the original product direction unchanged.

## 4.1 Core Platform / Infrastructure Models

### `AuditLog`
- **Role:** Immutable-ish audit trail for security-sensitive and administrative actions.
- **Examples:** login, role change, fee modification, wallet recharge, certificate issue/revoke, asset status change, student deletion/archive.
- **Associations:**
  - `acts_as_tenant :tenant` where applicable
  - `belongs_to :tenant, optional: true`
  - `belongs_to :user, optional: true`
- **Important fields:** `action`, `auditable_type`, `auditable_id`, `metadata`, `ip_address`, `user_agent`, `request_id`.

### `Notification`
- **Role:** In-app notification center for admins, trainers, receptionists and students.
- **Associations:**
  - `acts_as_tenant :tenant`
  - `belongs_to :tenant`
  - `belongs_to :user`
- **Important fields:** `title`, `body`, `type`, `read_at`, `data`.

### `RefreshToken`
- **Role:** Secure JWT session/refresh-token lifecycle.
- **Associations:**
  - `belongs_to :user`
- **Important fields:** `token_digest`, `expires_at`, `revoked_at`, `ip_address`, `user_agent`.
- **Rule:** Store token digests rather than reusable raw refresh tokens.

### `FileAttachment`
- **Role:** Central metadata layer for documents, student KYC, certificates, asset invoices, course materials and CMS media.
- **Associations:**
  - `acts_as_tenant :tenant`
  - `belongs_to :tenant`
  - `belongs_to :attachable, polymorphic: true`
- **Storage:** S3 / MinIO / Cloudflare R2.
- **Important fields:** `storage_key`, `filename`, `content_type`, `byte_size`, `checksum`.

---

## 4.2 Academic Models That Should Be Added

The current `Course -> Enrollment` model is good, but a franchise ERP normally needs a separate batch and session layer.

### `Batch`
- **Role:** Actual running class/group for a course.
- **Associations:**
  - `acts_as_tenant :tenant`
  - `belongs_to :tenant`
  - `belongs_to :course`
  - `belongs_to :trainer, class_name: 'User', optional: true`
  - `has_many :enrollments`
  - `has_many :batch_schedules`
- **Fields:** `name`, `code`, `start_date`, `end_date`, `capacity`, `status`.

### `BatchSchedule`
- **Role:** Recurring timetable.
- **Associations:**
  - `belongs_to :batch`
- **Fields:** `weekday`, `start_time`, `end_time`, `room_name`.

### `ClassSession`
- **Role:** A concrete daily class session.
- **Associations:**
  - `acts_as_tenant :tenant`
  - `belongs_to :tenant`
  - `belongs_to :batch`
  - `belongs_to :trainer, class_name: 'User', optional: true`
  - `has_many :attendances`
- **Why:** Separates the planned timetable from an actual class occurrence.

### `StudentDocument`
- **Role:** KYC / admission documents.
- **Associations:**
  - `acts_as_tenant :tenant`
  - `belongs_to :tenant`
  - `belongs_to :student`
  - `has_one :file_attachment, as: :attachable`
- **Examples:** photo, Aadhaar/PAN where legally appropriate, previous qualification, address proof.

---

## 4.3 Admissions & Lead Pipeline

Add a lightweight CRM before `Student`.

### `Lead`
- **Role:** Prospect who has not yet enrolled.
- **Associations:**
  - `acts_as_tenant :tenant`
  - `belongs_to :tenant`
  - `belongs_to :assigned_to, class_name: 'User', optional: true`
  - `has_many :follow_ups`
- **Fields:** `name`, `phone`, `email`, `source`, `interested_course_id`, `status`.

### `FollowUp`
- **Role:** Sales/admission follow-up history.
- **Associations:**
  - `acts_as_tenant :tenant`
  - `belongs_to :tenant`
  - `belongs_to :lead`
  - `belongs_to :user`
- **Fields:** `scheduled_at`, `completed_at`, `notes`, `outcome`.

### `Admission`
- **Role:** Admission/application record before or alongside final enrollment.
- **Associations:**
  - `acts_as_tenant :tenant`
  - `belongs_to :tenant`
  - `belongs_to :student`
  - `belongs_to :course`
  - `belongs_to :batch, optional: true`
- **Rule:** Keep lead, admission and enrollment as separate lifecycle concepts.

---

## 4.4 Fee Engine Corrections

`FeeTransaction` should not itself be responsible for calculating the entire financial state.

Add:

### `FeePlan`
- **Role:** Agreed course fee structure.
- **Associations:**
  - `acts_as_tenant :tenant`
  - `belongs_to :tenant`
  - `belongs_to :enrollment`
  - `has_many :fee_installments`
- **Fields:** `total_fee`, `discount`, `net_fee`, `currency`.

### `FeeInstallment`
- **Role:** Planned installment schedule.
- **Associations:**
  - `belongs_to :fee_plan`
  - `has_many :fee_transactions`
- **Fields:** `due_date`, `amount`, `status`.

### `FeeTransaction`
Keep as the immutable payment/receipt event:
- Never silently edit financial history.
- Corrections should be represented by reversal/refund/adjustment transactions.
- Every payment should have a unique receipt number.
- Use database transactions for payment + receipt generation.

---

## 4.5 Wallet System Corrections

The wallet should behave as a ledger, not merely a balance column.

### Recommended additions
- `WalletTransaction`: immutable ledger event.
- `Wallet` (optional but recommended): current balance/cache for fast reads.
- Every balance-changing operation must have:
  1. DB transaction
  2. row lock / concurrency protection
  3. ledger entry
  4. idempotency key where external payment systems are involved.

### Wallet transaction types
- `recharge`
- `certificate_debit`
- `refund`
- `adjustment`
- `bonus`
- `reversal`

Never allow direct client-side balance updates.

---

## 4.6 Certificate Lifecycle Improvements

Current certificate flow is good, but add explicit lifecycle states.

### Recommended status
`draft -> queued -> generating -> issued -> revoked`

Optional:
`failed`

### `CertificateRevocation`
- **Role:** Stores why and when a certificate was revoked.
- **Associations:**
  - `belongs_to :certificate`
  - `belongs_to :revoked_by, class_name: 'User'`
- **Fields:** `reason`, `revoked_at`.

### Verification
Verification should return:
- certificate number
- student name
- course
- center
- issue date
- result/grade where appropriate
- current status
- revocation information if revoked

Do not expose internal tenant IDs, database IDs or private student/KYC data publicly.

---

# 5. Recommended Domain Relationships

```text
Tenant
 ├── Users
 ├── Roles ── RolePermissions ── Permissions
 ├── Students
 │    ├── StudentDocuments
 │    ├── Enrollments
 │    │    ├── FeePlan ── FeeInstallments ── FeeTransactions
 │    │    ├── Attendances
 │    │    └── Certificate
 │    ├── ExamSubmissions
 │    └── TypingTests
 │
 ├── Courses
 │    ├── Batches
 │    │    ├── BatchSchedules
 │    │    └── ClassSessions
 │    │         └── Attendances
 │    └── Exams
 │         ├── ExamQuestions
 │         └── ExamSubmissions
 │
 ├── Assets
 │    └── AssetTickets
 │
 ├── Leads
 │    └── FollowUps
 │
 ├── Wallet
 │    └── WalletTransactions
 │
 ├── Notifications
 ├── AuditLogs
 └── FileAttachments
```

---

# 6. Important Missing Product Modules

## 6.1 Dashboard & Reporting
Create dedicated read-oriented reporting endpoints for:
- total students
- active enrollments
- today's attendance
- pending fees
- monthly collections
- certificate count
- active batches
- asset breakdowns
- wallet balance
- admission conversion

Do not calculate expensive dashboard metrics repeatedly inside controllers.

## 6.2 Search & Filtering
All major admin lists should support:
- search
- filters
- sorting
- pagination
- date ranges
- status filters
- CSV export where appropriate

Use database indexes for frequently searched fields.

## 6.3 Global Settings
Add platform/tenant configuration such as:
- timezone
- currency
- academic session
- receipt prefix
- certificate prefix
- date format
- attendance rules
- branding settings

Do not mix operational settings with CMS content.

## 6.4 Communication
Recommended notification channels:
- in-app
- email
- WhatsApp/SMS integration later

Use Sidekiq for outbound communication and record delivery status.

---

# 7. API Architecture

Recommended namespace:

```text
/api/v1/
  auth/
  public/
  admin/
  students/
  tenants/
  courses/
  batches/
  enrollments/
  fees/
  attendance/
  exams/
  typing/
  certificates/
  assets/
  leads/
  reports/
  notifications/
  cms/
```

### API conventions

```json
{
  "success": true,
  "data": {},
  "meta": {}
}
```

Errors:

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

---

# 8. Multi-Tenancy Rules — Strengthen These

The existing `acts_as_tenant` rule should be supplemented with database-level protection.

### Application level
- `Current.tenant` must be established before tenant-scoped queries.
- Never trust `tenant_id` from request params/body.
- Never switch tenants based solely on a client-provided header.
- Tenant must be derived from authenticated user/session or a securely validated host/subdomain context.

### Database level
Where practical:
- foreign keys
- composite unique indexes containing `tenant_id`
- tenant-aware unique constraints
- NOT NULL tenant IDs for tenant-owned resources

Example:

```text
UNIQUE (tenant_id, roll_number)
UNIQUE (tenant_id, receipt_number)
UNIQUE (tenant_id, certificate_number)
UNIQUE (tenant_id, asset_code)
```

---

# 9. Authentication & Security Flow

```text
Login
  │
  ▼
Validate credentials
  │
  ▼
Issue short-lived access JWT
  +
Secure refresh token
  │
  ▼
Request
  │
  ▼
Authenticate User
  │
  ▼
Resolve Tenant
  │
  ▼
Set Current.tenant
  │
  ▼
Pundit Authorization
  │
  ▼
Policy Scope / Record Access
  │
  ▼
Controller Action
```

Security requirements:
- password hashing
- refresh-token rotation
- token revocation
- rate limiting on authentication
- account lock/throttling strategy
- CORS configuration
- secure HTTP headers
- request ID / correlation ID
- audit logging for sensitive actions
- never log passwords, tokens or secrets

---

# 10. Background Job Architecture

Recommended jobs:

```text
GenerateCertificateJob
SendEmailJob
SendNotificationJob
SendFeeReminderJob
GenerateReportJob
ProcessFileJob
CleanupExpiredTokensJob
RecalculateReportingSnapshotJob
```

Every important job should consider:
- retry policy
- idempotency
- failure state
- structured logging
- dead-letter/recovery strategy

---

# 11. Certificate Flow — Improved

```text
Admin
  │
  ▼
Authorize certificate issuance
  │
  ▼
Validate enrollment + marks + payment eligibility
  │
  ▼
BEGIN DB TRANSACTION
  │
  ├── Lock tenant wallet
  ├── Verify available balance
  ├── Debit wallet
  ├── Create wallet ledger entry
  ├── Create certificate
  └── Commit
  │
  ▼
Enqueue GenerateCertificateJob
  │
  ▼
Generate PDF
  │
  ├── Build certificate HTML
  ├── Generate QR
  ├── Render with Chromium
  ├── Upload to object storage
  └── Update certificate
  │
  ▼
ISSUED
  │
  ▼
Public Verification
```

If PDF generation fails, **do not refund automatically without an explicit transactional policy**. The certificate should become `failed` and a safe retry mechanism should exist.

---

# 12. Attendance Flow

```text
Trainer/Admin
    │
    ▼
Select Batch
    │
    ▼
Select Class Session
    │
    ▼
Load active enrollments
    │
    ▼
Mark Present / Absent / Late / Leave
    │
    ▼
Validate duplicate attendance
    │
    ▼
Save attendance records
    │
    ▼
Audit action
    │
    ▼
Student PWA sees attendance
```

Recommended attendance statuses:

```text
present
absent
late
leave
```

---

# 13. Examination Flow

```text
Admin
  │
  ▼
Create Exam
  │
  ├── Questions
  ├── Duration
  ├── Passing Score
  ├── Attempt Rules
  └── Schedule
  │
  ▼
Publish Exam
  │
  ▼
Student Starts Attempt
  │
  ▼
Create ExamSubmission
  │
  ▼
Answer Questions
  │
  ▼
Submit / Auto-submit on timeout
  │
  ▼
Evaluate
  │
  ▼
Score + Pass/Fail
  │
  ▼
Result visible to student
```

Add an `ExamAttempt` model if multiple attempts are required. Keep the result separate from the attempt if the product later supports retakes.

---

# 14. Frontend Application Structure

Recommended:

```text
app/
├── (marketing)/
├── (auth)/
├── (student)/
│   ├── dashboard/
│   ├── courses/
│   ├── attendance/
│   ├── exams/
│   ├── typing/
│   ├── fees/
│   └── certificates/
│
└── (admin)/
    ├── dashboard/
    ├── students/
    ├── leads/
    ├── admissions/
    ├── courses/
    ├── batches/
    ├── fees/
    ├── attendance/
    ├── exams/
    ├── certificates/
    ├── assets/
    ├── reports/
    ├── users/
    ├── roles/
    ├── wallet/
    ├── cms/
    └── settings/
```

Keep:
- Student UX mobile-first.
- Admin UX desktop-first.
- Shared design system components.
- API client centralized.
- Permissions checked server-side; frontend checks are only UX helpers.

---

# 15. Database & Consistency Rules

Use:
- foreign keys for every relationship
- NOT NULL wherever business-required
- check constraints where useful
- unique indexes for business identifiers
- indexes on `tenant_id`
- indexes on common status/date queries
- database transactions for financial operations
- row locking for wallet/financial concurrency
- soft deletion only where business/audit requirements justify it

Avoid:
- storing calculated balances as the only source of truth
- deleting financial transactions
- deleting issued certificates
- polymorphic relationships without strong validation
- unbounded JSON blobs for core relational data

---

# 16. Observability & Operations

Add:

```text
Request ID
Structured logs
Error tracking
Job monitoring
Health endpoint
Readiness endpoint
Database monitoring
Redis monitoring
Storage failure monitoring
```

Recommended endpoints:

```text
GET /health
GET /ready
```

`/health` should be lightweight. `/ready` can validate required dependencies.

---

# 17. Testing Strategy

### Backend
- Model specs
- Request/API specs
- Policy specs
- Service specs
- Job specs
- Multi-tenancy isolation specs
- Financial transaction specs

### Critical security test

```text
Tenant A user
      │
      X
      │
Cannot read/write Tenant B records
```

This should be tested explicitly across every tenant-owned resource.

### Frontend
- component tests
- API integration tests
- critical user-flow tests
- responsive 360px student viewport tests

### E2E critical flows
1. Admin login
2. Create student
3. Create course
4. Create batch
5. Enroll student
6. Collect fee
7. Mark attendance
8. Student takes exam
9. Issue certificate
10. Verify certificate publicly

---

# 18. Recommended Service Layer

Controllers should remain thin.

Example:

```text
CertificateIssuanceService
WalletDebitService
FeeCollectionService
StudentEnrollmentService
ExamEvaluationService
AttendanceMarkingService
LeadConversionService
```

Services should contain business workflows; policies should contain authorization; models should contain domain-level invariants and associations.

---

# 19. Important Architectural Correction

The original blueprint says:

> `Certificate` has `has_one :course, through: :enrollment`

This is valid Rails syntax conceptually, but the domain relationship is actually:

```text
Certificate
   -> Enrollment
       -> Course
```

So the certificate does not independently own a course. Keep `Enrollment` as the authoritative source for the course.

Likewise, attendance should ideally point to the **specific enrollment + class session**, rather than only representing a generic daily record.

---

# 20. Suggested Module Roadmap

```text
PHASE 1  Foundation & Project Setup
PHASE 2  Authentication + Multi-Tenancy
PHASE 3  RBAC + Permissions
PHASE 4  Tenant / Franchise Management
PHASE 5  CMS + White Label
PHASE 6  Students + Admissions
PHASE 7  Courses + Batches + Enrollment
PHASE 8  Fees + Receipts + Wallet
PHASE 9  Attendance
PHASE 10 Online Exams + Typing
PHASE 11 Certificate Engine + QR Verification
PHASE 12 IT Asset + Ticket Management
PHASE 13 Notifications + Communication
PHASE 14 Reports + Dashboards
PHASE 15 File Storage + Media
PHASE 16 Audit + Security + Observability
PHASE 17 Student PWA
PHASE 18 Admin ERP UI
PHASE 19 Automated Testing + E2E
PHASE 20 Production Deployment + Hardening
```

---

# 21. Final Architectural Principle

The system should be designed around these boundaries:

```text
AUTHENTICATION
      ↓
TENANT RESOLUTION
      ↓
AUTHORIZATION
      ↓
DOMAIN SERVICE
      ↓
DATABASE TRANSACTION
      ↓
DOMAIN EVENT / AUDIT
      ↓
BACKGROUND JOB
      ↓
NOTIFICATION / EXTERNAL SYSTEM
```

**Source of truth hierarchy:**

```text
Database
   ↓
Domain Services
   ↓
API
   ↓
Frontend
   ↓
PWA / Browser
```

The frontend must never become the source of truth for authorization, financial balances, attendance integrity, examination results, certificate validity, or tenant isolation.

---

# 22. Canonical Repository / File Structure

The repository must follow a predictable modular structure. Do not introduce alternative locations for the same responsibility without an explicit architecture decision.

## 22.1 Backend — Rails 8 API

```text
backend/
├── app/
│   ├── controllers/
│   │   └── api/
│   │       └── v1/
│   │           ├── auth/
│   │           ├── public/
│   │           ├── admin/
│   │           ├── tenants/
│   │           ├── students/
│   │           ├── leads/
│   │           ├── admissions/
│   │           ├── courses/
│   │           ├── batches/
│   │           ├── enrollments/
│   │           ├── fees/
│   │           ├── attendance/
│   │           ├── exams/
│   │           ├── typing/
│   │           ├── certificates/
│   │           ├── assets/
│   │           ├── wallet/
│   │           ├── notifications/
│   │           ├── reports/
│   │           ├── cms/
│   │           └── settings/
│   │
│   ├── models/
│   │   ├── concerns/
│   │   └── ...
│   │
│   ├── policies/
│   │   ├── application_policy.rb
│   │   └── ...
│   │
│   ├── services/
│   │   ├── authentication/
│   │   ├── students/
│   │   ├── admissions/
│   │   ├── enrollment/
│   │   ├── fees/
│   │   ├── wallet/
│   │   ├── attendance/
│   │   ├── exams/
│   │   ├── certificates/
│   │   ├── assets/
│   │   ├── notifications/
│   │   ├── reports/
│   │   └── files/
│   │
│   ├── jobs/
│   │   ├── certificates/
│   │   ├── notifications/
│   │   ├── reports/
│   │   ├── files/
│   │   └── maintenance/
│   │
│   ├── serializers/
│   ├── validators/
│   ├── queries/
│   ├── presenters/
│   ├── mailers/
│   └── views/
│
├── config/
│   ├── routes/
│   ├── initializers/
│   ├── environments/
│   └── ...
│
├── db/
│   ├── migrate/
│   ├── seeds.rb
│   └── schema.rb
│
├── lib/
│   ├── tasks/
│   └── ...
│
├── spec/
│   ├── models/
│   ├── requests/
│   ├── policies/
│   ├── services/
│   ├── jobs/
│   ├── queries/
│   ├── serializers/
│   ├── support/
│   └── factories/
│
├── storage/                 # local development only
├── .env.example
├── Gemfile
├── Rakefile
└── README.md
```

### Backend ownership rules

- `controllers/` = HTTP orchestration only.
- `models/` = associations, validations and domain invariants.
- `policies/` = authorization only.
- `services/` = multi-step business workflows.
- `queries/` = complex read/query logic.
- `jobs/` = asynchronous work only.
- `serializers/` = API response representation.
- `validators/` = reusable complex validation.
- `mailers/` = email composition/delivery entry points.
- `db/migrate/` = schema evolution only.

---

## 22.2 Frontend — Next.js 15+ App Router

```text
frontend/
├── app/
│   ├── (marketing)/
│   ├── (auth)/
│   ├── (student)/
│   │   ├── dashboard/
│   │   ├── courses/
│   │   ├── attendance/
│   │   ├── exams/
│   │   ├── typing/
│   │   ├── fees/
│   │   └── certificates/
│   │
│   ├── (admin)/
│   │   ├── dashboard/
│   │   ├── students/
│   │   ├── leads/
│   │   ├── admissions/
│   │   ├── courses/
│   │   ├── batches/
│   │   ├── enrollments/
│   │   ├── fees/
│   │   ├── attendance/
│   │   ├── exams/
│   │   ├── certificates/
│   │   ├── assets/
│   │   ├── wallet/
│   │   ├── reports/
│   │   ├── users/
│   │   ├── roles/
│   │   ├── cms/
│   │   └── settings/
│   │
│   ├── api/                 # Only when a BFF/server route is genuinely needed
│   ├── layout.tsx
│   └── globals.css
│
├── components/
│   ├── ui/                  # shadcn/ui primitives
│   ├── forms/
│   ├── tables/
│   ├── charts/
│   ├── navigation/
│   ├── student/
│   ├── admin/
│   └── shared/
│
├── features/
│   ├── auth/
│   ├── students/
│   ├── admissions/
│   ├── courses/
│   ├── batches/
│   ├── enrollments/
│   ├── fees/
│   ├── attendance/
│   ├── exams/
│   ├── typing/
│   ├── certificates/
│   ├── assets/
│   ├── wallet/
│   ├── reports/
│   ├── notifications/
│   └── cms/
│
├── lib/
│   ├── api/
│   ├── auth/
│   ├── permissions/
│   ├── validation/
│   ├── formatting/
│   └── utils/
│
├── hooks/
├── stores/
├── types/
├── constants/
├── public/
├── tests/
│   ├── unit/
│   ├── integration/
│   └── e2e/
├── middleware.ts
├── next.config.ts
├── package.json
└── README.md
```

### Frontend ownership rules

- `app/` = routing, layouts and page composition.
- `features/` = domain-specific UI logic.
- `components/` = reusable presentation components.
- `lib/api/` = centralized API client.
- `lib/permissions/` = UI permission helpers only.
- `stores/` = client state that genuinely needs persistence/shared state.
- `types/` = shared TypeScript types.
- Server-side authorization remains authoritative in Rails.

---

## 22.3 Infrastructure / DevOps

```text
infra/
├── nginx/
├── docker/
├── scripts/
├── monitoring/
├── backups/
└── deployment/

.github/
└── workflows/
    ├── backend-ci.yml
    ├── frontend-ci.yml
    └── deploy.yml

docs/
├── architecture/
├── api/
├── database/
├── security/
├── deployment/
└── decisions/
```

Architecture decisions should be recorded in `docs/decisions/` as ADRs when a change materially affects the system.

---

# 23. AI Agent Navigation Contract

Before changing code, an AI coding agent MUST identify:

```text
1. Which module is being changed?
2. Which layer owns the requested behavior?
3. Which existing files implement the same pattern?
4. Which tenant/security rules apply?
5. Which model/policy/service/job/tests are affected?
6. What existing tests must remain green?
```

The agent must prefer the existing project pattern over inventing a new pattern.

If an appropriate pattern already exists elsewhere in the repository, copy its architectural approach—not blindly its code.


---

# 24. Final Review & Implementation Guardrails

## 24.1 Canonical Naming

Use these canonical domain names consistently:

```text
Tenant
User
Role
Permission
RolePermission

Lead
FollowUp
Admission

Student
StudentDocument
Course
Batch
BatchSchedule
ClassSession
Enrollment

FeePlan
FeeInstallment
FeeTransaction

Attendance

Exam
ExamQuestion
ExamAttempt
ExamSubmission
TypingTest

Wallet
WalletTransaction

Certificate
CertificateRevocation

Asset
AssetTicket

Notification
AuditLog
RefreshToken
FileAttachment
```

If an implementation needs a different name, verify that an equivalent model does not already exist before introducing it.

## 24.2 Important Relationship Clarifications

```text
Course
  └── Batch
       └── Enrollment
            └── Student

Batch
  └── ClassSession
       └── Attendance

Enrollment
  ├── FeePlan
  │    └── FeeInstallment
  │         └── FeeTransaction
  └── Certificate

Exam
  ├── ExamQuestion
  └── ExamAttempt
       └── ExamSubmission
```

If the product supports only one exam attempt initially, `ExamAttempt` may be introduced when retakes/attempt history are required. Do not prematurely duplicate result data.

## 24.3 Data Ownership

Every model should have an explicit answer to:

```text
Who owns this record?
Which tenant owns it?
Can it be global?
Who can read it?
Who can mutate it?
Can it be deleted?
Does it require an audit trail?
```

Global platform content such as selected CMS settings may be intentionally non-tenant-scoped. Everything else must be explicitly classified rather than accidentally left unscoped.

## 24.4 Delete vs Archive

Do not hard-delete business-critical historical records by default.

Prefer archival/status transitions for:

```text
Students with historical enrollments
Completed enrollments
Financial records
Issued/revoked certificates
Audit logs
Important asset history
```

Use `dependent: :destroy` only when deleting the parent is genuinely safe and the child has no independent historical value.

## 24.5 Idempotency

Use idempotency protection for operations that can be retried by clients, jobs, payment providers, or network retries.

High-priority examples:

```text
Fee payment creation
Wallet recharge
Wallet debit
Certificate issuance
External notification delivery
Webhook processing
```

## 24.6 External Integrations

All external integrations should be isolated behind dedicated adapters/services.

Example:

```text
app/services/integrations/
├── payments/
├── storage/
├── email/
├── sms/
└── whatsapp/
```

Do not spread vendor-specific API calls throughout controllers and domain models.

## 24.7 Architecture Stability

The default architecture remains:

```text
Next.js
    ↓
Rails API
    ↓
Domain Services / Queries
    ↓
PostgreSQL
    +
Redis / Sidekiq
    ↓
Object Storage / External Providers
```

Do not introduce microservices unless scale or a concrete product requirement makes the modular monolith insufficient.
